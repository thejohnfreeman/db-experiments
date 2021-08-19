\timing on

UPDATE nodes
SET refs = nodes.refs - removals.refs
FROM (
  SELECT node_id, COUNT(*) AS refs
  FROM changes
  WHERE ledger_id >= 0
  AND ledger_id < 250
  AND action = 0
  GROUP BY node_id
) AS removals
WHERE removals.node_id = nodes.id;

DELETE FROM nodes
WHERE refs <= 0;

DELETE FROM changes
WHERE ledger_id >= 0
AND ledger_id < 250;
