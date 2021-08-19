\timing on

CREATE OR REPLACE FUNCTION decrement_purge (
  _in_min_ledger int,
  _in_max_ledger int
) RETURNS int AS $$
DECLARE
  _ret    int := 0;
  _record record;
  _cursor CURSOR (min_ledger int, max_ledger int) FOR
    SELECT id, refs
    FROM nodes
    INNER JOIN changes
    ON nodes.id = changes.node_id
    AND changes.ledger_id >= min_ledger
    AND changes.ledger_id < max_ledger
    AND changes.action = 0
    FOR UPDATE;
BEGIN
  OPEN _cursor(_in_min_ledger, _in_max_ledger);
  LOOP
    FETCH _cursor INTO _record;
    IF _record IS NULL THEN EXIT; END IF;
    IF _record.refs = 1 THEN
      --RAISE INFO 'deleting: %', _record.id;
      DELETE FROM nodes WHERE CURRENT OF _cursor;
      _ret := _ret + 1;
      CONTINUE;
    END IF;
    --RAISE INFO 'decrementing: %', _record.id;
    UPDATE nodes SET refs = refs - 1 WHERE CURRENT OF _cursor;
  END LOOP;
  RETURN _ret;
END
$$ LANGUAGE plpgsql;

SELECT decrement_purge(0, 250);
