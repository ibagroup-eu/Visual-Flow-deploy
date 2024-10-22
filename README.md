Visual Flow is an ETL/ELT tool designed for effective data management via convenient and user-friendly interface. The tool has the following capabilities:

- Can integrate data from heterogeneous sources:
  - Azure Blob Storage
  - AWS S3
  - Cassandra
  - Click House
  - DB2
  - Databricks JDBC (global configuration)
  - Databricks (Databricks configuration)
  - Dataframe (for reading)
  - Google Cloud Storage
  - Elastic Search
  - IBM COS
  - Kafka
  - Local File
  - MS SQL
  - Mongo
  - MySQL/Maria
  - Oracle
  - PostgreSQL
  - Redis
  - Redshift
  - REST API
- It supports the following file formats:
  - Delta Lake
  - Parquet
  - JSON
  - CSV
  - ORC
  - Avro
  - Text
  - Binary (PDF, DOC, Audio files)
- Leverage direct connectivity to enterprise applications as sources and targets
- Perform data processing and transformation
- Run custom code
- Leverage metadata for analysis and maintenance
- Allows to deploy in two configurations and run jobs in Spark/Kubernetes and Databricks environments respectively
- Leverages Generative AI capabilities via tasks like Parse text, Generate data, Transcribe, Generic task

Visual Flow application is divided into the following repositories:

- [Visual-Flow-databricks-frontend](https://github.com/ibagroup-eu/Visual-Flow-databricks-frontend)
- [Visual-Flow-databricks](https://github.com/ibagroup-eu/Visual-Flow-databricks)
- [Visual-Flow-databricks-history-service](https://github.com/ibagroup-eu/Visual-Flow-databricks-history-service)
- [Visual-Flow-backend-job-storage-service](https://github.com/ibagroup-eu/Visual-Flow-backend-job-storage-service)
- [Visual-Flow-databricks-jobs](https://github.com/ibagroup-eu/Visual-Flow-databricks-jobs)

## Install

Follow the instructions from [Install.md](./INSTALL.md).

## Contribution

[Check the official guide](https://github.com/ibagroup-eu/Visual-Flow-for-Databricks/blob/main/CONTRIBUTING.md).

## License

Visual Flow is an open-source software licensed under the [Apache-2.0 license](./LICENSE).
