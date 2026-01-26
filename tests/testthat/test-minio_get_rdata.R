test_that("minio_get_rdata downloads an .RData and returns all objects as named list (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getrdata")

  df <- data.frame(
    id = 1:3,
    name = c("a", "b", "c"),
    value = c(10.5, 20.0, 30.25),
    stringsAsFactors = FALSE
  )
  x <- 42L
  msg <- "hello"

  tmp <- tempfile(fileext = ".RData")
  save(df, x, msg, file = tmp)

  raw_rdata <- readBin(tmp, what = "raw", n = file.info(tmp)$size)
  expect_true(is.raw(raw_rdata))
  expect_true(length(raw_rdata) > 0)

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_rdata,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  got <- minio_get_rdata(bucket = bucket, object = key)

  expect_true(is.list(got))
  expect_true(all(c("df", "x", "msg") %in% names(got)))

  expect_equal(got$df, df)
  expect_equal(got$x, x)
  expect_equal(got$msg, msg)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_get_rdata does not pollute the caller environment (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getrdata-nopollute")

  leaked_name <- "SHOULD_NOT_EXIST_IN_TEST_ENV"
  tmp <- tempfile(fileext = ".RData")

  # If something goes wrong, clean up without warnings
  on.exit({
    if (exists(leaked_name, envir = environment(), inherits = FALSE)) {
      rm(list = leaked_name, envir = environment(), inherits = FALSE)
    }
  }, add = TRUE)

  # Create the object in the test env just for saving, then remove it
  assign(leaked_name, 999L, envir = environment())
  save(list = leaked_name, file = tmp)
  rm(list = leaked_name, envir = environment(), inherits = FALSE)

  raw_rdata <- readBin(tmp, what = "raw", n = file.info(tmp)$size)

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_rdata,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  expect_false(exists(leaked_name, envir = environment(), inherits = FALSE))

  got <- minio_get_rdata(bucket = bucket, object = key)

  # The object must be in the returned list...
  expect_true(leaked_name %in% names(got))
  expect_equal(got[[leaked_name]], 999L)

  # ...but not leaked into the test/caller environment
  expect_false(exists(leaked_name, envir = environment(), inherits = FALSE))

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_get_rdata errors on invalid bucket/object inputs", {
  expect_error(minio_get_rdata(bucket = 123, object = "x"))
  expect_error(minio_get_rdata(bucket = "b", object = 456))
  expect_error(minio_get_rdata(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_get_rdata(bucket = "b", object = c("x1", "x2")))
})

test_that("minio_get_rdata errors when object does not exist (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("getrdata-missing")
  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_get_rdata(bucket = bucket, object = missing_key)
  )
})
