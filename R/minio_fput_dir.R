#' Upload a Local Directory to MinIO (Preserve Structure)
#'
#' Uploads a local directory to a MinIO bucket preserving the relative folder
#' structure, similar to a "sync". Files are discovered under \code{dir} and
#' uploaded using \code{\link{minio_fput_object}}.
#'
#' You can filter which files to upload using \code{include} and \code{exclude}
#' regex patterns applied to the relative path (POSIX style, forward slashes).
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param dir Character. Local directory path to upload.
#' @param prefix Character or \code{NULL}. Optional object key prefix inside the
#'   bucket. If provided, all objects will be uploaded under this prefix.
#'   Example: \code{"raw/projectA"}.
#' @param recursive Logical. Whether to include subdirectories. Defaults to \code{TRUE}.
#' @param include Character vector of regex patterns. If provided, only files whose
#'   relative path matches at least one pattern are included.
#' @param exclude Character vector of regex patterns. If provided, files whose
#'   relative path matches any pattern are excluded.
#' @param dry_run Logical. If \code{TRUE}, do not upload anything; only return the
#'   planned uploads. Defaults to \code{FALSE}.
#' @param multipart Logical. Whether to enable multipart upload. Defaults to \code{FALSE}.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return A \code{data.frame} with the upload plan and results. Columns:
#'   \code{local_file}, \code{object}, \code{uploaded}, \code{error}.
#'   In \code{dry_run = TRUE}, \code{uploaded} will be \code{FALSE} and \code{error} \code{NA}.
#'
#' @examples
#' \dontrun{
#' # Upload entire directory under a prefix
#' res <- minio_fput_dir(
#'   bucket = "assets",
#'   dir = "data/projectA",
#'   prefix = "raw/projectA",
#'   recursive = TRUE,
#'   exclude = c("\\\\.tmp$", "^\\.git/", "\\\\.DS_Store$"),
#'   dry_run = FALSE
#' )
#' }
#'
#' @export
minio_fput_dir <- function(bucket,
                           dir,
                           prefix = NULL,
                           recursive = TRUE,
                           include = NULL,
                           exclude = NULL,
                           dry_run = FALSE,
                           multipart = FALSE,
                           use_https = TRUE,
                           region = "") {
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(dir), length(dir) == 1,
    is.logical(recursive), length(recursive) == 1,
    is.logical(dry_run), length(dry_run) == 1,
    is.logical(multipart), length(multipart) == 1,
    is.logical(use_https), length(use_https) == 1,
    is.character(region), length(region) == 1
  )

  if (!dir.exists(dir)) {
    stop("Local directory does not exist: ", dir, call. = FALSE)
  }

  if (!is.null(prefix)) {
    stopifnot(is.character(prefix), length(prefix) == 1)
    # Normalize prefix: remove leading slashes, remove trailing slashes
    prefix <- gsub("^/+", "", prefix)
    prefix <- gsub("/+$", "", prefix)
    if (!nzchar(prefix)) prefix <- NULL
  }

  if (!is.null(include)) stopifnot(is.character(include))
  if (!is.null(exclude)) stopifnot(is.character(exclude))

  # List files
  files <- list.files(
    path = dir,
    recursive = recursive,
    all.files = TRUE,
    include.dirs = FALSE,
    full.names = TRUE,
    no.. = TRUE
  )

  # Remove directories just in case (list.files should only return files)
  files <- files[file.info(files)$isdir %in% FALSE]
  if (length(files) == 0) {
    out <- data.frame(
      local_file = character(0),
      object = character(0),
      uploaded = logical(0),
      error = character(0),
      stringsAsFactors = FALSE
    )
    return(out)
  }

  # Build relative paths and normalize to POSIX separators for object keys
  rel <- substring(files, nchar(normalizePath(dir, winslash = "/", mustWork = TRUE)) + 2)
  rel <- gsub("\\\\", "/", rel)

  # Apply include/exclude filters on relative path
  keep <- rep(TRUE, length(rel))

  if (!is.null(include) && length(include) > 0) {
    inc <- rep(FALSE, length(rel))
    for (pat in include) {
      inc <- inc | grepl(pat, rel, perl = TRUE)
    }
    keep <- keep & inc
  }

  if (!is.null(exclude) && length(exclude) > 0) {
    exc <- rep(FALSE, length(rel))
    for (pat in exclude) {
      exc <- exc | grepl(pat, rel, perl = TRUE)
    }
    keep <- keep & !exc
  }

  files <- files[keep]
  rel <- rel[keep]

  if (length(files) == 0) {
    out <- data.frame(
      local_file = character(0),
      object = character(0),
      uploaded = logical(0),
      error = character(0),
      stringsAsFactors = FALSE
    )
    return(out)
  }

  # Build object keys
  objects <- if (is.null(prefix)) rel else paste0(prefix, "/", rel)

  # Prepare result table
  res <- data.frame(
    local_file = files,
    object = objects,
    uploaded = rep(FALSE, length(files)),
    error = rep(NA_character_, length(files)),
    stringsAsFactors = FALSE
  )

  if (dry_run) {
    return(res)
  }

  # Upload sequentially (simple + predictable)
  for (i in seq_along(files)) {
    r <- tryCatch(
      minio_fput_object(
        bucket = bucket,
        file = files[i],
        object = objects[i],
        multipart = multipart,
        use_https = use_https,
        region = region
      ),
      error = function(e) e
    )

    if (inherits(r, "error")) {
      res$uploaded[i] <- FALSE
      res$error[i] <- conditionMessage(r)
    } else {
      res$uploaded[i] <- TRUE
      res$error[i] <- NA_character_
    }
  }

  res
}
