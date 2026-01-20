#' Download an Object from MinIO to Disk
#'
#' Downloads an object stored in a MinIO bucket and saves it to a local file.
#' Before downloading, the function checks whether the object exists using
#' \code{\link{minio_object_exists}}. If the object does not exist, an error
#' is raised.
#'
#' The download is streamed directly to disk (i.e., the full object is not
#' loaded into memory).
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) within the bucket.
#' @param destfile Character. Local file path where the downloaded object
#'   will be saved.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return Invisibly returns \code{destfile}.
#'
#' @examples
#' \dontrun{
#' minio_download_object(
#'   bucket = "assets",
#'   object = "path/file.parquet",
#'   destfile = "path/file.parquet"
#' )
#' }
#'
#' @export
minio_download_object <- function(bucket, object, destfile, use_https = TRUE, region = "") {
  # Basic input validation
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1,
    is.character(destfile), length(destfile) == 1
  )

  if (!isTRUE(minio_object_exists(bucket = bucket, object = object, quiet = TRUE))) {
    stop(
      "Object not found: '", object, "' in bucket '", bucket, "'.",
      call. = FALSE
    )
  }

  # Ensure destination directory exists (helpful default)
  dirpath <- dirname(destfile)
  if (!dir.exists(dirpath)) {
    dir.create(dirpath, recursive = TRUE, showWarnings = FALSE)
  }

  res <- tryCatch(
    aws.s3::save_object(
      bucket = bucket,
      object = object,
      file = destfile,
      use_https = use_https,
      region = region
    ),
    error = function(e) e
  )

  if (inherits(res, "error")) {
    stop(
      "Failed to download object '", object, "' from bucket '", bucket,
      "' to '", destfile, "': ",
      conditionMessage(res),
      call. = FALSE
    )
  }

  invisible(destfile)
}
