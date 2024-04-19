# Microsoft SQL Server

## Create database
```bash
docker exec -it dev-rootdb-mssql bash

/opt/mssql-tools/bin/sqlcmd -d sakila -U sa -i /mssql-sakila/sql-server-sakila-schema.sql -o /tmp/output_file.txt
/opt/mssql-tools/bin/sqlcmd -d sakila -U sa -i /mssql-sakila/sql-server-sakila-insert-data.sql -o /tmp/output_file.txt
```

