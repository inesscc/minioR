test_that("minio_move_object errors on invalid inputs", {
  expect_error(minio_move_object(from_bucket = 123, from_object = "a", to_bucket = "b"))
  expect_error(minio_move_object(from_bucket = "a", from_object = 123, to_bucket = "b"))
  expect_error(minio_move_object(from_bucket = "a", from_object = "x", to_bucket = 123))
  expect_error(minio_move_object(from_bucket = "a", from_object = "x", to_bucket = "b", overwrite = "no"))
  expect_error(minio_move_object(from_bucket = "a", from_object = "x", to_bucket = "b", verify = "no"))
  expect_error(minio_move_object(from_bucket = "a", from_object = "x", to_bucket = "b", verify_size = "no"))
  expect_error(minio_move_object(from_bucket = "a", from_object = "x", to_bucket = "b", use_https = "no"))
  expect_error(minio_move_object(from_bucket = "a", from_object = "x", to_bucket = "b", region = 123))
})

test_that("minio_move_object errors when source does not exist (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- sub("\\.bin$", ".txt", minior_unique_key("move-missing"))

  expect_false(minio_object_exists(bucket = bucket, object = missing_key, use_https = use_https, region = region))

  expect_error(
    minio_move_object(
      from_bucket = bucket,
      from_object = missing_key,
      to_bucket = bucket,
      to_object = sub("\\.txt$", "-dst.txt", missing_key),
      use_https = use_https,
      region = region
    ),
    "Source object not found",
    fixed = TRUE
  )
})

test_that("minio_move_object errors when destination exists and overwrite=FALSE (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  from_key <- sub("\\.bin$", ".txt", minior_unique_key("move-nooverwrite"))
  to_key   <- sub("\\.bin$", ".txt", minior_unique_key("move-nooverwrite-dst"))

  expect_true(minio_put_object(bucket, from_key, charToRaw("SRC\n"), content_type = "text/plain",
                               multipart = FALSE, use_https = use_https, region = region))
  expect_true(minio_put_object(bucket, to_key, charToRaw("DST\n"), content_type = "text/plain",
                               multipart = FALSE, use_https = use_https, region = region))

  expect_error(
    minio_move_object(
      from_bucket = bucket,
      from_object = from_key,
      to_bucket = bucket,
      to_object = to_key,
      overwrite = FALSE,
      verify = TRUE,
      verify_size = TRUE,
      use_https = use_https,
      region = region
    ),
    "Destination object already exists",
    fixed = TRUE
  )

  # Cleanup (both should still exist)
  expect_true(minio_object_exists(bucket, from_key, use_https = use_https, region = region))
  expect_true(minio_object_exists(bucket, to_key, use_https = use_https, region = region))
  minio_remove_object(bucket, from_key, use_https = use_https, region = region)
  minio_remove_object(bucket, to_key, use_https = use_https, region = region)
})

test_that("minio_move_object moves object within same bucket, default to_object=NULL keeps name (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  from_key <- sub("\\.bin$", ".txt", minior_unique_key("move-default-to"))
  raw <- charToRaw(paste0("HELLO-", sample.int(1e9, 1), "\n"))

  expect_true(minio_put_object(bucket, from_key, raw, content_type = "text/plain",
                               multipart = FALSE, use_https = use_https, region = region))
  expect_true(minio_object_exists(bucket, from_key, use_https = use_https, region = region))

  to_key <- sub("\\.txt$", "-moved.txt", from_key)

  expect_true(
    minio_move_object(
      from_bucket = bucket,
      from_object = from_key,
      to_bucket = bucket,
      to_object = to_key,
      overwrite = FALSE,
      verify = TRUE,
      verify_size = TRUE,
      use_https = use_https,
      region = region
    )
  )

  expect_false(minio_object_exists(bucket, from_key, use_https = use_https, region = region))
  expect_true(minio_object_exists(bucket, to_key, use_https = use_https, region = region))

  # Content should match
  got_raw <- minio_get_object(bucket = bucket, object = to_key)
  expect_equal(got_raw, raw)

  # Cleanup
  minio_remove_object(bucket, to_key, use_https = use_https, region = region)
})

test_that("minio_move_object overwrites destination when overwrite=TRUE (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  from_key <- sub("\\.bin$", ".txt", minior_unique_key("move-overwrite"))
  to_key   <- sub("\\.bin$", ".txt", minior_unique_key("move-overwrite-dst"))

  src_raw <- charToRaw(paste0("SRC-", sample.int(1e9, 1), "\n"))
  dst_raw <- charToRaw("OLD_DEST\n")

  expect_true(minio_put_object(bucket, from_key, src_raw, content_type = "text/plain",
                               multipart = FALSE, use_https = use_https, region = region))
  expect_true(minio_put_object(bucket, to_key, dst_raw, content_type = "text/plain",
                               multipart = FALSE, use_https = use_https, region = region))

  expect_true(
    minio_move_object(
      from_bucket = bucket,
      from_object = from_key,
      to_bucket = bucket,
      to_object = to_key,
      overwrite = TRUE,
      verify = TRUE,
      verify_size = TRUE,
      use_https = use_https,
      region = region
    )
  )

  expect_false(minio_object_exists(bucket, from_key, use_https = use_https, region = region))
  expect_true(minio_object_exists(bucket, to_key, use_https = use_https, region = region))

  got_raw <- minio_get_object(bucket = bucket, object = to_key)
  expect_equal(got_raw, src_raw)

  minio_remove_object(bucket, to_key, use_https = use_https, region = region)
})

test_that("minio_move_object errors when verify_size=TRUE and sizes mismatch (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  from_key <- sub("\\.bin$", ".txt", minior_unique_key("move-nosize"))
  to_key   <- sub("\\.bin$", ".txt", minior_unique_key("move-nosize-dst"))

  raw <- charToRaw(paste0("DATA-", sample.int(1e9, 1), "\n"))
  expect_true(minio_put_object(bucket, from_key, raw, content_type = "text/plain",
                               multipart = FALSE, use_https = use_https, region = region))

  expect_true(
    minio_move_object(
      from_bucket = bucket,
      from_object = from_key,
      to_bucket = bucket,
      to_object = to_key,
      overwrite = FALSE,
      verify = TRUE,
      verify_size = FALSE,  # explicitly disable size check
      use_https = use_https,
      region = region
    )
  )

  expect_false(minio_object_exists(bucket, from_key, use_https = use_https, region = region))
  expect_true(minio_object_exists(bucket, to_key, use_https = use_https, region = region))

  minio_remove_object(bucket, to_key, use_https = use_https, region = region)
})
