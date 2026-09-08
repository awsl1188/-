/* =============================================================
   NYC Yellow Taxi 2024 Q1
   OD路线与跨区域流向分析

   OD：Origin-Destination，上车区域—下车区域。
   金额指标使用total_amount，表示订单交易总额。
   ============================================================= */

USE nyc_taxi_analysis;


/* =============================================================
   1. OD路线数量及订单量分布

   中位数、P95、P99使用nearest-rank方法。
   ============================================================= */

WITH route_summary AS (
    SELECT
        pickup_location_id,
        dropoff_location_id,
        COUNT(*) AS route_order_count
    FROM fact_taxi_trip
    GROUP BY
        pickup_location_id,
        dropoff_location_id
),
ranked_routes AS (
    SELECT
        route_order_count,
        ROW_NUMBER() OVER (
            ORDER BY route_order_count
        ) AS row_number_ascending,
        COUNT(*) OVER () AS route_count
    FROM route_summary
)
SELECT
    MAX(route_count) AS od_route_count,
    MIN(route_order_count) AS minimum_route_orders,
    ROUND(AVG(route_order_count), 2) AS average_route_orders,
    MAX(
        CASE
            WHEN row_number_ascending = CEIL(route_count * 0.50)
            THEN route_order_count
        END
    ) AS median_route_orders,
    MAX(
        CASE
            WHEN row_number_ascending = CEIL(route_count * 0.95)
            THEN route_order_count
        END
    ) AS p95_route_orders,
    MAX(
        CASE
            WHEN row_number_ascending = CEIL(route_count * 0.99)
            THEN route_order_count
        END
    ) AS p99_route_orders,
    MAX(route_order_count) AS maximum_route_orders
FROM ranked_routes;


/* =============================================================
   2. 订单量最高的15条OD路线
   ============================================================= */

SELECT
    f.pickup_location_id,
    pz.zone_name AS pickup_zone,
    f.dropoff_location_id,
    dz.zone_name AS dropoff_zone,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) / NULLIF((SELECT COUNT(*) FROM dim_date), 0),
        2
    ) AS average_daily_orders,
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
INNER JOIN dim_zone AS pz
    ON f.pickup_location_id = pz.location_id
INNER JOIN dim_zone AS dz
    ON f.dropoff_location_id = dz.location_id
GROUP BY
    f.pickup_location_id,
    pz.zone_name,
    f.dropoff_location_id,
    dz.zone_name
ORDER BY order_count DESC
LIMIT 15;


/* =============================================================
   3. 同区域与跨区域订单比较
   ============================================================= */

WITH route_type_summary AS (
    SELECT
        CASE
            WHEN pickup_location_id = dropoff_location_id
            THEN '同区域订单'
            ELSE '跨区域订单'
        END AS route_type,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_transaction_amount,
        SUM(trip_distance) AS total_distance,
        SUM(trip_duration_minutes) AS total_duration_minutes
    FROM fact_taxi_trip
    GROUP BY
        CASE
            WHEN pickup_location_id = dropoff_location_id
            THEN '同区域订单'
            ELSE '跨区域订单'
        END
)
SELECT
    route_type,
    order_count,
    ROUND(order_count / SUM(order_count) OVER (), 4) AS order_share,
    ROUND(total_transaction_amount, 2) AS total_transaction_amount,
    ROUND(
        total_transaction_amount / SUM(total_transaction_amount) OVER (),
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
    ) AS average_duration_minutes
FROM route_type_summary
ORDER BY order_count DESC;


/* =============================================================
   4. 行政区之间的订单流向
   ============================================================= */

SELECT
    pz.borough AS pickup_borough,
    dz.borough AS dropoff_borough,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) / SUM(COUNT(*)) OVER (),
        4
    ) AS all_order_share,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2) AS average_duration_minutes
FROM fact_taxi_trip AS f
INNER JOIN dim_zone AS pz
    ON f.pickup_location_id = pz.location_id
INNER JOIN dim_zone AS dz
    ON f.dropoff_location_id = dz.location_id
GROUP BY
    pz.borough,
    dz.borough
ORDER BY order_count DESC;


/* =============================================================
   5. 跨行政区订单量最高的15条流向
   ============================================================= */

SELECT
    pz.borough AS pickup_borough,
    dz.borough AS dropoff_borough,
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
INNER JOIN dim_zone AS pz
    ON f.pickup_location_id = pz.location_id
