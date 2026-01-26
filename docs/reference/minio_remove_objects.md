# Remove Multiple Objects from MinIO

Removes (deletes) multiple objects from a MinIO bucket. You can either:

- Provide an explicit vector of object keys via `objects`, or

- Select objects by listing `prefix` and filtering with a regex
  `pattern`.

## Usage

``` r
minio_remove_objects(
  bucket,
  objects = NULL,
  prefix = NULL,
  pattern = NULL,
  dry_run = FALSE,
  quiet = TRUE,
  error_on_missing = TRUE,
  use_https = TRUE,
  region = ""
)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- objects:

  Character vector or `NULL`. Explicit object keys to remove.

- prefix:

  Character or `NULL`. Prefix used to list candidate objects when
  `objects` is `NULL`.

- pattern:

  Character or `NULL`. Regex pattern applied to object keys (after
  prefix listing). If `NULL`, all objects under `prefix` are selected.

- dry_run:

  Logical. If `TRUE`, does not delete anything; only returns the
  deletion plan. Defaults to `FALSE`.

- quiet:

  Logical. If `TRUE`, suppresses progress messages. Defaults to `TRUE`.

- error_on_missing:

  Logical. If `TRUE` (default), missing objects cause an error
  (consistent with `minio_remove_object`). If `FALSE`, missing objects
  are recorded and skipped.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

A `data.frame` with columns: `object`, `removed`, `error`. In
`dry_run = TRUE`, `removed` is always `FALSE` and `error` is `NA`.

## Details

Deletions are performed by calling
[`minio_remove_object`](https://inesscc.github.io/minioR/reference/minio_remove_object.md)
for each object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Remove explicit objects
res <- minio_remove_objects(
  bucket = "assets",
  objects = c("tmp/a.csv", "tmp/b.csv")
)

# Remove by prefix + regex pattern
res <- minio_remove_objects(
  bucket = "assets",
  prefix = "tmp/",
  pattern = "\\\\.csv$"
)

# Dry-run
plan <- minio_remove_objects(
  bucket = "assets",
  prefix = "tmp/",
  dry_run = TRUE
)
} # }
```
