# Read a Feather File from MinIO

Downloads a Feather `.feather` file stored in a MinIO bucket and reads
it into memory as a base `data.frame`. Internally, the function
retrieves the object contents as raw bytes using
[`minio_get_object`](https://inesscc.github.io/minioR/reference/minio_get_object.md),
writes them to a temporary file, and then delegates parsing to
`read_feather`.

## Usage

``` r
minio_get_feather(bucket, object, ...)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) of the Feather file within the bucket.

- ...:

  Additional arguments passed to `feather::read_feather()`.

## Value

A base `data.frame` containing the contents of the Feather file.

## Details

Additional arguments are forwarded to `feather::read_feather()`,
allowing control over column selection, memory mapping, and other
Feather-specific reading options.

Regardless of the return type produced by `feather::read_feather()`, the
result is always coerced to a base `data.frame` for consistency with
other `minio_get_*` reader functions.

## See also

[`minio_get_parquet`](https://inesscc.github.io/minioR/reference/minio_get_parquet.md),
[`minio_get_csv`](https://inesscc.github.io/minioR/reference/minio_get_csv.md),
[`minio_read_object`](https://inesscc.github.io/minioR/reference/minio_read_object.md)

## Examples

``` r
if (FALSE) { # \dontrun{
df <- minio_get_feather(
  bucket = "assets",
  object = "analytics/features.feather"
)
} # }
```
