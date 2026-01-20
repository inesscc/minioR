test_that("minio_get_csv downloads a CSV and returns identical data.frame (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getcsv")

  # Create a deterministic data.frame and serialize to CSV
  df <- data.frame(
    id = 1:3,
    name = c("a", "b", "c"),
    value = c(10.5, 20.0, 30.25),
    stringsAsFactors = FALSE
  )

  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(df, tmp, row.names = FALSE)
  csv_txt <- paste(readLines(tmp, warn = FALSE), collapse = "\n")
  csv_raw <- charToRaw(paste0(csv_txt, "\n"))

  # Upload CSV as an object
  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = csv_raw,
      content_type = "text/csv",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  # Read back as data.frame
  got <- minio_get_csv(bucket = bucket, object = key)

  expect_true(is.data.frame(got))
  expect_equal(got, df)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_get_csv passes ... arguments to read.csv (sep/header/stringsAsFactors)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getcsv-args")

  # Use ; separator and no header, include a factor-like column
  csv_txt <- paste(
    "1;A;10",
    "2;B;20",
    "3;A;30",
    sep = "\n"
  )
  csv_raw <- charToRaw(paste0(csv_txt, "\n"))

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = csv_raw,
      content_type = "text/csv",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  got <- minio_get_csv(
    bucket = bucket,
    object = key,
    sep = ";",
    header = FALSE,
    stringsAsFactors = TRUE
  )

  # Without header, read.csv will name columns V1, V2, V3
  expect_equal(names(got), c("V1", "V2", "V3"))
  expect_equal(got$V1, c(1, 2, 3))
  expect_true(is.factor(got$V2))
  expect_equal(levels(got$V2), c("A", "B"))
  expect_equal(got$V3, c(10, 20, 30))

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_get_csv errors on invalid bucket/object inputs", {
  expect_error(minio_get_csv(bucket = 123, object = "x"))
  expect_error(minio_get_csv(bucket = "b", object = 456))
  expect_error(minio_get_csv(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_get_csv(bucket = "b", object = c("x1", "x2")))
})

test_that("minio_get_csv errors when object does not exist (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("getcsv-missing")

  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_get_csv(bucket = bucket, object = missing_key)
  )
})
