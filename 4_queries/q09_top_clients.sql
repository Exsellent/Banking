-- Пять клиентов с наибольшим оборотом операций за период

-- Ваш SQL код здесь


WITH period AS (
    SELECT
        '2024-01-01'::date AS start_date,
        '2024-12-31'::date AS end_date
)

SELECT
    c.client_id,
    c.last_name || ' ' || c.first_name ||
        COALESCE(' ' || c.middle_name, '') AS client_fio,
    c.phone,
    ROUND(SUM(o.amount), 2)                AS total_turnover,
    COUNT(o.operation_id)                  AS operations_count,
    ROUND(AVG(o.amount), 2)                AS avg_operation_amount
FROM clients c
JOIN accounts a ON c.client_id = a.client_id
JOIN operations o ON a.account_id = o.account_id
CROSS JOIN period p
WHERE o.operation_date >= p.start_date
  AND o.operation_date <= p.end_date
GROUP BY
    c.client_id,
    c.last_name, c.first_name, c.middle_name,
    c.phone
ORDER BY
    total_turnover DESC
LIMIT 5;
