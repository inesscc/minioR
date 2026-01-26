# Read an RData/RDA File from MinIO

Downloads an R workspace file (`.RData` or `.rda`) stored in a MinIO
bucket and loads its contents into an isolated environment. Internally,
the function retrieves the object contents as raw bytes using
[`minio_get_object`](https://inesscc.github.io/minioR/reference/minio_get_object.md),
writes them to a temporary file, and then delegates deserialization to
[`load`](https://rdrr.io/r/base/load.html).

## Usage

``` r
minio_get_rdata(bucket, object)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) of the `.RData` or `.rda` file within the
  bucket.

## Value

A named `list` containing all objects loaded from the file.

## Details

To avoid polluting the caller's environment, all objects are loaded into
a new, empty environment and then returned as a named `list`. Each list
element corresponds to one object stored in the `.RData`/`.rda` file.

Unlike
[`minio_get_rds()`](https://inesscc.github.io/minioR/reference/minio_get_rds.md),
which returns a single R object, this function always returns a
collection of objects, making it suitable for archived workspaces or
multi-object snapshots.

## See also

[`minio_get_rds`](https://inesscc.github.io/minioR/reference/minio_get_rds.md),
[`minio_read_object`](https://inesscc.github.io/minioR/reference/minio_read_object.md),
[`minio_get_parquet`](https://inesscc.github.io/minioR/reference/minio_get_parquet.md)

## Examples

``` r
if (FALSE) { # \dontrun{
objs <- minio_get_rdata(
  bucket = "assets",
  object = "snapshots/data.RData"
)

names(objs)
df <- objs$df
} # }
```
