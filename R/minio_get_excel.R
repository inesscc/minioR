#' Read an Excel (.xlsx) File from MinIO
#'
#' Downloads an Excel \code{.xlsx} file stored in a MinIO bucket and reads it
#' into memory as a base \code{data.frame}. Internally, the function retrieves
#' the object contents as raw bytes using \code{\link{minio_get_object}}, writes
#' them to a temporary file (as required by \pkg{readxl}), and then delegates
#' parsing to \code{\link[readxl]{read_xlsx}}.
#'
#' Additional arguments are forwarded to \code{readxl::read_xlsx()}, allowing
#' control over sheets, ranges, column types, column names, and other
#' Excel-specific parsing options.
#'
#' Regardless of the return type produced by \code{readxl::read_xlsx()} (for
#' example, a tibble), the result is always coerced to a base
#' \code{data.frame} for consistency with other \code{minio_get_*} readers.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) of the Excel file within the bucket.
#' @param ... Additional arguments passed to \code{readxl::read_xlsx()}.
#'
#' @return A base \code{data.frame} containing the contents of the Excel file.
#'
#' @examples
#' \dontrun{
#' df <- minio_get_excel(
#'   bucket = "assets",
#'   object = "reports/sales_2024.xlsx",
#'   sheet = 1
#' )
#' }
#'
#' @seealso
#' \code{\link{minio_get_csv}},
#' \code{\link{minio_get_parquet}},
#' \code{\link{minio_read_object}}
#'
#' @export
minio_get_excel <- function(bucket, object, ...) {
  # Basic input validation
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1
  )

  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop(
      "Package 'readxl' is required to read Excel files. ",
      "Install it with install.packages('readxl').",
      call. = FALSE
    )
  }

  raw_obj <- minio_get_object(bucket = bucket, object = object)

  # readxl requires a file path → write to temp file
  tmp <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmp), add = TRUE)

  writeBin(raw_obj, tmp)

  df <- readxl::read_xlsx(tmp, ...)

  # Always return a base data.frame
  as.data.frame(df, stringsAsFactors = FALSE)
}
