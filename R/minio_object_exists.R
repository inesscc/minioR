#' Check Whether an Object Exists in MinIO
#'
#' Checks whether an object exists in a MinIO bucket using a \code{HEAD} request.
#' The function returns \code{TRUE} if the object exists and \code{FALSE} if the
#' object does not exist.
#'
#' For MinIO and other S3-compatible services, a non-existing object typically
#' results in a response containing the attribute
#' \code{x-minio-error-code = "NoSuchKey"}, which is interpreted as
#' "object does not exist".
#'
#' Any other unexpected response or error (for example, permission issues,
#' missing bucket, or network problems) results in an error.
#'
#' This function is intended to be the single, low-level existence-check
#' primitive used internally by other operations such as read, copy, or delete.
#'
#' @param bucket Character scalar. Name of the MinIO bucket.
#' @param object Character scalar. Object key (path) within the bucket.
#' @param quiet Logical. If \code{TRUE} (default), suppresses informational
#'   messages emitted by the underlying \code{aws.s3} client.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'   For MinIO deployments, this can usually be set to any value
#'   (for example, \code{"us-east-1"}).
#'
#' @return Logical scalar.
#' \itemize{
#'   \item \code{TRUE} if the object exists.
#'   \item \code{FALSE} if the object does not exist.
#' }
#'
#' @examples
#' \dontrun{
#' minio_object_exists(
#'   bucket = "assets",
#'   object = "data/file.parquet"
#' )
#'
#' if (minio_object_exists("assets", "data/file.parquet")) {
#'   message("Object exists")
#' }
#' }
#'
#' @export
minio_object_exists <- function(bucket, object, quiet = TRUE, use_https = TRUE, region = "") {
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1,
    is.logical(quiet), length(quiet) == 1,
    is.logical(use_https), length(use_https) == 1,
    is.character(region), length(region) == 1
  )

  x <- if (isTRUE(quiet)) {
    suppressMessages(
      aws.s3::head_object(
        object = object,
        bucket = bucket,
        use_https = use_https,
        region = region
      )
    )
  } else {
    aws.s3::head_object(
      object = object,
      bucket = bucket,
      use_https = use_https,
      region = region
    )
  }

  # Success case
  if (isTRUE(x)) return(TRUE)

  # Not-found case (MinIO commonly sets x-minio-error-code)
  code <- attr(x, "x-minio-error-code", exact = TRUE)
  if (is.null(code)) code <- attr(x, "x-amz-error-code", exact = TRUE)
  if (is.null(code)) code <- attr(x, "Code", exact = TRUE)

  if (identical(code, "NoSuchKey") || identical(code, "NotFound")) return(FALSE)

  # Other failures: surface useful details
  msg <- tryCatch(conditionMessage(x), error = function(e) "")
  stop(
    "Failed to check existence for object '", object, "' in bucket '", bucket, "'. ",
    if (!is.null(code)) paste0("Code: ", code, ". ") else "",
    if (nzchar(msg)) paste0("Message: ", msg) else "",
    call. = FALSE
  )
}
