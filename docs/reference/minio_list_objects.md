# List Objects in a MinIO Bucket

Lists the object keys stored in a MinIO bucket, optionally filtered by a
prefix (for example, simulating a folder structure).

## Usage

``` r
minio_list_objects(bucket, prefix = NULL, use_https = TRUE, region = "")
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- prefix:

  Character or `NULL`. Optional prefix used to filter object keys.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`

## Value

A character vector containing the object keys. If no objects are found,
returns `character(0)`.

## Details

This function is a thin wrapper around
[`aws.s3::get_bucket()`](https://rdrr.io/pkg/aws.s3/man/get_bucket.html),
providing a simplified and safer interface for MinIO environments.

## Examples

``` r
if (FALSE) { # \dontrun{
minio_list_objects("my-bucket")
minio_list_objects("my-bucket", prefix = "data/raw/")
} # }
```
