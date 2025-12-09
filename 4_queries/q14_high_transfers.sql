-- Клиенты с переводами, значительно превышающими средние значения по системе

-- Ваш SQL код здесь


WITH params AS (
    SELECT
        5.0 AS multiplier_threshold
),

system_avg AS (
    SELECT
        AVG(o.amount)        AS avg_withdrawal_amount,
        COUNT(o.operation_id) / NULLIF(COUNT(DISTINCT a.client_id), 0)::numeric
                             AS avg_withdrawals_per_client
    FROM operations o
    JOIN accounts a ON o.account_id = a.account_id
    JOIN account_statuses ast ON a.status_id = ast.status_id
    WHERE o.operation_type_id = 2
      AND ast.status_code = 'open'
),

client_withdrawals AS (
    SELECT
        c.client_id,
        c.last_name || ' ' || c.first_name ||
            COALESCE(' ' || c.middle_name, '') AS client_fio,
        c.phone,
        COUNT(o.operation_id)                  AS withdrawals_count,
        SUM(o.amount)                          AS total_withdrawn,
        MAX(o.amount)                          AS max_single_withdrawal,
        MAX(o.operation_date)                  AS last_withdrawal_date
    FROM clients c
    JOIN accounts a ON c.client_id = a.client_id
    JOIN account_statuses ast ON a.status_id = ast.status_id
    JOIN operations o ON a.account_id = o.account_id
    WHERE o.operation_type_id = 2
      AND ast.status_code = 'open'
    GROUP BY c.client_id, c.last_name, c.first_name, c.middle_name, c.phone
)

SELECT
    client_fio,
    phone,
    withdrawals_count,
    ROUND(total_withdrawn, 2)                     AS total_withdrawn,
    ROUND(max_single_withdrawal, 2)               AS largest_withdrawal,
    to_char(last_withdrawal_date, 'DD.MM.YYYY')   AS last_withdrawal,
    ROUND(total_withdrawn / NULLIF(sa.avg_withdrawal_amount, 0), 2)
                                                  AS times_above_avg_amount,
    ROUND(
        withdrawals_count::numeric / NULLIF(sa.avg_withdrawals_per_client, 0), 2
    )                                             AS times_above_avg_count,
    'ВЫСОКАЯ АКТИВНОСТЬ ПО СНЯТИЯМ'               AS risk_flag
FROM client_withdrawals cw
CROSS JOIN system_avg sa
CROSS JOIN params p
WHERE total_withdrawn > p.multiplier_threshold * sa.avg_withdrawal_amount
   OR withdrawals_count > p.multiplier_threshold * sa.avg_withdrawals_per_client
ORDER BY
    total_withdrawn DESC,
    times_above_avg_amount DESC;
