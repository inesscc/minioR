# Package index

## Package

Package overview.

- [`minioR-package`](https://inesscc.github.io/minioR/reference/minioR.md)
  [`minioR`](https://inesscc.github.io/minioR/reference/minioR.md) :
  minioR: A Simple MinIO Client for R

## Object management

Discover, inspect, and validate objects.

- [`minio_list_objects()`](https://inesscc.github.io/minioR/reference/minio_list_objects.md)
  : List Objects in a MinIO Bucket
- [`minio_object_exists()`](https://inesscc.github.io/minioR/reference/minio_object_exists.md)
  : Check Whether an Object Exists in MinIO
- [`minio_get_metadata()`](https://inesscc.github.io/minioR/reference/minio_get_metadata.md)
  : Retrieve Object Metadata from MinIO

## Read and download

Retrieve objects as raw, files, or parsed R objects.

- [`minio_get_object()`](https://inesscc.github.io/minioR/reference/minio_get_object.md)
  : Download an Object from MinIO as Raw Bytes
- [`minio_download_object()`](https://inesscc.github.io/minioR/reference/minio_download_object.md)
  : Download an Object from MinIO to Disk
- [`minio_read_object()`](https://inesscc.github.io/minioR/reference/minio_read_object.md)
  : Read an Object from MinIO (Auto-detect by Extension)
- [`minio_read_many()`](https://inesscc.github.io/minioR/reference/minio_read_many.md)
  : Read and Concatenate Many Parquet Objects from MinIO
- [`minio_get_csv()`](https://inesscc.github.io/minioR/reference/minio_get_csv.md)
  : Read a CSV File from MinIO
- [`minio_get_dta()`](https://inesscc.github.io/minioR/reference/minio_get_dta.md)
  : Read a Stata (.dta) File from MinIO
- [`minio_get_excel()`](https://inesscc.github.io/minioR/reference/minio_get_excel.md)
  : Read an Excel (.xlsx) File from MinIO
- [`minio_get_feather()`](https://inesscc.github.io/minioR/reference/minio_get_feather.md)
  : Read a Feather File from MinIO
- [`minio_get_json()`](https://inesscc.github.io/minioR/reference/minio_get_json.md)
  : Read a JSON File from MinIO
- [`minio_get_metadata()`](https://inesscc.github.io/minioR/reference/minio_get_metadata.md)
  : Retrieve Object Metadata from MinIO
- [`minio_get_parquet()`](https://inesscc.github.io/minioR/reference/minio_get_parquet.md)
  : Read a Parquet File from MinIO
- [`minio_get_rdata()`](https://inesscc.github.io/minioR/reference/minio_get_rdata.md)
  : Read an RData/RDA File from MinIO
- [`minio_get_rds()`](https://inesscc.github.io/minioR/reference/minio_get_rds.md)
  : Read an RDS File from MinIO

## Write and upload

Upload objects from memory, files, or via writer helpers.

- [`minio_put_object()`](https://inesscc.github.io/minioR/reference/minio_put_object.md)
  : Upload an Object to MinIO from Memory
- [`minio_fput_object()`](https://inesscc.github.io/minioR/reference/minio_fput_object.md)
  : Upload a Local File to MinIO
- [`minio_fput_dir()`](https://inesscc.github.io/minioR/reference/minio_fput_dir.md)
  : Upload a Local Directory to MinIO (Preserve Structure)
- [`minio_write_object()`](https://inesscc.github.io/minioR/reference/minio_write_object.md)
  : Write an Object to MinIO (Auto-detect by Extension)

## Object operations

Server-side operations over existing objects.

- [`minio_copy_object()`](https://inesscc.github.io/minioR/reference/minio_copy_object.md)
  : Copy an Object in MinIO
- [`minio_move_object()`](https://inesscc.github.io/minioR/reference/minio_move_object.md)
  : Move an Object in MinIO (Copy + Remove with Size Verification)
- [`minio_sync_objects()`](https://inesscc.github.io/minioR/reference/minio_sync_objects.md)
  : Sync Local Files/Directories with MinIO (Wrapper around
  aws.s3::s3sync)

## Delete and cleanup

Remove objects from MinIO.

- [`minio_remove_object()`](https://inesscc.github.io/minioR/reference/minio_remove_object.md)
  : Remove an Object from MinIO
- [`minio_remove_objects()`](https://inesscc.github.io/minioR/reference/minio_remove_objects.md)
  : Remove Multiple Objects from MinIO
