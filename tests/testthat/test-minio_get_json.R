test_that("minio_get_json downloads a JSON and returns expected parsed object (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("jsonlite")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getjson")

  # NOTE: items is a list of records with same keys -> jsonlite will simplify to data.frame by default
  obj <- list(
    id = 123,
    name = "alpha",
    active = TRUE,
    scores = c(10.5, 20, 30.25),
    meta = list(source = "unit-test", tags = c("a", "b")),
    items = list(
      list(k = "x", v = 1),
      list(k = "y", v = 2)
    )
  )

  json_txt <- jsonlite::toJSON(obj, auto_unbox = TRUE, null = "null", pretty = FALSE)
  json_raw <- charToRaw(paste0(json_txt, "\n"))

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = json_raw,
      content_type = "application/json",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )
  expect_true(minio_object_exists(bucket, key, use_https = use_https, region = region))

  got <- minio_get_json(bucket = bucket, object = key)

  # Check scalar/list pieces that should match straightforwardly
  expect_true(is.list(got))
  expect_equal(got$id, obj$id)
  expect_equal(got$name, obj$name)
  expect_equal(got$active, obj$active)
  expect_equal(got$scores, obj$scores)
  expect_equal(got$meta, obj$meta)

  # By default, jsonlite simplifies list-of-records to data.frame
  expect_true(is.data.frame(got$items))
  expect_equal(names(got$items), c("k", "v"))
  expect_equal(got$items$k, c("x", "y"))
  expect_equal(got$items$v, c(1L, 2L))

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, key, use_https = use_https, region = region))
})

test_that("minio_get_json passes ... arguments to jsonlite::fromJSON (simplifyDataFrame, simplifyVector)", {
  skip_if_no_minio()
  skip_if_not_installed("jsonlite")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("getjson-args")

  obj <- list(
    nums = c(1, 2, 3),
    items = list(
      list(k = "x", v = 1),
      list(k = "y", v = 2)
    )
  )

  json_txt <- jsonlite::toJSON(obj, auto_unbox = TRUE, pretty = FALSE)
  json_raw <- charToRaw(paste0(json_txt, "\n"))

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = json_raw,
      content_type = "application/json",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  # Default behavior: nums simplifies to atomic; items simplifies to data.frame
  got_default <- minio_get_json(bucket = bucket, object = key)
  expect_true(is.atomic(got_default$nums))
  expect_equal(got_default$nums, c(1, 2, 3))
  expect_true(is.data.frame(got_default$items))

  # Turn off vector simplification
  got_no_vec <- minio_get_json(bucket = bucket, object = key, simplifyVector = FALSE)
  expect_true(is.list(got_no_vec$nums))
  expect_equal(got_no_vec$nums, as.list(c(1, 2, 3)))

  # Turn off data.frame simplification for records
  got_no_df <- minio_get_json(bucket = bucket, object = key, simplifyDataFrame = FALSE)
  expect_true(is.list(got_no_df$items))
  expect_equal(got_no_df$items, obj$items)

  # Cleanup
  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_get_json errors on invalid bucket/object inputs", {
  expect_error(minio_get_json(bucket = 123, object = "x"))
  expect_error(minio_get_json(bucket = "b", object = 456))
  expect_error(minio_get_json(bucket = c("b1", "b2"), object = "x"))
  expect_error(minio_get_json(bucket = "b", object = c("x1", "x2")))
})

test_that("minio_get_json errors when 'jsonlite' is not installed", {
  skip_if_installed("jsonlite")

  expect_error(
    minio_get_json(bucket = "b", object = "x"),
    "Package 'jsonlite' is required to read JSON files",
    fixed = TRUE
  )
})

test_that("minio_get_json errors when object does not exist (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("jsonlite")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- minior_unique_key("getjson-missing")
  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_get_json(bucket = bucket, object = missing_key)
  )
})
