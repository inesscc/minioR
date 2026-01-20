#' Remove an Object from MinIO
#'
#' Removes (deletes) an object from a MinIO bucket. Before deletion, the
#' function checks whether the object exists using
#' \code{\link{minio_object_exists}}. If the object does not exist, an error
#' is raised.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) within the bucket.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return Invisibly returns \code{TRUE} if the object was successfully removed.
#'
#' @examples
#' \dontrun{
#' minio_remove_object(
#'   bucket = "assets",
#'   object = "path/file.parquet"
#' )
#' }
#'
#' @export
minio_remove_object <- function(bucket, object, use_https = TRUE, region = "") {
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
    aws.s3::delete_object(
      bucket = bucket,
      object = object,
      use_https = use_https,
      region = region
    ),
    error = function(e) e
  )

  if (inherits(res, "error")) {
    stop(
      "Failed to remove object '", object, "' from bucket '", bucket, "': ",
      conditionMessage(res),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
