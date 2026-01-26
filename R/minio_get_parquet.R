#' Read a Parquet File from MinIO
#'
#' Downloads a Parquet \code{.parquet} file stored in a MinIO bucket and reads it
#' into memory using the \pkg{arrow} package. Internally, the function retrieves
#' the object contents as raw bytes using \code{\link{minio_get_object}}, writes
#' them to a temporary file, and then delegates parsing to
#' \code{\link[arrow]{read_parquet}}.
#'
#' The returned object depends on the Arrow backend configuration and may be a
#' base \code{data.frame}, a \code{tibble}, or an \code{arrow::Table}. Unlike
#' other \code{minio_get_*} readers, this function does not coerce the result to
#' a specific R data structure, allowing users to take full advantage of Arrow
#' for large or lazy workflows.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) of the Parquet file within the bucket.
#'
#' @return A tabular object read from the Parquet file. The exact return type
#'   depends on the Arrow configuration and may be a \code{data.frame},
#'   \code{tibble}, or \code{arrow::Table}.
#'
#' @examples
#' \dontrun{
#' tbl <- minio_get_parquet(
#'   bucket = "vault",
#'   object = "data/example.parquet"
#' )
#'
#' # Convert explicitly if needed
#' df <- as.data.frame(tbl)
#' }
#'
#' @seealso
#' \code{\link{minio_read_many}},
#' \code{\link{minio_read_object}},
#' \code{\link{minio_get_csv}}
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
