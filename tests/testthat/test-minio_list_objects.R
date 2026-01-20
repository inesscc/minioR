test_that("minio_list_objects lists all objects in a bucket (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  keys <- c(
    minior_unique_key("list/a"),
    minior_unique_key("list/b"),
    minior_unique_key("list/c")
  )

  payload <- charToRaw("test\n")

  # Upload
  for (k in keys) {
    expect_true(
      minio_put_object(
        bucket = bucket,
        object = k,
        raw = payload,
        multipart = FALSE,
        use_https = use_https,
        region = region
      )
    )
  }

  listed <- minio_list_objects(
    bucket = bucket,
    use_https = use_https,
    region = region
  )

  expect_true(is.character(listed))
  expect_true(all(keys %in% listed))

  # Cleanup
  for (k in keys) {
    minio_remove_object(bucket, k, use_https = use_https, region = region)
  }
})

test_that("minio_list_objects filters objects by prefix (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  keys_with_prefix <- c(
    minior_unique_key("data/raw/a"),
    minior_unique_key("data/raw/b")
  )
  keys_without_prefix <- c(
    minior_unique_key("data/curated/x"),
    minior_unique_key("logs/y")
  )

  payload <- charToRaw("prefix-test\n")

  for (k in c(keys_with_prefix, keys_without_prefix)) {
    expect_true(
      minio_put_object(
        bucket = bucket,
        object = k,
        raw = payload,
        multipart = FALSE,
        use_https = use_https,
        region = region
      )
    )
  }

  listed <- minio_list_objects(
    bucket = bucket,
    prefix = "data/raw/",
    use_https = use_https,
    region = region
  )

  expect_true(is.character(listed))
  expect_equal(sort(listed), sort(keys_with_prefix))
  expect_false(any(keys_without_prefix %in% listed))

  # Cleanup
  for (k in c(keys_with_prefix, keys_without_prefix)) {
    minio_remove_object(bucket, k, use_https = use_https, region = region)
  }
})

test_that("minio_list_objects returns empty character vector when no objects are found (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  # Use a prefix that should not exist
  prefix <- paste0("empty-prefix-", sample.int(1e9, 1), "/")

  listed <- minio_list_objects(
    bucket = bucket,
    prefix = prefix,
    use_https = use_https,
    region = region
  )

  expect_true(is.character(listed))
  expect_length(listed, 0)
})

test_that("minio_list_objects validates inputs", {
  expect_error(minio_list_objects(bucket = 123))
  expect_error(minio_list_objects(bucket = c("b1", "b2")))
  expect_error(minio_list_objects(bucket = "b", prefix = 456))
  expect_error(minio_list_objects(bucket = "b", prefix = c("p1", "p2")))
})

test_that("minio_list_objects errors cleanly when listing fails (integration)", {
  skip("Omitted: backend/policy emits noisy AccessDenied output for unknown buckets.")
  skip_if_no_minio()
  bad_bucket <- paste0("nonexistent-bucket-", sample.int(1e9, 1))

  expect_error(
    minio_list_objects(bucket = bad_bucket),
    "Failed to list objects in bucket"
  )
})

