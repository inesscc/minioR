#' Read an Object from MinIO (Auto-detect by Extension)
#'
#' Reads an object stored in a MinIO bucket by automatically detecting its file
#' type from the object key extension and delegating to the corresponding
#' \code{minio_get_*} function (e.g., CSV, Parquet, JSON, XLSX, etc.).
#'
#' This function is designed as a convenience wrapper so users only need to
#' learn a single reader function.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) within the bucket. The file
#'   extension is used to infer the type (e.g., \code{.csv}, \code{.parquet}).
#' @param ... Additional arguments passed to the underlying reader function
#'   selected by file type (e.g., \code{sep} for CSV, \code{sheet} for XLSX,
#'   \code{flatten} for JSON, etc.).
#'
#' @return The parsed object. For tabular formats, returns a \code{data.frame}.
#'   For JSON, returns the parsed JSON object (typically a list). For RDS,
#'   returns the stored R object. For RData/RDA, returns a named list.
#'
#' @examples
#' \dontrun{
#' # CSV
#' df <- minio_read_object("assets", "raw/data.csv", sep = ";")
#'
#' # Excel
#' df2 <- minio_read_object("assets", "raw/report.xlsx", sheet = 2)
#'
#' # JSON
#' x <- minio_read_object("assets", "raw/config.json", flatten = TRUE)
#'
#' # RDS
#' model <- minio_read_object("assets", "models/model.rds")
#'
#' # RData / RDA
#' objs <- minio_read_object("assets", "snapshots/objects.RData")
#' }
#'
#' @export
minio_read_object <- function(bucket, object, ...) {
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1
  )

  ext <- tolower(tools::file_ext(object))

  if (identical(ext, "") || is.na(ext)) {
    stop(
      "Cannot detect object type: 'object' has no file extension. ",
      "Provide an extension (e.g., .csv, .parquet, .json, .xlsx).",
      call. = FALSE
    )
  }

  # Dispatch to specific reader based on extension
  switch(
    ext,
    "csv"     = minio_get_csv(bucket = bucket, object = object, ...),
    "parquet" = minio_get_parquet(bucket = bucket, object = object, ...),
    "pq"      = minio_get_parquet(bucket = bucket, object = object, ...),

    "json"    = minio_get_json(bucket = bucket, object = object, ...),

    "xlsx"    = minio_get_excel(bucket = bucket, object = object, ...),

    "feather" = minio_get_feather(bucket = bucket, object = object, ...),

    "dta"     = minio_get_dta(bucket = bucket, object = object, ...),

    "rds"     = minio_get_rds(bucket = bucket, object = object),
    "rda"     = minio_get_rdata(bucket = bucket, object = object),
    "rdata"   = minio_get_rdata(bucket = bucket, object = object),

    stop(
      "Unsupported file extension: '", ext, "'. ",
      "Supported: csv, parquet/pq, json, xlsx, feather, dta, rds, rda/rdata.",
      call. = FALSE
    )
  )
}
