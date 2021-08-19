\timing on

-- Recreate the nodes table.
DROP TABLE IF EXISTS nodes;
CREATE TABLE IF NOT EXISTS nodes (
  id bytea PRIMARY KEY,
  value bytea NOT NULL
);
COPY nodes FROM '/tmp/nodes.tsv';
ALTER TABLE nodes ADD COLUMN refs int NOT NULL DEFAULT 1;
ANALYZE nodes;

-- Create the changes table.
-- For the action column:
-- 0 = removed
-- 1 = added
-- Using integers keeps the messages as short as possible.
-- We can add constraints to bound the range if we want.
DROP TABLE IF EXISTS changes;
CREATE TABLE IF NOT EXISTS changes (
  ledger_id int NOT NULL,
  node_id bytea NOT NULL,
  action smallint NOT NULL,
  PRIMARY KEY (ledger_id, node_id)
);

-- Set parameters for following queries.
-- How many ledgers should we have if
-- every node is added by one ledger,
-- and a typical ledger adds 2000 nodes?
DROP TABLE IF EXISTS const;
CREATE TABLE IF NOT EXISTS const AS (
  SELECT 2000 AS nodes_per_ledger
);
DROP TABLE IF EXISTS params;
CREATE TABLE IF NOT EXISTS params AS (
  SELECT (SELECT COUNT(*) / const.nodes_per_ledger FROM nodes) AS nledgers
  FROM const
);

-- Randomly assign added nodes to ledgers targeting given nodes per ledger.
INSERT INTO changes (ledger_id, node_id, action)
SELECT floor(random() * params.nledgers), nodes.id, 1
FROM nodes, params;

-- Randomly assign removed nodes to ledgers targeting given nodes per ledger,
-- so long as no node is added and removed by the same ledger.
INSERT INTO changes (ledger_id, node_id, action)
SELECT floor(random() * params.nledgers), nodes.id, 0
FROM nodes, params
ON CONFLICT DO NOTHING;

-- Randomly assign a few more added/removed nodes to ledgers
-- to get some round-trips.
INSERT INTO changes (ledger_id, node_id, action)
SELECT floor(random() * params.nledgers), nodes.id, floor(random() * 2)
FROM nodes TABLESAMPLE BERNOULLI(10), params
ON CONFLICT DO NOTHING;

-- We don't need this index in production,
-- but we do for setting up test data.
CREATE INDEX idx_changes_nodes ON changes (node_id, action);

-- Assign reference counts by fetching the count for each node.
/* UPDATE nodes */
/* SET refs = ( */
/*   SELECT COUNT(*) */
/*   FROM changes */
/*   WHERE action = 1 AND node_id = nodes.id */
/* ); */

-- Assign reference counts by joining.
UPDATE nodes
SET refs = t.refs
FROM (
  SELECT node_id, COUNT(*) AS refs
  FROM changes
  WHERE action = 1
  GROUP BY node_id
) AS t
WHERE nodes.id = t.node_id;

-- Problem: adds and removes per node must alternate,
-- but that is not enforced.
-- Solution: for each node, create a random number of changes, [1, m],
-- and a random starting change,
-- then sort m random ledgers,
-- and insert change records.
