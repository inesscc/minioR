test_that("minio_copy_object copies an object (integration)", {
  skip_if_no_minio()

  bucket <- minior_bucket()

  key1 <- minior_unique_key("copy")
  key2 <- sub("\\.bin$", "-copy.bin", key1)

  payload <- charToRaw("hello minioR\n")

  # upload
  minio_put_object(bucket = bucket, object = key1, raw = payload, content_type = "text/plain")
  expect_true(minio_object_exists(bucket, key1))

  # copy
  minio_copy_object(from_bucket = bucket, from_object = key1, to_bucket = bucket, to_object = key2)
  expect_true(minio_object_exists(bucket, key2))

  # cleanup
  minio_remove_object(bucket, key1)
  minio_remove_object(bucket, key2)
  expect_false(minio_object_exists(bucket, key1))
  expect_false(minio_object_exists(bucket, key2))
})
