/* =============================================================
   NYC Yellow Taxi 2024 Q1
   Power BI / Tableau 业务分析视图

   使用方法：
   1. 在PyCharm Query Console中选择nyc_taxi_analysis数据库。
   2. 以脚本方式执行本文件。
   3. 视图不保存重复数据，只保存查询逻辑。

   重要口径：
   - total_amount：乘客支付的订单交易总额，并非平台或司机净收入。
   - 单位载客小时交易额：只计算载客时间，不含候客和空驶时间。
   - 本项目覆盖2024年第一季度，共91个自然日。
   ============================================================= */

USE nyc_taxi_analysis;


/* =============================================================
   一、删除旧视图

   先删除引用其他视图的对象，再删除基础视图。
   这样可以安全地重复执行本文件。
   ============================================================= */

DROP VIEW IF EXISTS vw_zone_flow;
DROP VIEW IF EXISTS vw_zone_dropoff_summary;
DROP VIEW IF EXISTS vw_zone_pickup_summary;
DROP VIEW IF EXISTS vw_airport_business;
DROP VIEW IF EXISTS vw_od_route_business;
DROP VIEW IF EXISTS vw_zone_business;
DROP VIEW IF EXISTS vw_time_period_business;
DROP VIEW IF EXISTS vw_weekday_business;
DROP VIEW IF EXISTS vw_monthly_business;
DROP VIEW IF EXISTS vw_kpi_overview;


/* =============================================================
   二、第一季度核心经营指标

   该视图只有一行，适合制作Power BI KPI卡片。
   ============================================================= */

CREATE VIEW vw_kpi_overview AS
SELECT
    COUNT(*) AS order_count,
    ROUND(SUM(total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(total_amount), 2) AS average_order_amount,
    ROUND(SUM(trip_distance), 2) AS total_distance,
    ROUND(AVG(trip_distance), 2) AS average_distance,
    ROUND(SUM(trip_duration_minutes), 2) AS total_duration_minutes,
    ROUND(AVG(trip_duration_minutes), 2) AS average_duration_minutes,
    ROUND(AVG(average_speed_mph), 2) AS average_speed_mph,
    ROUND(
        SUM(total_amount) / NULLIF(SUM(trip_distance), 0),
        2
    ) AS transaction_amount_per_mile,
    ROUND(
        SUM(total_amount)
        / NULLIF(SUM(trip_duration_minutes) / 60, 0),
        2
    ) AS transaction_amount_per_occupied_hour,
    ROUND(SUM(COALESCE(tip_amount, 0)), 2) AS total_tip_amount,
    ROUND(
        SUM(COALESCE(tip_amount, 0))
        / NULLIF(SUM(fare_amount), 0),
        4
    ) AS overall_tip_rate,
    MIN(pickup_datetime) AS earliest_pickup_datetime,
    MAX(pickup_datetime) AS latest_pickup_datetime
FROM fact_taxi_trip;


/* =============================================================
   三、月度经营视图
   ============================================================= */

CREATE VIEW vw_monthly_business AS
SELECT
    d.year_number,
    d.quarter_number,
    d.month_number,
    d.month_name,
    COUNT(*) AS order_count,
    COUNT(DISTINCT d.full_date) AS observed_days,
    ROUND(COUNT(*) / COUNT(DISTINCT d.full_date), 2)
        AS average_daily_orders,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(SUM(f.total_amount) / COUNT(DISTINCT d.full_date), 2)
        AS average_daily_transaction_amount,
    ROUND(SUM(f.trip_distance), 2) AS total_distance,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2)
        AS average_duration_minutes,
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
INNER JOIN dim_date AS d
    ON f.date_key = d.date_key
GROUP BY
    d.year_number,
    d.quarter_number,
    d.month_number,
    d.month_name;


/* =============================================================
   四、星期经营视图

   weekday_number：0=星期一，6=星期日。
   ============================================================= */

CREATE VIEW vw_weekday_business AS
SELECT
    d.weekday_number,
    d.weekday_name,
    d.is_weekend,
    COUNT(*) AS order_count,
    COUNT(DISTINCT d.full_date) AS observed_days,
    ROUND(COUNT(*) / COUNT(DISTINCT d.full_date), 2)
        AS average_daily_orders,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(SUM(f.total_amount) / COUNT(DISTINCT d.full_date), 2)
        AS average_daily_transaction_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2)
        AS average_duration_minutes,
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
INNER JOIN dim_date AS d
    ON f.date_key = d.date_key
GROUP BY
    d.weekday_number,
    d.weekday_name,
    d.is_weekend;


/* =============================================================
   五、上车时段经营视图
   ============================================================= */

CREATE VIEW vw_time_period_business AS
SELECT
    t.time_period,
    t.period_order,
    COUNT(DISTINCT t.hour_key) AS hours_in_period,
    COUNT(*) AS order_count,
    COUNT(DISTINCT f.date_key) AS observed_days,
    ROUND(COUNT(*) / COUNT(DISTINCT f.date_key), 2)
        AS average_daily_orders,
    ROUND(
        COUNT(*)
        / COUNT(DISTINCT f.date_key)
        / COUNT(DISTINCT t.hour_key),
        2
    ) AS average_orders_per_clock_hour,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2)
        AS average_duration_minutes,
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
INNER JOIN dim_time_period AS t
    ON f.pickup_hour = t.hour_key
GROUP BY
    t.time_period,
    t.period_order;


/* =============================================================
   六、上车区域经营视图

   average_daily_pickup_orders统一除以91天，使不同区域可比较。
   ============================================================= */

