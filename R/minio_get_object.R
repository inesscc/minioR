#' Download an Object from MinIO as Raw Bytes
#'
#' Downloads an object from a MinIO bucket and returns its contents as a
#' \code{raw} vector. Before downloading, the function checks whether the
#' object exists using \code{\link{minio_object_exists}}. If the object does
#' not exist, an error is raised.
#'
#' This function is intended as a low-level building block for higher-level
#' helpers (e.g., reading CSV/Parquet), centralizing validation and download
#' logic.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) within the bucket.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return A \code{raw} vector with the object contents.
#'
#' @examples
#' \dontrun{
#' x <- minio_get_object(
#'   bucket = "assets",
#'   object = "path/file.parquet"
#' )
#' length(x)
#' }
#'
#' @export
minio_get_object <- function(bucket, object, use_https = TRUE, region = "") {
  # Basic input validation
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1
  )

  if (!isTRUE(minio_object_exists(bucket = bucket, object = object, quiet = TRUE))) {
    stop(
      "Object not found: '", object, "' in bucket '", bucket, "'.",
      call. = FALSE
    )
  }

  res <- tryCatch(
    aws.s3::get_object(
      bucket = bucket,
      object = object,
      use_https = use_https,
      region = region
    ),
    error = function(e) e
  )

  if (inherits(res, "error")) {
    stop(
      "Failed to download object '", object, "' from bucket '", bucket, "': ",
      conditionMessage(res),
      call. = FALSE
    )
  }

  # get_object() should return raw; enforce to be safe
  if (!is.raw(res)) {
    stop(
      "Unexpected response type from aws.s3::get_object(); expected raw.",
      call. = FALSE
    )
  }

  res
}
