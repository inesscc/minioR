# Write an Object to MinIO (Auto-detect by Extension)

Serializes an R object to bytes (`raw`) based on the file extension of
`object` and uploads it to MinIO using
[`minio_put_object`](https://inesscc.github.io/minioR/reference/minio_put_object.md).

## Usage

``` r
minio_write_object(
  bucket,
  object,
  x,
  ...,
  content_type = NULL,
  multipart = FALSE,
  use_https = TRUE,
  region = ""
)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) within the bucket. Extension is used to
  infer the serialization format.

- x:

  R object to serialize and upload (often a data.frame, list, model,
  etc.).

- ...:

  Additional arguments passed to the underlying writer function.

- content_type:

  Character or `NULL`. Optional MIME type. If `NULL`, a sensible default
  is used based on the extension.

- multipart:

  Logical. Whether to use multipart upload. Defaults to `FALSE`.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

Invisibly returns `TRUE` if the upload was successful.

## Details

Supported formats are selected by extension:

- `.csv` via
  [`utils::write.csv()`](https://rdrr.io/r/utils/write.table.html)

- `.parquet` / `.pq` via
  [`arrow::write_parquet()`](https://arrow.apache.org/docs/r/reference/write_parquet.html)

- `.json` via
  [`jsonlite::toJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)

- `.xlsx` via
  [`writexl::write_xlsx()`](https://docs.ropensci.org/writexl//reference/write_xlsx.html)

- `.feather` via `feather::write_feather()`

- `.dta` via
  [`haven::write_dta()`](https://haven.tidyverse.org/reference/read_dta.html)

- `.rds` via [`saveRDS()`](https://rdrr.io/r/base/readRDS.html)

- `.rda` / `.RData` via [`save()`](https://rdrr.io/r/base/save.html)

Additional arguments (`...`) are forwarded to the underlying writer
selected by extension.

## Examples

``` r
if (FALSE) { # \dontrun{
# CSV
minio_write_object("assets", "tmp/df.csv", mtcars, row.names = FALSE)

# JSON (returns JSON in MinIO)
minio_write_object("assets", "tmp/config.json", list(a = 1, b = TRUE), auto_unbox = TRUE)

# RDS
minio_write_object("assets", "tmp/model.rds", lm(mpg ~ wt, data = mtcars))

# RData (stores an object named 'x' by default)
minio_write_object("assets", "tmp/objects.RData", mtcars)
} # }
```
