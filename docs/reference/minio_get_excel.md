# Read an Excel (.xlsx) File from MinIO

Downloads an Excel `.xlsx` file stored in a MinIO bucket and reads it
into memory as a base `data.frame`. Internally, the function retrieves
the object contents as raw bytes using
[`minio_get_object`](https://inesscc.github.io/minioR/reference/minio_get_object.md),
writes them to a temporary file (as required by readxl), and then
delegates parsing to
[`read_xlsx`](https://readxl.tidyverse.org/reference/read_excel.html).

## Usage

``` r
minio_get_excel(bucket, object, ...)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) of the Excel file within the bucket.

- ...:

  Additional arguments passed to
  [`readxl::read_xlsx()`](https://readxl.tidyverse.org/reference/read_excel.html).

## Value

A base `data.frame` containing the contents of the Excel file.

## Details

Additional arguments are forwarded to
[`readxl::read_xlsx()`](https://readxl.tidyverse.org/reference/read_excel.html),
allowing control over sheets, ranges, column types, column names, and
other Excel-specific parsing options.

Regardless of the return type produced by
[`readxl::read_xlsx()`](https://readxl.tidyverse.org/reference/read_excel.html)
(for example, a tibble), the result is always coerced to a base
`data.frame` for consistency with other `minio_get_*` readers.

## See also

[`minio_get_csv`](https://inesscc.github.io/minioR/reference/minio_get_csv.md),
[`minio_get_parquet`](https://inesscc.github.io/minioR/reference/minio_get_parquet.md),
[`minio_read_object`](https://inesscc.github.io/minioR/reference/minio_read_object.md)

## Examples

``` r
if (FALSE) { # \dontrun{
df <- minio_get_excel(
  bucket = "assets",
  object = "reports/sales_2024.xlsx",
  sheet = 1
)
} # }
```
