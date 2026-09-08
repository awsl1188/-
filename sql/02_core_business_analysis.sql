/* =============================================================
   NYC Yellow Taxi 2024 Q1
   第一组：核心经营指标分析
   ============================================================= */

USE nyc_taxi_analysis;


/* =============================================================
   1. 整体经营概况
   ============================================================= */

SELECT
    COUNT(*) AS order_count,

    ROUND(
        SUM(total_amount),
        2
    ) AS total_transaction_amount,

    ROUND(
        AVG(total_amount),
        2
    ) AS average_order_amount,

    ROUND(
        SUM(trip_distance),
        2
    ) AS total_distance,

    ROUND(
        AVG(trip_distance),
        2
    ) AS average_distance,

    ROUND(
        SUM(trip_duration_minutes),
        2
    ) AS total_duration_minutes,

    ROUND(
        AVG(trip_duration_minutes),
        2
    ) AS average_duration_minutes,

    ROUND(
        SUM(total_amount)
        / NULLIF(SUM(trip_distance), 0),
        2
    ) AS transaction_amount_per_mile,

    ROUND(
        SUM(total_amount)
        / NULLIF(
            SUM(trip_duration_minutes) / 60,
            0
        ),
        2
    ) AS transaction_amount_per_occupied_hour

FROM fact_taxi_trip;


/* =============================================================
   2. 月度经营指标
   ============================================================= */

WITH monthly_summary AS (
    SELECT
        d.month_number,
        d.month_name,

        COUNT(*) AS order_count,

        COUNT(
            DISTINCT f.date_key
        ) AS observed_days,

        SUM(
            f.total_amount
        ) AS total_transaction_amount,

        SUM(
            f.trip_distance
        ) AS total_distance,

        SUM(
            f.trip_duration_minutes
        ) AS total_duration_minutes

    FROM fact_taxi_trip AS f

    INNER JOIN dim_date AS d
        ON f.date_key = d.date_key

    GROUP BY
        d.month_number,
        d.month_name
),

overall_summary AS (
    SELECT
        SUM(order_count) AS all_orders,

        SUM(
            total_transaction_amount
        ) AS all_transaction_amount

    FROM monthly_summary
)

SELECT
    m.month_number,
    m.month_name,
    m.observed_days,
    m.order_count,

    ROUND(
        m.order_count
        / NULLIF(m.observed_days, 0),
        2
    ) AS average_daily_orders,

    ROUND(
        m.total_transaction_amount,
        2
    ) AS total_transaction_amount,

    ROUND(
        m.total_transaction_amount
        / NULLIF(m.observed_days, 0),
        2
    ) AS average_daily_transaction_amount,

    ROUND(
        m.total_transaction_amount
        / NULLIF(m.order_count, 0),
        2
    ) AS average_order_amount,

    ROUND(
        m.total_distance
        / NULLIF(m.order_count, 0),
        2
    ) AS average_distance,

    ROUND(
        m.total_duration_minutes
        / NULLIF(m.order_count, 0),
        2
    ) AS average_duration_minutes,

    ROUND(
        m.total_transaction_amount
        / NULLIF(m.total_distance, 0),
        2
    ) AS transaction_amount_per_mile,

    ROUND(
        m.total_transaction_amount
        / NULLIF(
            m.total_duration_minutes / 60,
            0
        ),
        2
    ) AS transaction_amount_per_occupied_hour,

    ROUND(
        m.order_count
        / NULLIF(o.all_orders, 0),
        4
    ) AS order_share,

    ROUND(
        m.total_transaction_amount
        / NULLIF(
            o.all_transaction_amount,
            0
        ),
        4
    ) AS transaction_amount_share

FROM monthly_summary AS m

CROSS JOIN overall_summary AS o

ORDER BY
    m.month_number;


/* =============================================================
   3. 1月至3月日均指标增长率
   ============================================================= */

WITH monthly_daily AS (
    SELECT
        d.month_number,

        COUNT(*) / COUNT(
            DISTINCT f.date_key
        ) AS average_daily_orders,

        SUM(f.total_amount) / COUNT(
            DISTINCT f.date_key
        ) AS average_daily_transaction_amount

    FROM fact_taxi_trip AS f

    INNER JOIN dim_date AS d
        ON f.date_key = d.date_key

    GROUP BY
        d.month_number
),

january_march AS (
    SELECT
        MAX(
            CASE
                WHEN month_number = 1
                THEN average_daily_orders
            END
        ) AS january_daily_orders,

        MAX(
            CASE
                WHEN month_number = 3
                THEN average_daily_orders
            END
        ) AS march_daily_orders,

        MAX(
            CASE
                WHEN month_number = 1
                THEN average_daily_transaction_amount
            END
        ) AS january_daily_amount,

        MAX(
            CASE
                WHEN month_number = 3
                THEN average_daily_transaction_amount
            END
        ) AS march_daily_amount

    FROM monthly_daily
)

