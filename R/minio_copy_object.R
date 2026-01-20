#' Copy an Object in MinIO
#'
#' Copies an object from a source bucket/key to a destination bucket/key using
#' the S3 CopyObject operation (supported by MinIO). The function first checks
#' that the source object exists using \code{\link{minio_object_exists}}.
#'
#' @param from_bucket Character. Source bucket name.
#' @param from_object Character. Source object key (path).
#' @param to_bucket Character. Destination bucket name.
#' @param to_object Character or \code{NULL}. Destination object key (path).
#'   If \code{NULL} or empty, defaults to \code{from_object}.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return Invisibly returns \code{TRUE} if the copy was successful.
#'
#' @examples
#' \dontrun{
#' # Copy within the same bucket
#' minio_copy_object(
#'   from_bucket = "assets",
#'   from_object = "data/file.csv",
#'   to_bucket = "assets",
#'   to_object = "archive/file.csv"
#' )
#'
#' # Copy to another bucket (same key)
#' minio_copy_object(
#'   from_bucket = "raw",
#'   from_object = "data/file.parquet",
#'   to_bucket = "curated"
#' )
#' }
#'
#' @export
minio_copy_object <- function(from_bucket, from_object, to_bucket, to_object = NULL, use_https = TRUE, region = "") {
  # Basic input validation
  stopifnot(
    is.character(from_bucket), length(from_bucket) == 1,
    is.character(from_object), length(from_object) == 1,
    is.character(to_bucket), length(to_bucket) == 1
  )

  if (is.null(to_object) || !nzchar(to_object)) {
    to_object <- from_object
  } else {
    stopifnot(is.character(to_object), length(to_object) == 1)
  }

  if (!isTRUE(minio_object_exists(bucket = from_bucket, object = from_object, quiet = TRUE))) {
    stop(
      "Source object not found: '", from_object, "' in bucket '", from_bucket, "'.",
      call. = FALSE
    )
  }

  res <- tryCatch(
    aws.s3::copy_object(
      from_bucket = from_bucket,
      from_object = from_object,
      to_bucket = to_bucket,
      to_object = to_object,
      use_https = use_https,
      region = region
    ),
    error = function(e) e
  )

  if (inherits(res, "error")) {
    stop(
      "Failed to copy object from '", from_bucket, "/", from_object,
      "' to '", to_bucket, "/", to_object, "': ",
      conditionMessage(res),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
