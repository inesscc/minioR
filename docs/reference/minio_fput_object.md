# Upload a Local File to MinIO

Uploads a local file to a MinIO bucket. If the object name is not
provided, the base name of the local file path is used as the object
key.

## Usage

``` r
minio_fput_object(
  bucket,
  object = NULL,
  file,
  multipart = FALSE,
  use_https = TRUE,
  region = ""
)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character or `NULL`. Object key (path) to use in the bucket. If `NULL`
  or empty, defaults to `basename(file)`.

- file:

  Character. Path to the local file to upload.

- multipart:

  Logical. Whether to enable multipart upload. Defaults to `FALSE`.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

Logical. Returns `TRUE` if the upload was successful.

## Details

This function wraps
[`put_object`](https://rdrr.io/pkg/aws.s3/man/put_object.html) and adds
input validation and clearer error handling for MinIO environments.

## Examples

``` r
if (FALSE) { # \dontrun{
minio_fput_object(
  bucket = "assets",
  object = "raw/example.parquet",
  file = "data/example.parquet"
)
} # }
```
