#' Move an Object in MinIO (Copy + Remove with Size Verification)
#'
#' Moves an object from a source bucket/key to a destination bucket/key by
#' performing a copy operation followed by a delete of the source object.
#'
#' Before deleting the source object, the function can verify that the
#' destination exists and that the object size (content-length) matches
#' between source and destination.
#'
#' @param from_bucket Character. Source bucket name.
#' @param from_object Character. Source object key (path).
#' @param to_bucket Character. Destination bucket name.
#' @param to_object Character or \code{NULL}. Destination object key (path).
#'   If \code{NULL} or empty, defaults to \code{from_object}.
#' @param overwrite Logical. If \code{TRUE}, overwrites the destination object
#'   if it already exists. Defaults to \code{FALSE}.
#' @param verify Logical. If \code{TRUE}, checks that the destination object
#'   exists after copy before deleting the source. Defaults to \code{TRUE}.
#' @param verify_size Logical. If \code{TRUE}, compares object size (bytes)
#'   between source and destination before deleting the source.
#'   Defaults to \code{TRUE}.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return Invisibly returns \code{TRUE} if the move was successful.
#'
#' @examples
#' \dontrun{
#' minio_move_object(
#'   from_bucket = "raw",
#'   from_object = "data/file.parquet",
#'   to_bucket   = "curated",
#'   overwrite   = FALSE
#' )
#' }
#'
#' @export
minio_move_object <- function(from_bucket,
                              from_object,
                              to_bucket,
                              to_object = NULL,
                              overwrite = FALSE,
                              verify = TRUE,
                              verify_size = TRUE,
                              use_https = TRUE,
                              region = "") {
  stopifnot(
    is.character(from_bucket), length(from_bucket) == 1,
    is.character(from_object), length(from_object) == 1,
    is.character(to_bucket), length(to_bucket) == 1,
    is.logical(overwrite), length(overwrite) == 1,
    is.logical(verify), length(verify) == 1,
    is.logical(verify_size), length(verify_size) == 1,
    is.logical(use_https), length(use_https) == 1,
    is.character(region), length(region) == 1
  )

  if (is.null(to_object) || !nzchar(to_object)) {
    to_object <- from_object
  } else {
    stopifnot(is.character(to_object), length(to_object) == 1)
  }

  # Ensure source exists
  if (!isTRUE(minio_object_exists(bucket = from_bucket, object = from_object, quiet = TRUE))) {
    stop(
      "Source object not found: '", from_object,
      "' in bucket '", from_bucket, "'.",
      call. = FALSE
    )
  }

  # Handle destination overwrite policy
  dest_exists <- isTRUE(minio_object_exists(bucket = to_bucket, object = to_object, quiet = TRUE))
  if (dest_exists && !overwrite) {
    stop(
      "Destination object already exists: '", to_object,
      "' in bucket '", to_bucket, "'. ",
      "Set overwrite = TRUE to replace it.",
      call. = FALSE
    )
  }

  if (dest_exists && overwrite) {
    minio_remove_object(
      bucket = to_bucket,
      object = to_object,
      use_https = use_https,
      region = region
    )
  }

  # Copy
  minio_copy_object(
    from_bucket = from_bucket,
    from_object = from_object,
    to_bucket   = to_bucket,
    to_object   = to_object,
    use_https   = use_https,
    region      = region
  )

  # Verify destination existence
  if (verify) {
    if (!isTRUE(minio_object_exists(bucket = to_bucket, object = to_object, quiet = TRUE))) {
      stop(
        "Move aborted: destination verification failed after copy. ",
        "Source was not removed.",
        call. = FALSE
      )
    }
  }

  # Verify size equality
  if (verify_size) {
    src_meta <- minio_get_metadata(
      bucket = from_bucket,
      object = from_object,
      quiet = TRUE,
      use_https = use_https,
      region = region
    )
    dst_meta <- minio_get_metadata(
      bucket = to_bucket,
      object = to_object,
      quiet = TRUE,
      use_https = use_https,
      region = region
    )

    if (is.na(src_meta$size) || is.na(dst_meta$size)) {
      stop(
        "Move aborted: could not verify object size (missing metadata). ",
        "Source was not removed.",
        call. = FALSE
      )
    }

    if (!identical(as.numeric(src_meta$size), as.numeric(dst_meta$size))) {
      stop(
        "Move aborted: size mismatch after copy. ",
        "Source size: ", src_meta$size, " bytes; ",
        "Destination size: ", dst_meta$size, " bytes. ",
        "Source was not removed.",
        call. = FALSE
      )
    }
  }

  # Remove source only after all checks pass
  minio_remove_object(
    bucket = from_bucket,
    object = from_object,
    use_https = use_https,
    region = region
  )

  invisible(TRUE)
}