CREATE VIEW vw_zone_business AS
SELECT
    z.location_id,
    z.borough AS pickup_borough,
    z.zone_name AS pickup_zone,
    z.service_zone AS pickup_service_zone,
    COUNT(*) AS pickup_order_count,
    ROUND(COUNT(*) / 91.0, 2) AS average_daily_pickup_orders,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(SUM(f.trip_distance), 2) AS total_distance,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2)
        AS average_duration_minutes,
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
    z.service_zone;


/* =============================================================
   七、区域流向辅助视图

   将上车量和下车量分别聚合，避免在最终视图中重复扫描逻辑。
   ============================================================= */

CREATE VIEW vw_zone_pickup_summary AS
SELECT
    pickup_location_id AS location_id,
    COUNT(*) AS pickup_order_count
FROM fact_taxi_trip
GROUP BY pickup_location_id;


CREATE VIEW vw_zone_dropoff_summary AS
SELECT
    dropoff_location_id AS location_id,
    COUNT(*) AS dropoff_order_count
FROM fact_taxi_trip
GROUP BY dropoff_location_id;


/* =============================================================
   八、区域车辆流向不平衡视图

   net_pickup_orders = 上车量 - 下车量
   正值：上车量更高，可能存在补充车辆需求。
   负值：下车量更高，可能形成车辆流入。
   该指标只是车辆再平衡压力的代理变量。
   ============================================================= */

CREATE VIEW vw_zone_flow AS
SELECT
    z.location_id,
    z.borough,
    z.zone_name,
    z.service_zone,
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
    ) AS flow_imbalance_rate,
    CASE
        WHEN COALESCE(p.pickup_order_count, 0)
             - COALESCE(d.dropoff_order_count, 0) > 0
            THEN '上车量高于下车量'
        WHEN COALESCE(p.pickup_order_count, 0)
             - COALESCE(d.dropoff_order_count, 0) < 0
            THEN '下车量高于上车量'
        ELSE '基本平衡'
    END AS flow_direction
FROM dim_zone AS z
LEFT JOIN vw_zone_pickup_summary AS p
    ON z.location_id = p.location_id
LEFT JOIN vw_zone_dropoff_summary AS d
    ON z.location_id = d.location_id;


/* =============================================================
   九、OD路线经营视图

   每行代表一条“上车区域—下车区域”路线。
   is_same_zone：1表示上、下车区域相同。
   is_cross_borough：1表示跨行政区。
   ============================================================= */

CREATE VIEW vw_od_route_business AS
SELECT
    f.pickup_location_id,
    pz.borough AS pickup_borough,
    pz.zone_name AS pickup_zone,
    f.dropoff_location_id,
    dz.borough AS dropoff_borough,
    dz.zone_name AS dropoff_zone,
    CASE
        WHEN f.pickup_location_id = f.dropoff_location_id THEN 1
        ELSE 0
    END AS is_same_zone,
    CASE
        WHEN pz.borough <> dz.borough THEN 1
        ELSE 0
    END AS is_cross_borough,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) / 91.0, 2) AS average_daily_orders,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2)
        AS average_duration_minutes,
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
    pz.borough,
    pz.zone_name,
    f.dropoff_location_id,
    dz.borough,
    dz.zone_name;


/* =============================================================
   十、机场上车订单经营视图
   ============================================================= */

CREATE VIEW vw_airport_business AS
SELECT
    z.location_id,
    z.borough AS pickup_borough,
    z.zone_name AS airport_name,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) / 91.0, 2) AS average_daily_orders,
    ROUND(SUM(f.total_amount), 2) AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2) AS average_order_amount,
    ROUND(AVG(f.trip_distance), 2) AS average_distance,
    ROUND(AVG(f.trip_duration_minutes), 2)
        AS average_duration_minutes,
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
    z.zone_name;


/* =============================================================
   十一、创建结果验证
   ============================================================= */

SELECT
    table_name AS created_view
FROM information_schema.views
WHERE table_schema = DATABASE()
  AND table_name IN (
      'vw_kpi_overview',
      'vw_monthly_business',
      'vw_weekday_business',
      'vw_time_period_business',
      'vw_zone_business',
      'vw_zone_pickup_summary',
      'vw_zone_dropoff_summary',
      'vw_zone_flow',
      'vw_od_route_business',
      'vw_airport_business'
  )
ORDER BY table_name;


/* =============================================================
   十二、抽样验证

   执行后应得到：
   - KPI：1行
   - 月度：3行
   - 星期：7行
   - 时段：5行
   - 机场：通常3行
   ============================================================= */

SELECT * FROM vw_kpi_overview;

SELECT *
FROM vw_monthly_business
ORDER BY month_number;

SELECT *
FROM vw_weekday_business
ORDER BY weekday_number;

SELECT *
FROM vw_time_period_business
ORDER BY period_order;

SELECT *
FROM vw_airport_business
ORDER BY order_count DESC;

SELECT *
FROM vw_zone_business
ORDER BY pickup_order_count DESC
LIMIT 15;

SELECT *
FROM vw_zone_flow
ORDER BY flow_imbalance_rate DESC
LIMIT 15;

SELECT *
FROM vw_od_route_business
ORDER BY order_count DESC
LIMIT 15;










USE nyc_taxi_analysis;

SELECT
    COUNT(*) AS business_view_count
FROM information_schema.views
WHERE table_schema = 'nyc_taxi_analysis'
  AND table_name IN (
      'vw_kpi_overview',
      'vw_monthly_business',
      'vw_weekday_business',
      'vw_time_period_business',
      'vw_zone_business',
      'vw_zone_pickup_summary',
      'vw_zone_dropoff_summary',
      'vw_zone_flow',
      'vw_od_route_business',
      'vw_airport_business'
  );


SELECT
    table_name
FROM information_schema.views
WHERE table_schema = 'nyc_taxi_analysis'
ORDER BY table_name;