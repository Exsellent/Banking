-- Аналитика по каждому клиенту: суммы и количество операций для открытых и заблокированных счетов за октябрь 2025

-- Ваш SQL код здесь

SELECT
    c.client_id,
    c.last_name || ' ' || c.first_name || COALESCE(' ' || c.middle_name, '') AS client_fio,
    COUNT(CASE WHEN ast.status_code = 'open'     THEN 1 END) AS open_accounts,
    COUNT(CASE WHEN ast.status_code = 'blocked'  THEN 1 END) AS blocked_accounts,
    SUM(CASE WHEN ast.status_code = 'open'     THEN a.current_balance ELSE 0 END) AS open_balance,
    SUM(CASE WHEN ast.status_code = 'blocked'  THEN a.current_balance ELSE 0 END) AS blocked_balance,
    SUM(CASE WHEN ast.status_code = 'open'     THEN o.amount ELSE 0 END) AS open_october_turnover,
    SUM(CASE WHEN ast.status_code = 'blocked'  THEN o.amount ELSE 0 END) AS blocked_october_turnover
FROM clients c
LEFT JOIN accounts a ON c.client_id = a.client_id
LEFT JOIN account_statuses ast ON a.status_id = ast.status_id
LEFT JOIN operations o ON a.account_id = o.account_id
    AND o.operation_date >= '2025-10-01' AND o.operation_date < '2025-11-01'
GROUP BY c.client_id, client_fio
ORDER BY blocked_accounts DESC, open_october_turnover DESC;