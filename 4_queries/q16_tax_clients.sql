-- Клиенты с прибылью выше 250000 руб. и сумма налога 13%

-- Ваш SQL код здесь


WITH params AS (
    SELECT
        '2024-01-01'::date AS period_start,
        '2024-12-31'::date AS period_end,
        250000.00          AS tax_free_threshold,
        0.13               AS tax_rate
),

client_interest AS (
    SELECT
        c.client_id,
        c.last_name || ' ' || c.first_name ||
            COALESCE(' ' || c.middle_name, '') AS client_fio,
        c.phone,
        c.email,
        COALESCE(SUM(
            CASE WHEN a.currency = 'RUB' THEN o.amount ELSE 0 END
        ), 0) AS total_interest_rub,
        COUNT(o.operation_id) AS interest_operations_count
    FROM clients c
    JOIN accounts a ON c.client_id = a.client_id
    JOIN operations o ON a.account_id = o.account_id
    JOIN operation_types ot ON o.operation_type_id = ot.operation_type_id
    CROSS JOIN params p
    WHERE ot.code = 'interest_accrual'
      AND o.operation_date >= p.period_start
      AND o.operation_date <= p.period_end
    GROUP BY c.client_id, c.last_name, c.first_name, c.middle_name, c.phone, c.email
)

SELECT
    client_id,
    client_fio,
    phone,
    email,
    ROUND(total_interest_rub, 2)                  AS total_interest_rub,
    interest_operations_count,
    ROUND(total_interest_rub * p.tax_rate, 2)     AS tax_13_percent,
    ROUND(total_interest_rub * (1 - p.tax_rate), 2) AS profit_after_tax,
    'ОБЯЗАН УПЛАТИТЬ НДФЛ 13%'                    AS tax_status
FROM client_interest
CROSS JOIN params p
WHERE total_interest_rub > p.tax_free_threshold
ORDER BY total_interest_rub DESC;