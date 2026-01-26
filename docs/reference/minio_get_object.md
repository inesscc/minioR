# Download an Object from MinIO as Raw Bytes

Downloads an object from a MinIO bucket and returns its contents as a
`raw` vector. Before downloading, the function checks whether the object
exists using
[`minio_object_exists`](https://inesscc.github.io/minioR/reference/minio_object_exists.md).
If the object does not exist, an error is raised.

## Usage

``` r
minio_get_object(bucket, object, use_https = TRUE, region = "")
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

A `raw` vector with the object contents.

## Details

This function is intended as a low-level building block for higher-level
helpers (e.g., reading CSV/Parquet), centralizing validation and
download logic.

## Examples

``` r
if (FALSE) { # \dontrun{
x <- minio_get_object(
  bucket = "assets",
  object = "path/file.parquet"
)
length(x)
} # }
```
