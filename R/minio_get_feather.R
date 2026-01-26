#' Read a Feather File from MinIO
#'
#' Downloads a Feather \code{.feather} file stored in a MinIO bucket and reads it
#' into memory as a base \code{data.frame}. Internally, the function retrieves
#' the object contents as raw bytes using \code{\link{minio_get_object}}, writes
#' them to a temporary file, and then delegates parsing to
#' \code{\link[feather]{read_feather}}.
#'
#' Additional arguments are forwarded to \code{feather::read_feather()}, allowing
#' control over column selection, memory mapping, and other Feather-specific
#' reading options.
#'
#' Regardless of the return type produced by \code{feather::read_feather()},
#' the result is always coerced to a base \code{data.frame} for consistency
#' with other \code{minio_get_*} reader functions.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) of the Feather file within the bucket.
#' @param ... Additional arguments passed to \code{feather::read_feather()}.
#'
#' @return A base \code{data.frame} containing the contents of the Feather file.
#'
#' @examples
#' \dontrun{
#' df <- minio_get_feather(
#'   bucket = "assets",
#'   object = "analytics/features.feather"
#' )
#' }
#'
#' @seealso
#' \code{\link{minio_get_parquet}},
#' \code{\link{minio_get_csv}},
#' \code{\link{minio_read_object}}
#'
#' @export
minio_get_feather <- function(bucket, object, ...) {
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1
  )

  if (!requireNamespace("feather", quietly = TRUE)) {
    stop(
      "Package 'feather' is required to read Feather files. ",
      "Install it with install.packages('feather').",
      call. = FALSE
    )
  }

  raw_obj <- minio_get_object(bucket = bucket, object = object)

  tmp <- tempfile(fileext = ".feather")
  on.exit(unlink(tmp), add = TRUE)

  writeBin(raw_obj, tmp)

  df <- feather::read_feather(tmp, ...)

  as.data.frame(df, stringsAsFactors = FALSE)
}
