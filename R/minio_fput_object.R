#' Upload a Local File to MinIO
#'
#' Uploads a local file to a MinIO bucket. If the object name is not provided,
#' the base name of the local file path is used as the object key.
#'
#' This function wraps \code{\link[aws.s3]{put_object}} and adds input
#' validation and clearer error handling for MinIO environments.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character or \code{NULL}. Object key (path) to use in the
#'   bucket. If \code{NULL} or empty, defaults to \code{basename(file)}.
#' @param file Character. Path to the local file to upload.
#' @param multipart Logical. Whether to enable multipart upload. Defaults
#'   to \code{FALSE}.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return Logical. Returns \code{TRUE} if the upload was successful.
#'
#' @examples
#' \dontrun{
#' minio_fput_object(
#'   bucket = "assets",
#'   object = "raw/example.parquet",
#'   file = "data/example.parquet"
#' )
#' }
#'
#' @export
minio_fput_object <- function(bucket, object = NULL, file, multipart = FALSE, use_https = TRUE, region = "") {
  # Basic input validation
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(file), length(file) == 1,
    is.logical(multipart), length(multipart) == 1
  )

  if (!file.exists(file)) {
    stop("Local file does not exist: ", file, call. = FALSE)
  }

  if (is.null(object) || !nzchar(object)) {
    object <- basename(file)
  }

  res <- tryCatch(
    aws.s3::put_object(
      file = file,
      object = object,
      bucket = bucket,
      multipart = multipart,
      use_https = use_https,
      region = region
    ),
    error = function(e) e
  )

  if (inherits(res, "error")) {
    stop(
      "Failed to upload object '", object, "' to bucket '", bucket,
      "' from local file '", file, "': ",
      conditionMessage(res),
      call. = FALSE
    )
  }

  TRUE
}
