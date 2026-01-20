test_that("minio_remove_object deletes an existing object and returns TRUE (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("rm")
  payload <- as.raw(sample(0:255, 2048, replace = TRUE))

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

  # Remove
  expect_true(
    minio_remove_object(
      bucket = bucket,
      object = key,
      use_https = use_https,
      region = region
    )
  )

  # Verify it's gone
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_remove_object errors when object does not exist (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("rm-missing")
  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_remove_object(
      bucket = bucket,
      object = missing_key,
      use_https = use_https,
      region = region
    ),
    "Object not found"
  )
})

test_that("minio_remove_object validates inputs", {
  expect_error(minio_remove_object(bucket = 123, object = "x"))
  expect_error(minio_remove_object(bucket = "b", object = 456))
  expect_error(minio_remove_object(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_remove_object(bucket = "b", object = c("x1", "x2")))
})
