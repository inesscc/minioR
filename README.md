# minioR

<!-- badges: start -->
<!-- badges: end -->

## Overview

`minioR` is an R package that provides a **simple, consistent, and production-ready interface** for interacting with **MinIO object storage** from R.

The package acts as a lightweight wrapper around low-level S3-compatible APIs, focusing on:

- Clear and explicit function naming
- Robust error handling
- Safe defaults for data workflows
- Ease of use in analytical and data engineering pipelines

`minioR` is especially suited for data teams using MinIO as a data lake, object store, or intermediate storage layer.

---

## Features

- Upload and download objects to/from MinIO
- Support for in-memory (`raw`) and file-based uploads
- Explicit handling of content types
- Multipart upload support for large objects
- Clear and informative error messages
- Minimal configuration with sensible defaults

---

## Installation

### CRAN

Once released on CRAN, install the package with:

```r
install.packages("minioR")
```

### Development version

You can install the development version from GitHub:

```r
install.packages("devtools")
devtools::install_github("your-org/minioR")
```

---

## Configuration

minioR uses standard MinIO / S3 environment variables.

Make sure the following variables are defined before using the package:

```r
Sys.setenv(
  MINIO_ENDPOINT = "http://localhost:9000",
  MINIO_REGION = "us-east-1",
  AWS_SECRET_ACCESS_KEY = "minioadmin",
  AWS_ACCESS_KEY_ID = "minioadmin",
  AWS_SIGNATURE_VERSION=2
)
```

HTTPS can be enabled depending on your MinIO deployment.

---

## Usage

### Load the package

```r
library(minioR)
```

### List objects in a bucket/prefix

```r
objs <- minio_get_list_objects(
  bucket = "data",
  prefix = "raw/",
  recursive = TRUE
)

print(objs)
```

### Check whether an object exists

```r
exists <- minio_object_exists(
bucket = "data",
object_name = "raw/example.csv"
)

exists
```

### Upload a local file

```r
minio_fput_object(
  bucket = "data",
  file_path = "example.csv",
  object_name = "raw/example.csv",
  content_type = "text/csv"
)
```

### Upload an object from memory

```r
raw_data <- charToRaw("Hello MinIO")

minio_put_object(
  bucket = "data",
  raw_obj = raw_data,
  object_name = "tmp/hello.txt",
  content_type = "text/plain"
)
```

### Download an object to a local path

```r
minio_download_object(
  bucket = "data",
  object_name = "raw/example.csv",
  dest_file = "example_downloaded.csv"
)
```

### Download an object into memory (raw)

```r
raw_obj <- minio_get_object(
  bucket = "data",
  object_name = "tmp/hello.txt"
)

rawToChar(raw_obj)
```

### Read a CSV object directly as a data.frame

```r
df_csv <- minio_get_csv(
  bucket = "data",
  object_name = "raw/example.csv"
)

head(df_csv)
```

### Read a Parquet object directly (as a data.frame / tibble)

```r
df_parquet <- minio_get_parquet(
bucket = "data",
object_name = "curated/example.parquet"
)

head(df_parquet)
```

### Get object metadata (HEAD)

```r
meta <- minio_get_object_metadata(
  bucket = "data",
  object_name = "raw/example.csv"
)

meta
```

### Copy an object (server-side copy)

```r
minio_copy_object(
  bucket_src = "data",
  object_name_src = "raw/example.csv",
  bucket_dst = "data",
  object_name_dst = "raw/example_copy.csv"
)
```

### Remove an object

```r
minio_remove_object(
  bucket = "data",
  object_name = "tmp/hello.txt"
)
```

---

## Error handling

All public functions fail **explicitly and early** when an operation cannot be completed.

Errors include:

* Bucket or object not found
* Authentication or authorization issues
* Network or endpoint errors
* Invalid input types

This design makes the package suitable for automated pipelines and scheduled jobs.

---

## Design principles

* **Explicit over implicit**
  Function arguments must be clear and intentional.

* **Fail fast**
  Errors are raised immediately with meaningful messages.

* **Minimal abstraction**
  The package does not hide S3 concepts, only simplifies their usage.

* **Production-first**
  Designed for real data pipelines, not only interactive use.
  
  
---

## Relationship to other packages

minioR is not intended to replace general S3 clients such as aws.s3.
Instead, it provides:

- A cleaner interface for MinIO-specific workflows
- Safer defaults
- Spanish-friendly function naming (where appropriate)
- A focused API surface

---

## Contributing

Contributions are welcome.

Please ensure that:

- All new features include tests
- Code follows tidyverse-style formatting
- Documentation is updated accordingly

---

## License

MIT License © 2026
