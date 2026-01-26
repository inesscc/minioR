#' Write an Object to MinIO (Auto-detect by Extension)
#'
#' Serializes an R object to bytes (\code{raw}) based on the file extension of
#' \code{object} and uploads it to MinIO using \code{\link{minio_put_object}}.
#'
#' Supported formats are selected by extension:
#' \itemize{
#'   \item \code{.csv} via \code{utils::write.csv()}
#'   \item \code{.parquet} / \code{.pq} via \code{arrow::write_parquet()}
#'   \item \code{.json} via \code{jsonlite::toJSON()}
#'   \item \code{.xlsx} via \code{writexl::write_xlsx()}
#'   \item \code{.feather} via \code{feather::write_feather()}
#'   \item \code{.dta} via \code{haven::write_dta()}
#'   \item \code{.rds} via \code{saveRDS()}
#'   \item \code{.rda} / \code{.RData} via \code{save()}
#' }
#'
#' Additional arguments (\code{...}) are forwarded to the underlying writer
#' selected by extension.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) within the bucket. Extension is
#'   used to infer the serialization format.
#' @param x R object to serialize and upload (often a data.frame, list, model, etc.).
#' @param ... Additional arguments passed to the underlying writer function.
#' @param content_type Character or \code{NULL}. Optional MIME type. If \code{NULL},
#'   a sensible default is used based on the extension.
#' @param multipart Logical. Whether to use multipart upload. Defaults to \code{FALSE}.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return Invisibly returns \code{TRUE} if the upload was successful.
#'
#' @examples
#' \dontrun{
#' # CSV
#' minio_write_object("assets", "tmp/df.csv", mtcars, row.names = FALSE)
#'
#' # JSON (returns JSON in MinIO)
#' minio_write_object("assets", "tmp/config.json", list(a = 1, b = TRUE), auto_unbox = TRUE)
#'
#' # RDS
#' minio_write_object("assets", "tmp/model.rds", lm(mpg ~ wt, data = mtcars))
#'
#' # RData (stores an object named 'x' by default)
#' minio_write_object("assets", "tmp/objects.RData", mtcars)
#' }
#'
#' @export
minio_write_object <- function(bucket,
                               object,
                               x,
                               ...,
                               content_type = NULL,
                               multipart = FALSE,
                               use_https = TRUE,
                               region = "") {
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1,
    is.logical(multipart), length(multipart) == 1,
    is.logical(use_https), length(use_https) == 1,
    is.character(region), length(region) == 1
  )

  ext <- tolower(tools::file_ext(object))
  if (!nzchar(ext)) {
    stop(
      "Cannot detect serialization format: 'object' has no file extension. ",
      "Provide an extension like .csv, .parquet, .json, .xlsx, .rds, .RData.",
      call. = FALSE
    )
  }

  # Default MIME types (can be overridden by content_type)
  if (is.null(content_type)) {
    content_type <- switch(
      ext,
      "csv"     = "text/csv",
      "json"    = "application/json",
      "parquet" = "application/x-parquet",
      "pq"      = "application/x-parquet",
      "feather" = "application/octet-stream",
      "xlsx"    = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "dta"     = "application/octet-stream",
      "rds"     = "application/octet-stream",
      "rda"     = "application/octet-stream",
      "rdata"   = "application/octet-stream",
      "application/octet-stream"
    )
  } else {
    stopifnot(is.character(content_type), length(content_type) == 1)
    if (!nzchar(content_type)) {
      stop("'content_type' must be a non-empty string when provided.", call. = FALSE)
    }
  }

  tmp <- tempfile(fileext = paste0(".", ext))
  on.exit(unlink(tmp), add = TRUE)

  # Serialize to temp file based on extension
  if (ext %in% c("csv")) {
    if (!is.data.frame(x)) {
      stop("For '.csv', 'x' must be a data.frame.", call. = FALSE)
    }
    utils::write.csv(x, file = tmp, ...)

  } else if (ext %in% c("parquet", "pq")) {
    if (!requireNamespace("arrow", quietly = TRUE)) {
      stop("Package 'arrow' is required to write Parquet files.", call. = FALSE)
    }
    arrow::write_parquet(x, sink = tmp, ...)

  } else if (ext %in% c("json")) {
    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      stop("Package 'jsonlite' is required to write JSON files.", call. = FALSE)
    }
    json_txt <- jsonlite::toJSON(x, ...)
    # Ensure UTF-8 text output
    writeLines(enc2utf8(json_txt), con = tmp, useBytes = TRUE)

  } else if (ext %in% c("xlsx")) {
    if (!requireNamespace("writexl", quietly = TRUE)) {
      stop("Package 'writexl' is required to write Excel (.xlsx) files.", call. = FALSE)
    }
    # writexl accepts a data.frame or a named list of data.frames (multiple sheets)
    writexl::write_xlsx(x, path = tmp, ...)

  } else if (ext %in% c("feather")) {
    if (!requireNamespace("feather", quietly = TRUE)) {
      stop("Package 'feather' is required to write Feather files.", call. = FALSE)
    }
    feather::write_feather(x, path = tmp, ...)

  } else if (ext %in% c("dta")) {
    if (!requireNamespace("haven", quietly = TRUE)) {
      stop("Package 'haven' is required to write Stata (.dta) files.", call. = FALSE)
    }
    haven::write_dta(x, path = tmp, ...)

  } else if (ext %in% c("rds")) {
    saveRDS(x, file = tmp, ...)

  } else if (ext %in% c("rda", "rdata")) {
    # Save into an isolated env. By default we store it as 'x' unless the user
    # passes a named list (then we store each element as its name).
    env <- new.env(parent = emptyenv())

    if (is.list(x) && !is.data.frame(x) && length(x) > 0 && all(nzchar(names(x)))) {
      list2env(x, envir = env)
      save(list = names(x), file = tmp, envir = env, ...)
    } else {
      env$x <- x
      save(list = "x", file = tmp, envir = env, ...)
    }

  } else {
    stop(
      "Unsupported file extension: '", ext, "'. ",
      "Supported: csv, parquet/pq, json, xlsx, feather, dta, rds, rda/rdata.",
      call. = FALSE
    )
  }

  # Read file bytes and upload
  payload <- readBin(tmp, what = "raw", n = file.info(tmp)$size)

  minio_put_object(
    bucket = bucket,
    object = object,
    raw = payload,
    content_type = content_type,
    multipart = multipart,
    use_https = use_https,
    region = region
  )
}
