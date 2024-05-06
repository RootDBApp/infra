# PostgreSQL
## Import data
```bash
docker exec -it dev-rootdb-postgresql bash

psql  --username=postgres dvdrental < /postgres-sakila/postgres-sakila-schema.sql
psql  --username=postgres dvdrental < /postgres-sakila/postgres-sakila-insert-data.sql
```

## Connector configuration

```bash
name    : test-postgre connection
IP      : 172.20.0.70
db name : dvdrental
username: postgres
password: <POSTGRES_PASSWORD from docker-compose.yml>
```



# Microsoft SQL Server
## Import data
```bash
docker exec -it dev-rootdb-mssql bash

/opt/mssql-tools/bin/sqlcmd -d sakila -U sa -i /mssql-sakila/sql-server-sakila-schema.sql -o /tmp/output_file.txt
/opt/mssql-tools/bin/sqlcmd -d sakila -U sa -i /mssql-sakila/sql-server-sakila-insert-data.sql -o /tmp/output_file.txt
```

