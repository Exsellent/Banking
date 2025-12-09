-- Клиенты с суммой снятий свыше 1000000 руб. за месяц

-- Ваш SQL код здесь

WITH client_withdrawals AS (
    SELECT
        c.client_id,
        c.last_name,
        c.first_name,
        SUM(o.amount) AS total_withdrawals_rub,
        COUNT(o.operation_id) AS withdrawals_count,
        COUNT(*) FILTER (WHERE o.amount > 100000) AS large_withdrawals_count
    FROM clients c
    JOIN accounts a ON c.client_id = a.client_id
    JOIN product_types pt ON a.product_type_id = pt.product_type_id
    JOIN operations o ON a.account_id = o.account_id
    JOIN operation_types ot ON o.operation_type_id = ot.operation_type_id
    WHERE pt.is_deposit = FALSE              -- накопительные
      AND ot.code = 'withdraw'               -- только снятия
      AND o.operation_date >= CURRENT_DATE - INTERVAL '30 days'
      AND a.currency = 'RUB'
    GROUP BY c.client_id, c.last_name, c.first_name
)
SELECT *,
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
