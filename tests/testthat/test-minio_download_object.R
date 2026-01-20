test_that("minio_download_object downloads an object to disk (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("download")
  payload <- as.raw(sample(0:255, 2048, replace = TRUE))

  # Upload
  minio_put_object(
    bucket = bucket,
    raw = payload,
    object = key,
    content_type = "application/octet-stream",
    multipart = FALSE,
    use_https = use_https,
    region = region
  )
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  # Download to a temp file
  dest <- tempfile(fileext = ".bin")
  expect_true(
    file.exists(dirname(dest))
  )

  minio_download_object(
    bucket = bucket,
    object = key,
    destfile = dest,
    use_https = use_https,
    region = region
  )

  expect_true(file.exists(dest))
  expect_equal(file.info(dest)$size, length(payload))

  # Validate exact bytes
  got <- readBin(dest, what = "raw", n = length(payload))
  expect_identical(got, payload)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_download_object errors for a missing object (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("missing-download")
  dest <- tempfile(fileext = ".bin")

  # Ensure it does not exist
  if (minio_object_exists(bucket, key, use_https = use_https, region = region)) {
    minio_remove_object(bucket, key, use_https = use_https, region = region)
  }

  expect_error(
    minio_download_object(
      bucket = bucket,
      object = key,
      destfile = dest,
      use_https = use_https,
      region = region
    )
  )
})
