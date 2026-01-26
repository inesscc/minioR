# Read an Object from MinIO (Auto-detect by Extension)

Reads an object stored in a MinIO bucket by automatically detecting its
file type from the object key extension and delegating to the
corresponding `minio_get_*` function (e.g., CSV, Parquet, JSON, XLSX,
etc.).

## Usage

``` r
minio_read_object(bucket, object, ...)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) within the bucket. The file extension is
  used to infer the type (e.g., `.csv`, `.parquet`).

- ...:

  Additional arguments passed to the underlying reader function selected
  by file type (e.g., `sep` for CSV, `sheet` for XLSX, `flatten` for
  JSON, etc.).

## Value

The parsed object. For tabular formats, returns a `data.frame`. For
JSON, returns the parsed JSON object (typically a list). For RDS,
returns the stored R object. For RData/RDA, returns a named list.

## Details

This function is designed as a convenience wrapper so users only need to
learn a single reader function.

## Examples

``` r
if (FALSE) { # \dontrun{
# CSV
df <- minio_read_object("assets", "raw/data.csv", sep = ";")

# Excel
df2 <- minio_read_object("assets", "raw/report.xlsx", sheet = 2)

# JSON
x <- minio_read_object("assets", "raw/config.json", flatten = TRUE)

# RDS
model <- minio_read_object("assets", "models/model.rds")

# RData / RDA
objs <- minio_read_object("assets", "snapshots/objects.RData")
} # }
```
