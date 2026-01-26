# Read a Stata (.dta) File from MinIO

Downloads a Stata `.dta` file stored in a MinIO bucket and reads it into
memory as a base `data.frame`. Internally, the function retrieves the
object contents as raw bytes using
[`minio_get_object`](https://inesscc.github.io/minioR/reference/minio_get_object.md),
writes them to a temporary file, and then delegates parsing to
[`read_dta`](https://haven.tidyverse.org/reference/read_dta.html).

## Usage

``` r
minio_get_dta(bucket, object, ...)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) of the `.dta` file within the bucket.

- ...:

  Additional arguments passed to
  [`haven::read_dta()`](https://haven.tidyverse.org/reference/read_dta.html).

## Value

A base `data.frame` containing the contents of the Stata file.

## Details

Additional arguments are forwarded to
[`haven::read_dta()`](https://haven.tidyverse.org/reference/read_dta.html),
allowing control over encoding, labelled values, user-defined missing
values, and other Stata-specific parsing options.

Regardless of the return type produced by
[`haven::read_dta()`](https://haven.tidyverse.org/reference/read_dta.html)
(for example, a tibble), the result is always coerced to a base
`data.frame` for consistency with other `minio_get_*` readers.

## See also

[`minio_get_csv`](https://inesscc.github.io/minioR/reference/minio_get_csv.md),
[`minio_get_parquet`](https://inesscc.github.io/minioR/reference/minio_get_parquet.md),
[`minio_read_object`](https://inesscc.github.io/minioR/reference/minio_read_object.md)

## Examples

``` r
if (FALSE) { # \dontrun{
df <- minio_get_dta(
  bucket = "assets",
  object = "survey/data_2023.dta"
)
} # }
```
