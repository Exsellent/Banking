-- Для каждого клиента определить наиболее прибыльный продукт

-- Ваш SQL код здесь


WITH interest_by_product AS (
    SELECT
        c.client_id,
        c.last_name || ' ' || c.first_name ||
            COALESCE(' ' || c.middle_name, '') AS client_fio,
        c.phone,
        pt.product_type_id,
        pt.name AS product_name,
        CASE WHEN pt.is_deposit THEN 'Срочный вклад' ELSE 'Накопительный счёт' END AS product_type,
        COALESCE(SUM(o.amount), 0.00) AS total_interest
    FROM clients c
    JOIN accounts a ON c.client_id = a.client_id
    JOIN product_types pt ON a.product_type_id = pt.product_type_id
    LEFT JOIN operations o ON a.account_id = o.account_id
        AND o.operation_type_id = 3
    GROUP BY
        c.client_id, c.last_name, c.first_name, c.middle_name, c.phone,
        pt.product_type_id, pt.name, pt.is_deposit
),

ranked AS (
    SELECT
        client_id,
        client_fio,
        phone,
        product_name,
        product_type,
        total_interest,
        ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY total_interest DESC) AS rn,
        RANK() OVER (PARTITION BY client_id ORDER BY total_interest DESC) AS rank_pos
    FROM interest_by_product
)

SELECT
    client_fio,
    phone,
    product_name AS most_profitable_product,
    product_type,
    ROUND(total_interest, 2) AS total_interest_accrued,
    CASE
        WHEN total_interest = 0 THEN 'Нет начислений'
        ELSE 'Прибыльный продукт'
    END AS status
FROM ranked
WHERE rn = 1
ORDER BY total_interest DESC, client_fio;