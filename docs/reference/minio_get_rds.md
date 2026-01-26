# Read an RDS File from MinIO

Downloads an R serialized `.rds` file stored in a MinIO bucket and
deserializes it into memory. Internally, the function retrieves the
object contents as raw bytes using
[`minio_get_object`](https://inesscc.github.io/minioR/reference/minio_get_object.md),
writes them to a temporary file, and then delegates deserialization to
[`readRDS`](https://rdrr.io/r/base/readRDS.html).

## Usage

``` r
minio_get_rds(bucket, object)
```

## Arguments

- bucket:

  Character. Name of the MinIO bucket.

- object:

  Character. Object key (path) of the `.rds` file within the bucket.

## Value

An R object deserialized from the `.rds` file.

## Details

Unlike tabular readers such as
[`minio_get_csv()`](https://inesscc.github.io/minioR/reference/minio_get_csv.md)
or
[`minio_get_parquet()`](https://inesscc.github.io/minioR/reference/minio_get_parquet.md),
this function does not enforce any specific data structure. The returned
value is exactly the R object that was serialized when the `.rds` file
was created (for example, a data frame, list, model object, or any other
R object).

## See also

[`minio_get_rdata`](https://inesscc.github.io/minioR/reference/minio_get_rdata.md),
[`minio_read_object`](https://inesscc.github.io/minioR/reference/minio_read_object.md),
[`minio_get_parquet`](https://inesscc.github.io/minioR/reference/minio_get_parquet.md)

## Examples

``` r
if (FALSE) { # \dontrun{
model <- minio_get_rds(
  bucket = "assets",
  object = "models/linear_model.rds"
)

summary(model)
} # }
```
