/* =============================================================
   NYC Yellow Taxi 2024 Q1
   行政区、区域、机场与车辆再平衡分析

   指标口径：
   1. total_amount 表示乘客订单交易总额，不代表平台或司机净收入。
   2. 单位载客时间交易额不包含空驶、候客和司机上下线时间。
   3. 流向不平衡率仅作为车辆再平衡压力的代理变量。
   ============================================================= */

USE nyc_taxi_analysis;


/* =============================================================
   1. 各上车行政区经营情况
   ============================================================= */

SELECT
    z.borough AS pickup_borough,
    COUNT(*) AS order_count,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(SUM(f.trip_distance), 2) AS total_distance,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2) AS average_duration_minutes,
    ROUND(
        SUM(f.total_amount) / NULLIF(SUM(f.trip_distance), 0),
        2
    ) AS transaction_amount_per_mile,
    ROUND(
        SUM(f.total_amount)
        / NULLIF(SUM(f.trip_duration_minutes) / 60, 0),
        2
    ) AS transaction_amount_per_occupied_hour,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4) AS order_share,
    ROUND(
        SUM(f.total_amount) / SUM(SUM(f.total_amount)) OVER (),
        4
    ) AS transaction_amount_share
FROM fact_taxi_trip AS f
INNER JOIN dim_zone AS z
    ON f.pickup_location_id = z.location_id
GROUP BY z.borough
ORDER BY order_count DESC;


/* =============================================================
   2. 上车订单量最高的15个区域
   ============================================================= */

SELECT
    z.location_id,
    z.borough AS pickup_borough,
    z.zone_name AS pickup_zone,
    z.service_zone,
    COUNT(*) AS pickup_order_count,
    ROUND(
        COUNT(*) / NULLIF(COUNT(DISTINCT f.date_key), 0),
        2
    ) AS average_daily_pickup_orders,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2) AS average_duration_minutes,
    ROUND(
        SUM(f.total_amount) / NULLIF(SUM(f.trip_distance), 0),
        2
    ) AS transaction_amount_per_mile,
    ROUND(
        SUM(f.total_amount)
        / NULLIF(SUM(f.trip_duration_minutes) / 60, 0),
        2
    ) AS transaction_amount_per_occupied_hour
FROM fact_taxi_trip AS f
INNER JOIN dim_zone AS z
    ON f.pickup_location_id = z.location_id
GROUP BY
    z.location_id,
    z.borough,
    z.zone_name,
    z.service_zone
ORDER BY pickup_order_count DESC
LIMIT 15;


/* =============================================================
   3. 各机场上车订单经营表现
   ============================================================= */

SELECT
    z.location_id,
    z.borough AS pickup_borough,
    z.zone_name AS airport_name,
    COUNT(*) AS order_count,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2) AS average_duration_minutes,
    ROUND(
        SUM(f.total_amount) / NULLIF(SUM(f.trip_distance), 0),
        2
    ) AS transaction_amount_per_mile,
    ROUND(
        SUM(f.total_amount)
        / NULLIF(SUM(f.trip_duration_minutes) / 60, 0),
        2
    ) AS transaction_amount_per_occupied_hour
FROM fact_taxi_trip AS f
INNER JOIN dim_zone AS z
    ON f.pickup_location_id = z.location_id
WHERE z.zone_name IN (
    'JFK Airport',
    'LaGuardia Airport',
    'Newark Airport'
)
GROUP BY
    z.location_id,
    z.borough,
    z.zone_name
ORDER BY order_count DESC;


/* =============================================================
   4. 机场与非机场订单价值比较
   ============================================================= */

