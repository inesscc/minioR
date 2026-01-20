#' Read a CSV File from MinIO
#'
#' Downloads a CSV object stored in a MinIO bucket and reads it into memory
#' as a \code{data.frame}. Internally, the function retrieves the object
#' contents as raw bytes using \code{\link{minio_get_object}} and then
#' delegates parsing to \code{\link[utils]{read.csv}}.
#'
#' Additional arguments are passed directly to \code{read.csv()}, allowing
#' control over separators, headers, encoding, and other parsing options.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) of the CSV file within the bucket.
#' @param ... Additional arguments passed to \code{read.csv()}, such as
#'   \code{sep}, \code{header}, \code{stringsAsFactors}, \code{fileEncoding},
#'   etc.
#'
#' @return A \code{data.frame} containing the contents of the CSV file.
#'
#' @examples
#' \dontrun{
#' df <- minio_get_csv(
#'   bucket = "assets",
#'   object = "path/file.csv",
#'   sep = ";",
#'   header = TRUE,
#'   fileEncoding = "latin1"
#' )
#' }
#'
#' @export
minio_get_csv <- function(bucket, object, ...) {
  # Basic input validation
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1
  )

  raw_obj <- minio_get_object(bucket = bucket, object = object)

  # Convert raw bytes to character
  txt <- rawToChar(raw_obj)

  con <- textConnection(txt)
  on.exit(close(con), add = TRUE)

  utils::read.csv(con, ...)
}
