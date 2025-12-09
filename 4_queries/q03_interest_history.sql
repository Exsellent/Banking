-- Хронологическая история изменений процентной ставки для продуктов с активными счетами

-- Ваш SQL код здесь

SELECT
    pt.name AS product_name,
    irh.rate_percent,
    irh.effective_from AS valid_from,
    COALESCE(irh.effective_to::text, 'действует') AS valid_to
FROM interest_rate_history irh
JOIN product_types pt ON irh.product_type_id = pt.product_type_id
WHERE EXISTS (
    SELECT 1
    FROM accounts a
    JOIN account_statuses ast ON a.status_id = ast.status_id
    WHERE a.product_type_id = pt.product_type_id
      AND ast.status_code = 'open'
)
ORDER BY
    pt.name,
    irh.effective_from ASC;