test_that("minio_read_object errors on invalid bucket/object inputs", {
  expect_error(minio_read_object(bucket = 123, object = "x.csv"))
  expect_error(minio_read_object(bucket = "b", object = 456))
  expect_error(minio_read_object(bucket = c("b1", "b2"), object = "x.csv"))
  expect_error(minio_read_object(bucket = "b", object = c("x.csv", "y.csv")))
})

test_that("minio_read_object errors when object has no extension", {
  expect_error(
    minio_read_object(bucket = "b", object = "path/noext"),
    "has no file extension",
    fixed = TRUE
  )
})

test_that("minio_read_object errors on unsupported extension", {
  expect_error(
    minio_read_object(bucket = "b", object = "x.unsupported"),
    "Unsupported file extension",
    fixed = TRUE
  )
})

test_that("minio_read_object dispatches to minio_get_csv and forwards ... (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("readobj-csv")
  key <- sub("\\.bin$", ".csv", key)

  # Create CSV with ; separator and no header
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

  got <- minio_read_object(
    bucket = bucket,
    object = key,
    sep = ";",
    header = FALSE,
    stringsAsFactors = TRUE
  )

  expect_true(is.data.frame(got))
  expect_equal(names(got), c("V1", "V2", "V3"))
  expect_equal(got$V1, c(1, 2, 3))
  expect_true(is.factor(got$V2))
  expect_equal(levels(got$V2), c("A", "B"))
  expect_equal(got$V3, c(10, 20, 30))

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_read_object dispatches pq/parquet to minio_get_parquet (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("arrow")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  df <- data.frame(
    id = 1:3,
    name = c("a", "b", "c"),
    value = c(10.5, 20.0, 30.25),
    stringsAsFactors = FALSE
  )

  tmp <- tempfile(fileext = ".parquet")
  arrow::write_parquet(df, tmp)
  raw_parquet <- readBin(tmp, what = "raw", n = file.info(tmp)$size)

  # parquet
  key_parquet <- sub("\\.bin$", ".parquet", minior_unique_key("readobj-parquet"))

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key_parquet,
      raw = raw_parquet,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  got1 <- minio_read_object(bucket = bucket, object = key_parquet)
  expect_true(is.data.frame(got1) || inherits(got1, "tbl"))
  expect_equal(as.data.frame(got1, stringsAsFactors = FALSE), df)

  minio_remove_object(bucket, key_parquet, use_https = use_https, region = region)

  # pq alias
  key_pq <- sub("\\.bin$", ".pq", minior_unique_key("readobj-pq"))

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key_pq,
      raw = raw_parquet,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  got2 <- minio_read_object(bucket = bucket, object = key_pq)
  expect_true(is.data.frame(got2) || inherits(got2, "tbl"))
  expect_equal(as.data.frame(got2, stringsAsFactors = FALSE), df)

  minio_remove_object(bucket, key_pq, use_https = use_https, region = region)
})

test_that("minio_read_object dispatches to Excel reader for .xlsx and forwards ... (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- sub("\\.bin$", ".xlsx", minior_unique_key("readobj-xlsx"))

  df1 <- data.frame(id = 1:3, val = c(10, 20, 30))
  df2 <- data.frame(id = 4:6, val = c(40, 50, 60))

  tmp <- tempfile(fileext = ".xlsx")
  writexl::write_xlsx(list(sheet_one = df1, sheet_two = df2), tmp)
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

  # NOTE: this will work once minio_read_object dispatches .xlsx to your actual function
  # (minio_get_excel or minio_get_xlsx depending on what you choose)
  got <- minio_read_object(bucket = bucket, object = key, sheet = "sheet_two", range = "A1:B3")

  expect_true(is.data.frame(got))
  expect_equal(got, df2[1:2, , drop = FALSE])

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})


test_that("minio_read_object dispatches to minio_get_json and forwards ... (integration)", {
  skip_if_no_minio()
  skip_if_not_installed("jsonlite")

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("readobj-json")
  key <- sub("\\.bin$", ".json", key)

  obj <- list(nums = c(1, 2, 3), items = list(list(k = "x", v = 1), list(k = "y", v = 2)))
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

  got <- minio_read_object(bucket = bucket, object = key, simplifyDataFrame = FALSE)
  expect_true(is.list(got))
  expect_equal(got, obj)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_read_object dispatches to minio_get_rds (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  key <- minior_unique_key("readobj-rds")
  key <- sub("\\.bin$", ".rds", key)

  obj <- list(a = 1:3, msg = "hello", df = data.frame(x = 1:2, y = c("a", "b")))

  tmp <- tempfile(fileext = ".rds")
  saveRDS(obj, tmp)
  raw_rds <- readBin(tmp, what = "raw", n = file.info(tmp)$size)

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key,
      raw = raw_rds,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  got <- minio_read_object(bucket = bucket, object = key)
  expect_equal(got, obj)

  minio_remove_object(bucket, key, use_https = use_https, region = region)
})

test_that("minio_read_object dispatches to minio_get_rdata for rda/rdata (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()
  use_https <- minior_use_https()
  region <- minior_region()

  df <- data.frame(id = 1:2, v = c("x", "y"), stringsAsFactors = FALSE)
  x <- 99L

  tmp <- tempfile(fileext = ".RData")
  save(df, x, file = tmp)
  raw_rdata <- readBin(tmp, what = "raw", n = file.info(tmp)$size)

  # rda
  key_rda <- minior_unique_key("readobj-rda")
  key_rda <- sub("\\.bin$", ".rda", key_rda)

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key_rda,
      raw = raw_rdata,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  got1 <- minio_read_object(bucket = bucket, object = key_rda)
  expect_true(is.list(got1))
  expect_true(all(c("df", "x") %in% names(got1)))
  expect_equal(got1$df, df)
  expect_equal(got1$x, x)

  minio_remove_object(bucket, key_rda, use_https = use_https, region = region)

  # rdata
  key_rdata <- minior_unique_key("readobj-rdata")
  key_rdata <- sub("\\.bin$", ".rdata", key_rdata)

  expect_true(
    minio_put_object(
      bucket = bucket,
      object = key_rdata,
      raw = raw_rdata,
      content_type = "application/octet-stream",
      multipart = FALSE,
      use_https = use_https,
      region = region
    )
  )

  got2 <- minio_read_object(bucket = bucket, object = key_rdata)
  expect_true(is.list(got2))
  expect_true(all(c("df", "x") %in% names(got2)))
  expect_equal(got2$df, df)
  expect_equal(got2$x, x)

  minio_remove_object(bucket, key_rdata, use_https = use_https, region = region)
})