INNER JOIN dim_zone AS dz
    ON f.dropoff_location_id = dz.location_id
WHERE pz.borough <> dz.borough
GROUP BY
    pz.borough,
    dz.borough
ORDER BY order_count DESC
LIMIT 15;


/* =============================================================
   6. 具体跨行政区OD路线TOP15
   ============================================================= */

SELECT
    pz.borough AS pickup_borough,
    pz.zone_name AS pickup_zone,
    dz.borough AS dropoff_borough,
    dz.zone_name AS dropoff_zone,
    COUNT(*) AS order_count,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2) AS average_duration_minutes
FROM fact_taxi_trip AS f
INNER JOIN dim_zone AS pz
    ON f.pickup_location_id = pz.location_id
INNER JOIN dim_zone AS dz
    ON f.dropoff_location_id = dz.location_id
WHERE pz.borough <> dz.borough
GROUP BY
    pz.borough,
    pz.zone_name,
    dz.borough,
    dz.zone_name
ORDER BY order_count DESC
LIMIT 15;


/* =============================================================
   7. 高价值且具有稳定订单量的OD路线

   最低订单量设为1000，避免被偶发极高金额订单主导。
   ============================================================= */

SELECT
    pz.borough AS pickup_borough,
    pz.zone_name AS pickup_zone,
    dz.borough AS dropoff_borough,
    dz.zone_name AS dropoff_zone,
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
INNER JOIN dim_zone AS pz
    ON f.pickup_location_id = pz.location_id
INNER JOIN dim_zone AS dz
    ON f.dropoff_location_id = dz.location_id
GROUP BY
    pz.borough,
    pz.zone_name,
    dz.borough,
    dz.zone_name
HAVING COUNT(*) >= 1000
ORDER BY average_order_amount DESC
LIMIT 20;


/* =============================================================
   8. JFK机场上车订单的主要目的地区域
   ============================================================= */

SELECT
    dz.borough AS dropoff_borough,
    dz.zone_name AS dropoff_zone,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) / SUM(COUNT(*)) OVER (),
        4
    ) AS jfk_order_share,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2) AS average_duration_minutes
FROM fact_taxi_trip AS f
INNER JOIN dim_zone AS pz
    ON f.pickup_location_id = pz.location_id
INNER JOIN dim_zone AS dz
    ON f.dropoff_location_id = dz.location_id
WHERE pz.zone_name = 'JFK Airport'
GROUP BY
    dz.borough,
    dz.zone_name
ORDER BY order_count DESC
LIMIT 15;


/* =============================================================
   9. LaGuardia机场上车订单的主要目的地区域
   ============================================================= */

SELECT
    dz.borough AS dropoff_borough,
    dz.zone_name AS dropoff_zone,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) / SUM(COUNT(*)) OVER (),
        4
    ) AS laguardia_order_share,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2) AS average_duration_minutes
FROM fact_taxi_trip AS f
INNER JOIN dim_zone AS pz
    ON f.pickup_location_id = pz.location_id
INNER JOIN dim_zone AS dz
    ON f.dropoff_location_id = dz.location_id
WHERE pz.zone_name = 'LaGuardia Airport'
GROUP BY
    dz.borough,
    dz.zone_name
ORDER BY order_count DESC
LIMIT 15;


/* =============================================================
   10. 机场至核心商务/旅游区域的重点路线
   ============================================================= */

SELECT
    pz.zone_name AS airport_name,
    dz.zone_name AS destination_zone,
    COUNT(*) AS order_count,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2) AS average_duration_minutes
FROM fact_taxi_trip AS f
INNER JOIN dim_zone AS pz
    ON f.pickup_location_id = pz.location_id
INNER JOIN dim_zone AS dz
    ON f.dropoff_location_id = dz.location_id
WHERE
    pz.zone_name IN ('JFK Airport', 'LaGuardia Airport')
    AND dz.zone_name IN (
        'Times Sq/Theatre District',
        'Midtown Center',
        'Midtown East',
        'Midtown North',
        'Penn Station/Madison Sq West',
        'Upper East Side North',
        'Upper East Side South',
        'Financial District North',
        'Financial District South'
    )
GROUP BY
    pz.zone_name,
    dz.zone_name
ORDER BY order_count DESC;
