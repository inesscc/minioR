skip_if_no_minio <- function() {
  if (!identical(Sys.getenv("MINIOR_TESTS", ""), "true")) {
    testthat::skip("MinIO integration tests disabled (set MINIOR_TESTS=true).")
  }

  required <- c("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_S3_ENDPOINT")
  missing <- required[Sys.getenv(required) == ""]
  if (length(missing) > 0) {
    testthat::skip(
      paste("Missing environment variables:", paste(missing, collapse = ", "))
    )
  }
}

minior_bucket <- function() Sys.getenv("MINIOR_BUCKET")
minior_use_https <- function() tolower(Sys.getenv("MINIOR_USE_HTTPS")) %in% c("true", "1", "yes")
minior_region <- function() Sys.getenv("MINIOR_REGION")

minior_unique_key <- function(prefix = "tmp") {
  paste0(prefix, "/", format(Sys.time(), "%Y%m%d-%H%M%OS3"), "-", sample.int(1e9, 1), ".bin")
}

minior_ensure_bucket <- function(bucket) {
  try(aws.s3::create_bucket(bucket), silent = TRUE)
  invisible(TRUE)
}

skip_if_not_installed <- function(pkg) {
  stopifnot(is.character(pkg), length(pkg) == 1)

  if (!requireNamespace(pkg, quietly = TRUE)) {
    testthat::skip(
      paste0(
        "Skipping test because required package '",
        pkg,
        "' is not installed."
      )
    )
  }
}

skip_if_installed <- function(pkg) {
  stopifnot(is.character(pkg), length(pkg) == 1)

  if (requireNamespace(pkg, quietly = TRUE)) {
    testthat::skip(
      paste0(
        "Skipping test because package '",
        pkg,
        "' is installed."
      )
    )
  }
}
