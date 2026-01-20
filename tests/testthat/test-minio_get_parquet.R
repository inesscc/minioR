test_that("minio_get_parquet reads a parquet object and returns identical data (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("arrow")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getparquet")

  df <- data.frame(
    id = 1:5,
    name = c("a", "b", "c", "d", "e"),
    value = c(10.5, 20.0, 30.25, NA_real_, 50.75),
    flag = c(TRUE, FALSE, TRUE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )

  tmp <- tempfile(fileext = ".parquet")
  arrow::write_parquet(df, tmp)

  raw_parquet <- readBin(tmp, what = "raw", n = file.info(tmp)$size)
  expect_true(is.raw(raw_parquet))
  expect_true(length(raw_parquet) > 0)

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_parquet,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  got <- minio_get_parquet(bucket = bucket, object = key)
  got_df <- as.data.frame(got)

  expect_equal(names(got_df), names(df))
  expect_equal(got_df, df)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_get_parquet errors when arrow is not installed", {
  skip_if_installed("arrow")

  expect_error(
    minio_get_parquet(bucket = "b", object = "x"),
    "Package 'arrow' is required to read Parquet files"
  )
})

test_that("minio_get_parquet validates inputs", {
  skip_if_not_installed("arrow")

  expect_error(minio_get_parquet(bucket = 123, object = "x"))
  expect_error(minio_get_parquet(bucket = "b", object = 456))
  expect_error(minio_get_parquet(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_get_parquet(bucket = "b", object = c("x1", "x2")))
})
