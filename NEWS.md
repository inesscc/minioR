# minioR 0.1.0

Initial public release.

This version provides a stable, production-oriented interface for interacting with MinIO object storage from R, with a focus on explicit APIs, robust error handling, and data engineering workflows.

## Core features

* Added core object management helpers:

  * minio_list_objects()

  * minio_object_exists()

  * minio_get_metadata()

* Added generic read helpers:

  * minio_get_object()

  * minio_download_object()

  * minio_read_object()

  * minio_read_many()

* Added format-specific readers:

  * minio_get_csv()

  * minio_get_parquet()

  * minio_get_json()

  * minio_get_xlsx()

  * minio_get_dta()

  * minio_get_feather()

  * minio_get_rds()

  * minio_get_rdata()

* Added write and upload helpers:

  * minio_put_object()

  * minio_fput_object()

  * minio_fput_dir()

  * minio_write_object()

* Added server-side object operations:

  * minio_copy_object()

  * minio_move_object()

  * minio_sync_objects()

* Added delete helpers:

  * minio_remove_object()

  * minio_remove_objects()

## Design and behavior

* All public functions fail fast with explicit and informative error messages.

* Safe defaults are enforced for automated and scheduled pipelines.

* No silent side effects on the user environment.

* Minimal abstraction over S3-compatible APIs, optimized for MinIO workflows.

## Testing and quality

* Comprehensive unit and integration test coverage.

* Optional dependencies (arrow, haven, readxl) are handled gracefully.

* CI configured for multiple R versions and operating systems.
