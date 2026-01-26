#' Read an RDS File from MinIO
#'
#' Downloads an R serialized \code{.rds} file stored in a MinIO bucket and
#' deserializes it into memory. Internally, the function retrieves the object
#' contents as raw bytes using \code{\link{minio_get_object}}, writes them to a
#' temporary file, and then delegates deserialization to
#' \code{\link[base]{readRDS}}.
#'
#' Unlike tabular readers such as \code{minio_get_csv()} or
#' \code{minio_get_parquet()}, this function does not enforce any specific data
#' structure. The returned value is exactly the R object that was serialized
#' when the \code{.rds} file was created (for example, a data frame, list,
#' model object, or any other R object).
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) of the \code{.rds} file within the bucket.
#'
#' @return An R object deserialized from the \code{.rds} file.
#'
#' @examples
#' \dontrun{
#' model <- minio_get_rds(
#'   bucket = "assets",
#'   object = "models/linear_model.rds"
#' )
#'
#' summary(model)
#' }
#'
#' @seealso
#' \code{\link{minio_get_rdata}},
#' \code{\link{minio_read_object}},
#' \code{\link{minio_get_parquet}}
#'
#' @export
minio_get_rds <- function(bucket, object) {
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1
  )

  raw_obj <- minio_get_object(bucket = bucket, object = object)

  tmp <- tempfile(fileext = ".rds")
  on.exit(unlink(tmp), add = TRUE)

  writeBin(raw_obj, tmp)

  readRDS(tmp)
}
