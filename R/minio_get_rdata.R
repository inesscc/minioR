#' Read an RData/RDA File from MinIO
#'
#' Downloads an R workspace file (\code{.RData} or \code{.rda}) stored in a
#' MinIO bucket and loads its contents into an isolated environment.
#' Internally, the function retrieves the object contents as raw bytes using
#' \code{\link{minio_get_object}}, writes them to a temporary file, and then
#' delegates deserialization to \code{\link[base]{load}}.
#'
#' To avoid polluting the caller's environment, all objects are loaded into a
#' new, empty environment and then returned as a named \code{list}. Each list
#' element corresponds to one object stored in the \code{.RData}/\code{.rda}
#' file.
#'
#' Unlike \code{minio_get_rds()}, which returns a single R object, this function
#' always returns a collection of objects, making it suitable for archived
#' workspaces or multi-object snapshots.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param object Character. Object key (path) of the \code{.RData} or \code{.rda}
#'   file within the bucket.
#'
#' @return A named \code{list} containing all objects loaded from the file.
#'
#' @examples
#' \dontrun{
#' objs <- minio_get_rdata(
#'   bucket = "assets",
#'   object = "snapshots/data.RData"
#' )
#'
#' names(objs)
#' df <- objs$df
#' }
#'
#' @seealso
#' \code{\link{minio_get_rds}},
#' \code{\link{minio_read_object}},
#' \code{\link{minio_get_parquet}}
#'
#' @export
minio_get_rdata <- function(bucket, object) {
  # Basic input validation
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.character(object), length(object) == 1
  )

  raw_obj <- minio_get_object(bucket = bucket, object = object)

  # load() requires a file path -> write to temp file
  tmp <- tempfile(fileext = ".RData")
  on.exit(unlink(tmp), add = TRUE)

  writeBin(raw_obj, tmp)

  env <- new.env(parent = emptyenv())
  obj_names <- load(tmp, envir = env)

  # Return as named list (safe, no side effects)
  out <- mget(obj_names, envir = env, inherits = FALSE)
  out
}
