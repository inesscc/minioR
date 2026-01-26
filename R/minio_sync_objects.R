#' Sync Local Files/Directories with MinIO (Wrapper around aws.s3::s3sync)
#'
#' Convenience wrapper for \code{aws.s3::s3sync()} tailored for MinIO usage.
#' It synchronizes a local directory with a bucket/prefix, uploading and/or
#' downloading missing files.
#'
#' Compared to \code{aws.s3::s3sync()}, this wrapper:
#' \itemize{
#'   \item Uses \code{sync} instead of \code{direction}:
#'     \code{"server"} means upload, \code{"local"} means download, and if omitted
#'     performs two-way sync (upload + download), matching \code{s3sync()} default.
#'   \item Forces \code{create = FALSE}.
#'   \item Defaults \code{use_https = TRUE} and \code{region = ""}.
#' }
#'
#' @param path Character. Local directory path to synchronize. Defaults to \code{"."}.
#' @param bucket Character. Name of the bucket.
#' @param prefix Character. Prefix (remote "subdirectory") to consider. Defaults to \code{""}.
#'   For subdirectory-like behavior, typically include a trailing slash (e.g. \code{"raw/projectA/"}).
#' @param sync Character or \code{NULL}. One of \code{"server"} (upload),
#'   \code{"local"} (download), or \code{NULL} for two-way sync (upload + download).
#' @param verbose Logical. Whether to be verbose. Defaults to \code{TRUE}.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO. Defaults to \code{TRUE}.
#' @param region Character. Region string required by \code{aws.s3}. Defaults to \code{""}.
#' @param ... Additional arguments passed to \code{aws.s3::s3sync()} (and then to s3HTTP),
#'   such as \code{multipart}, \code{headers}, etc.
#'
#' @return Logical. Returns \code{TRUE} if the sync completed successfully.
#'
#' @examples
#' \dontrun{
#' # Two-way (upload + download), default behavior
#' minio_sync_objects(
#'   path = "data/projectA",
#'   bucket = "assets",
#'   prefix = "raw/projectA/"
#' )
#'
#' # Only upload local -> server
#' minio_sync_objects(
#'   path = "data/projectA",
#'   bucket = "assets",
#'   prefix = "raw/projectA/",
#'   sync = "server"
#' )
#'
#' # Only download server -> local
#' minio_sync_objects(
#'   path = "data/projectA",
#'   bucket = "assets",
#'   prefix = "raw/projectA/",
#'   sync = "local"
#' )
#' }
#'
#' @export
minio_sync_objects <- function(path = ".",
                               bucket,
                               prefix = "",
                               sync = NULL,
                               verbose = TRUE,
                               use_https = TRUE,
                               region = "",
                               ...) {
  stopifnot(
    is.character(path), length(path) == 1,
    is.character(bucket), length(bucket) == 1,
    is.character(prefix), length(prefix) == 1,
    is.logical(verbose), length(verbose) == 1,
    is.logical(use_https), length(use_https) == 1,
    is.character(region), length(region) == 1
  )

  if (!requireNamespace("aws.s3", quietly = TRUE)) {
    stop(
      "Package 'aws.s3' is required for syncing. ",
      "Install it with install.packages('aws.s3').",
      call. = FALSE
    )
  }

  # Expand path like s3sync does (but keep validation friendly)
  path <- path.expand(path)

  # Map sync -> direction
  direction <- NULL
  if (!is.null(sync)) {
    stopifnot(is.character(sync), length(sync) == 1)
    sync <- tolower(sync)

    if (identical(sync, "server")) {
      direction <- "upload"
    } else if (identical(sync, "local")) {
      direction <- "download"
    } else {
      stop(
        "Invalid 'sync' value: '", sync, "'. ",
        "Use 'server', 'local', or NULL for two-way sync.",
        call. = FALSE
      )
    }
  }
  # If sync is NULL, keep direction NULL -> s3sync default (two-way)

  # NOTE: create is always FALSE (forced)
  if (is.null(direction)) {
    aws.s3::s3sync(
      path = path,
      bucket = bucket,
      prefix = prefix,
      verbose = verbose,
      create = FALSE,
      use_https = use_https,
      region = region,
      ...
    )
  } else {
    aws.s3::s3sync(
      path = path,
      bucket = bucket,
      prefix = prefix,
      direction = direction,
      verbose = verbose,
      create = FALSE,
      use_https = use_https,
      region = region,
      ...
    )
  }
}
