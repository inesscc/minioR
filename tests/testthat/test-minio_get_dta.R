# Helper: remove haven-added attributes so we compare pure values
strip_haven_attrs <- function(x) {
  stopifnot(is.data.frame(x))

  x[] <- lapply(x, function(col) {
    keep <- intersect(names(attributes(col)), c("names", "row.names", "class"))
    attributes(col) <- attributes(col)[keep]
    col
  })

  x
}

test_that("minio_get_dta downloads a .dta and returns identical data.frame (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("haven")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getdta")

  df <- data.frame(
    id = 1:5,
    name = c("a", "b", "c", "d", "e"),
    value = c(10.5, 20.0, 30.25, NA_real_, 50.75),
    flag = c(TRUE, FALSE, TRUE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )

  tmp <- tempfile(fileext = ".dta")
  haven::write_dta(df, tmp)

  raw_dta <- readBin(tmp, what = "raw", n = file.info(tmp)$size)
  expect_true(is.raw(raw_dta))
  expect_true(length(raw_dta) > 0)

  # Upload DTA as an object
  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_dta,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  # Read back
  got <- minio_get_dta(bucket = bucket, object = key)

  expect_true(is.data.frame(got))

  # Compare values ignoring haven attributes, and tolerate 0/1 numeric for logical
  got2 <- strip_haven_attrs(got)
  df2  <- strip_haven_attrs(df)

  if ("flag" %in% names(got2) &&
      is.numeric(got2$flag) &&
      all(got2$flag %in% c(0, 1, NA))) {
    got2$flag <- as.logical(got2$flag)
  }

  expect_equal(got2, df2)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_get_dta passes ... arguments to haven::read_dta (n_max)", {
  skip_if_no_minio()
  skip_if_not_installed("haven")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getdta-args")

  df <- data.frame(
    id = 1:3,
    name = c("a", "b", "c"),
    value = c(10.5, 20.0, 30.25),
    extra = c("x", "y", "z"),
    stringsAsFactors = FALSE
  )

  tmp <- tempfile(fileext = ".dta")
  haven::write_dta(df, tmp)
  raw_dta <- readBin(tmp, what = "raw", n = file.info(tmp)$size)

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_dta,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  got <- minio_get_dta(
    bucket = bucket,
    object = key,
    n_max = 2
  )

  expect_true(is.data.frame(got))
  expect_equal(nrow(got), 2L)

  # Ensure the first rows match (ignoring haven attrs)
  got2 <- strip_haven_attrs(got)
  df2  <- strip_haven_attrs(df[1:2, , drop = FALSE])
  expect_equal(got2, df2)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_get_dta errors on invalid bucket/object inputs", {
  expect_error(minio_get_dta(bucket = 123, object = "x"))
  expect_error(minio_get_dta(bucket = "b", object = 456))
  expect_error(minio_get_dta(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_get_dta(bucket = "b", object = c("x1", "x2")))
})

test_that("minio_get_dta errors when 'haven' is not installed", {
  skip_if_installed("haven")

  expect_error(
    minio_get_dta(bucket = "b", object = "x"),
    "Package 'haven' is required to read .dta files",
    fixed = TRUE
  )
})

test_that("minio_get_dta errors when object does not exist (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("haven")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("getdta-missing")
  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_get_dta(bucket = bucket, object = missing_key)
  )
})
