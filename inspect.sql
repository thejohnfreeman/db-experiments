\timing on

SELECT * FROM params;

-- How big is our table?
SELECT COUNT(*) FROM changes;

-- How many ledgers do we have?
SELECT COUNT(DISTINCT ledger_id) FROM changes;

-- Which ledgers are unrepresented?
SELECT ledgers.id
FROM generate_series(0, (SELECT nledgers - 1 FROM params)) AS ledgers(id)
LEFT JOIN (
  SELECT ledger_id, COUNT(node_id) AS nodes
  FROM changes
  GROUP BY ledger_id
) AS changes
ON changes.ledger_id = ledgers.id
WHERE changes.nodes IS NULL;

-- Which ledgers add/remove the most nodes?
SELECT *
FROM (
  SELECT ledger_id, COUNT(*) AS nodes
  FROM changes
  GROUP BY ledger_id
) AS t
ORDER BY nodes DESC
LIMIT 10;

-- Which ledgers add/remove the fewest nodes?
SELECT *
FROM (
  SELECT ledger_id, COUNT(*) AS nodes
  FROM changes
  GROUP BY ledger_id
) AS t
ORDER BY nodes ASC
LIMIT 10;

-- Which nodes are removed by the most ledgers in a given range?
SELECT *
FROM (
  SELECT node_id, COUNT(*) AS removals
  FROM changes
  WHERE action = 0
  AND ledger_id >= 0
  AND ledger_id < 250
  GROUP BY node_id
) AS t
ORDER BY removals DESC
LIMIT 10;