SELECT
    ROUND(
        january_daily_orders,
        2
    ) AS january_daily_orders,

    ROUND(
        march_daily_orders,
        2
    ) AS march_daily_orders,

    ROUND(
        (
            march_daily_orders
            / NULLIF(january_daily_orders, 0)
            - 1
        ) * 100,
        2
    ) AS daily_order_growth_percent,

    ROUND(
        january_daily_amount,
        2
    ) AS january_daily_amount,

    ROUND(
        march_daily_amount,
        2
    ) AS march_daily_amount,

    ROUND(
        (
            march_daily_amount
            / NULLIF(january_daily_amount, 0)
            - 1
        ) * 100,
        2
    ) AS daily_amount_growth_percent

FROM january_march;


/* =============================================================
   4. 星期日均经营指标
   ============================================================= */

WITH weekday_summary AS (
    SELECT
        d.weekday_number,
        d.weekday_name,

        COUNT(
            DISTINCT f.date_key
        ) AS number_of_days,

        COUNT(*) AS order_count,

        SUM(
            f.total_amount
        ) AS total_transaction_amount,

        SUM(
            f.trip_distance
        ) AS total_distance,

        SUM(
            f.trip_duration_minutes
        ) AS total_duration_minutes

    FROM fact_taxi_trip AS f

    INNER JOIN dim_date AS d
        ON f.date_key = d.date_key

    GROUP BY
        d.weekday_number,
        d.weekday_name
)

SELECT
    weekday_number,
    weekday_name,
    number_of_days,
    order_count,

    ROUND(
        order_count
        / NULLIF(number_of_days, 0),
        2
    ) AS average_daily_orders,

    ROUND(
        total_transaction_amount,
        2
    ) AS total_transaction_amount,

    ROUND(
        total_transaction_amount
        / NULLIF(number_of_days, 0),
        2
    ) AS average_daily_transaction_amount,

    ROUND(
        total_transaction_amount
        / NULLIF(order_count, 0),
        2
    ) AS average_order_amount,

    ROUND(
        total_distance
        / NULLIF(order_count, 0),
        2
    ) AS average_distance,

    ROUND(
        total_duration_minutes
        / NULLIF(order_count, 0),
        2
    ) AS average_duration_minutes,

    ROUND(
        total_transaction_amount
        / NULLIF(total_distance, 0),
        2
    ) AS transaction_amount_per_mile,

    ROUND(
        total_transaction_amount
        / NULLIF(
            total_duration_minutes / 60,
            0
        ),
        2
    ) AS transaction_amount_per_occupied_hour

FROM weekday_summary

ORDER BY
    weekday_number;


/* =============================================================
   5. 时段需求强度
   ============================================================= */

WITH time_period_summary AS (
    SELECT
        t.period_order,
        t.time_period,

        COUNT(
            DISTINCT f.date_key
        ) AS number_of_days,

        COUNT(
            DISTINCT t.hour_key
        ) AS hours_in_period,

        COUNT(*) AS order_count,

        SUM(
            f.total_amount
        ) AS total_transaction_amount,

        SUM(
            f.trip_distance
        ) AS total_distance,

        SUM(
            f.trip_duration_minutes
        ) AS total_duration_minutes

    FROM fact_taxi_trip AS f

    INNER JOIN dim_time_period AS t
        ON f.pickup_hour = t.hour_key

    GROUP BY
        t.period_order,
        t.time_period
)

SELECT
    period_order,
    time_period,
    number_of_days,
    hours_in_period,
    order_count,

    ROUND(
        order_count
        / NULLIF(number_of_days, 0),
        2
    ) AS average_daily_orders,

    ROUND(
        order_count
        / NULLIF(
            number_of_days
            * hours_in_period,
            0
        ),
        2
    ) AS average_orders_per_clock_hour,

    ROUND(
        total_transaction_amount,
        2
    ) AS total_transaction_amount,

    ROUND(
        total_transaction_amount
        / NULLIF(
            number_of_days
            * hours_in_period,
            0
        ),
        2
    ) AS average_transaction_amount_per_clock_hour,

    ROUND(
        total_transaction_amount
        / NULLIF(order_count, 0),
        2
    ) AS average_order_amount,

    ROUND(
        total_distance
        / NULLIF(order_count, 0),
        2
    ) AS average_distance,

    ROUND(
        total_duration_minutes
        / NULLIF(order_count, 0),
        2
    ) AS average_duration_minutes

FROM time_period_summary

ORDER BY
    period_order;