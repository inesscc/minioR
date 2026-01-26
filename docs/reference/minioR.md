# minioR: A Simple MinIO Client for R

\`minioR\` provides a set of functions to interact with Amazon
S3–compatible object storage services such as MinIO. It allows
uploading, downloading, copying, listing, and deleting objects directly
from R.

## Details

The package is designed for data engineering workflows, automation, and
testing scenarios, offering a simple and explicit interface.

## Configuration

Access to MinIO is configured using environment variables:

- AWS_S3_ENDPOINT:

  Endpoint URL (e.g. `localhost:9000`)

- AWS_SECRET_ACCESS_KEY:

  Access key

- AWS_ACCESS_KEY_ID :

  Secret key

- AWS_SIGNATURE_VERSION:

  Use value = 2

- AWS_REGION:

  Region (optional)

## Typical workflow

1.  Configure environment variables

2.  Upload objects using
    [`minio_put_object()`](https://inesscc.github.io/minioR/reference/minio_put_object.md)

3.  Download objects using
    [`minio_download_object()`](https://inesscc.github.io/minioR/reference/minio_download_object.md)

## See also

- [`minio_list_objects`](https://inesscc.github.io/minioR/reference/minio_list_objects.md)

- [`minio_object_exists`](https://inesscc.github.io/minioR/reference/minio_object_exists.md)

- [`minio_get_metadata`](https://inesscc.github.io/minioR/reference/minio_get_metadata.md)

- [`minio_read_object`](https://inesscc.github.io/minioR/reference/minio_read_object.md)

- [`minio_read_many`](https://inesscc.github.io/minioR/reference/minio_read_many.md)

- [`minio_get_object`](https://inesscc.github.io/minioR/reference/minio_get_object.md)

- [`minio_get_csv`](https://inesscc.github.io/minioR/reference/minio_get_csv.md)

- [`minio_get_dta`](https://inesscc.github.io/minioR/reference/minio_get_dta.md)

- [`minio_get_feather`](https://inesscc.github.io/minioR/reference/minio_get_feather.md)

- [`minio_get_json`](https://inesscc.github.io/minioR/reference/minio_get_json.md)

- [`minio_get_parquet`](https://inesscc.github.io/minioR/reference/minio_get_parquet.md)

- [`minio_get_excel`](https://inesscc.github.io/minioR/reference/minio_get_excel.md)

- [`minio_get_rds`](https://inesscc.github.io/minioR/reference/minio_get_rds.md)

- [`minio_get_rdata`](https://inesscc.github.io/minioR/reference/minio_get_rdata.md)

- [`minio_download_object`](https://inesscc.github.io/minioR/reference/minio_download_object.md)

- [`minio_write_object`](https://inesscc.github.io/minioR/reference/minio_write_object.md)

- [`minio_put_object`](https://inesscc.github.io/minioR/reference/minio_put_object.md)

- [`minio_fput_object`](https://inesscc.github.io/minioR/reference/minio_fput_object.md)

- [`minio_fput_dir`](https://inesscc.github.io/minioR/reference/minio_fput_dir.md)

- [`minio_remove_object`](https://inesscc.github.io/minioR/reference/minio_remove_object.md)

- [`minio_remove_objects`](https://inesscc.github.io/minioR/reference/minio_remove_objects.md)

- [`minio_copy_object`](https://inesscc.github.io/minioR/reference/minio_copy_object.md)

- [`minio_move_object`](https://inesscc.github.io/minioR/reference/minio_move_object.md)

- [`minio_sync_objects`](https://inesscc.github.io/minioR/reference/minio_sync_objects.md)

## Author

**Maintainer**: Javier Ramos <jaramosg@ine.gob.cl>

Other contributors:

- Victor Ballesteros <vaballesteros@ine.gob.cl> \[contributor\]

- Catalina Quijada <caquijada@ine.gob.cl> \[contributor\]

- Gabriel Molina <gemolinah@ine.gob.cl> \[contributor\]
