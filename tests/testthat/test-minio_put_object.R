test_that("minio_put_object uploads raw bytes and object exists afterwards (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("put")
  payload <- charToRaw("hello from minioR\n")

  expect_true(
    minio_put_object(
      bucket = bucket,
      raw = payload,
      object = key,
      content_type = "text/plain",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  # cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_put_object can overwrite an existing object (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("put-overwrite")

  payload1 <- charToRaw("first\n")
  payload2 <- charToRaw("second\n")

  minio_put_object(
    bucket = bucket, raw = payload1, object = key,
    content_type = "text/plain",
    multipart = FALSE,
    use_https = use_https, region = region
  )

  minio_put_object(
    bucket = bucket, raw = payload2, object = key,
    content_type = "text/plain",
    multipart = FALSE,
    use_https = use_https, region = region
  )

  # read back to confirm overwrite
  got <- minio_get_object(bucket = bucket, object = key, use_https = use_https, region = region)
  expect_true(is.raw(got))
  expect_equal(rawToChar(got), "second\n")

  # cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_put_object errors if raw is not a raw vector", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("put-badraw")

  expect_error(
    minio_put_object(
      bucket = bucket,
      raw = "not-raw",
      object = key,
      use_https = use_https,
      region = region
    )
  )
})
