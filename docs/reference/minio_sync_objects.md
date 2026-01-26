# Sync Local Files/Directories with MinIO (Wrapper around aws.s3::s3sync)

Convenience wrapper for
[`aws.s3::s3sync()`](https://rdrr.io/pkg/aws.s3/man/sync.html) tailored
for MinIO usage. It synchronizes a local directory with a bucket/prefix,
uploading and/or downloading missing files.

## Usage

``` r
minio_sync_objects(
  path = ".",
  bucket,
  prefix = "",
  sync = NULL,
  verbose = TRUE,
  use_https = TRUE,
  region = "",
  ...
)
```

## Arguments

- path:

  Character. Local directory path to synchronize. Defaults to `"."`.

- bucket:

  Character. Name of the bucket.

- prefix:

  Character. Prefix (remote "subdirectory") to consider. Defaults to
  `""`. For subdirectory-like behavior, typically include a trailing
  slash (e.g. `"raw/projectA/"`).

- sync:

  Character or `NULL`. One of `"server"` (upload), `"local"` (download),
  or `NULL` for two-way sync (upload + download).

- verbose:

  Logical. Whether to be verbose. Defaults to `TRUE`.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO. Defaults to
  `TRUE`.

- region:

  Character. Region string required by `aws.s3`. Defaults to `""`.

- ...:

  Additional arguments passed to
  [`aws.s3::s3sync()`](https://rdrr.io/pkg/aws.s3/man/sync.html) (and
  then to s3HTTP), such as `multipart`, `headers`, etc.

## Value

Logical. Returns `TRUE` if the sync completed successfully.

## Details

Compared to
[`aws.s3::s3sync()`](https://rdrr.io/pkg/aws.s3/man/sync.html), this
wrapper:

- Uses `sync` instead of `direction`: `"server"` means upload, `"local"`
  means download, and if omitted performs two-way sync (upload +
  download), matching `s3sync()` default.

- Forces `create = FALSE`.

- Defaults `use_https = TRUE` and `region = ""`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Two-way (upload + download), default behavior
minio_sync_objects(
  path = "data/projectA",
  bucket = "assets",
  prefix = "raw/projectA/"
)

# Only upload local -> server
minio_sync_objects(
  path = "data/projectA",
  bucket = "assets",
  prefix = "raw/projectA/",
  sync = "server"
)

# Only download server -> local
minio_sync_objects(
  path = "data/projectA",
  bucket = "assets",
  prefix = "raw/projectA/",
  sync = "local"
)
} # }
```
