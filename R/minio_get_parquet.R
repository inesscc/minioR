#' Read a Parquet File from MinIO
#'
#' Downloads a Parquet object stored in a MinIO bucket and reads it into
#' memory using the \pkg{arrow} package. Internally, the function retrieves
#' the object contents as raw bytes via \code{\link{minio_get_object}}, writes
#' them to a temporary file, and then delegates parsing to
#' \code{\link[arrow]{read_parquet}}.
#'
#' The returned object depends on the Arrow backend configuration and is
#' typically a \code{data.frame}, \code{tibble}, or an \code{arrow::Table}.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) of the Parquet file within
#'   the bucket.
#'
#' @return A tabular object read from the Parquet file. Usually a
#'   \code{data.frame}, \code{tibble}, or \code{arrow::Table}, depending on
#'   the Arrow configuration.
#'
#' @examples
#' \dontrun{
#' df <- minio_get_parquet(
#'   bucket = "vault",
#'   object = "data/example.parquet"
#' )
#' }
#'
#' @export
minio_get_parquet <- function(bucket, object) {
  # Basic input validation
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1
  )

  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop(
      "Package 'arrow' is required to read Parquet files. ",
      "Please install it with install.packages('arrow').",
      call. = FALSE
    )
  }

  raw_obj <- minio_get_object(bucket = bucket, object = object)

  tmp <- tempfile(fileext = ".parquet")
  on.exit(unlink(tmp), add = TRUE)

  writeBin(raw_obj, tmp)

  arrow::read_parquet(tmp)
}
