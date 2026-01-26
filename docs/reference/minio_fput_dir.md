# Upload a Local Directory to MinIO (Preserve Structure)

Uploads a local directory to a MinIO bucket preserving the relative
folder structure, similar to a "sync". Files are discovered under `dir`
and uploaded using
[`minio_fput_object`](https://inesscc.github.io/minioR/reference/minio_fput_object.md).

## Usage

``` r
minio_fput_dir(
  bucket,
  dir,
  prefix = NULL,
  recursive = TRUE,
  include = NULL,
  exclude = NULL,
  dry_run = FALSE,
  multipart = FALSE,
  use_https = TRUE,
  region = ""
)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- dir:

  Character. Local directory path to upload.

- prefix:

  Character or `NULL`. Optional object key prefix inside the bucket. If
  provided, all objects will be uploaded under this prefix. Example:
  `"raw/projectA"`.

- recursive:

  Logical. Whether to include subdirectories. Defaults to `TRUE`.

- include:

  Character vector of regex patterns. If provided, only files whose
  relative path matches at least one pattern are included.

- exclude:

  Character vector of regex patterns. If provided, files whose relative
  path matches any pattern are excluded.

- dry_run:

  Logical. If `TRUE`, do not upload anything; only return the planned
  uploads. Defaults to `FALSE`.

- multipart:

  Logical. Whether to enable multipart upload. Defaults to `FALSE`.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

A `data.frame` with the upload plan and results. Columns: `local_file`,
`object`, `uploaded`, `error`. In `dry_run = TRUE`, `uploaded` will be
`FALSE` and `error` `NA`.

## Details

You can filter which files to upload using `include` and `exclude` regex
patterns applied to the relative path (POSIX style, forward slashes).

## Examples

``` r
if (FALSE) { # \dontrun{
# Upload entire directory under a prefix
res <- minio_fput_dir(
  bucket = "assets",
  dir = "data/projectA",
  prefix = "raw/projectA",
  recursive = TRUE,
  exclude = c("\\\\.tmp$", "^\\.git/", "\\\\.DS_Store$"),
  dry_run = FALSE
)
} # }
```
