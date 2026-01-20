test_that("minio_object_exists returns TRUE for existing object (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("exists")
  payload <- as.raw(sample(0:255, 1024, replace = TRUE))

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

  expect_true(minio_object_exists(bucket, key, quiet = TRUE, use_https = use_https, region = region))

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, quiet = TRUE, use_https = use_https, region = region))
})

test_that("minio_object_exists returns FALSE for missing object in an existing bucket (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("missing")

  # Ensure it really doesn't exist
  if (isTRUE(minio_object_exists(bucket, missing_key, quiet = TRUE, use_https = use_https, region = region))) {
    missing_key <- minior_unique_key("missing2")
  }

  expect_false(minio_object_exists(bucket, missing_key, quiet = TRUE, use_https = use_https, region = region))
})

test_that("minio_object_exists works with quiet = FALSE (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("exists-quietfalse")
  payload <- charToRaw("hello\n")

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = payload,
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  expect_true(minio_object_exists(bucket, key, quiet = FALSE, use_https = use_https, region = region))

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_object_exists validates inputs", {
  expect_error(minio_object_exists(bucket = 123, object = "x"))
  expect_error(minio_object_exists(bucket = "b", object = 456))
  expect_error(minio_object_exists(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_object_exists(bucket = "b", object = c("x1", "x2")))

  expect_error(minio_object_exists(bucket = "b", object = "x", quiet = "yes"))
  expect_error(minio_object_exists(bucket = "b", object = "x", quiet = c(TRUE, FALSE)))

  expect_error(minio_object_exists(bucket = "b", object = "x", use_https = "true"))
  expect_error(minio_object_exists(bucket = "b", object = "x", use_https = c(TRUE, FALSE)))

  expect_error(minio_object_exists(bucket = "b", object = "x", region = 123))
  expect_error(minio_object_exists(bucket = "b", object = "x", region = c("r1", "r2")))
})
