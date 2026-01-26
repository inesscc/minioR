# minioR

## Overview

`minioR` is an R package that provides a **simple, consistent, and
production-ready interface** for interacting with **MinIO object
storage** from R.

The package acts as a lightweight wrapper around low-level S3-compatible
APIs, focusing on:

- Clear and explicit function naming
- Robust error handling
- Safe defaults for data workflows
- Ease of use in analytical and data engineering pipelines

`minioR` is especially suited for data teams using MinIO as a data lake,
object store, or intermediate storage layer.

------------------------------------------------------------------------

## Features

- Upload and download objects to/from MinIO
- Support for in-memory (raw) and file-based uploads
- Explicit handling of content types
- Multipart upload support for large objects
- Clear and informative error messages
- Minimal configuration with sensible defaults

------------------------------------------------------------------------

## Installation

### CRAN

Once released on CRAN, install the package with:

``` r
install.packages("minioR")
```

### Development version

You can install the development version from GitHub:

``` r
install.packages("devtools")
devtools::install_github("https://github.com/inesscc/minioR.git")
```

------------------------------------------------------------------------

## Configuration

minioR uses standard MinIO / S3 environment variables.

Make sure the following variables are defined before using the package:

``` r
Sys.setenv(
  AWS_S3_ENDPOINT = "localhost:9000",
  AWS_REGION = "us-east-1",
  AWS_SECRET_ACCESS_KEY = "minioadmin",
  AWS_ACCESS_KEY_ID = "minioadmin",
  AWS_SIGNATURE_VERSION=2
)
```

HTTPS can be enabled depending on your MinIO deployment.

------------------------------------------------------------------------

## Quick Start

### List Objects

``` r
objs <- minio_list_objects(
  bucket = "data",
  prefix = "raw/",
  recursive = TRUE
)
```

### Read a CSV directly from MinIO

``` r
df <- minio_get_csv(
  bucket = "data",
  object = "raw/example.csv"
)
```

### Upload data from memory

``` r
minio_put_object(
  bucket = "data",
  object = "tmp/hello.txt",
  raw_obj = charToRaw("Hello MinIO"),
  content_type = "text/plain"
)
```

------------------------------------------------------------------------

## Documentation

Full documentation, tutorials, and function reference are available on
the package website:

<https://inesscc.github.io/minioR/>

The site is built with pkgdown and includes:

- Getting started guides
- Format-specific readers and writers
- Data lake patterns and best practices
- Complete function reference

------------------------------------------------------------------------

## License

MIT License © 2026
