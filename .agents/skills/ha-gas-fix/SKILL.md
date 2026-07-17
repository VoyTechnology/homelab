---
name: ha-gas-fix
description: Detect and delete anomalous Home Assistant gas sensor entries where consecutive readings jump implausibly (hundreds/thousands of m³), which corrupts the gas usage and derived price sensors. Use this when gas usage or price metrics show obviously wrong spikes.
---

# Home Assistant Gas Sensor Anomaly Fixer

Runs SQL queries inside the Home Assistant pod to find and delete gas sensor
states and statistics with implausible deltas between consecutive readings.
The energy dashboard reads from `statistics` tables, so both `states` and
`statistics` (plus `statistics_short_term`) must be cleaned.

## Prerequisites

- `kubectl` pointing at the cluster
- Deduct namespace based on your HA deployment (default: `homeassistant`)

## Pod Discovery

```sh
kubectl get pods -n homeassistant \
  --selector app.kubernetes.io/instance=homeassistant \
  --field-selector status.phase=Running \
  -o 'jsonpath={.items[0].metadata.name}'
```

Store the result as `POD`.

## Python Helper

The `sqlite3` binary is **not** available in the HA container. Use Python's
built-in `sqlite3` module instead. Wrap every query like this:

```sh
kubectl exec -n homeassistant $POD -i -- python3 -c "
import sqlite3
conn = sqlite3.connect('/config/home-assistant_v2.db')
cursor = conn.cursor()
cursor.execute('''<SQL HERE>''')
for row in cursor.fetchall():
    print(row)
conn.close()
"
```

For write operations, add `conn.commit()` after the execute.

## Schema Notes

Newer HA versions (2023.x+) store entity IDs in `states_meta` and reference
them via `metadata_id` in `states`. The `entity_id` column in `states` is
NULL. The timestamp column is `last_updated`, not `created`.

The `statistics` and `statistics_short_term` tables use `metadata_id` to
reference `statistics_meta`. The energy dashboard reads from these tables,
not from `states`.

## Execution Steps

### 1. Discover gas sensor entity_ids

```sql
SELECT DISTINCT sm.entity_id
FROM states s
JOIN states_meta sm ON s.metadata_id = sm.metadata_id
WHERE sm.entity_id LIKE 'sensor.gas%' OR sm.entity_id LIKE 'input_number.gas%'
ORDER BY sm.entity_id;
```

Collect the entity_ids. If none found, stop.

Also find the corresponding `statistics_meta` IDs for later steps:

```sql
SELECT id, statistic_id, unit_of_measurement
FROM statistics_meta
WHERE statistic_id LIKE 'sensor.gas%' OR statistic_id LIKE 'input_number.gas%';
```

### 2. Check states for anomalous readings

Query consecutive readings to find deltas > threshold (default 50 m³):

```sql
WITH gas_states AS (
  SELECT s.state_id, sm.entity_id, s.state, s.last_updated
  FROM states s
  JOIN states_meta sm ON s.metadata_id = sm.metadata_id
  WHERE sm.entity_id IN (<ENTITY_IDS>)
),
numbered AS (
  SELECT state_id, entity_id, state, last_updated,
         LAG(state) OVER (PARTITION BY entity_id ORDER BY last_updated) AS prev_state,
         LAG(last_updated) OVER (PARTITION BY entity_id ORDER BY last_updated) AS prev_created
  FROM gas_states
)
SELECT state_id, entity_id, prev_created, prev_state, last_updated, state,
       CAST(state AS REAL) - CAST(prev_state AS REAL) AS delta
FROM numbered
WHERE prev_state IS NOT NULL
  AND abs(CAST(state AS REAL) - CAST(prev_state AS REAL)) > 50
ORDER BY last_updated;
```

Collect all state_ids where delta > threshold.

### 3. Check statistics for corrupted sums

The energy dashboard reads the `sum` column from `statistics`. Corrupted
state entries propagate incorrect sums here. Find entries where the sum
jumped implausibly:

```sql
SELECT st.id, sm.statistic_id, st.state, st.sum
FROM statistics st
JOIN statistics_meta sm ON st.metadata_id = sm.id
WHERE sm.statistic_id IN (<ENTITY_IDS>)
  AND abs(CAST(st.sum AS REAL)) > 10000
ORDER BY st.id;
```

Also check `statistics_short_term` with the same query.

### 4. Display anomalies to the user

Show anomalies from both `states` and `statistics`, grouped by table:
- **states**: entity_id, state_id, timestamps, prev_state -> state, delta
- **statistics**: id, entity, state, sum (and which table: `statistics` / `statistics_short_term`)

### 5. Ask user for confirmation

Ask what to delete. Always offer at minimum:
- Delete state anomalies only
- Delete state + statistics anomalies (recommended)

Only proceed if user confirms.

### 6. Delete anomalous rows

For `states`:

```sql
DELETE FROM states WHERE state_id IN (<id1>, <id2>, ...);
```

For `statistics` — delete by ID range (find boundaries first):

```sql
-- Find the last good entry before corruption
SELECT id, state, sum FROM statistics
WHERE metadata_id = <META_ID> AND sum < 10000
ORDER BY id DESC LIMIT 1;

-- Delete all corrupted entries from first bad onward
DELETE FROM statistics WHERE id >= <FIRST_BAD_ID> AND metadata_id = <META_ID>;
```

Repeat for each affected `metadata_id` and for `statistics_short_term`.

### 7. Confirm deletion

Re-run step 2 and 3 to verify anomalies are gone from both `states` and
`statistics` tables.

## Configuration

- Threshold: 50 m³ (adjust by changing the `> 50` in the WHERE clause)
- Pattern: `sensor.gas%` (adjust in step 1)
- Statistics sum threshold: 10000 (adjust in step 3)
