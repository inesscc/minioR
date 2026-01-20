#' minioR: A Simple MinIO Client for R
#'
#' `minioR` provides a set of functions to interact with
#' Amazon S3–compatible object storage services such as MinIO.
#' It allows uploading, downloading, copying, listing, and
#' deleting objects directly from R.
#'
#' The package is designed for data engineering workflows,
#' automation, and testing scenarios, offering a simple and
#' explicit interface.
#'
#' @section Configuration:
#' Access to MinIO is configured using environment variables:
#' \describe{
#'   \item{AWS_S3_ENDPOINT}{Endpoint URL (e.g. \code{localhost:9000})}
#'   \item{AWS_SECRET_ACCESS_KEY}{Access key}
#'   \item{AWS_ACCESS_KEY_ID }{Secret key}
#'   \item{AWS_SIGNATURE_VERSION}{Use value = 2}
#'   \item{AWS_REGION}{Region (optional)}
#' }
#'
#' @section Typical workflow:
#' \enumerate{
#'   \item Configure environment variables
#'   \item Upload objects using \code{minio_put_object()}
#'   \item Download objects using \code{minio_download_object()}
#' }
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{minio_put_object}}
#'   \item \code{\link{minio_fput_object}}
#'   \item \code{\link{minio_get_object}}
#'   \item \code{\link{minio_get_object_metadata}}
#'   \item \code{\link{minio_get_csv}}
#'   \item \code{\link{minio_get_parquet}}
#'   \item \code{\link{minio_download_object}}
#'   \item \code{\link{minio_copy_object}}
#'   \item \code{\link{minio_list_objects}}
#'   \item \code{\link{minio_object_exists}}
#'   \item \code{\link{minio_remove_object}}
#' }
#'
#' @docType package
#' @name minioR
"_PACKAGE"
