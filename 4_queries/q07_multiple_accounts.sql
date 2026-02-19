-- Клиенты с хотя бы одним продуктом со ставкой выше указанного значения

-- Ваш SQL код здесь

SELECT
    c.client_id,
    c.last_name || ' ' || c.first_name ||
        COALESCE(' ' || c.middle_name, '') AS client_fio,
    c.phone,
    COUNT(a.account_id) AS total_active_accounts,
    COUNT(a.account_id) FILTER (WHERE pt.is_deposit = TRUE)  AS deposit_accounts_count,
    COUNT(a.account_id) FILTER (WHERE pt.is_deposit = FALSE) AS savings_accounts_count,
    STRING_AGG(a.account_number, ', ' ORDER BY a.opened_date DESC) AS account_numbers
FROM clients c
JOIN accounts a ON c.client_id = a.client_id
JOIN account_statuses ast ON a.status_id = ast.status_id
JOIN product_types pt ON a.product_type_id = pt.product_type_id
WHERE ast.status_code = 'open'
GROUP BY
    c.client_id,
    c.last_name, c.first_name, c.middle_name,
    c.phone
HAVING COUNT(a.account_id) > 1
ORDER BY
    total_active_accounts DESC,
    client_fio ASC;
