# Read a Parquet File from MinIO

Downloads a Parquet `.parquet` file stored in a MinIO bucket and reads
it into memory using the arrow package. Internally, the function
retrieves the object contents as raw bytes using
[`minio_get_object`](https://inesscc.github.io/minioR/reference/minio_get_object.md),
writes them to a temporary file, and then delegates parsing to
[`read_parquet`](https://arrow.apache.org/docs/r/reference/read_parquet.html).

## Usage

``` r
minio_get_parquet(bucket, object)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) of the Parquet file within the bucket.

## Value

A tabular object read from the Parquet file. The exact return type
depends on the Arrow configuration and may be a `data.frame`, `tibble`,
or
[`arrow::Table`](https://arrow.apache.org/docs/r/reference/Table-class.html).

## Details

The returned object depends on the Arrow backend configuration and may
be a base `data.frame`, a `tibble`, or an
[`arrow::Table`](https://arrow.apache.org/docs/r/reference/Table-class.html).
Unlike other `minio_get_*` readers, this function does not coerce the
result to a specific R data structure, allowing users to take full
advantage of Arrow for large or lazy workflows.

## See also

[`minio_read_many`](https://inesscc.github.io/minioR/reference/minio_read_many.md),
[`minio_read_object`](https://inesscc.github.io/minioR/reference/minio_read_object.md),
[`minio_get_csv`](https://inesscc.github.io/minioR/reference/minio_get_csv.md)

## Examples

``` r
if (FALSE) { # \dontrun{
tbl <- minio_get_parquet(
  bucket = "vault",
  object = "data/example.parquet"
)

# Convert explicitly if needed
df <- as.data.frame(tbl)
} # }
```
