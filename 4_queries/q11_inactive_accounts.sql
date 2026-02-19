-- Счета без операций дольше указанного количества дней

-- Ваш SQL код здесь

WITH params AS (
    SELECT 90 AS days_threshold
),
last_ops AS (
    SELECT
        account_id,
        MAX(operation_date)::date AS last_operation_date
    FROM operations
    GROUP BY account_id
)
SELECT
    c.client_id,
    c.last_name || ' ' || c.first_name ||
        COALESCE(' ' || c.middle_name, '') AS client_fio,
    c.phone,
    a.account_number,
    pt.name AS product_name,
    a.currency,
    a.current_balance,
    a.opened_date,
    COALESCE(
        to_char(lo.last_operation_date, 'DD.MM.YYYY'),
        'Никогда'
    ) AS last_operation,
    CASE
        WHEN lo.last_operation_date IS NULL
            THEN CURRENT_DATE - a.opened_date::date
        ELSE CURRENT_DATE - lo.last_operation_date
    END AS days_inactive
FROM accounts a
JOIN clients c ON a.client_id = c.client_id
JOIN product_types pt ON a.product_type_id = pt.product_type_id
JOIN account_statuses ast ON a.status_id = ast.status_id
LEFT JOIN last_ops lo ON a.account_id = lo.account_id
CROSS JOIN params p
WHERE ast.status_code = 'open'
  AND (
        lo.last_operation_date IS NULL
        AND (CURRENT_DATE - a.opened_date::date) > p.days_threshold
     OR
        lo.last_operation_date IS NOT NULL
        AND (CURRENT_DATE - lo.last_operation_date) > p.days_threshold
  )
ORDER BY days_inactive DESC, a.current_balance DESC;