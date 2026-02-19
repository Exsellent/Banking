-- Рейтинг продуктов по приросту активов за 90 дней

-- Ваш SQL код здесь


WITH params AS (
    SELECT
        CURRENT_DATE - INTERVAL '90 days' AS period_start,
        CURRENT_DATE                      AS period_end
),

-- Все операции за период
ops_period AS (
    SELECT
        o.account_id,
        ot.code,
        o.amount
    FROM operations o
    JOIN operation_types ot ON o.operation_type_id = ot.operation_type_id
    WHERE o.operation_date >= (SELECT period_start FROM params)
      AND o.operation_date <  (SELECT period_end   FROM params) + INTERVAL '1 day'
),

-- Баланс на начало периода (последний известный до period_start)
balance_start AS (
    SELECT DISTINCT ON (o.account_id)
        o.account_id,
        o.balance_after AS balance_at_start
    FROM operations o
    WHERE o.operation_date < (SELECT period_start FROM params)
    ORDER BY o.account_id, o.operation_date DESC
),

-- Оценочный стартовый баланс для каждого счёта
account_with_start AS (
    SELECT
        a.account_id,
        a.product_type_id,
        a.current_balance,
        COALESCE(bs.balance_at_start,
            CASE WHEN a.opened_date >= (SELECT period_start FROM params) THEN 0 ELSE a.current_balance END
        ) AS estimated_start_balance
    FROM accounts a
    LEFT JOIN balance_start bs ON a.account_id = bs.account_id
    JOIN account_statuses ast ON a.status_id = ast.status_id
    WHERE ast.status_code = 'open'
),

-- Прирост по каждому счёту
growth_per_account AS (
    SELECT
        aws.account_id,
        aws.product_type_id,
        aws.estimated_start_balance,
        aws.current_balance,
        COALESCE(SUM(CASE WHEN op.code = 'deposit' THEN op.amount ELSE 0 END), 0)          AS deposits,
        COALESCE(SUM(CASE WHEN op.code = 'withdraw' THEN op.amount ELSE 0 END), 0)         AS withdrawals,
        COALESCE(SUM(CASE WHEN op.code = 'interest_accrual' THEN op.amount ELSE 0 END), 0) AS interest,
        aws.current_balance - aws.estimated_start_balance                                 AS net_growth
    FROM account_with_start aws
    LEFT JOIN ops_period op ON aws.account_id = op.account_id
    GROUP BY aws.account_id, aws.product_type_id, aws.estimated_start_balance, aws.current_balance
)

-- Итоговый рейтинг по продуктам
SELECT
    ROW_NUMBER() OVER (ORDER BY SUM(g.net_growth) DESC) AS rank,
    pt.name AS product_name,
    CASE WHEN pt.is_deposit THEN 'Срочный вклад' ELSE 'Накопительный счёт' END AS product_type,
    COUNT(*) AS active_accounts,
    ROUND(SUM(g.deposits), 2)       AS deposits_90d,
    ROUND(SUM(g.withdrawals), 2)    AS withdrawals_90d,
    ROUND(SUM(g.interest), 2)       AS interest_earned_90d,
    ROUND(SUM(g.net_growth), 2)     AS net_growth_90d,
    ROUND(SUM(g.estimated_start_balance), 2) AS estimated_start_balance,
    CASE
        WHEN SUM(g.estimated_start_balance) > 0
        THEN ROUND(100.0 * SUM(g.net_growth) / SUM(g.estimated_start_balance), 2)
        ELSE NULL
    END AS growth_percent,
    ROUND(SUM(g.net_growth) / 90.0, 2) AS avg_daily_growth,
    CASE
        WHEN SUM(g.net_growth) > 1000000 THEN 'ВЗРЫВНОЙ РОСТ'
        WHEN SUM(g.net_growth) > 100000  THEN 'ВЫСОКИЙ ПРИРОСТ'
        WHEN SUM(g.net_growth) > 0       THEN 'Умеренный рост'
        ELSE 'Отток средств'
    END AS growth_status
FROM growth_per_account g
JOIN product_types pt ON g.product_type_id = pt.product_type_id
GROUP BY pt.product_type_id, pt.name, pt.is_deposit
ORDER BY net_growth_90d DESC;