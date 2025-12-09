-- Продукты, по которым ставка изменялась хотя бы раз за последний год

-- Ваш SQL код здесь


WITH rate_changes AS (
    SELECT
        pt.product_type_id,
        pt.name AS product_name,
        CASE WHEN pt.is_deposit THEN 'Срочный вклад' ELSE 'Накопительный счёт' END AS product_type,
        irh.rate_percent,
        irh.effective_from,
        irh.effective_to,
        FIRST_VALUE(irh.rate_percent) OVER (
            PARTITION BY pt.product_type_id
            ORDER BY irh.effective_from
        ) AS initial_rate_last_year
    FROM product_types pt
    JOIN interest_rate_history irh ON irh.product_type_id = pt.product_type_id
    WHERE irh.effective_from >= CURRENT_DATE - INTERVAL '365 days'
),

agg AS (
    SELECT
        product_type_id,
        product_name,
        product_type,
        COUNT(*) AS changes_count,
        MIN(effective_from) AS first_change_date,
        MAX(effective_from) AS last_change_date,
        MIN(initial_rate_last_year) AS initial_rate,
        (
            SELECT rate_percent
            FROM interest_rate_history ir2
            WHERE ir2.product_type_id = r.product_type_id
              AND ir2.effective_from <= CURRENT_DATE
              AND (ir2.effective_to IS NULL OR ir2.effective_to >= CURRENT_DATE)
            ORDER BY ir2.effective_from DESC
            LIMIT 1
        ) AS current_rate
    FROM rate_changes r
    GROUP BY product_type_id, product_name, product_type
    HAVING COUNT(*) > 0
)

SELECT
    product_name,
    product_type,
    changes_count,
    to_char(first_change_date,'DD.MM.YYYY') AS first_change,
    to_char(last_change_date,'DD.MM.YYYY')  AS last_change,
    ROUND(initial_rate,2) AS rate_start_year,
    ROUND(current_rate,2) AS current_rate,
    ROUND(current_rate - initial_rate,2) AS rate_delta,
    CASE
        WHEN current_rate > initial_rate THEN 'Рост'
        WHEN current_rate < initial_rate THEN 'Падение'
        ELSE 'Без изменений'
    END AS trend,
    CURRENT_DATE - last_change_date AS days_since_last_change
FROM agg
ORDER BY changes_count DESC, last_change_date DESC;
