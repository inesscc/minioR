#' Read and Concatenate Many Parquet Objects from MinIO
#'
#' Reads multiple Parquet objects from MinIO and concatenates them. Objects can be
#' provided explicitly via \code{objects} or discovered via \code{prefix} and
#' optional regex \code{pattern}. Optionally filters objects by a date-like suffix
#' in the key: \code{_YYYY}, \code{_YYYYMM}, or \code{_YYYYMMDD} (inclusive range).
#'
#' The function computes total remote bytes using \code{\link{minio_get_metadata}}
#' and warns if the estimated size exceeds \code{warn_bytes}. For large reads, you
#' can stream results to a local Parquet dataset directory via \code{out_dir}.
#'
#' Concatenation is schema-union: the output includes all columns across all files.
#' Missing columns in individual files are filled with \code{NA}.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param objects Character vector or \code{NULL}. Explicit object keys to read.
#' @param prefix Character or \code{NULL}. Prefix for listing objects when \code{objects} is \code{NULL}.
#' @param pattern Character or \code{NULL}. Regex pattern to filter keys when using \code{prefix}.
#' @param date_from,date_to Character/numeric or \code{NULL}. Inclusive range filter based on suffix.
#'   If 4 digits -> year, 6 digits -> yearmonth, 8 digits -> yearmonthday.
#'   Example: \code{date_from = 2020, date_to = 2024} filters \code{_YYYY}.
#' @param warn_bytes Numeric. If total remote size exceeds this threshold, a warning is emitted.
#'   Defaults to 1e9 (≈ 1 GB).
#' @param out_dir Character or \code{NULL}. If provided, results are streamed to this local directory
#'   as a Parquet dataset (one file per input object) and the function returns the directory path.
#' @param verbose Logical. Whether to print progress messages. Defaults to \code{TRUE}.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return If \code{out_dir} is \code{NULL}, returns a \code{data.frame} (union schema).
#'   If \code{out_dir} is provided, returns \code{out_dir} (invisibly) after writing the dataset.
#'
#' @examples
#' \dontrun{
#' # Explicit keys
#' df <- minio_read_many(
#'   bucket = "assets",
#'   objects = c("raw/x_202301.parquet", "raw/x_202302.parquet")
#' )
#'
#' # Prefix + pattern + date range by year
#' df <- minio_read_many(
#'   bucket = "assets",
#'   prefix = "raw/x/",
#'   pattern = "\\\\.parquet$",
#'   date_from = 2020,
#'   date_to = 2024
#' )
#'
#' # Stream to local dataset (recommended for large volumes)
#' out <- minio_read_many(
#'   bucket = "assets",
#'   prefix = "raw/x/",
#'   pattern = "\\\\.parquet$",
#'   date_from = 202301,
#'   date_to = 202312,
#'   out_dir = "output/many_parquet_dataset"
#' )
#' }
#'
#' @export
minio_read_many <- function(bucket,
                            objects = NULL,
                            prefix = NULL,
                            pattern = NULL,
                            date_from = NULL,
                            date_to = NULL,
                            warn_bytes = 1e9,
                            out_dir = NULL,
                            verbose = TRUE,
                            use_https = TRUE,
                            region = "") {
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.logical(verbose), length(verbose) == 1,
    is.logical(use_https), length(use_https) == 1,
    is.character(region), length(region) == 1,
    is.numeric(warn_bytes), length(warn_bytes) == 1
  )

  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop(
      "Package 'arrow' is required to read/write Parquet files. ",
      "Please install it with install.packages('arrow').",
      call. = FALSE
    )
  }

  # --- helpers ---
  is_parquet_key <- function(x) {
    ext <- tolower(tools::file_ext(x))
    ext %in% c("parquet", "pq")
  }

  parse_suffix_digits <- function(key) {
    # Extract trailing _{digits} before extension (supports .parquet or .pq)
    # e.g. "path/file_202401.parquet" -> "202401"
    base <- sub("\\.(parquet|pq)$", "", key, ignore.case = TRUE)
    m <- regexpr("_[0-9]{4,8}$", base, perl = TRUE)
    if (m[1] == -1) return(NA_character_)
    sub("^_", "", regmatches(base, m))
  }

  normalize_date_input <- function(x) {
    if (is.null(x)) return(NULL)
    if (is.numeric(x)) x <- as.character(as.integer(x))
    stopifnot(is.character(x), length(x) == 1)
    x <- gsub("\\s+", "", x)
    if (!grepl("^[0-9]{4}([0-9]{2}([0-9]{2})?)?$", x)) {
      stop("Invalid date filter value: '", x, "'. Use YYYY, YYYYMM, or YYYYMMDD.", call. = FALSE)
    }
    x
  }

  # --- resolve keys ---
  keys <- NULL
  if (!is.null(objects)) {
    stopifnot(is.character(objects))
    keys <- objects
  } else {
    if (is.null(prefix)) {
      stop("Provide either 'objects' or 'prefix' (optionally with 'pattern').", call. = FALSE)
    }
    stopifnot(is.character(prefix), length(prefix) == 1)

    keys <- minio_list_objects(bucket = bucket, prefix = prefix, use_https = use_https, region = region)

    if (!is.null(pattern)) {
      stopifnot(is.character(pattern), length(pattern) == 1)
      keys <- keys[grepl(pattern, keys, perl = TRUE)]
    }
  }

  keys <- unique(keys[!is.na(keys)])
  if (length(keys) == 0) {
    return(if (is.null(out_dir)) {
      data.frame(stringsAsFactors = FALSE)
    } else {
      invisible(out_dir)
    })
  }

  # Only parquet
  keys <- keys[vapply(keys, is_parquet_key, logical(1))]
  if (length(keys) == 0) {
    stop("No Parquet objects found after filtering.", call. = FALSE)
  }

  # --- date range filtering ---
  date_from <- normalize_date_input(date_from)
  date_to   <- normalize_date_input(date_to)

  if (!is.null(date_from) || !is.null(date_to)) {
    if (is.null(date_from) || is.null(date_to)) {
      stop("Provide both 'date_from' and 'date_to' for date range filtering.", call. = FALSE)
    }
    if (nchar(date_from) != nchar(date_to)) {
      stop("'date_from' and 'date_to' must have the same precision (YYYY vs YYYYMM vs YYYYMMDD).", call. = FALSE)
    }
    nd <- nchar(date_from)
    if (!nd %in% c(4, 6, 8)) {
      stop("Date precision must be 4, 6, or 8 digits.", call. = FALSE)
    }

    suf <- vapply(keys, parse_suffix_digits, character(1))
    ok_precision <- !is.na(suf) & nchar(suf) == nd
    suf_num <- suppressWarnings(as.integer(ifelse(ok_precision, suf, NA)))
    from_num <- as.integer(date_from)
    to_num <- as.integer(date_to)

    keep <- ok_precision & !is.na(suf_num) & suf_num >= from_num & suf_num <= to_num
    keys <- keys[keep]

    if (length(keys) == 0) {
      stop("No Parquet objects matched the provided date range filter.", call. = FALSE)
    }
  }

  # --- metadata pre-check (bytes) ---
  if (verbose) message("Fetching metadata for ", length(keys), " objects...")
  sizes <- numeric(length(keys))
  for (i in seq_along(keys)) {
    meta <- minio_get_metadata(
      bucket = bucket,
      object = keys[i],
      quiet = TRUE,
      use_https = use_https,
      region = region
    )
    sizes[i] <- suppressWarnings(as.numeric(meta$size))
    if (is.na(sizes[i])) sizes[i] <- 0
  }
  total_bytes <- sum(sizes, na.rm = TRUE)

  if (is.finite(warn_bytes) && total_bytes >= warn_bytes) {
    warning(
      "Total remote size is ~", format(total_bytes, big.mark = ","), " bytes. ",
      "This may exceed memory depending on your environment. ",
      "Consider using out_dir to stream results to disk (dataset parquet).",
      call. = FALSE
    )
  }

  # --- stream to disk mode ---
  if (!is.null(out_dir)) {
    stopifnot(is.character(out_dir), length(out_dir) == 1)
    if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

    if (verbose) message("Streaming to local dataset dir: ", out_dir)

    for (i in seq_along(keys)) {
      if (verbose) message("[", i, "/", length(keys), "] Reading: ", keys[i])
      tab <- minio_get_parquet(bucket = bucket, object = keys[i]) # may be Table/df depending arrow
      # Ensure we write a parquet file per object (dataset-style)
      # Write with a stable file name derived from key
      safe_name <- gsub("[^A-Za-z0-9._-]+", "_", keys[i])
      # keep it from getting too long on Windows
      if (nchar(safe_name) > 180) safe_name <- paste0(substr(safe_name, 1, 180), "_", i)
      out_file <- file.path(out_dir, paste0(safe_name, ".parquet"))

      # Write using arrow; convert to Table if needed
      if (!inherits(tab, "Table")) tab <- arrow::Table$create(tab)
      arrow::write_parquet(tab, sink = out_file)
    }

    return(invisible(out_dir))
  }

  # --- in-memory mode (union schema data.frame) ---
  if (verbose) message("Reading and concatenating ", length(keys), " Parquet objects in memory...")

  dfs <- vector("list", length(keys))
  all_cols <- character(0)

  for (i in seq_along(keys)) {
    if (verbose) message("[", i, "/", length(keys), "] Reading: ", keys[i])
    x <- minio_get_parquet(bucket = bucket, object = keys[i])

    # Normalize to data.frame (schema-union will be handled below)
    df <- if (inherits(x, "Table")) {
      as.data.frame(x)
    } else {
      as.data.frame(x)
    }

    dfs[[i]] <- df
    all_cols <- union(all_cols, names(df))
  }

  # Add missing cols as NA and align column order
  dfs2 <- lapply(dfs, function(df) {
    missing <- setdiff(all_cols, names(df))
    if (length(missing) > 0) {
      for (m in missing) df[[m]] <- NA
    }
    df <- df[, all_cols, drop = FALSE]
    df
  })

  out <- do.call(rbind, dfs2)
  rownames(out) <- NULL
  out
}
