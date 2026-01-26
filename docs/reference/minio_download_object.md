# Download an Object from MinIO to Disk

Downloads an object stored in a MinIO bucket and saves it to a local
file. Before downloading, the function checks whether the object exists
using
[`minio_object_exists`](https://inesscc.github.io/minioR/reference/minio_object_exists.md).
If the object does not exist, an error is raised.

## Usage

``` r
minio_download_object(bucket, object, destfile, use_https = TRUE, region = "")
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) within the bucket.

- destfile:

  Character. Local file path where the downloaded object will be saved.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

Invisibly returns `destfile`.

## Details

The download is streamed directly to disk (i.e., the full object is not
loaded into memory).

## Examples

``` r
if (FALSE) { # \dontrun{
minio_download_object(
  bucket = "assets",
  object = "path/file.parquet",
  destfile = "path/file.parquet"
)
} # }
```
