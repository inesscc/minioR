# Read a JSON File from MinIO

Downloads a JSON file stored in a MinIO bucket and parses it into R.
Internally, the function retrieves the object contents as raw bytes
using
[`minio_get_object`](https://inesscc.github.io/minioR/reference/minio_get_object.md),
converts them to text, and then delegates parsing to
[`fromJSON`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).

## Usage

``` r
minio_get_json(bucket, object, ...)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) of the JSON file within the bucket.

- ...:

  Additional arguments passed to
  [`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).

## Value

An R object representing the parsed JSON content (often a list or
vector; not necessarily a `data.frame`).

## Details

Unlike other `minio_get_*` readers, this function does not enforce a
tabular structure. The returned object is exactly what
[`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
produces, typically a list, vector, or nested structure depending on the
JSON content and parsing options.

Additional arguments are forwarded to
[`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html),
allowing control over simplification, flattening, unboxing, and handling
of nested data.

## See also

[`minio_read_object`](https://inesscc.github.io/minioR/reference/minio_read_object.md),
[`minio_get_csv`](https://inesscc.github.io/minioR/reference/minio_get_csv.md),
[`minio_get_parquet`](https://inesscc.github.io/minioR/reference/minio_get_parquet.md)

## Examples

``` r
if (FALSE) { # \dontrun{
json <- minio_get_json(
  bucket = "assets",
  object = "config/settings.json",
  simplifyVector = FALSE
)

json$database$host
} # }
```
