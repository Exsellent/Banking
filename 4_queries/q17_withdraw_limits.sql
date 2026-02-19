-- Клиенты с суммой снятий свыше 1 000 000 руб. за последний календарный месяц

-- Ваш SQL код здесь
WITH client_withdrawals AS (
    SELECT
        c.client_id,
        c.last_name,
        c.first_name,
        c.middle_name,
        c.phone,
        SUM(o.amount) AS total_withdrawals_rub,
        COUNT(o.operation_id) AS withdrawals_count,
        COUNT(*) FILTER (WHERE o.amount > 100000) AS large_withdrawals_count
    FROM clients c
    JOIN accounts a
         ON a.client_id = c.client_id
    JOIN product_types pt
         ON pt.product_type_id = a.product_type_id
    JOIN operations o
         ON o.account_id = a.account_id
    JOIN operation_types ot
         ON ot.operation_type_id = o.operation_type_id
    WHERE pt.is_deposit = FALSE
      AND ot.code = 'withdraw'
      AND a.currency = 'RUB'
      AND o.operation_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
      AND o.operation_date <  DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY
        c.client_id,
        c.last_name,
        c.first_name,
        c.middle_name,
        c.phone
)
SELECT
    client_id,
    last_name || ' ' || first_name || COALESCE(' ' || middle_name, '') AS client_fio,
    phone,
    total_withdrawals_rub,
    withdrawals_count,
    large_withdrawals_count,
    CASE
        WHEN large_withdrawals_count >= 5 THEN 'Высокий'
        WHEN large_withdrawals_count >= 3 THEN 'Средний'
        WHEN large_withdrawals_count >= 1 THEN 'Низкий'
        ELSE 'Нормальный'
    END AS risk_level,
    total_withdrawals_rub - 1000000 AS excess_amount
FROM client_withdrawals
WHERE total_withdrawals_rub > 1000000
ORDER BY total_withdrawals_rub DESC;
