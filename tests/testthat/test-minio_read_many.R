test_that("minio_read_many errors when neither objects nor prefix are provided", {
  expect_error(
    minio_read_many(bucket = "b"),
    "Provide either 'objects' or 'prefix'",
    fixed = TRUE
  )
})

test_that("minio_read_many errors when only one of date_from/date_to is provided", {
  expect_error(
    minio_read_many(bucket = "b", objects = "x.parquet", date_from = 2020),
    "Provide both 'date_from' and 'date_to'",
    fixed = TRUE
  )
  expect_error(
    minio_read_many(bucket = "b", objects = "x.parquet", date_to = 2020),
    "Provide both 'date_from' and 'date_to'",
    fixed = TRUE
  )
})

test_that("minio_read_many errors when date precisions differ", {
  expect_error(
    minio_read_many(bucket = "b", objects = "x_202001.parquet", date_from = 2020, date_to = 202001),
    "must have the same precision",
    fixed = TRUE
  )
})

test_that("minio_read_many errors on invalid date filter values", {
  expect_error(
    minio_read_many(bucket = "b", objects = "x_202001.parquet", date_from = "2020-01", date_to = "202001"),
    "Invalid date filter value",
    fixed = TRUE
  )
})

test_that("minio_read_many errors when no parquet keys remain after filtering", {
  expect_error(
    minio_read_many(bucket = "b", objects = c("x.csv", "y.json")),
    "No Parquet objects found",
    fixed = TRUE
  )
})

test_that("minio_read_many returns empty data.frame when listing yields no keys", {
  skip_if_no_minio()
  skip_if_not_installed("arrow")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  # Use a prefix that should have no objects (random)
  prefix <- paste0("empty-prefix-", sample.int(1e9, 1), "/")

  got <- minio_read_many(
    bucket = bucket,
    prefix = prefix,
    pattern = "\\.(parquet|pq)$",
    verbose = FALSE,
    use_https = use_https,
    region = region
  )

  expect_true(is.data.frame(got))
  expect_equal(nrow(got), 0L)
  expect_equal(ncol(got), 0L)
})

test_that("minio_read_many reads explicit objects and union-concats schemas (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("arrow")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  # Create two parquet files with different schemas
  df1 <- data.frame(
    id = 1:2,
    a = c("x", "y"),
    stringsAsFactors = FALSE
  )
  df2 <- data.frame(
    id = 3:4,
    b = c(10, 20),
    stringsAsFactors = FALSE
  )

  tmp1 <- tempfile(fileext = ".parquet")
  tmp2 <- tempfile(fileext = ".parquet")
  arrow::write_parquet(df1, tmp1)
  arrow::write_parquet(df2, tmp2)

  raw1 <- readBin(tmp1, what = "raw", n = file.info(tmp1)$size)
  raw2 <- readBin(tmp2, what = "raw", n = file.info(tmp2)$size)

  key1 <- sub("\\.bin$", "_202401.parquet", minior_unique_key("readmany"))
  key2 <- sub("\\.bin$", "_202402.parquet", minior_unique_key("readmany"))

  expect_true(
    minio_put_object(
      bucket = bucket, object = key1, raw = raw1,
      content_type = "application/octet-stream", multipart = FALSE,
      use_https = use_https, region = region
    )
  )
  expect_true(
    minio_put_object(
      bucket = bucket, object = key2, raw = raw2,
      content_type = "application/octet-stream", multipart = FALSE,
      use_https = use_https, region = region
    )
  )

  got <- minio_read_many(
    bucket = bucket,
    objects = c(key1, key2),
    verbose = FALSE,
    use_https = use_https,
    region = region,
    warn_bytes = Inf
  )

  expect_true(is.data.frame(got))
  expect_equal(names(got), c("id", "a", "b"))

  # Expected union: df1 has b=NA, df2 has a=NA
  exp <- rbind(
    data.frame(id = 1:2, a = c("x", "y"), b = c(NA, NA), stringsAsFactors = FALSE),
    data.frame(id = 3:4, a = c(NA, NA), b = c(10, 20), stringsAsFactors = FALSE)
  )
  rownames(exp) <- NULL

  expect_equal(got, exp)

  # Cleanup
  minio_remove_object(bucket, key1, use_https = use_https, region = region)
  minio_remove_object(bucket, key2, use_https = use_https, region = region)
})

