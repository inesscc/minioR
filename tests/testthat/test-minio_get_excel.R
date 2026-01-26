test_that("minio_get_excel downloads an .xlsx and returns identical data.frame (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getexcel")

  df <- data.frame(
    id = 1:4,
    name = c("a", "b", "c", "d"),
    value = c(10.5, 20.0, 30.25, NA_real_),
    stringsAsFactors = FALSE
  )

  tmp <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(df, tmp)

  raw_xlsx <- readBin(tmp, what = "raw", n = file.info(tmp)$size)
  expect_true(is.raw(raw_xlsx))
  expect_true(length(raw_xlsx) > 0)

  # Upload Excel object
  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_xlsx,
      content_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  # Read back
  got <- minio_get_excel(bucket = bucket, object = key)

  expect_true(is.data.frame(got))
  expect_equal(got, df)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_get_excel passes ... arguments to readxl::read_xlsx (sheet, range)", {
  skip_if_no_minio()
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getexcel-args")

  df1 <- data.frame(
    id = 1:3,
    val = c(10, 20, 30)
  )

  df2 <- data.frame(
    id = 4:6,
    val = c(40, 50, 60)
  )

  tmp <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(
    list(
      sheet_one = df1,
      sheet_two = df2
    ),
    tmp
  )

  raw_xlsx <- readBin(tmp, what = "raw", n = file.info(tmp)$size)

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_xlsx,
      content_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  # Read only second sheet and a subset of rows
  got <- minio_get_excel(
    bucket = bucket,
    object = key,
    sheet = "sheet_two",
    range = "A1:B3"
  )

  expect_true(is.data.frame(got))
  expect_equal(got, df2[1:2, , drop = FALSE])

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_get_excel errors on invalid bucket/object inputs", {
  expect_error(minio_get_excel(bucket = 123, object = "x"))
  expect_error(minio_get_excel(bucket = "b", object = 456))
  expect_error(minio_get_excel(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_get_excel(bucket = "b", object = c("x1", "x2")))
})

test_that("minio_get_excel errors when 'readxl' is not installed", {
  skip_if_installed("readxl")

  expect_error(
    minio_get_excel(bucket = "b", object = "x"),
    "Package 'readxl' is required to read Excel files",
    fixed = TRUE
  )
})

test_that("minio_get_excel errors when object does not exist (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("readxl")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("getexcel-missing")
  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_get_excel(bucket = bucket, object = missing_key)
  )
})
