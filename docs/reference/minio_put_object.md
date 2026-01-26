# Upload an Object to MinIO from Memory

Uploads an object to a MinIO bucket using an in-memory `raw` vector. For
maximum cross-platform compatibility, the payload is first written to a
temporary file and then uploaded using
[`put_object`](https://rdrr.io/pkg/aws.s3/man/put_object.html).

## Usage

``` r
minio_put_object(
  bucket,
  object,
  raw,
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

  Character. Object key (path) within the bucket.

- raw:

  Raw vector containing the object payload.

- content_type:

  Character or `NULL`. Optional MIME type (e.g., `"text/csv"`,
  `"application/octet-stream"`).

- multipart:

  Logical. Whether to use multipart upload. Defaults to `FALSE`.

- use_https:

  Logical. Whether to use HTTPS when connecting to MinIO.

- region:

  Character. Region string required by `aws.s3`.

## Value

Invisibly returns `TRUE` if the upload was successful.

## Examples

``` r
if (FALSE) { # \dontrun{
payload <- charToRaw("hello\n")
minio_put_object("vault", payload, "tests/hello.txt", content_type = "text/plain")
} # }
```
