# Retrieve Object Metadata from MinIO

Retrieves metadata (HTTP headers) for an object stored in a MinIO bucket
using a HEAD request. Before querying metadata, the function verifies
that the object exists using
[`minio_object_exists`](https://inesscc.github.io/minioR/reference/minio_object_exists.md).
If the object does not exist, an error is raised.

## Usage

``` r
minio_get_metadata(bucket, object, quiet = TRUE, use_https = TRUE, region = "")
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) within the bucket.

- quiet:

  Logical. If `TRUE` (default), suppresses informational messages
  emitted by the underlying client during the HEAD request.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

A named list containing object metadata with the following elements:

- `exists`: Always `TRUE` if the function returns.

- `bucket`: Bucket name.

- `object`: Object key.

- `size`: Object size in bytes.

- `last_modified`: Last modification date (character).

- `etag`: Object ETag.

- `content_type`: Content type.

- `headers`: Full list of headers returned by MinIO.

## Details

The returned information typically includes object size, last
modification date, ETag, content type, and other headers provided by
MinIO.

## Examples

``` r
if (FALSE) { # \dontrun{
info <- minio_get_metadata("assets", "path/file.parquet")
info$size
info$last_modified
} # }
```
