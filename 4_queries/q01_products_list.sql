-- Список всех активных вкладов или накопительных счетов конкретного клиента с названием продукта

-- Ваш SQL код здесь

SELECT
    a.account_id,
    a.account_number,
    pt.name AS product_name,
    CASE WHEN pt.is_deposit THEN 'Срочный вклад' ELSE 'Накопительный счёт' END AS product_type,
    a.currency,
    a.current_balance,
    a.current_rate,
    a.opened_date,
    CASE
        WHEN pt.is_deposit THEN CONCAT('Срок: ', a.deposit_term_months, ' мес.')
        ELSE 'Бессрочный'
    END AS term_info
FROM accounts a
JOIN product_types pt ON a.product_type_id = pt.product_type_id
JOIN account_statuses ast ON a.status_id = ast.status_id
WHERE ast.status_code = 'open'
  AND a.client_id = 1
ORDER BY a.opened_date DESC;
