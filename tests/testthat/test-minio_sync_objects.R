test_that("minio_sync_objects errors on invalid inputs", {
  expect_error(minio_sync_objects(path = 123, bucket = "b"))
  expect_error(minio_sync_objects(path = ".", bucket = 123))
  expect_error(minio_sync_objects(path = ".", bucket = "b", prefix = 123))
  expect_error(minio_sync_objects(path = ".", bucket = "b", verbose = "yes"))
  expect_error(minio_sync_objects(path = ".", bucket = "b", use_https = "yes"))
  expect_error(minio_sync_objects(path = ".", bucket = "b", region = 123))
})

test_that("minio_sync_objects errors on invalid sync value", {
  skip_if_not_installed("aws.s3")

  expect_error(
    minio_sync_objects(path = ".", bucket = "b", sync = "up"),
    "Invalid 'sync' value",
    fixed = TRUE
  )
})

test_that("minio_sync_objects maps sync to direction (unit, stub aws.s3::s3sync)", {
  # Need MINIOR_BUCKET set (even though we stub, we want consistent bucket usage)
  skip_if_no_minio()
  skip_if_not_installed("aws.s3")
  skip_if_not_installed("mockery")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  called <- new.env(parent = emptyenv())
  called$args <- NULL

  s3sync_stub <- function(...) {
    called$args <- list(...)
    TRUE
  }

  # Replace the internal call to aws.s3::s3sync
  mockery::stub(minio_sync_objects, "aws.s3::s3sync", s3sync_stub)

  # server -> upload
  expect_true(minio_sync_objects(
    path = ".",
    bucket = bucket,
    prefix = "",
    sync = "server",
    verbose = FALSE,
    use_https = use_https,
    region = region
  ))
  expect_equal(called$args$direction, "upload")
  expect_equal(called$args$create, FALSE)
  expect_equal(called$args$bucket, bucket)

  # local -> download
  expect_true(minio_sync_objects(
    path = ".",
    bucket = bucket,
    prefix = "",
    sync = "local",
    verbose = FALSE,
    use_https = use_https,
    region = region
  ))
  expect_equal(called$args$direction, "download")
  expect_equal(called$args$create, FALSE)
  expect_equal(called$args$bucket, bucket)

  # NULL -> two-way (direction omitted)
  expect_true(minio_sync_objects(
    path = ".",
    bucket = bucket,
    prefix = "",
    sync = NULL,
    verbose = FALSE,
    use_https = use_https,
    region = region
  ))
  expect_true(is.null(called$args$direction))
  expect_equal(called$args$create, FALSE)
  expect_equal(called$args$bucket, bucket)
})

test_that("minio_sync_objects uploads local files to server with sync='server' (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("aws.s3")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  d <- tempfile("minio_sync_up_")
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE, force = TRUE), add = TRUE)

  local_file <- file.path(d, "a.txt")

  # No trailing \n; writeLines adds EOL
  txt <- paste0("HELLO-", sample.int(1e9, 1))
  writeLines(txt, local_file, useBytes = TRUE)

  prefix <- paste0("sync-up/", format(Sys.time(), "%Y%m%d-%H%M%OS3"), "-", sample.int(1e9, 1), "/")
  remote_key <- paste0(prefix, "a.txt")

  if (minio_object_exists(bucket, remote_key, quiet = TRUE, use_https = use_https, region = region)) {
    minio_remove_object(bucket, remote_key, use_https = use_https, region = region)
  }

  expect_true(minio_sync_objects(
    path = d,
    bucket = bucket,
    prefix = prefix,
    sync = "server",
    verbose = FALSE,
    use_https = use_https,
    region = region
  ))

  expect_true(minio_object_exists(bucket, remote_key, use_https = use_https, region = region))

  got_raw <- minio_get_object(bucket = bucket, object = remote_key)
  got_txt <- rawToChar(got_raw)

  norm <- function(x) {
    x <- gsub("\r\n", "\n", x, fixed = TRUE)
    sub("[\n\r]+$", "", x)
  }
  expect_equal(norm(got_txt), norm(txt))

  minio_remove_object(bucket, remote_key, use_https = use_https, region = region)
})

test_that("minio_sync_objects downloads server files to local with sync='local' (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("aws.s3")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  prefix <- paste0("sync-down/", format(Sys.time(), "%Y%m%d-%H%M%OS3"), "-", sample.int(1e9, 1), "/")
  remote_key <- paste0(prefix, "b.txt")

  txt <- paste0("WORLD-", sample.int(1e9, 1))

  expect_true(minio_put_object(
    bucket = bucket,
    object = remote_key,
    raw = charToRaw(paste0(txt, "\n")),
    content_type = "text/plain",
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  d <- tempfile("minio_sync_down_")
  dir.create(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE, force = TRUE), add = TRUE)

  local_file <- file.path(d, "b.txt")
  if (file.exists(local_file)) unlink(local_file)

  expect_true(minio_sync_objects(
    path = d,
    bucket = bucket,
    prefix = prefix,
    sync = "local",
    verbose = FALSE,
    use_https = use_https,
    region = region
  ))

  expect_true(file.exists(local_file))

  got_txt <- paste(readLines(local_file, warn = FALSE), collapse = "\n")

  norm <- function(x) {
    x <- gsub("\r\n", "\n", x, fixed = TRUE)
    sub("[\n\r]+$", "", x)
  }
  expect_equal(norm(got_txt), norm(txt))

  minio_remove_object(bucket, remote_key, use_https = use_https, region = region)
})
