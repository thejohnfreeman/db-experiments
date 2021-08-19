This project has scripts for benchmarking different approaches to online delete
using different databases.

For now all these scripts are for PostgreSQL.
I assume you have PostgreSQL installed and running,
and that you have created a database.

- **populate.sql**: Load node data from `/tmp/nodes.tsv`, and randomly
    generate change data.
- **inspect.sql**: Check the `params` table and a few key indicators from the
    `nodes` and `changes` tables.
- **delete.groupby.sql**: Delete ledgers [0, 250) via group-by and join.
- **delete.function.sql**: Delete ledgers [0, 250) via PL/pgSQL function.
