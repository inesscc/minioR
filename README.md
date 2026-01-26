# minioR <img src="man/figures/logo.png" align="right" height="120" />
<!-- badges: start -->
<!-- badges: end -->

## 1. Overview

`minioR` is an R package that provides a **simple, consistent, and production-ready interface** for interacting with **MinIO object storage** from R.

The package acts as a lightweight wrapper around low-level S3-compatible APIs, focusing on:

- Clear and explicit function naming
- Robust error handling
- Safe defaults for data workflows
- Ease of use in analytical and data engineering pipelines

`minioR` is especially suited for data teams using MinIO as a data lake, object store, or intermediate storage layer.

---

## 2. Features

- Upload and download objects to/from MinIO
- Support for in-memory (`raw`) and file-based uploads
- Explicit handling of content types
- Multipart upload support for large objects
- Clear and informative error messages
- Minimal configuration with sensible defaults

---

## 3. Installation

### 3.1. CRAN

Once released on CRAN, install the package with:

```r
install.packages("minioR")
```

### 3.2. Development version

You can install the development version from GitHub:

```r
install.packages("devtools")
devtools::install_github("https://github.com/inesscc/minioR.git")
```

---

## 4. Configuration

minioR uses standard MinIO / S3 environment variables.

Make sure the following variables are defined before using the package:

```r
Sys.setenv(
  AWS_S3_ENDPOINT = "localhost:9000",
  AWS_REGION = "us-east-1",
  AWS_SECRET_ACCESS_KEY = "minioadmin",
  AWS_ACCESS_KEY_ID = "minioadmin",
  AWS_SIGNATURE_VERSION=2
)
```

HTTPS can be enabled depending on your MinIO deployment.

---

## 5. Usage

### 5.1. Object Management and Discovery

This section covers functions used to explore, inspect, and validate objects stored in MinIO. These operations are typically used at the beginning of data workflows to discover available data, verify object existence, and retrieve metadata without transferring the object contents.

#### 5.1.1. List objects in a bucket or prefix (`minio_list_objects()`)

Lists objects stored in a bucket, optionally filtered by a prefix. When `recursive = TRUE`, all nested objects under the prefix are returned. The result is typically a data frame or tibble with object keys and metadata.

```r
objs <- minio_list_objects(
  bucket = "data",
  prefix = "raw/",
  recursive = TRUE
)

print(objs)
```

#### 5.1.2. Check whether an object exists (`minio_object_exists()`)

Checks for the existence of an object without downloading it. Returns a logical value (`TRUE` or `FALSE`), making it suitable for guards in pipelines and conditional logic.

```r
exists <- minio_object_exists(
  bucket = "data",
  object = "raw/example.csv"
)

exists
```

#### 5.1.3. Retrieve object metadata (HEAD request) (`minio_get_metadata()`)

Retrieves metadata associated with an object using a HEAD operation. This typically includes size, content type, last modified timestamp, and custom metadata, without transferring the object body.

```r
meta <- minio_get_metadata(
  bucket = "data",
  object = "raw/example.csv"
)

meta
```

### 5.2. Read / Download

This section covers functions used to retrieve objects from MinIO, either as raw bytes, parsed R objects (e.g., data frames), or files saved locally. Use `minio_get_object()` and `minio_download_object()` for generic retrieval, and the `minio_get_*()` helpers to read common data formats directly.

#### 5.2.1. Read an object as raw bytes (in-memory)

Use this when you want the raw content of an object (e.g., to parse it yourself).

```r
raw_obj <- minio_get_object(
  bucket = "data",
  object = "raw/example.csv"
)

# Inspect a few bytes
raw_obj[1:20]
```

#### 5.2.2. Read an object into a local file (download)

Use this when you want to materialize the object on disk.

```r
minio_download_object(
  bucket = "data",
  object = "raw/example.csv",
  dest_file = "example_downloaded.csv"
)
```

#### 5.2.3. Read an object with a generic reader (`minio_read_object()`)