WITH classified_orders AS (
    SELECT
        CASE
            WHEN z.zone_name IN (
                'JFK Airport',
                'LaGuardia Airport',
                'Newark Airport'
            ) THEN '机场上车订单'
            ELSE '非机场上车订单'
        END AS order_type,
        f.total_amount,
        f.trip_distance,
        f.trip_duration_minutes
    FROM fact_taxi_trip AS f
    INNER JOIN dim_zone AS z
        ON f.pickup_location_id = z.location_id
),
class_summary AS (
    SELECT
        order_type,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_transaction_amount,
        SUM(trip_distance) AS total_distance,
        SUM(trip_duration_minutes) AS total_duration_minutes
    FROM classified_orders
    GROUP BY order_type
)
SELECT
    order_type,
    order_count,
    ROUND(order_count / SUM(order_count) OVER (), 4) AS order_share,
    ROUND(total_transaction_amount, 2) AS total_transaction_amount,
    ROUND(
        total_transaction_amount
        / SUM(total_transaction_amount) OVER (),
        4
    ) AS transaction_amount_share,
    ROUND(
        total_transaction_amount / NULLIF(order_count, 0),
        2
    ) AS average_order_amount,
    ROUND(total_distance / NULLIF(order_count, 0), 2) AS average_distance,
    ROUND(
        total_duration_minutes / NULLIF(order_count, 0),
        2
    ) AS average_duration_minutes,
    ROUND(
        total_transaction_amount / NULLIF(total_distance, 0),
        2
    ) AS transaction_amount_per_mile,
    ROUND(
        total_transaction_amount
        / NULLIF(total_duration_minutes / 60, 0),
        2
    ) AS transaction_amount_per_occupied_hour
FROM class_summary
ORDER BY order_count DESC;


/* =============================================================
   5. 机场平均订单金额相对非机场的倍数
   ============================================================= */

WITH airport_comparison AS (
    SELECT
        CASE
            WHEN z.zone_name IN (
                'JFK Airport',
                'LaGuardia Airport',
                'Newark Airport'
            ) THEN 'airport'
            ELSE 'non_airport'
        END AS order_type,
        AVG(f.total_amount) AS average_order_amount
    FROM fact_taxi_trip AS f
    INNER JOIN dim_zone AS z
        ON f.pickup_location_id = z.location_id
    GROUP BY
        CASE
            WHEN z.zone_name IN (
                'JFK Airport',
                'LaGuardia Airport',
                'Newark Airport'
            ) THEN 'airport'
            ELSE 'non_airport'
        END
)
SELECT
    ROUND(MAX(CASE WHEN order_type = 'airport'
        THEN average_order_amount END), 2) AS airport_average_order_amount,
    ROUND(MAX(CASE WHEN order_type = 'non_airport'
        THEN average_order_amount END), 2) AS non_airport_average_order_amount,
    ROUND(
        MAX(CASE WHEN order_type = 'airport'
            THEN average_order_amount END)
        / NULLIF(
            MAX(CASE WHEN order_type = 'non_airport'
                THEN average_order_amount END),
            0
        ),
        2
    ) AS airport_value_multiple
FROM airport_comparison;


/* =============================================================
   6. 形成区域流向基础指标

   正值：上车量高于下车量，存在车辆补位压力。
   负值：下车量高于上车量，存在车辆净流入。
   ============================================================= */

WITH pickup_summary AS (
    SELECT
        pickup_location_id AS location_id,
        COUNT(*) AS pickup_order_count
    FROM fact_taxi_trip
    GROUP BY pickup_location_id
),
dropoff_summary AS (
    SELECT
        dropoff_location_id AS location_id,
        COUNT(*) AS dropoff_order_count
    FROM fact_taxi_trip
    GROUP BY dropoff_location_id
)
SELECT
    z.location_id,
    z.borough,
    z.zone_name,
    COALESCE(p.pickup_order_count, 0) AS pickup_order_count,
    COALESCE(d.dropoff_order_count, 0) AS dropoff_order_count,
    COALESCE(p.pickup_order_count, 0)
        - COALESCE(d.dropoff_order_count, 0) AS net_pickup_orders,
    ROUND(
        (
            COALESCE(p.pickup_order_count, 0)
            - COALESCE(d.dropoff_order_count, 0)
        )
        / NULLIF(
            COALESCE(p.pickup_order_count, 0)
            + COALESCE(d.dropoff_order_count, 0),
            0
        ),
        4
    ) AS flow_imbalance_rate
FROM dim_zone AS z
LEFT JOIN pickup_summary AS p
    ON z.location_id = p.location_id
