# Read and Concatenate Many Parquet Objects from MinIO

Reads multiple Parquet objects from MinIO and concatenates them. Objects
can be provided explicitly via `objects` or discovered via `prefix` and
optional regex `pattern`. Optionally filters objects by a date-like
suffix in the key: `_YYYY`, `_YYYYMM`, or `_YYYYMMDD` (inclusive range).

## Usage

``` r
minio_read_many(
  bucket,
  objects = NULL,
  prefix = NULL,
  pattern = NULL,
  date_from = NULL,
  date_to = NULL,
  warn_bytes = 1e+09,
  out_dir = NULL,
  verbose = TRUE,
  use_https = TRUE,
  region = ""
)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- objects:

  Character vector or `NULL`. Explicit object keys to read.

- prefix:

  Character or `NULL`. Prefix for listing objects when `objects` is
  `NULL`.

- pattern:

  Character or `NULL`. Regex pattern to filter keys when using `prefix`.

- date_from, date_to:

  Character/numeric or `NULL`. Inclusive range filter based on suffix.
  If 4 digits -\> year, 6 digits -\> yearmonth, 8 digits -\>
  yearmonthday. Example: `date_from = 2020, date_to = 2024` filters
  `_YYYY`.

- warn_bytes:

  Numeric. If total remote size exceeds this threshold, a warning is
  emitted. Defaults to 1e9 (≈ 1 GB).

- out_dir:

  Character or `NULL`. If provided, results are streamed to this local
  directory as a Parquet dataset (one file per input object) and the
  function returns the directory path.

- verbose:

  Logical. Whether to print progress messages. Defaults to `TRUE`.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

If `out_dir` is `NULL`, returns a `data.frame` (union schema). If
`out_dir` is provided, returns `out_dir` (invisibly) after writing the
dataset.

## Details

The function computes total remote bytes using
[`minio_get_metadata`](https://inesscc.github.io/minioR/reference/minio_get_metadata.md)
and warns if the estimated size exceeds `warn_bytes`. For large reads,
you can stream results to a local Parquet dataset directory via
`out_dir`.

Concatenation is schema-union: the output includes all columns across
all files. Missing columns in individual files are filled with `NA`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Explicit keys
df <- minio_read_many(
  bucket = "assets",
  objects = c("raw/x_202301.parquet", "raw/x_202302.parquet")
)

# Prefix + pattern + date range by year
df <- minio_read_many(
  bucket = "assets",
  prefix = "raw/x/",
  pattern = "\\\\.parquet$",
  date_from = 2020,
  date_to = 2024
)

# Stream to local dataset (recommended for large volumes)
out <- minio_read_many(
  bucket = "assets",
  prefix = "raw/x/",
  pattern = "\\\\.parquet$",
  date_from = 202301,
  date_to = 202312,
  out_dir = "output/many_parquet_dataset"
)
} # }
```
