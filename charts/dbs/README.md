# Install required dbs for a full functionality of VF app

Chart contains at least two DBs:
- Redis: Session and Job's execution history
- PosgreSQL: History service

To install it - you can use following commands and custom values files:

# Redis
> helm install redis -f values.yaml bitnami/redis

# PostgreSQL
> helm install pgserver -f values.yaml bitnami/postgresql

FYI: Just in case better to save output of these command (it contains helpful info with short guide, how to get access to pod & dbs and show default credentials).