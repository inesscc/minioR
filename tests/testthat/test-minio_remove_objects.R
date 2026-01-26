test_that("minio_remove_objects errors when neither objects nor prefix are provided", {
  expect_error(
    minio_remove_objects(bucket = "b"),
    "Provide either 'objects' or 'prefix'",
    fixed = TRUE
  )
})

test_that("minio_remove_objects errors on invalid inputs", {
  expect_error(minio_remove_objects(bucket = 123, objects = c("a")))
  expect_error(minio_remove_objects(bucket = "b", dry_run = "no"))
  expect_error(minio_remove_objects(bucket = "b", quiet = "no"))
  expect_error(minio_remove_objects(bucket = "b", error_on_missing = "no"))
  expect_error(minio_remove_objects(bucket = "b", use_https = "no"))
  expect_error(minio_remove_objects(bucket = "b", region = 123))

  expect_error(minio_remove_objects(bucket = "b", objects = 123))
  expect_error(minio_remove_objects(bucket = "b", prefix = 123))
  expect_error(minio_remove_objects(bucket = "b", pattern = 123))
})

test_that("minio_remove_objects returns empty data.frame when resolved keys are empty", {
  # Via explicit objects
  out1 <- minio_remove_objects(bucket = "b", objects = character(0), dry_run = TRUE)
  expect_true(is.data.frame(out1))
  expect_equal(nrow(out1), 0L)
  expect_equal(names(out1), c("object", "removed", "error"))

  # Via prefix (can't guarantee listing w/out MinIO), so just check explicit case enough
})

test_that("minio_remove_objects dry_run returns a deletion plan (no deletions)", {
  out <- minio_remove_objects(
    bucket = "b",
    objects = c("a.csv", "b.csv", "a.csv"), # duplicates
    dry_run = TRUE
  )

  expect_true(is.data.frame(out))
  expect_equal(out$object, c("a.csv", "b.csv")) # unique keeps first occurrence
  expect_true(all(out$removed == FALSE))
  expect_true(all(is.na(out$error)))
})

test_that("minio_remove_objects removes explicit objects (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key1 <- sub("\\.bin$", ".txt", minior_unique_key("rmobjs-explicit"))
  key2 <- sub("\\.bin$", ".txt", minior_unique_key("rmobjs-explicit"))

  raw1 <- charToRaw("hello 1\n")
  raw2 <- charToRaw("hello 2\n")

  expect_true(minio_put_object(bucket, key1, raw1, content_type = "text/plain",
                               multipart = FALSE, use_https = use_https, region = region))
  expect_true(minio_put_object(bucket, key2, raw2, content_type = "text/plain",
                               multipart = FALSE, use_https = use_https, region = region))

  expect_true(minio_object_exists(bucket, key1, use_https = use_https, region = region))
  expect_true(minio_object_exists(bucket, key2, use_https = use_https, region = region))

  out <- minio_remove_objects(
    bucket = bucket,
    objects = c(key1, key2),
    dry_run = FALSE,
    quiet = TRUE,
    use_https = use_https,
    region = region
  )

  expect_true(is.data.frame(out))
  expect_equal(out$object, c(key1, key2))
  expect_true(all(out$removed))
  expect_true(all(is.na(out$error)))

  expect_false(minio_object_exists(bucket, key1, use_https = use_https, region = region))
  expect_false(minio_object_exists(bucket, key2, use_https = use_https, region = region))
})

test_that("minio_remove_objects removes objects discovered by prefix + pattern (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  prefix <- paste0("rmobjs-prefix/", format(Sys.time(), "%Y%m%d-%H%M%OS3"), "-", sample.int(1e9, 1), "/")

  k_csv1 <- paste0(prefix, "a.csv")
  k_csv2 <- paste0(prefix, "b.csv")
  k_txt  <- paste0(prefix, "c.txt")

  expect_true(minio_put_object(bucket, k_csv1, charToRaw("a\n"), content_type = "text/csv",
                               multipart = FALSE, use_https = use_https, region = region))
  expect_true(minio_put_object(bucket, k_csv2, charToRaw("b\n"), content_type = "text/csv",
                               multipart = FALSE, use_https = use_https, region = region))
  expect_true(minio_put_object(bucket, k_txt, charToRaw("c\n"), content_type = "text/plain",
                               multipart = FALSE, use_https = use_https, region = region))

  expect_true(minio_object_exists(bucket, k_csv1, use_https = use_https, region = region))
  expect_true(minio_object_exists(bucket, k_csv2, use_https = use_https, region = region))
  expect_true(minio_object_exists(bucket, k_txt, use_https = use_https, region = region))

  out <- minio_remove_objects(
    bucket = bucket,
    prefix = prefix,
    pattern = "\\.csv$",
    dry_run = FALSE,
    quiet = TRUE,
    use_https = use_https,
    region = region
  )

  expect_true(is.data.frame(out))
  expect_equal(sort(out$object), sort(c(k_csv1, k_csv2)))
  expect_true(all(out$removed))
  expect_true(all(is.na(out$error)))

  expect_false(minio_object_exists(bucket, k_csv1, use_https = use_https, region = region))
  expect_false(minio_object_exists(bucket, k_csv2, use_https = use_https, region = region))
  # non-matching file should remain
  expect_true(minio_object_exists(bucket, k_txt, use_https = use_https, region = region))

  # cleanup remaining
  minio_remove_object(bucket, k_txt, use_https = use_https, region = region)
})

test_that("minio_remove_objects errors on missing objects by default (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  missing_key <- sub("\\.bin$", ".txt", minior_unique_key("rmobjs-missing"))
  expect_false(minio_object_exists(bucket, missing_key, use_https = use_https, region = region))

  expect_error(
    minio_remove_objects(
      bucket = bucket,
      objects = c(missing_key),
      error_on_missing = TRUE,
      quiet = TRUE,
      use_https = use_https,
      region = region
    )
  )
})

test_that("minio_remove_objects can skip missing objects when error_on_missing=FALSE (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  # one existing, one missing
  present <- sub("\\.bin$", ".txt", minior_unique_key("rmobjs-skip"))
  missing <- sub("\\.bin$", ".txt", minior_unique_key("rmobjs-skip"))

  expect_true(minio_put_object(bucket, present, charToRaw("ok\n"), content_type = "text/plain",
                               multipart = FALSE, use_https = use_https, region = region))
  expect_true(minio_object_exists(bucket, present, use_https = use_https, region = region))
  expect_false(minio_object_exists(bucket, missing, use_https = use_https, region = region))

  out <- minio_remove_objects(
    bucket = bucket,
    objects = c(present, missing),
    error_on_missing = FALSE,
    quiet = TRUE,
    use_https = use_https,
    region = region
  )

  expect_true(is.data.frame(out))
  expect_equal(out$object, c(present, missing))

  # present removed
  expect_true(out$removed[1])
  expect_true(is.na(out$error[1]))
  expect_false(minio_object_exists(bucket, present, use_https = use_https, region = region))

  # missing skipped
  expect_false(out$removed[2])
  expect_equal(out$error[2], "Object not found (skipped).")

  # (no cleanup needed for missing)
})
