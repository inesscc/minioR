# Check Whether an Object Exists in MinIO

Checks whether an object exists in a MinIO bucket using a `HEAD`
request. The function returns `TRUE` if the object exists and `FALSE` if
the object does not exist.

## Usage

``` r
minio_object_exists(
  bucket,
  object,
  quiet = TRUE,
  use_https = TRUE,
  region = ""
)
```

## Arguments

- bucket:

  Character scalar. Name of the MinIO bucket.

- object:

  Character scalar. Object key (path) within the bucket.

- quiet:

  Logical. If `TRUE` (default), suppresses informational messages
  emitted by the underlying `aws.s3` client.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`. For MinIO deployments,
  this can usually be set to any value (for example, `"us-east-1"`).

## Value

Logical scalar.

- `TRUE` if the object exists.

- `FALSE` if the object does not exist.

## Details

For MinIO and other S3-compatible services, a non-existing object
typically results in a response containing the attribute
`x-minio-error-code = "NoSuchKey"`, which is interpreted as "object does
not exist".

Any other unexpected response or error (for example, permission issues,
missing bucket, or network problems) results in an error.

This function is intended to be the single, low-level existence-check
primitive used internally by other operations such as read, copy, or
delete.

## Examples

``` r
if (FALSE) { # \dontrun{
minio_object_exists(
  bucket = "assets",
  object = "data/file.parquet"
)

if (minio_object_exists("assets", "data/file.parquet")) {
  message("Object exists")
}
} # }
```
