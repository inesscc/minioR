test_that("minio_fput_object uploads a local file and preserves bytes (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("fput")
  payload <- as.raw(sample(0:255, 4096, replace = TRUE))

  # Create local file
  src <- tempfile(fileext = ".bin")
  writeBin(payload, src)
  expect_true(file.exists(src))
  expect_equal(file.info(src)$size, length(payload))

  # Upload (fput)
  expect_true(
    minio_fput_object(
      bucket = bucket,
      file = src,
      object = key,
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  # Validate content by reading back
  got <- minio_get_object(bucket = bucket, object = key, use_https = use_https, region = region)
  expect_true(is.raw(got))
  expect_identical(got, payload)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_fput_object defaults object name to basename(file) when object is NULL (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  payload <- charToRaw("hello\n")

  src <- tempfile(pattern = "minior-", fileext = ".txt")
  writeBin(payload, src)

  # object defaults to basename(src)
  expect_true(
    minio_fput_object(
      bucket = bucket,
      file = src,
      object = NULL,
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  key <- basename(src)
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_fput_object errors when local file does not exist", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  fake <- file.path(tempdir(), paste0("does-not-exist-", sample.int(1e9, 1), ".bin"))
  key <- minior_unique_key("fput-missing")

  expect_error(
    minio_fput_object(
      bucket = bucket,
      file = fake,
      object = key,
      use_https = use_https,
      region = region
    )
  )
})
