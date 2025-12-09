-- Счета с подозрительно большим числом операций за короткий период

-- Ваш SQL код здесь


WITH params AS (
    SELECT
        10 AS min_operations_count,
        7  AS days_period
),

recent_activity AS (
    SELECT
        a.account_id,
        a.account_number,
        c.client_id,
        c.last_name || ' ' || c.first_name ||
            COALESCE(' ' || c.middle_name, '') AS client_fio,
        c.phone,
        pt.name AS product_name,
        COUNT(o.operation_id) AS operations_count,
        MIN(o.operation_date) AS first_operation_in_period,
        MAX(o.operation_date) AS last_operation_in_period
    FROM accounts a
    JOIN clients c ON a.client_id = c.client_id
    JOIN product_types pt ON a.product_type_id = pt.product_type_id
    JOIN account_statuses ast ON a.status_id = ast.status_id
    JOIN operations o ON a.account_id = o.account_id
    WHERE ast.status_code = 'open'
      AND o.operation_date >= CURRENT_DATE - INTERVAL '1 day' * (SELECT days_period FROM params)
    GROUP BY
        a.account_id, a.account_number,
        c.client_id, c.last_name, c.first_name, c.middle_name, c.phone, pt.name
    HAVING COUNT(o.operation_id) >= (SELECT min_operations_count FROM params)
)

SELECT
    client_fio,
    phone,
    account_number,
    product_name,
    operations_count,
    to_char(first_operation_in_period, 'DD.MM.YYYY HH24:MI') AS period_start,
    to_char(last_operation_in_period,  'DD.MM.YYYY HH24:MI') AS period_end,

    ROUND(
        operations_count::numeric /
        ((EXTRACT(EPOCH FROM (last_operation_in_period - first_operation_in_period)) / 86400) + 1),
        2
    ) AS avg_operations_per_day,

    CASE
        WHEN operations_count >= 20 THEN 'КРИТИЧЕСКАЯ АКТИВНОСТЬ'
        WHEN operations_count >= 15 THEN 'ВЫСОКАЯ АКТИВНОСТЬ'
        ELSE 'ПОДОЗРИТЕЛЬНАЯ АКТИВНОСТЬ'
    END AS alert_level

FROM recent_activity
ORDER BY
    operations_count DESC,
    (last_operation_in_period - first_operation_in_period) ASC;
