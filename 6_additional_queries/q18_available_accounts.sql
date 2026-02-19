-- Вывести все счета клиента, доступные для операций, с суммой операций за октябрь 2025

-- Ваш SQL код здесь


SELECT
    a.account_number,
    pt.name AS product_name,
    a.currency,
    a.current_balance,
    COALESCE(SUM(o.amount), 0) AS october_2025_turnover
FROM accounts a
JOIN product_types pt ON a.product_type_id = pt.product_type_id
JOIN account_statuses ast ON a.status_id = ast.status_id
LEFT JOIN operations o ON a.account_id = o.account_id
    AND o.operation_date >= '2025-10-01' AND o.operation_date < '2025-11-01'
WHERE a.client_id = 2
  AND ast.status_code = 'open'
GROUP BY a.account_id, a.account_number, pt.name, a.currency, a.current_balance
ORDER BY october_2025_turnover DESC;