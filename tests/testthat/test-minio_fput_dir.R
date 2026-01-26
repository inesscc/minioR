test_that("minio_fput_dir errors on invalid inputs", {
  expect_error(minio_fput_dir(bucket = 123, dir = tempdir()))
  expect_error(minio_fput_dir(bucket = "b", dir = 123))
  expect_error(minio_fput_dir(bucket = "b", dir = tempdir(), recursive = "yes"))
  expect_error(minio_fput_dir(bucket = "b", dir = tempdir(), dry_run = "no"))
  expect_error(minio_fput_dir(bucket = "b", dir = tempdir(), multipart = "no"))
  expect_error(minio_fput_dir(bucket = "b", dir = tempdir(), use_https = "no"))
  expect_error(minio_fput_dir(bucket = "b", dir = tempdir(), region = 123))
})

test_that("minio_fput_dir errors when local directory does not exist", {
  expect_error(
    minio_fput_dir(bucket = "b", dir = file.path(tempdir(), paste0("nope_", sample.int(1e9, 1)))),
    "Local directory does not exist",
    fixed = TRUE
  )
})

test_that("minio_fput_dir returns empty result when directory has no files", {
  d <- tempfile("empty_dir_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE, force = TRUE), add = TRUE)

  out <- minio_fput_dir(bucket = "b", dir = d, dry_run = TRUE)

  expect_true(is.data.frame(out))
  expect_equal(nrow(out), 0L)
  expect_equal(names(out), c("local_file", "object", "uploaded", "error"))
})

test_that("minio_fput_dir dry_run returns planned uploads with normalized prefix + filters", {
  d <- tempfile("minio_fput_dir_")
  dir.create(d, recursive = TRUE)
  dir.create(file.path(d, "sub"), recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE, force = TRUE), add = TRUE)

  f1 <- file.path(d, "a.csv")
  f2 <- file.path(d, "b.tmp")
  f3 <- file.path(d, "sub", "c.csv")
  f4 <- file.path(d, "sub", "d.json")

  writeLines("x", f1)
  writeLines("x", f2)
  writeLines("x", f3)
  writeLines("x", f4)

  out <- minio_fput_dir(
    bucket = "b",
    dir = d,
    prefix = "/raw/projectA/",
    recursive = TRUE,
    include = c("\\.csv$", "\\.json$"),
    exclude = c("\\.tmp$", "^sub/c\\.csv$"),
    dry_run = TRUE
  )

  expect_true(is.data.frame(out))
  expect_true(all(c("local_file", "object", "uploaded", "error") %in% names(out)))
  expect_true(all(out$uploaded == FALSE))
  expect_true(all(is.na(out$error)))

  # Object keys should be S3-style: POSIX and no leading slashes
  expect_false(any(grepl("\\\\", out$object)))
  expect_false(any(grepl("^/+", out$object)))

  # Prefix normalized
  expect_true(all(startsWith(out$object, "raw/projectA/")))

  # Should include a.csv and sub/d.json only
  rel_objects <- sub("^raw/projectA/+", "", out$object)
  expect_equal(sort(rel_objects), sort(c("a.csv", "sub/d.json")))

  # And local_file should end with those paths (OS-agnostic)
  lf <- gsub("\\\\", "/", out$local_file)
  expect_true(all(grepl("(a\\.csv|sub/d\\.json)$", lf)))
})

test_that("minio_fput_dir uploads directory preserving structure (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  d <- tempfile("minio_fput_dir_int_")
  dir.create(d, recursive = TRUE)
  dir.create(file.path(d, "sub"), recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE, force = TRUE), add = TRUE)

  f1 <- file.path(d, "a.csv")
  f2 <- file.path(d, "sub", "b.json")

  writeLines("id,name\n1,a\n2,b", f1)
  writeLines('{"ok": true}', f2)

  prefix <- paste0("test-fput-dir/", format(Sys.time(), "%Y%m%d-%H%M%OS3"), "-", sample.int(1e9, 1))

  res <- minio_fput_dir(
    bucket = bucket,
    dir = d,
    prefix = prefix,
    recursive = TRUE,
    dry_run = FALSE,
    multipart = FALSE,
    use_https = use_https,
    region = region
  )

  expect_true(is.data.frame(res))
  expect_equal(names(res), c("local_file", "object", "uploaded", "error"))
  expect_equal(nrow(res), 2L)
  expect_true(all(res$uploaded))
  expect_true(all(is.na(res$error)))

  obj1 <- paste0(prefix, "/a.csv")
  obj2 <- paste0(prefix, "/sub/b.json")
  expect_true(minio_object_exists(bucket, obj1, use_https = use_https, region = region))
  expect_true(minio_object_exists(bucket, obj2, use_https = use_https, region = region))

  minio_remove_object(bucket, obj1, use_https = use_https, region = region)
  minio_remove_object(bucket, obj2, use_https = use_https, region = region)
  expect_false(minio_object_exists(bucket, obj1, use_https = use_https, region = region))
  expect_false(minio_object_exists(bucket, obj2, use_https = use_https, region = region))
})

test_that("minio_fput_dir honors recursive=FALSE (dry_run)", {
  d <- tempfile("minio_fput_dir_norec_")
  dir.create(d, recursive = TRUE)
  dir.create(file.path(d, "sub"), recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE, force = TRUE), add = TRUE)

  f1 <- file.path(d, "a.csv")
  f2 <- file.path(d, "sub", "b.csv")
  writeLines("x", f1)
  writeLines("y", f2)

  out <- minio_fput_dir(
    bucket = "b",
    dir = d,
    recursive = FALSE,
    dry_run = TRUE
  )

  expect_equal(nrow(out), 1L)

  # local_file check OS-agnostic
  expect_true(grepl("/a\\.csv$", gsub("\\\\", "/", out$local_file)))

  # object key should be just a.csv
  obj <- gsub("\\\\", "/", out$object)
  obj <- sub("^/+", "", obj)
  expect_equal(obj, "a.csv")
})
