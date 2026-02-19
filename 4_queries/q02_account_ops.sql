-- Все операции по выбранному счёту за период с названием продукта

-- Ваш SQL код здесь


SELECT o.operation_date,
       pt.name AS product_name,
       ot.name AS operation_type,
       o.amount,
       o.balance_after,
       o.description
FROM operations o
         JOIN accounts a ON o.account_id = a.account_id
         JOIN product_types pt ON a.product_type_id = pt.product_type_id
         JOIN operation_types ot ON o.operation_type_id = ot.operation_type_id
WHERE o.account_id = 2
  AND o.operation_date >= '2024-06-01'
  AND o.operation_date < '2025-01-01'
ORDER BY o.operation_date ASC;
