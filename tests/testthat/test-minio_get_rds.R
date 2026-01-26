test_that("minio_get_rds downloads an .rds and returns identical object (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getrds")

  obj <- list(
    id = 123L,
    name = "alpha",
    created = as.POSIXct("2020-01-02 03:04:05", tz = "UTC"),
    df = data.frame(
      a = 1:3,
      b = c("x", "y", "z"),
      stringsAsFactors = FALSE
    ),
    vec = c(TRUE, FALSE, TRUE),
    num = c(10.5, NA_real_, 30.25)
  )

  tmp <- tempfile(fileext = ".rds")
  saveRDS(obj, tmp)

  raw_rds <- readBin(tmp, what = "raw", n = file.info(tmp)$size)
  expect_true(is.raw(raw_rds))
  expect_true(length(raw_rds) > 0)

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_rds,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  got <- minio_get_rds(bucket = bucket, object = key)

  expect_equal(got, obj)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_get_rds errors on invalid bucket/object inputs", {
  expect_error(minio_get_rds(bucket = 123, object = "x"))
  expect_error(minio_get_rds(bucket = "b", object = 456))
  expect_error(minio_get_rds(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_get_rds(bucket = "b", object = c("x1", "x2")))
})

test_that("minio_get_rds errors when object does not exist (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("getrds-missing")
  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_get_rds(bucket = bucket, object = missing_key)
  )
})