LEFT JOIN dropoff_summary AS d
    ON z.location_id = d.location_id
ORDER BY net_pickup_orders DESC;


/* =============================================================
   7. 潜在车辆补充区域

   规则：
   - 上下车总量不少于5000条；
   - 流向不平衡率不低于10%；
   - 按净上车订单量降序排列。
   ============================================================= */

WITH pickup_summary AS (
    SELECT
        pickup_location_id AS location_id,
        COUNT(*) AS pickup_order_count
    FROM fact_taxi_trip
    GROUP BY pickup_location_id
),
dropoff_summary AS (
    SELECT
        dropoff_location_id AS location_id,
        COUNT(*) AS dropoff_order_count
    FROM fact_taxi_trip
    GROUP BY dropoff_location_id
),
zone_flow AS (
    SELECT
        z.location_id,
        z.borough,
        z.zone_name,
        COALESCE(p.pickup_order_count, 0) AS pickup_order_count,
        COALESCE(d.dropoff_order_count, 0) AS dropoff_order_count
    FROM dim_zone AS z
    LEFT JOIN pickup_summary AS p
        ON z.location_id = p.location_id
    LEFT JOIN dropoff_summary AS d
        ON z.location_id = d.location_id
),
flow_metrics AS (
    SELECT
        location_id,
        borough,
        zone_name,
        pickup_order_count,
        dropoff_order_count,
        pickup_order_count - dropoff_order_count AS net_pickup_orders,
        (pickup_order_count - dropoff_order_count)
            / NULLIF(pickup_order_count + dropoff_order_count, 0)
            AS flow_imbalance_rate
    FROM zone_flow
)
SELECT
    location_id,
    borough,
    zone_name,
    pickup_order_count,
    dropoff_order_count,
    net_pickup_orders,
    ROUND(flow_imbalance_rate, 4) AS flow_imbalance_rate
FROM flow_metrics
WHERE
    pickup_order_count + dropoff_order_count >= 5000
    AND flow_imbalance_rate >= 0.10
ORDER BY net_pickup_orders DESC
LIMIT 15;


/* =============================================================
   8. 潜在车辆流出区域

   规则：
   - 上下车总量不少于5000条；
   - 流向不平衡率不高于-10%；
   - 按净上车订单量升序排列。
   ============================================================= */

WITH pickup_summary AS (
    SELECT
        pickup_location_id AS location_id,
        COUNT(*) AS pickup_order_count
    FROM fact_taxi_trip
    GROUP BY pickup_location_id
),
dropoff_summary AS (
    SELECT
        dropoff_location_id AS location_id,
        COUNT(*) AS dropoff_order_count
    FROM fact_taxi_trip
    GROUP BY dropoff_location_id
),
zone_flow AS (
    SELECT
        z.location_id,
        z.borough,
        z.zone_name,
        COALESCE(p.pickup_order_count, 0) AS pickup_order_count,
        COALESCE(d.dropoff_order_count, 0) AS dropoff_order_count
    FROM dim_zone AS z
    LEFT JOIN pickup_summary AS p
        ON z.location_id = p.location_id
    LEFT JOIN dropoff_summary AS d
        ON z.location_id = d.location_id
),
flow_metrics AS (
    SELECT
        location_id,
        borough,
        zone_name,
        pickup_order_count,
        dropoff_order_count,
        pickup_order_count - dropoff_order_count AS net_pickup_orders,
        (pickup_order_count - dropoff_order_count)
            / NULLIF(pickup_order_count + dropoff_order_count, 0)
            AS flow_imbalance_rate
    FROM zone_flow
)
SELECT
    location_id,
    borough,
    zone_name,
    pickup_order_count,
    dropoff_order_count,
    net_pickup_orders,
    ROUND(flow_imbalance_rate, 4) AS flow_imbalance_rate
FROM flow_metrics
WHERE
    pickup_order_count + dropoff_order_count >= 5000
    AND flow_imbalance_rate <= -0.10
ORDER BY net_pickup_orders ASC
LIMIT 15;

