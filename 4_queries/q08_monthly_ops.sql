-- Количество операций за последний календарный месяц по каждому клиенту

-- Ваш SQL код здесь


WITH period AS (
    SELECT
        DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month' AS start_date,
        DATE_TRUNC('month', CURRENT_DATE)                      AS end_date
)
SELECT
    c.client_id,
    c.last_name || ' ' || c.first_name || COALESCE(' ' || c.middle_name, '') AS client_fio,
    c.phone,
    COUNT(o.operation_id) AS operations_last_month
FROM clients c
LEFT JOIN accounts a
       ON a.client_id = c.client_id
LEFT JOIN operations o
       ON o.account_id = a.account_id
      AND o.operation_date >= (SELECT start_date FROM period)
      AND o.operation_date <  (SELECT end_date   FROM period)
GROUP BY
    c.client_id,
    c.last_name,
    c.first_name,
    c.middle_name,
    c.phone
ORDER BY
    operations_last_month DESC,
    client_fio;
