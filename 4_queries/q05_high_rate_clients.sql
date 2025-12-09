-- Клиенты с хотя бы одним продуктом со ставкой выше указанного значения

-- Ваш SQL код здесь

WITH params AS (
    SELECT 7.50::NUMERIC(5,2) AS min_rate
)

SELECT
    c.client_id,
    c.last_name || ' ' || c.first_name ||
        COALESCE(' ' || c.middle_name, '') AS client_fio,
    c.phone,
    c.email,
    COUNT(a.account_id)                    AS high_rate_accounts_count,
    MAX(a.current_rate)                    AS max_rate,
    ROUND(AVG(a.current_rate), 2)          AS avg_rate,
    SUM(a.current_balance)                 AS total_balance_high_rate_accounts,
    STRING_AGG(a.account_number, ', ')     AS account_numbers
FROM clients c
JOIN accounts a ON c.client_id = a.client_id
JOIN account_statuses ast ON a.status_id = ast.status_id
JOIN product_types pt ON a.product_type_id = pt.product_type_id
CROSS JOIN params p
WHERE ast.status_code = 'open'
  AND a.current_rate > p.min_rate
GROUP BY
    c.client_id,
    c.last_name, c.first_name, c.middle_name,
    c.phone, c.email
ORDER BY
    max_rate DESC,
    total_balance_high_rate_accounts DESC;