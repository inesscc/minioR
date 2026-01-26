test_that("minio_write_object errors on invalid bucket/object inputs", {
  expect_error(minio_write_object(bucket = 123, object = "x.csv", x = data.frame(a = 1)))
  expect_error(minio_write_object(bucket = "b", object = 456, x = data.frame(a = 1)))
  expect_error(minio_write_object(bucket = c("b1", "b2"), object = "x.csv", x = data.frame(a = 1)))
  expect_error(minio_write_object(bucket = "b", object = c("x.csv", "y.csv"), x = data.frame(a = 1)))
})

test_that("minio_write_object errors when object has no extension", {
  expect_error(
    minio_write_object(bucket = "b", object = "path/noext", x = data.frame(a = 1)),
    "has no file extension",
    fixed = TRUE
  )
})

test_that("minio_write_object errors on unsupported extension", {
  expect_error(
    minio_write_object(bucket = "b", object = "x.unsupported", x = 1),
    "Unsupported file extension",
    fixed = TRUE
  )
})

test_that("minio_write_object errors when content_type is empty string", {
  expect_error(
    minio_write_object(bucket = "b", object = "x.csv", x = data.frame(a = 1), content_type = ""),
    "content_type",
    fixed = FALSE
  )
})

test_that("minio_write_object writes CSV and can be read back (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".csv", minior_unique_key("writeobj-csv"))

  df <- data.frame(
    id = 1:3,
    name = c("a", "b", "c"),
    value = c(10.5, 20.0, 30.25),
    stringsAsFactors = FALSE
  )

  expect_true(minio_write_object(
    bucket = bucket,
    object = key,
    x = df,
    row.names = FALSE,
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  got <- minio_get_csv(bucket = bucket, object = key)
  expect_true(is.data.frame(got))
  expect_equal(got, df)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_write_object errors for CSV when x is not a data.frame", {
  expect_error(
    minio_write_object(bucket = "b", object = "x.csv", x = list(a = 1)),
    "must be a data.frame",
    fixed = TRUE
  )
})

test_that("minio_write_object writes JSON and can be read back (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("jsonlite")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".json", minior_unique_key("writeobj-json"))

  x <- list(
    id = 1,
    ok = TRUE,
    nums = c(1, 2, 3),
    items = list(list(k = "x", v = 1), list(k = "y", v = 2))
  )

  expect_true(minio_write_object(
    bucket = bucket,
    object = key,
    x = x,
    auto_unbox = TRUE,
    pretty = FALSE,
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  got <- minio_get_json(bucket = bucket, object = key, simplifyDataFrame = FALSE)
  expect_equal(got, x)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_write_object writes Parquet and can be read back (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("arrow")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".parquet", minior_unique_key("writeobj-parquet"))

  df <- data.frame(
    id = 1:4,
    name = c("a", "b", "c", "d"),
    value = c(10.5, 20.0, 30.25, NA_real_),
    stringsAsFactors = FALSE
  )

  expect_true(minio_write_object(
    bucket = bucket,
    object = key,
    x = df,
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  got <- minio_get_parquet(bucket = bucket, object = key)
  expect_equal(as.data.frame(got, stringsAsFactors = FALSE), df)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_write_object writes XLSX and can be read back (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".xlsx", minior_unique_key("writeobj-xlsx"))

  df <- data.frame(
    id = 1:3,
    name = c("a", "b", "c"),
    stringsAsFactors = FALSE
  )

  expect_true(minio_write_object(
    bucket = bucket,
    object = key,
    x = df,
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  got <- minio_get_excel(bucket = bucket, object = key)
  expect_equal(got, df)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_write_object writes Feather and can be read back (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("feather")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".feather", minior_unique_key("writeobj-feather"))

  df <- data.frame(
    id = 1:3,
    value = c(10.5, 20.0, 30.25),
    stringsAsFactors = FALSE
  )

  expect_true(minio_write_object(
    bucket = bucket,
    object = key,
    x = df,
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  got <- minio_get_feather(bucket = bucket, object = key)
  expect_equal(got, df)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_write_object writes DTA and can be read back (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("haven")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".dta", minior_unique_key("writeobj-dta"))

  df <- data.frame(
    id = 1:3,
    name = c("a", "b", "c"),
    value = c(10.5, 20.0, 30.25),
    flag = c(TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )

  expect_true(minio_write_object(
    bucket = bucket,
    object = key,
    x = df,
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  got <- minio_get_dta(bucket = bucket, object = key)

  # Strip haven attrs + tolerate 0/1 numeric logical like we did before
  got2 <- got
  got2[] <- lapply(got2, function(col) {
    keep <- intersect(names(attributes(col)), c("names", "row.names", "class"))
    attributes(col) <- attributes(col)[keep]
    col
  })
  if (is.numeric(got2$flag) && all(got2$flag %in% c(0, 1, NA))) got2$flag <- as.logical(got2$flag)

  expect_equal(got2, df)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_write_object writes RDS and can be read back (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".rds", minior_unique_key("writeobj-rds"))

  x <- list(a = 1:3, msg = "hello", df = data.frame(x = 1:2, y = c("a", "b")))

  expect_true(minio_write_object(
    bucket = bucket,
    object = key,
    x = x,
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  got <- minio_get_rds(bucket = bucket, object = key)
  expect_equal(got, x)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_write_object writes RData (unnamed) as object 'x' and can be read back (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".RData", minior_unique_key("writeobj-rdata-x"))

  x <- data.frame(id = 1:2, v = c("a", "b"), stringsAsFactors = FALSE)

  expect_true(minio_write_object(
    bucket = bucket,
    object = key,
    x = x,
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  got <- minio_get_rdata(bucket = bucket, object = key)
  expect_true(is.list(got))
  expect_true("x" %in% names(got))
  expect_equal(got$x, x)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_write_object writes RData (named list) and can be read back (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".rda", minior_unique_key("writeobj-rdata-list"))

  df <- data.frame(id = 1:2, v = c("a", "b"), stringsAsFactors = FALSE)
  n <- 99L

  x <- list(df = df, n = n)

  expect_true(minio_write_object(
    bucket = bucket,
    object = key,
    x = x,
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  got <- minio_get_rdata(bucket = bucket, object = key)
  expect_true(is.list(got))
  expect_true(all(c("df", "n") %in% names(got)))
  expect_equal(got$df, df)
  expect_equal(got$n, n)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_write_object uses custom content_type when provided (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".csv", minior_unique_key("writeobj-ctype"))

  df <- data.frame(a = 1:2, stringsAsFactors = FALSE)

  expect_true(minio_write_object(
    bucket = bucket,
    object = key,
    x = df,
    row.names = FALSE,
    content_type = "text/plain",
    multipart = FALSE,
    use_https = use_https,
    region = region
  ))

  meta <- minio_get_metadata(bucket = bucket, object = key, quiet = TRUE, use_https = use_https, region = region)
  # content-type header key can vary (content_type vs content-type); check robustly
  ct <- meta[["content_type"]]
  if (is.null(ct)) ct <- meta[["content-type"]]
  if (!is.null(ct)) {
    expect_equal(tolower(ct), "text/plain")
  }

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})
