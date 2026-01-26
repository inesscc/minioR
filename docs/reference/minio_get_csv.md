# Read a CSV File from MinIO

Downloads a CSV object stored in a MinIO bucket and reads it into memory
as a `data.frame`. Internally, the function retrieves the object
contents as raw bytes using
[`minio_get_object`](https://inesscc.github.io/minioR/reference/minio_get_object.md)
and then delegates parsing to
[`read.csv`](https://rdrr.io/r/utils/read.table.html).

## Usage

``` r
minio_get_csv(bucket, object, ...)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) of the CSV file within the bucket.

- ...:

  Additional arguments passed to
  [`read.csv()`](https://rdrr.io/r/utils/read.table.html), such as
  `sep`, `header`, `stringsAsFactors`, `fileEncoding`, etc.

## Value

A `data.frame` containing the contents of the CSV file.

## Details

Additional arguments are passed directly to
[`read.csv()`](https://rdrr.io/r/utils/read.table.html), allowing
control over separators, headers, encoding, and other parsing options.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- minio_get_csv(
  bucket = "assets",
  object = "path/file.csv",
  sep = ";",
  header = TRUE,
  fileEncoding = "latin1"
)
} # }
```
