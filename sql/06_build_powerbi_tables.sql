/* =============================================================
   NYC Yellow Taxi 2024 Q1
   Power BI专用实体聚合表

   为什么创建实体表：
   业务视图每次查询都会重新扫描约909万条事实记录；实体聚合表
   只在创建/刷新时扫描一次，Power BI读取速度更快、连接更稳定。

   执行要求：
   1. 必须已经成功创建05文件中的业务视图。
   2. 不要一次运行整个文件；按“步骤1～步骤8”逐段执行。
   3. 每段完成后再执行下一段，尤其是OD路线表。
   ============================================================= */

USE nyc_taxi_analysis;


/* =============================================================
   步骤0：检查业务视图是否完整
   正常结果应为10。
   ============================================================= */

SELECT COUNT(*) AS business_view_count
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
  );


/* =============================================================
   步骤1：核心KPI表（预计1行）
   ============================================================= */

DROP TABLE IF EXISTS pbi_kpi_overview;

CREATE TABLE pbi_kpi_overview AS
SELECT *
FROM vw_kpi_overview;


/* =============================================================
   步骤2：月度经营表（预计3行）
   ============================================================= */

DROP TABLE IF EXISTS pbi_monthly_business;

CREATE TABLE pbi_monthly_business AS
SELECT *
FROM vw_monthly_business;

ALTER TABLE pbi_monthly_business
    ADD PRIMARY KEY (year_number, month_number);


/* =============================================================
   步骤3：星期经营表（预计7行）
   ============================================================= */

DROP TABLE IF EXISTS pbi_weekday_business;

CREATE TABLE pbi_weekday_business AS
SELECT *
FROM vw_weekday_business;

ALTER TABLE pbi_weekday_business
    ADD PRIMARY KEY (weekday_number);


/* =============================================================
   步骤4：时段经营表（预计5行）
   ============================================================= */

DROP TABLE IF EXISTS pbi_time_period_business;

CREATE TABLE pbi_time_period_business AS
SELECT *
FROM vw_time_period_business;

ALTER TABLE pbi_time_period_business
    ADD PRIMARY KEY (period_order);


/* =============================================================
   步骤5：区域经营表（预计约265行）
   ============================================================= */

# DROP TABLE IF EXISTS pbi_zone_business;

CREATE TABLE pbi_zone_business AS
SELECT *
FROM vw_zone_business;

ALTER TABLE pbi_zone_business
    ADD PRIMARY KEY (location_id),
    ADD INDEX idx_pbi_zone_borough (pickup_borough),
    ADD INDEX idx_pbi_zone_orders (pickup_order_count);


/* =============================================================
   步骤6：区域流向不平衡表（预计约265行）-未执行
   ============================================================= */

# DROP TABLE IF EXISTS pbi_zone_flow;
#
# CREATE TABLE pbi_zone_flow AS
# SELECT *
# FROM vw_zone_flow;
#
# ALTER TABLE pbi_zone_flow
#     ADD PRIMARY KEY (location_id),
#     ADD INDEX idx_pbi_flow_borough (borough),
#     ADD INDEX idx_pbi_flow_rate (flow_imbalance_rate);


/* =============================================================
   步骤7：OD路线经营表（预计35,595行，执行时间最长）--未执行

   数据量仍然很小，Power BI可直接导入全部路线。
   ============================================================= */

# DROP TABLE IF EXISTS pbi_od_route_business;
#
# CREATE TABLE pbi_od_route_business AS
# SELECT *
# FROM vw_od_route_business;
#
# ALTER TABLE pbi_od_route_business
#     ADD PRIMARY KEY (pickup_location_id, dropoff_location_id),
#     ADD INDEX idx_pbi_od_orders (order_count),
#     ADD INDEX idx_pbi_od_pickup_borough (pickup_borough),
#     ADD INDEX idx_pbi_od_dropoff_borough (dropoff_borough);


/* =============================================================
   步骤8：机场经营表（预计3行）
   ============================================================= */

DROP TABLE IF EXISTS pbi_airport_business;

CREATE TABLE pbi_airport_business AS
SELECT *
FROM vw_airport_business;

ALTER TABLE pbi_airport_business
    ADD PRIMARY KEY (location_id);


/* =============================================================
   步骤9：检查Power BI实体表

   该段只读取小型聚合表，可以一次执行。
   ============================================================= */

# SELECT 'pbi_kpi_overview' AS table_name,
#        COUNT(*) AS row_count
# FROM pbi_kpi_overview
# UNION ALL
# SELECT 'pbi_monthly_business', COUNT(*)
# FROM pbi_monthly_business
# UNION ALL
# SELECT 'pbi_weekday_business', COUNT(*)
# FROM pbi_weekday_business
# UNION ALL
# SELECT 'pbi_time_period_business', COUNT(*)
# FROM pbi_time_period_business
# UNION ALL
# SELECT 'pbi_zone_business', COUNT(*)
# FROM pbi_zone_business
# UNION ALL
# SELECT 'pbi_zone_flow', COUNT(*)
# FROM pbi_zone_flow
# UNION ALL
# SELECT 'pbi_od_route_business', COUNT(*)
# FROM pbi_od_route_business
# UNION ALL
# SELECT 'pbi_airport_business', COUNT(*)
# FROM pbi_airport_business;



/* =============================================================
   步骤9：检查Power BI实体表-----修改版
   ============================================================= */
#
# USE nyc_taxi_analysis;
#
# SELECT 'pbi_kpi_overview' AS table_name,
#        COUNT(*) AS row_count
# FROM pbi_kpi_overview
#
# UNION ALL
#
# SELECT 'pbi_monthly_business',
#        COUNT(*)
# FROM pbi_monthly_business
#
# UNION ALL
#
# SELECT 'pbi_weekday_business',
#        COUNT(*)
# FROM pbi_weekday_business
#
# UNION ALL
#
# SELECT 'pbi_time_period_business',
#        COUNT(*)
# FROM pbi_time_period_business
#
# UNION ALL
#
# SELECT 'pbi_airport_business',
#        COUNT(*)
# FROM pbi_airport_business;




/* =============================================================
   步骤10：关键金额校验

   应接近：
   订单数 9,092,943
   订单交易总额 246,704,663.12美元
   ============================================================= */

SELECT
    order_count,
    total_transaction_amount,
    average_order_amount,
    earliest_pickup_datetime,
    latest_pickup_datetime
FROM pbi_kpi_overview;


/* =============================================================
   后续刷新方式

   若事实表发生变化，重新按步骤1～8执行即可。DROP TABLE会删除
   旧聚合结果，然后根据最新业务视图重新创建。
   ============================================================= */






# SHOW VARIABLES LIKE 'require_secure_transport';



# SHOW DATABASES;

#

# USE nyc_taxi_analysis;
#
# SHOW FULL TABLES;
#
#
# USE nyc_taxi_analysis;
#
# SHOW TABLES LIKE 'pbi_%';