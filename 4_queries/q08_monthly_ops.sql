-- Количество операций за последний месяц по каждому клиенту

-- Ваш SQL код здесь

WITH period AS (
    SELECT
        CURRENT_DATE - INTERVAL '30 days' AS start_date,
        CURRENT_DATE                     AS end_date
)

SELECT
    c.client_id,
    c.last_name || ' ' || c.first_name ||
        COALESCE(' ' || c.middle_name, '') AS client_fio,
    c.phone,
    COALESCE(COUNT(o.operation_id), 0)      AS operations_last_30_days
FROM clients c
LEFT JOIN accounts a ON c.client_id = a.client_id
LEFT JOIN operations o ON a.account_id = o.account_id
    AND o.operation_date >= (SELECT start_date FROM period)
    AND o.operation_date <  (SELECT end_date FROM period) + INTERVAL '1 day'
GROUP BY
    c.client_id,
    c.last_name, c.first_name, c.middle_name,
    c.phone
ORDER BY
    operations_last_30_days DESC,
    client_fio ASC;