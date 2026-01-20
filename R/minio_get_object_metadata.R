#' Retrieve Object Metadata from MinIO
#'
#' Retrieves metadata (HTTP headers) for an object stored in a MinIO bucket
#' using a HEAD request. Before querying metadata, the function verifies
#' that the object exists using \code{\link{minio_object_exists}}. If the
#' object does not exist, an error is raised.
#'
#' The returned information typically includes object size, last modification
#' date, ETag, content type, and other headers provided by MinIO.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) within the bucket.
#' @param quiet Logical. If \code{TRUE} (default), suppresses informational
#'   messages emitted by the underlying client during the HEAD request.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return A named list containing object metadata with the following elements:
#'   \itemize{
#'     \item \code{exists}: Always \code{TRUE} if the function returns.
#'     \item \code{bucket}: Bucket name.
#'     \item \code{object}: Object key.
#'     \item \code{size}: Object size in bytes.
#'     \item \code{last_modified}: Last modification date (character).
#'     \item \code{etag}: Object ETag.
#'     \item \code{content_type}: Content type.
#'     \item \code{headers}: Full list of headers returned by MinIO.
#'   }
#'
#' @examples
#' \dontrun{
#' info <- minio_get_object_metadata("assets", "path/file.parquet")
#' info$size
#' info$last_modified
#' }
#'
#' @export
minio_get_object_metadata <- function(bucket, object, quiet = TRUE, use_https = TRUE, region = "") {
  # Basic input validation
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1,
    is.logical(quiet), length(quiet) == 1
  )

  if (!isTRUE(minio_object_exists(bucket = bucket, object = object, quiet = quiet))) {
    stop(
      "Object not found: '", object, "' in bucket '", bucket, "'.",
      call. = FALSE
    )
  }

  do_head <- function() {
    aws.s3::head_object(
      bucket = bucket,
      object = object,
      use_https = use_https,
      region = region
    )
  }

  res <- tryCatch(
    if (isTRUE(quiet)) suppressMessages(do_head()) else do_head(),
    error = function(e) e
  )

  if (inherits(res, "error")) {
    stop(
      "Failed to retrieve metadata for object '", object,
      "' in bucket '", bucket, "': ",
      conditionMessage(res),
      call. = FALSE
    )
  }

  at <- attributes(res)

  list(
    exists = TRUE,
    bucket = bucket,
    object = object,
    size = suppressWarnings(as.numeric(at[["content-length"]])),
    last_modified = at[["last-modified"]],
    etag = at[["etag"]],
    content_type = at[["content-type"]],
    headers = at
  )
}
