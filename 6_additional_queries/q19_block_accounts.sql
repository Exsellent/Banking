-- Заблокировать счета с суммой операций за октябрь 2025 > 1_000_000 и вывести их

-- Ваш SQL код здесь


WITH suspicious AS (
    SELECT a.account_id
    FROM operations o
    JOIN accounts a ON o.account_id = a.account_id
    WHERE o.operation_date >= '2025-10-01' AND o.operation_date < '2025-11-01'
    GROUP BY a.account_id
    HAVING SUM(o.amount) > 1000000
)
SELECT block_account(s.account_id, 'Оборот за октябрь 2025 > 1 000 000 ₽')
FROM suspicious s;