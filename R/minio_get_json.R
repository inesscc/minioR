#' Read a JSON File from MinIO
#'
#' Downloads a JSON file stored in a MinIO bucket and parses it into R.
#' Internally, the function retrieves the object contents as raw bytes using
#' \code{\link{minio_get_object}}, converts them to text, and then delegates
#' parsing to \code{\link[jsonlite]{fromJSON}}.
#'
#' Unlike other \code{minio_get_*} readers, this function does not enforce a
#' tabular structure. The returned object is exactly what
#' \code{jsonlite::fromJSON()} produces, typically a list, vector, or nested
#' structure depending on the JSON content and parsing options.
#'
#' Additional arguments are forwarded to \code{jsonlite::fromJSON()}, allowing
#' control over simplification, flattening, unboxing, and handling of nested
#' data.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) of the JSON file within the bucket.
#' @param ... Additional arguments passed to \code{jsonlite::fromJSON()}.
#'
#' @return An R object representing the parsed JSON content (often a list or
#'   vector; not necessarily a \code{data.frame}).
#'
#' @examples
#' \dontrun{
#' json <- minio_get_json(
#'   bucket = "assets",
#'   object = "config/settings.json",
#'   simplifyVector = FALSE
#' )
#'
#' json$database$host
#' }
#'
#' @seealso
#' \code{\link{minio_read_object}},
#' \code{\link{minio_get_csv}},
#' \code{\link{minio_get_parquet}}
#'
#' @export
minio_get_json <- function(bucket, object, ...) {
  # Basic input validation
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1
  )

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop(
      "Package 'jsonlite' is required to read JSON files. ",
      "Install it with install.packages('jsonlite').",
      call. = FALSE
    )
  }

  raw_obj <- minio_get_object(bucket = bucket, object = object)

  # Convert raw bytes to character
  txt <- rawToChar(raw_obj)

  jsonlite::fromJSON(txt, ...)
}
