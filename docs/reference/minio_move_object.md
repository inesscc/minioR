# Move an Object in MinIO (Copy + Remove with Size Verification)

Moves an object from a source bucket/key to a destination bucket/key by
performing a copy operation followed by a delete of the source object.

## Usage

``` r
minio_move_object(
  from_bucket,
  from_object,
  to_bucket,
  to_object = NULL,
  overwrite = FALSE,
  verify = TRUE,
  verify_size = TRUE,
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

- overwrite:

  Logical. If `TRUE`, overwrites the destination object if it already
  exists. Defaults to `FALSE`.

- verify:

  Logical. If `TRUE`, checks that the destination object exists after
  copy before deleting the source. Defaults to `TRUE`.

- verify_size:

  Logical. If `TRUE`, compares object size (bytes) between source and
  destination before deleting the source. Defaults to `TRUE`.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

Invisibly returns `TRUE` if the move was successful.

## Details

Before deleting the source object, the function can verify that the
destination exists and that the object size (content-length) matches
between source and destination.

## Examples

``` r
if (FALSE) { # \dontrun{
minio_move_object(
  from_bucket = "raw",
  from_object = "data/file.parquet",
  to_bucket   = "curated",
  overwrite   = FALSE
)
} # }
```
