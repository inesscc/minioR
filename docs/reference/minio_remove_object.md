# Remove an Object from MinIO

Removes (deletes) an object from a MinIO bucket. Before deletion, the
function checks whether the object exists using
[`minio_object_exists`](https://inesscc.github.io/minioR/reference/minio_object_exists.md).
If the object does not exist, an error is raised.

## Usage

``` r
minio_remove_object(bucket, object, use_https = TRUE, region = "")
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) within the bucket.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

Invisibly returns `TRUE` if the object was successfully removed.

## Examples

``` r
if (FALSE) { # \dontrun{
minio_remove_object(
  bucket = "assets",
  object = "path/file.parquet"
)
} # }
```
