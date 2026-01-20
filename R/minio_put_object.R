#' Upload an Object to MinIO from Memory
#'
#' Uploads an object to a MinIO bucket using an in-memory \code{raw} vector.
#' For maximum cross-platform compatibility, the payload is first written to a
#' temporary file and then uploaded using \code{\link[aws.s3]{put_object}}.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) within the bucket.
#' @param raw Raw vector containing the object payload.
#' @param content_type Character or \code{NULL}. Optional MIME type (e.g.,
#'   \code{"text/csv"}, \code{"application/octet-stream"}).
#' @param multipart Logical. Whether to use multipart upload. Defaults to
#'   \code{FALSE}.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return Invisibly returns \code{TRUE} if the upload was successful.
#'
#' @examples
#' \dontrun{
#' payload <- charToRaw("hello\n")
#' minio_put_object("vault", payload, "tests/hello.txt", content_type = "text/plain")
#' }
#'
#' @export
minio_put_object <- function(bucket, object, raw, content_type = NULL, multipart = FALSE, use_https = TRUE, region = "") {
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1,
    is.logical(multipart), length(multipart) == 1
  )

  if (!is.raw(raw)) {
    stop("'raw' must be a raw vector.", call. = FALSE)
  }

  if (!is.null(content_type)) {
    stopifnot(is.character(content_type), length(content_type) == 1)
    if (!nzchar(content_type)) {
      stop("'content_type' must be a non-empty string when provided.", call. = FALSE)
    }
  }

  headers <- NULL
  if (!is.null(content_type)) {
    headers <- list(`Content-Type` = content_type)
  }

  # Write payload to a temporary file for compatibility with aws.s3
  tmp <- tempfile(fileext = ".bin")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw, tmp)

  res <- tryCatch(
    aws.s3::put_object(
      file = tmp,
      object = object,
      bucket = bucket,
      headers = headers,
      multipart = multipart,
      use_https = use_https,
      region = region
    ),
    error = function(e) e
  )

  if (inherits(res, "error") || inherits(res, "aws_error")) {
    stop(
      "Failed to upload object '", object, "' to bucket '", bucket, "': ",
      conditionMessage(res),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