`minio_read_object()` is a convenience wrapper that downloads an object and applies a reader function. This is useful when you have a custom parser or want a unified pattern.

```r
df <- minio_read_object(
  bucket = "data",
  object = "raw/example.csv",
  reader = read.csv
)

head(df)
```

#### 5.2.4. Read many objects with a generic reader (`minio_read_many()`)

Read multiple objects (typically under a prefix) and return a list of parsed results. This is helpful for ingestion patterns like daily partitions: raw/2026-01-*/file.csv

```r
dfs <- minio_read_many(
  bucket = "data",
  prefix = "raw/daily/",
  recursive = TRUE,
  reader = read.csv
)

length(dfs)
# names(dfs) typically correspond to object keys
names(dfs)[1:min(3, length(dfs))]
```

#### 5.2.5. Read a CSV object directly as a data.frame

Uses a format-specific helper for CSV parsing.

```r
df_csv <- minio_get_csv(
  bucket = "data",
  object = "raw/example.csv"
)

head(df_csv)
```

#### 5.2.6. Read a Stata (.dta) object directly

Requires `haven` (suggested). Ideal for Stata extracts stored in MinIO.

```r
df_dta <- minio_get_dta(
  bucket = "data",
  object = "raw/example.dta"
)

head(df_dta)
```

#### 5.2.7. Read an Apache Feather object directly

Requires `arrow` (suggested). Feather is useful for fast columnar interchange.

```r
df_feather <- minio_get_feather(
  bucket = "data",
  object = "curated/example.feather"
)

head(df_feather)
```

#### 5.2.8. Read a JSON object directly

Typically returns a list; you can transform it afterwards as needed.

```r
obj_json <- minio_get_json(
  bucket = "data",
  object = "raw/example.json"
)

str(obj_json)
```

#### 5.2.9. Read a Parquet object directly

Requires `arrow` (suggested). Parquet is recommended for analytics and lakehouse patterns.

```r
df_parquet <- minio_get_parquet(
  bucket = "data",
  object = "curated/example.parquet"
)

head(df_parquet)
```

#### 5.2.10. Read an Excel object directly

Requires `readxl` (suggested). Useful for user-provided spreadsheets.

```r
df_xlsx <- minio_get_excel(
  bucket = "data",
  object = "raw/example.xlsx",
  sheet = 1
)

head(df_xlsx)
```

#### 5.2.11. Read a serialized R object (.rds)

Loads a single R object saved with `saveRDS()`.

```r
model_or_obj <- minio_get_rds(
  bucket = "data",
  object = "models/example.rds"
)

model_or_obj
```

#### 5.2.12. Read an .RData/.rda file (multiple objects)

Loads all objects into an isolated environment and returns them as a named list.

```r
objs_rdata <- minio_get_rdata(
  bucket = "data",
  object = "assets/example.RData"
)

names(objs_rdata)
# Access one object by name (example)
# objs_rdata[["my_object"]]
```

### 5.3. Write / Upload

This section describes the functions used to write or upload data to MinIO. The API supports both in-memory writes (raw objects) and file-based uploads, including recursive directory uploads. These functions are designed to be explicit, safe, and suitable for automated data pipelines.

#### 5.3.1. Write an object with a writer function (`minio_write_object()`)

`minio_write_object()` is a high-level helper that applies a writer function to an R object, captures the output, and uploads it to MinIO. This is useful when you want a symmetric counterpart to `minio_read_object()`.

```r
df <- data.frame(
  id = 1:3,
  value = c("a", "b", "c"),
  stringsAsFactors = FALSE
)

minio_write_object(
  bucket = "data",
  object = "raw/example.csv",
  x = df,
  writer = write.csv
)
```

#### 5.3.2. Upload an object from memory (`minio_put_object()`)

Use this function when the object content is already available as raw bytes. This is the lowest-level write helper and maps closely to the underlying S3-compatible PUT operation.

```r
raw_data <- charToRaw("Hello MinIO")

minio_put_object(
  bucket = "data",
  object = "tmp/hello.txt",
  raw_obj = raw_data,
  content_type = "text/plain"
)
```

