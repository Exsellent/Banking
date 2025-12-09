-- Клиенты с хотя бы одним продуктом со ставкой выше указанного значения

-- Ваш SQL код здесь


WITH params AS (
    SELECT 2 AS product_type_id
)

SELECT
    pt.name AS product_name,
    CASE WHEN pt.is_deposit THEN 'Срочный вклад' ELSE 'Накопительный счёт' END AS product_type,
    a.currency,
    COUNT(a.account_id)                          AS accounts_count,
    COUNT(DISTINCT a.client_id)                  AS unique_clients_count,
    ROUND(SUM(a.current_balance), 2)             AS total_balance,
    ROUND(AVG(a.current_balance), 2)             AS avg_balance,
    ROUND(AVG(a.current_rate), 2)                AS avg_rate,
    MIN(a.current_balance)                       AS min_balance,
    MAX(a.current_balance)                       AS max_balance
FROM accounts a
JOIN product_types pt ON a.product_type_id = pt.product_type_id
JOIN account_statuses ast ON a.status_id = ast.status_id
CROSS JOIN params p
WHERE ast.status_code = 'open'
  AND a.product_type_id = p.product_type_id
GROUP BY pt.name, pt.is_deposit, a.currency
ORDER BY total_balance DESC;