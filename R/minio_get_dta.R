#' Read a Stata (.dta) File from MinIO
#'
#' Downloads a Stata \code{.dta} file stored in a MinIO bucket and reads it into
#' memory as a base \code{data.frame}. Internally, the function retrieves the
#' object contents as raw bytes using \code{\link{minio_get_object}}, writes them
#' to a temporary file, and then delegates parsing to
#' \code{\link[haven]{read_dta}}.
#'
#' Additional arguments are forwarded to \code{haven::read_dta()}, allowing
#' control over encoding, labelled values, user-defined missing values, and
#' other Stata-specific parsing options.
#'
#' Regardless of the return type produced by \code{haven::read_dta()} (for
#' example, a tibble), the result is always coerced to a base
#' \code{data.frame} for consistency with other \code{minio_get_*} readers.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) of the \code{.dta} file within the bucket.
#' @param ... Additional arguments passed to \code{haven::read_dta()}.
#'
#' @return A base \code{data.frame} containing the contents of the Stata file.
#'
#' @examples
#' \dontrun{
#' df <- minio_get_dta(
#'   bucket = "assets",
#'   object = "survey/data_2023.dta"
#' )
#' }
#'
#' @seealso
#' \code{\link{minio_get_csv}},
#' \code{\link{minio_get_parquet}},
#' \code{\link{minio_read_object}}
#'
#' @export
minio_get_dta <- function(bucket, object, ...) {
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1
  )

  if (!requireNamespace("haven", quietly = TRUE)) {
    stop(
      "Package 'haven' is required to read .dta files. ",
      "Install it with install.packages('haven').",
      call. = FALSE
    )
  }

  raw_obj <- minio_get_object(bucket = bucket, object = object)

  tmp <- tempfile(fileext = ".dta")
  on.exit(unlink(tmp), add = TRUE)

  writeBin(raw_obj, tmp)

  df <- haven::read_dta(tmp, ...)

  as.data.frame(df, stringsAsFactors = FALSE)
}


