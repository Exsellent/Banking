-- Сумма начисленных процентов на конкретный счёт за период

-- Ваш SQL код здесь

WITH params AS (
    SELECT
        1                     AS account_id,
        '2024-01-01'::date   AS period_start,
        '2024-12-31'::date   AS period_end
),

interest_data AS (
    SELECT
        a.account_number,
        pt.name AS product_name,
        o.operation_date,
        o.amount AS interest_amount,
        o.balance_after
    FROM operations o
    JOIN accounts a        ON o.account_id = a.account_id
    JOIN product_types pt  ON a.product_type_id = pt.product_type_id
    JOIN operation_types ot ON o.operation_type_id = ot.operation_type_id
    CROSS JOIN params p
    WHERE o.account_id = p.account_id
      AND ot.code = 'interest_accrual'
      AND o.operation_date >= p.period_start
      AND o.operation_date <= p.period_end
)

SELECT
    account_number,
    product_name,
    COUNT(interest_amount)                                   AS accruals_count,
    COALESCE(SUM(interest_amount), 0.00)                     AS total_interest_accrued,
    to_char(p.period_start, 'DD.MM.YYYY') || ' – ' ||
    to_char(p.period_end,   'DD.MM.YYYY')                    AS period,
    CASE
        WHEN COUNT(interest_amount) = 0 THEN 'Начислений не было'
        ELSE 'Начислено процентов'
    END                                                      AS status
FROM interest_data
CROSS JOIN params p
GROUP BY account_number, product_name, p.period_start, p.period_end
ORDER BY total_interest_accrued DESC;