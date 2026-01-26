test_that("minio_get_feather downloads a .feather and returns identical data.frame (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("feather")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getfeather")

  df <- data.frame(
    id = 1:5,
    name = c("a", "b", "c", "d", "e"),
    value = c(10.5, 20.0, 30.25, NA_real_, 50.75),
    flag = c(TRUE, FALSE, TRUE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )

  tmp <- tempfile(fileext = ".feather")
  feather::write_feather(df, tmp)

  raw_feather <- readBin(tmp, what = "raw", n = file.info(tmp)$size)
  expect_true(is.raw(raw_feather))
  expect_true(length(raw_feather) > 0)

  # Upload Feather as an object
  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_feather,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  # Read back
  got <- minio_get_feather(bucket = bucket, object = key)

  expect_true(is.data.frame(got))
  expect_equal(got, df)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_get_feather passes ... arguments to feather::read_feather (columns)", {
  skip_if_no_minio()
  skip_if_not_installed("feather")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getfeather-args")

  df <- data.frame(
    id = 1:3,
    name = c("a", "b", "c"),
    value = c(10.5, 20.0, 30.25),
    extra = c("x", "y", "z"),
    stringsAsFactors = FALSE
  )

  tmp <- tempfile(fileext = ".feather")
  feather::write_feather(df, tmp)
  raw_feather <- readBin(tmp, what = "raw", n = file.info(tmp)$size)

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_feather,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  got <- minio_get_feather(
    bucket = bucket,
    object = key,
    columns = c("id", "value")
  )

  expect_true(is.data.frame(got))
  expect_equal(names(got), c("id", "value"))
  expect_equal(got$id, df$id)
  expect_equal(got$value, df$value)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_get_feather errors on invalid bucket/object inputs", {
  expect_error(minio_get_feather(bucket = 123, object = "x"))
  expect_error(minio_get_feather(bucket = "b", object = 456))
  expect_error(minio_get_feather(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_get_feather(bucket = "b", object = c("x1", "x2")))
})

test_that("minio_get_feather errors when 'feather' is not installed", {
  skip_if_installed("feather")

  expect_error(
    minio_get_feather(bucket = "b", object = "x"),
    "Package 'feather' is required to read Feather files",
    fixed = TRUE
  )
})

test_that("minio_get_feather errors when object does not exist (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("feather")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("getfeather-missing")
  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_get_feather(bucket = bucket, object = missing_key)
  )
})
