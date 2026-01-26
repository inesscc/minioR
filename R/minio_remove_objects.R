#' Remove Multiple Objects from MinIO
#'
#' Removes (deletes) multiple objects from a MinIO bucket. You can either:
#' \itemize{
#'   \item Provide an explicit vector of object keys via \code{objects}, or
#'   \item Select objects by listing \code{prefix} and filtering with a regex \code{pattern}.
#' }
#'
#' Deletions are performed by calling \code{\link{minio_remove_object}} for each object.
#'
#' @param bucket Character. Name of the MinIO bucket.
#' @param objects Character vector or \code{NULL}. Explicit object keys to remove.
#' @param prefix Character or \code{NULL}. Prefix used to list candidate objects
#'   when \code{objects} is \code{NULL}.
#' @param pattern Character or \code{NULL}. Regex pattern applied to object keys
#'   (after prefix listing). If \code{NULL}, all objects under \code{prefix} are selected.
#' @param dry_run Logical. If \code{TRUE}, does not delete anything; only returns
#'   the deletion plan. Defaults to \code{FALSE}.
#' @param quiet Logical. If \code{TRUE}, suppresses progress messages. Defaults to \code{TRUE}.
#' @param error_on_missing Logical. If \code{TRUE} (default), missing objects cause
#'   an error (consistent with \code{minio_remove_object}). If \code{FALSE}, missing
#'   objects are recorded and skipped.
#' @param use_https Logical. Whether to use HTTPS when connecting to MinIO.
#' @param region Character. Region string required by \code{aws.s3}.
#'
#' @return A \code{data.frame} with columns: \code{object}, \code{removed}, \code{error}.
#'   In \code{dry_run = TRUE}, \code{removed} is always \code{FALSE} and \code{error} is \code{NA}.
#'
#' @examples
#' \dontrun{
#' # Remove explicit objects
#' res <- minio_remove_objects(
#'   bucket = "assets",
#'   objects = c("tmp/a.csv", "tmp/b.csv")
#' )
#'
#' # Remove by prefix + regex pattern
#' res <- minio_remove_objects(
#'   bucket = "assets",
#'   prefix = "tmp/",
#'   pattern = "\\\\.csv$"
#' )
#'
#' # Dry-run
#' plan <- minio_remove_objects(
#'   bucket = "assets",
#'   prefix = "tmp/",
#'   dry_run = TRUE
#' )
#' }
#'
#' @export
minio_remove_objects <- function(bucket,
                                 objects = NULL,
                                 prefix = NULL,
                                 pattern = NULL,
                                 dry_run = FALSE,
                                 quiet = TRUE,
                                 error_on_missing = TRUE,
                                 use_https = TRUE,
                                 region = "") {
  stopifnot(
    is.character(bucket), length(bucket) == 1,
    is.logical(dry_run), length(dry_run) == 1,
    is.logical(quiet), length(quiet) == 1,
    is.logical(error_on_missing), length(error_on_missing) == 1,
    is.logical(use_https), length(use_https) == 1,
    is.character(region), length(region) == 1
  )

  # Resolve candidate objects
  if (!is.null(objects)) {
    stopifnot(is.character(objects))
    keys <- objects
  } else {
    # Must have prefix if objects not provided (to avoid accidental mass delete)
    if (is.null(prefix)) {
      stop(
        "Provide either 'objects' or 'prefix' (optionally with 'pattern').",
        call. = FALSE
      )
    }
    stopifnot(is.character(prefix), length(prefix) == 1)

    keys <- minio_list_objects(
      bucket = bucket,
      prefix = prefix,
      use_https = use_https,
      region = region
    )

    if (!is.null(pattern)) {
      stopifnot(is.character(pattern), length(pattern) == 1)
      keys <- keys[grepl(pattern, keys, perl = TRUE)]
    }
  }

  # Normalize: drop NAs, ensure unique, keep order stable
  keys <- keys[!is.na(keys)]
  if (length(keys) == 0) {
    return(data.frame(
      object = character(0),
      removed = logical(0),
      error = character(0),
      stringsAsFactors = FALSE
    ))
  }
  keys <- unique(keys)

  # Prepare output
  out <- data.frame(
    object = keys,
    removed = rep(FALSE, length(keys)),
    error = rep(NA_character_, length(keys)),
    stringsAsFactors = FALSE
  )

  if (dry_run) {
    return(out)
  }

  # Delete sequentially for predictability
  for (i in seq_along(keys)) {
    if (!quiet) message("Removing: ", keys[i])

    r <- tryCatch(
      minio_remove_object(
        bucket = bucket,
        object = keys[i],
        use_https = use_https,
        region = region
      ),
      error = function(e) e
    )

    if (inherits(r, "error")) {
      msg <- conditionMessage(r)

      # Optionally tolerate missing objects
      # (minio_remove_object errors on missing; we detect that case from the message)
      is_missing <- grepl("^Object not found:", msg)

      if (is_missing && !isTRUE(error_on_missing)) {
        out$removed[i] <- FALSE
        out$error[i] <- "Object not found (skipped)."
      } else {
        out$removed[i] <- FALSE
        out$error[i] <- msg

        # Fail fast to match minio_remove_object behavior by default
        if (isTRUE(error_on_missing)) {
          stop(msg, call. = FALSE)
        }
      }
    } else {
      out$removed[i] <- TRUE
      out$error[i] <- NA_character_
    }
  }

  out
}
