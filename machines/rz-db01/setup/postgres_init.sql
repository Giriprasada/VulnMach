CREATE TABLE IF NOT EXISTS pg_flag (
  id SERIAL PRIMARY KEY,
  flag TEXT
);
INSERT INTO pg_flag (flag)
SELECT 'VULN{pg_rce_4_th3_w1n}'
WHERE NOT EXISTS (
  SELECT 1 FROM pg_flag WHERE flag = 'VULN{pg_rce_4_th3_w1n}'
);
