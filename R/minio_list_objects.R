#' List Objects in a MinIO Bucket
#'
#' Lists the object keys stored in a MinIO bucket, optionally filtered
#' by a prefix (for example, simulating a folder structure).
#'
#' This function is a thin wrapper around \code{aws.s3::get_bucket()},
#' providing a simplified and safer interface for MinIO environments.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param prefix Character or \code{NULL}. Optional prefix used to filter
#'   object keys.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}
#'
#' @return A character vector containing the object keys. If no objects
#'   are found, returns \code{character(0)}.
#'
#' @examples
#' \dontrun{
#' minio_list_objects("my-bucket")
#' minio_list_objects("my-bucket", prefix = "data/raw/")
#' }
#'
#' @export
minio_list_objects <- function(bucket, prefix = NULL, use_https = TRUE, region = "") {
  stopifnot(is.character(bucket), length(bucket) == 1)

  if (!is.null(prefix)) {
    stopifnot(is.character(prefix), length(prefix) == 1)
  }

  res <- tryCatch(
    suppressWarnings(suppressMessages(
      aws.s3::get_bucket(
        bucket = bucket,
        prefix = prefix,
        use_https = use_https,
        region = region
      )
    )),
    error = function(e) e
  )

  if (inherits(res, "error") || inherits(res, "aws_error")) {
    stop(
      "Failed to list objects in bucket '", bucket, "': ",
      conditionMessage(res),
      call. = FALSE
    )
  }

  if (length(res) == 0) {
    return(character(0))
  }

  unname(vapply(res, function(x) x$Key, character(1)))
}

