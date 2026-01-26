# Copy an Object in MinIO

Copies an object from a source bucket/key to a destination bucket/key
using the S3 CopyObject operation (supported by MinIO). The function
first checks that the source object exists using
[`minio_object_exists`](https://inesscc.github.io/minioR/reference/minio_object_exists.md).

## Usage

``` r
minio_copy_object(
  from_bucket,
  from_object,
  to_bucket,
  to_object = NULL,
  use_https = TRUE,
  region = ""
)
```

## Arguments

- from_bucket:

  Character. Source bucket name.

- from_object:

  Character. Source object key (path).

- to_bucket:

  Character. Destination bucket name.

- to_object:

  Character or `NULL`. Destination object key (path). If `NULL` or
  empty, defaults to `from_object`.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

Invisibly returns `TRUE` if the copy was successful.

## Examples

``` r
if (FALSE) { # \dontrun{
# Copy within the same bucket
minio_copy_object(
  from_bucket = "assets",
  from_object = "data/file.csv",
  to_bucket = "assets",
  to_object = "archive/file.csv"
)

# Copy to another bucket (same key)
minio_copy_object(
  from_bucket = "raw",
  from_object = "data/file.parquet",
  to_bucket = "curated"
)
} # }
```
