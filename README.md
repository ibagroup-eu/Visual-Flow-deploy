# About Visual Flow

Visual Flow is an ETL tool designed for effective data manipulation via convenient and user-friendly interface. The tool has the following capabilities:

- Can integrate data from heterogeneous sources:
  - DB2
  - IBM COS
  - AWS S3
  - Elastic Search
  - PostgreSQL
  - MySQL/Maria
  - MSSQL
  - Oracle
  - Cassandra
  - Mongo
  - Redis
  - Redshift
- Leverage direct connectivity to enterprise applications as sources and targets
- Perform data processing and transformation
- Run custom code
- Leverage metadata for analysis and maintenance

Visual Flow application is divided into the following repositories: 

- [Visual-Flow-frontend](https://github.com/ibagomel/Visual-Flow-frontend)
- [Visual-Flow-backend](https://github.com/ibagomel/Visual-Flow-backend)
- [Visual-Flow-jobs](https://github.com/ibagomel/Visual-Flow-jobs)
- _**Visual-Flow-deploy**_ (current)

# Visual Flow deploy

This repository contains helm chart to deploy Visual Flow app with all requirements to Amazon EKS cluster.

Helm charts in this repository:

- [visual-flow](./charts/visual-flow/) - to deploy Visual Flow application.

## Installation

[Check the official guide](./INSTALL.md).

## Contribution

[Check the official guide](https://github.com/ibagomel/Visual-Flow/blob/main/CONTRIBUTING.md).

## License

Visual Flow is an open-source software licensed under the [Apache-2.0 license](./LICENSE).
