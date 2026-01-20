test_that("minio_get_object downloads raw bytes and preserves content (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("get")
  payload <- as.raw(sample(0:255, 8192, replace = TRUE))

  # Upload
  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = payload,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  got <- minio_get_object(bucket = bucket, object = key, use_https = use_https, region = region)

  expect_true(is.raw(got))
  expect_identical(got, payload)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_get_object errors when object does not exist (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("get-missing")
  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_get_object(bucket = bucket, object = missing_key, use_https = use_https, region = region),
    "Object not found"
  )
})

test_that("minio_get_object validates inputs", {
  expect_error(minio_get_object(bucket = 123, object = "x"))
  expect_error(minio_get_object(bucket = "b", object = 456))
  expect_error(minio_get_object(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_get_object(bucket = "b", object = c("x1", "x2")))
})