test_that("minio_read_many supports prefix + pattern + date range suffix filtering (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("arrow")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  prefix <- paste0("readmany-prefix/", format(Sys.time(), "%Y%m%d-%H%M%OS3"), "/", sample.int(1e6, 1), "/")

  make_parquet_raw <- function(df) {
    tmp <- tempfile(fileext = ".parquet")
    arrow::write_parquet(df, tmp)
    readBin(tmp, what = "raw", n = file.info(tmp)$size)
  }

  # three files: 202401, 202402, 202403
  k1 <- paste0(prefix, "x_202401.parquet")
  k2 <- paste0(prefix, "x_202402.parquet")
  k3 <- paste0(prefix, "x_202403.parquet")

  df1 <- data.frame(id = 1L, m = "202401", stringsAsFactors = FALSE)
  df2 <- data.frame(id = 2L, m = "202402", stringsAsFactors = FALSE)
  df3 <- data.frame(id = 3L, m = "202403", stringsAsFactors = FALSE)

  expect_true(minio_put_object(bucket, k1, make_parquet_raw(df1), content_type = "application/octet-stream",
                               multipart = FALSE, use_https = use_https, region = region))
  expect_true(minio_put_object(bucket, k2, make_parquet_raw(df2), content_type = "application/octet-stream",
                               multipart = FALSE, use_https = use_https, region = region))
  expect_true(minio_put_object(bucket, k3, make_parquet_raw(df3), content_type = "application/octet-stream",
                               multipart = FALSE, use_https = use_https, region = region))

  got <- minio_read_many(
    bucket = bucket,
    prefix = prefix,
    pattern = "\\.parquet$",
    date_from = 202402,
    date_to = 202403,
    verbose = FALSE,
    use_https = use_https,
    region = region,
    warn_bytes = Inf
  )

  expect_true(is.data.frame(got))
  expect_equal(got$m, c("202402", "202403"))
  expect_equal(got$id, c(2L, 3L))

  # Cleanup
  minio_remove_object(bucket, k1, use_https = use_https, region = region)
  minio_remove_object(bucket, k2, use_https = use_https, region = region)
  minio_remove_object(bucket, k3, use_https = use_https, region = region)
})

test_that("minio_read_many warns when total remote size exceeds warn_bytes (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("arrow")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  df <- data.frame(id = 1:2, x = c("a", "b"), stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".parquet")
  arrow::write_parquet(df, tmp)
  raw_parquet <- readBin(tmp, what = "raw", n = file.info(tmp)$size)

  key <- sub("\\.bin$", "_202401.parquet", minior_unique_key("readmany-warn"))

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

  expect_warning(
    minio_read_many(
      bucket = bucket,
      objects = c(key),
      warn_bytes = 1,       # force warning
      verbose = FALSE,
      use_https = use_https,
      region = region
    ),
    "Total remote size",
    fixed = TRUE
  )

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_read_many streams to out_dir and returns directory (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("arrow")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  df1 <- data.frame(id = 1:2, a = c("x", "y"), stringsAsFactors = FALSE)
  df2 <- data.frame(id = 3:4, b = c(10, 20), stringsAsFactors = FALSE)

  tmp1 <- tempfile(fileext = ".parquet")
  tmp2 <- tempfile(fileext = ".parquet")
  arrow::write_parquet(df1, tmp1)
  arrow::write_parquet(df2, tmp2)

  raw1 <- readBin(tmp1, what = "raw", n = file.info(tmp1)$size)
  raw2 <- readBin(tmp2, what = "raw", n = file.info(tmp2)$size)

  key1 <- sub("\\.bin$", "_202401.parquet", minior_unique_key("readmany-out"))
  key2 <- sub("\\.bin$", "_202402.parquet", minior_unique_key("readmany-out"))

  expect_true(minio_put_object(bucket, key1, raw1, content_type = "application/octet-stream",
                               multipart = FALSE, use_https = use_https, region = region))
  expect_true(minio_put_object(bucket, key2, raw2, content_type = "application/octet-stream",
                               multipart = FALSE, use_https = use_https, region = region))

  out_dir <- file.path(tempdir(), paste0("minio_read_many_out_", sample.int(1e9, 1)))
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  out <- minio_read_many(
    bucket = bucket,
    objects = c(key1, key2),
    out_dir = out_dir,
    verbose = FALSE,
    use_https = use_https,
    region = region,
    warn_bytes = Inf
  )

  # Function returns out_dir invisibly; still equals string
  expect_equal(out, out_dir)
  expect_true(dir.exists(out_dir))

  files <- list.files(out_dir, pattern = "\\.parquet$", full.names = TRUE)
  expect_true(length(files) >= 2)

  # Read back dataset files and ensure union schema holds
  tabs <- lapply(files, arrow::read_parquet)
  tabs <- lapply(tabs, function(x) as.data.frame(x, stringsAsFactors = FALSE))

  all_cols <- Reduce(union, lapply(tabs, names))
  tabs2 <- lapply(tabs, function(d) {
    miss <- setdiff(all_cols, names(d))
    for (m in miss) d[[m]] <- NA
    d <- d[, all_cols, drop = FALSE]
    d
  })
  combined <- do.call(rbind, tabs2)
  rownames(combined) <- NULL

  # Should contain both original ids
  expect_true(all(c(1L, 2L, 3L, 4L) %in% combined$id))

  # Cleanup remote
  minio_remove_object(bucket, key1, use_https = use_https, region = region)
  minio_remove_object(bucket, key2, use_https = use_https, region = region)
})
