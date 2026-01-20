test_that("minio_get_object_metadata returns expected fields and headers (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("meta")
  payload <- charToRaw("hello-metadata\n")

  # Upload
  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = payload,
      content_type = "text/plain",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  info <- minio_get_object_metadata(
    bucket = bucket,
    object = key,
    quiet = TRUE,
    use_https = use_https,
    region = region
  )

  # Structure
  expect_true(is.list(info))
  expect_true(isTRUE(info$exists))
  expect_identical(info$bucket, bucket)
  expect_identical(info$object, key)

  # Size should match payload length
  expect_true(is.numeric(info$size))
  expect_equal(info$size, length(payload))

  # Content type should be present
  expect_true(is.character(info$content_type) || is.null(info$content_type))
  if (!is.null(info$content_type)) {
    expect_true(grepl("text/plain", info$content_type, fixed = TRUE))
  }

  # ETag / last-modified are typically present
  expect_true(is.null(info$etag) || (is.character(info$etag) && nzchar(info$etag)))
  expect_true(is.null(info$last_modified) || (is.character(info$last_modified) && nzchar(info$last_modified)))

  # Headers should be a named list of attributes
  expect_true(is.list(info$headers))
  expect_true(length(info$headers) > 0)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_get_object_metadata errors when object does not exist (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("meta-missing")
  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_get_object_metadata(
      bucket = bucket,
      object = missing_key,
      quiet = TRUE,
      use_https = use_https,
      region = region
    ),
    "Object not found"
  )
})

test_that("minio_get_object_metadata validates inputs", {
  expect_error(minio_get_object_metadata(bucket = 123, object = "x"))
  expect_error(minio_get_object_metadata(bucket = "b", object = 456))
  expect_error(minio_get_object_metadata(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_get_object_metadata(bucket = "b", object = c("x1", "x2")))
  expect_error(minio_get_object_metadata(bucket = "b", object = "x", quiet = "yes"))
  expect_error(minio_get_object_metadata(bucket = "b", object = "x", quiet = c(TRUE, FALSE)))
})

test_that("minio_get_object_metadata works with quiet = FALSE (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("meta-quietfalse")
  payload <- as.raw(sample(0:255, 128, replace = TRUE))

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

  info <- minio_get_object_metadata(
    bucket = bucket,
    object = key,
    quiet = FALSE,
    use_https = use_https,
    region = region
  )

  expect_true(isTRUE(info$exists))
  expect_equal(info$size, length(payload))

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})