#### 5.3.3. Upload a local file (`minio_fput_object()`)

Uploads a file from the local filesystem to MinIO. This is the recommended approach for large files or when the data already exists on disk.

```r
minio_fput_object(
  bucket = "data",
  object = "raw/example.csv",
  file_path = "example.csv",
  content_type = "text/csv"
)
```

#### 5.3.4. Upload a directory recursively (`minio_fput_dir()`)

Recursively uploads all files under a local directory to a given prefix in a MinIO bucket. Useful for batch ingestion, data lake loads, or backups.

```r
minio_fput_dir(
  bucket = "data",
  dir_path = "local_data/",
  prefix = "raw/bulk_upload/"
)
```

### 5.4. Delete / Cleanup

This section covers functions used to remove objects from MinIO. These helpers allow for safe and explicit deletion of single objects or multiple objects in batch. They are especially useful for cleanup tasks in automated pipelines, temporary data removal, or lifecycle management workflows.

#### 5.4.1. Remove a single object (`minio_remove_object()`)

Deletes a single object from a bucket. The function fails explicitly if the object does not exist or cannot be removed.

```r
minio_remove_object(
  bucket = "data",
  object = "tmp/hello.txt"
)
```

#### 5.4.2. Remove multiple objects (`minio_remove_objects()`)

Deletes multiple objects in a single operation. Objects can be specified explicitly or obtained programmatically (e.g., from `minio_list_objects()`).

```r
objects_to_remove <- c(
  "raw/example_1.csv",
  "raw/example_2.csv",
  "raw/example_3.csv"
)

minio_remove_objects(
  bucket = "data",
  objects = objects_to_remove
)
```

### 5.5. Object Operations

This section describes server-side operations that act on existing objects within MinIO. These functions do not require downloading data locally and are optimized for efficiency and scalability in data lake workflows.

#### 5.5.1. Copy an object (`minio_copy_object()`)

Performs a server-side copy of an object. The source object remains unchanged, and a new object is created at the destination.

```r
minio_copy_object(
  bucket_src = "data",
  object_src = "raw/example.csv",
  bucket_dst = "data",
  object_dst = "archive/example_copy.csv"
)
```

#### 5.5.2. Move an object (`minio_move_object()`)

Moves an object by performing a copy followed by a delete operation. This is useful for promoting data between layers (e.g., raw -> curated).

```r
minio_move_object(
  bucket_src = "data",
  object_src = "raw/example.csv",
  bucket_dst = "data",
  object_dst = "curated/example.csv"
)
```

#### 5.5.3. Synchronize objects between prefixes (`minio_sync_objects()`)

Synchronizes objects from a source prefix to a destination prefix. Only missing or outdated objects are transferred, making this suitable for incremental replication or environment synchronization.

```r
minio_sync_objects(
  bucket_src = "data",
  prefix_src = "raw/",
  bucket_dst = "data",
  prefix_dst = "backup/raw/"
)
```

---

## 6. Error handling

All public functions fail **explicitly and early** when an operation cannot be completed.

Errors include:

* Bucket or object not found
* Authentication or authorization issues
* Network or endpoint errors
* Invalid input types

This design makes the package suitable for automated pipelines and scheduled jobs.

---

## 7. Design principles

* **Explicit over implicit**
  Function arguments must be clear and intentional.

* **Fail fast**
  Errors are raised immediately with meaningful messages.

* **Minimal abstraction**
  The package does not hide S3 concepts, only simplifies their usage.

* **Production-first**
  Designed for real data pipelines, not only interactive use.
  
  
---

## 8. Relationship to other packages

minioR is not intended to replace general S3 clients such as aws.s3.
Instead, it provides:

- A cleaner interface for MinIO-specific workflows
- Safer defaults
- Spanish-friendly function naming (where appropriate)
- A focused API surface

---

## 9. Contributing

Contributions are welcome.

Please ensure that:

- All new features include tests
- Code follows tidyverse-style formatting
- Documentation is updated accordingly

---

## 10. License

MIT License © 2026
