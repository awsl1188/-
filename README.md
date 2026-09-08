# NYC Yellow Taxi Business Analysis

> Analysis of 9.09 million NYC Yellow Taxi trips using Python, MySQL, SQL and Power BI.

## Project Overview

This project analyzes New York City Yellow Taxi trip records from January to March 2024.

The objective is to evaluate operating performance, identify temporal demand patterns, measure regional supply-demand imbalance, and provide data-driven recommendations for vehicle scheduling and repositioning.

## Project Highlights

| Metric | Result |
|---|---:|
| Analysis period | January–March 2024 |
| Raw trip records | 9,554,778 |
| Cleaned trip records | 9,092,942 |
| Data retention rate | 95.17% |
| Total transaction amount | $246.70 million |
| Average order amount | $27.13 |
| Average trip distance | 3.25 miles |
| Transaction amount per occupied hour | $105.20 |

> Transaction amount represents the amount charged to passengers and should not be interpreted as net profit.

## Key Business Findings

- March recorded approximately **109,560 average daily trips**, representing an increase of about **20.0%** compared with January.
- Thursday had the highest weekday demand, with approximately **113,307 average daily trips**.
- The evening peak recorded the highest demand intensity, reaching approximately **6,849 trips per clock hour**.
- Manhattan accounted for the majority of Yellow Taxi pickup activity.
- JFK Airport and LaGuardia Airport were important high-value pickup markets.
- JFK Airport generated substantially more pickup trips than drop-off trips, indicating potential vehicle replenishment demand.
- Several Manhattan zones showed significant pickup-drop-off flow imbalance, providing a reference for vehicle repositioning.
- Nighttime trips generated higher transaction value per occupied hour than daytime trips, although waiting time and empty cruising time were not included.

## Technology Stack

- **Python:** Pandas, NumPy and PyArrow
- **Visualization:** Matplotlib and Seaborn
- **Database:** MySQL
- **Business analysis:** SQL
- **Business intelligence:** Power BI
- **Development environment:** Jupyter Notebook and PyCharm
- **Version control:** Git and GitHub

## Dashboard Preview

![Power BI Dashboard](dashboard/dashboard_preview.png)

The Power BI dashboard presents five core operating indicators:

- Total trip volume
- Total transaction amount
- Average order amount
- Average trip distance
- Transaction amount per occupied hour

It also presents monthly trends, weekday demand patterns and time-period demand intensity.

## Key Visualizations

### 1. Monthly Operating Performance

![Monthly Operating Performance](images/01_monthly_daily_business.png)

Average daily trip volume increased continuously during the first quarter of 2024. March achieved the highest average daily order volume and transaction amount.

### 2. Weekday Demand Pattern

![Weekday Demand Pattern](images/02_weekday_demand.png)

Thursday recorded the highest average daily demand, while Monday and Sunday had relatively lower order volumes.

### 3. Time-Period Demand Intensity

![Time-Period Demand Intensity](images/03_time_period_demand.png)

The evening peak had the highest hourly order intensity, followed by daytime and nighttime periods.

### 4. Regional Demand and Occupied-Hour Efficiency

![Regional Demand and Efficiency](images/06_zone_demand_efficiency_quadrant.png)

Taxi zones were divided into four operational categories according to average daily pickup demand and transaction amount per occupied hour:

- High demand — High occupied-hour efficiency
- High demand — Low occupied-hour efficiency
- Low demand — High occupied-hour efficiency
- Low demand — Low occupied-hour efficiency

## Additional Analysis

The following visualizations provide further regional, airport and OD-route analysis:

- [Top 15 Pickup Zones](images/04_top_pickup_zones.png)
- [Top 15 OD Routes](images/05_top_od_routes.png)
- [Zone Pickup-Dropoff Flow Imbalance](images/07_zone_flow_imbalance.png)
- [Airport Order Value Comparison](images/08_airport_value_comparison.png)
- [Borough OD Flow Heatmap](images/09_borough_od_heatmap.png)

## Analysis Workflow

1. Collected NYC TLC Yellow Taxi trip records for January, February and March 2024.
2. Combined approximately 9.55 million raw trip records.
3. Inspected data types, missing values, duplicate records and descriptive statistics.
4. Cleaned date, duration, distance, speed, location and payment anomalies.
5. Constructed trip duration, average speed and transaction-efficiency indicators.
6. Added date, weekday, time-period and taxi-zone attributes.
7. Built MySQL fact tables, dimension tables and query indexes.
8. Created reusable SQL business-analysis views.
9. Analyzed monthly, weekday, time-period, regional, airport and OD-route performance.
10. Developed an interactive Power BI operating dashboard.
11. Generated operational recommendations for demand scheduling and vehicle repositioning.

## Selected Code Samples

The following snippets demonstrate the main technical components of the project. Complete implementations are available in the [`notebooks`](notebooks/) and [`sql`](sql/) directories.

### 1. Loading and Combining Monthly Trip Data

```python
from pathlib import Path

import pandas as pd

# Define the local data directory
data_dir = Path("../data")

# Read the three monthly Yellow Taxi Parquet files
jan_df = pd.read_parquet(
    data_dir / "yellow_tripdata_2024-01.parquet"
)
feb_df = pd.read_parquet(
    data_dir / "yellow_tripdata_2024-02.parquet"
)
mar_df = pd.read_parquet(
    data_dir / "yellow_tripdata_2024-03.parquet"
)

# Combine the monthly datasets
taxi_df = pd.concat(
    [jan_df, feb_df, mar_df],
    ignore_index=True
)

print(f"Raw trip records: {len(taxi_df):,}")
print(f"Number of fields: {taxi_df.shape[1]}")
```

### 2. Feature Engineering

```python
import numpy as np

# Calculate occupied trip duration in minutes
analysis_df["trip_duration_minutes"] = (
    analysis_df["tpep_dropoff_datetime"]
    - analysis_df["tpep_pickup_datetime"]
).dt.total_seconds() / 60

# Calculate average occupied-trip speed
analysis_df["average_speed_mph"] = (
    analysis_df["trip_distance"]
    / (analysis_df["trip_duration_minutes"] / 60)
)

# Calculate transaction amount per mile
analysis_df["transaction_amount_per_mile"] = (
    analysis_df["total_amount"]
    / analysis_df["trip_distance"]
)

# Calculate transaction amount per occupied hour
analysis_df["transaction_amount_per_occupied_hour"] = (
    analysis_df["total_amount"]
    / (analysis_df["trip_duration_minutes"] / 60)
)

# Replace infinite results with missing values
derived_columns = [
    "average_speed_mph",
    "transaction_amount_per_mile",
    "transaction_amount_per_occupied_hour"
]

analysis_df[derived_columns] = (
    analysis_df[derived_columns]
    .replace([np.inf, -np.inf], np.nan)
)
```

### 3. SQL Monthly Business Analysis

```sql
SELECT
    d.year_number,
    d.month_number,
    d.month_name,
    COUNT(*) AS order_count,
    ROUND(SUM(f.total_amount), 2)
        AS total_transaction_amount,
    ROUND(AVG(f.total_amount), 2)
        AS average_order_amount,
    ROUND(SUM(f.trip_distance), 2)
        AS total_distance,
    ROUND(AVG(f.trip_distance), 2)
        AS average_distance,
    ROUND(
        COUNT(*) / COUNT(DISTINCT d.full_date),
        2
    ) AS average_daily_orders
FROM fact_taxi_trip AS f
INNER JOIN dim_date AS d
    ON f.date_key = d.date_key
GROUP BY
    d.year_number,
    d.month_number,
    d.month_name
ORDER BY
    d.year_number,
    d.month_number;
```

These samples are simplified extracts. The complete Notebook contains additional data validation, cleaning thresholds, taxi-zone mapping and business-analysis logic.

## Data Cleaning

The raw dataset contained missing values, abnormal timestamps, invalid distances, non-positive transaction amounts and invalid taxi-zone identifiers.

The main cleaning rules included:

- Retaining only trips from the first quarter of 2024
- Removing duplicate records
- Removing invalid pickup and drop-off timestamps
- Removing trips with abnormal duration
- Removing trips with invalid or extreme distance
- Removing trips with abnormal average speed
- Removing records with invalid taxi-zone identifiers
- Removing records with non-positive transaction amounts
- Treating invalid passenger counts as missing values
- Preventing infinite values in derived indicators

After data cleaning, **9,092,942 records** were retained for the final analysis.

## Derived Business Indicators

| Indicator | Calculation | Business meaning |
|---|---|---|
| Trip duration | Drop-off time − Pickup time | Occupied trip duration |
| Average speed | Distance ÷ Duration | Trip operating-speed indicator |
| Transaction amount per mile | Total amount ÷ Distance | Distance-based transaction efficiency |
| Transaction amount per occupied hour | Total amount ÷ Occupied duration | Occupied-time transaction efficiency |
| Flow imbalance | Pickup orders − Drop-off orders | Proxy for vehicle repositioning pressure |
| Average daily orders | Orders ÷ Observed days | Comparable demand indicator across periods |

## Database Design

The MySQL analytical database contains:

- Taxi trip fact table
- Date dimension
- Taxi-zone dimension
- Time-period dimension
- Business-analysis views
- Query-performance indexes

Indexes were created for:

- Date
- Pickup hour
- Pickup location
- Drop-off location
- Date and hour
- Pickup and drop-off OD pairs

The SQL layer supports reusable business queries and Power BI reporting.

## Repository Structure

```text
nyc-taxi-business-analysis/
├── README.md
├── requirements.txt
├── notebooks/
│   ├── README.md
│   └── nyc_taxi_business_analysis.ipynb
├── sql/
│   ├── README.md
│   ├── 01_database_schema.sql
│   ├── 02_create_dimensions.sql
│   ├── 03_create_indexes.sql
│   ├── 04_business_analysis.sql
│   ├── 05_create_business_views.sql
│   └── 06_build_powerbi_tables.sql
├── dashboard/
│   ├── README.md
│   ├── dashboard_preview.png
│   └── nyc_taxi_dashboard.pbix
├── images/
│   ├── README.md
│   ├── 01_monthly_daily_business.png
│   ├── 02_weekday_demand.png
│   ├── 03_time_period_demand.png
│   ├── 04_top_pickup_zones.png
│   ├── 05_top_od_routes.png
│   ├── 06_zone_demand_efficiency_quadrant.png
│   ├── 07_zone_flow_imbalance.png
│   ├── 08_airport_value_comparison.png
│   └── 09_borough_od_heatmap.png
├── data/
│   ├── README.md
│   └── taxi_zone_lookup.csv
└── docs/
    └── data_dictionary.md
```

> The directory structure above represents the planned project organization. Files not included in the public repository can be marked as available upon request.

## Data Source

This project uses public trip-record data provided by the New York City Taxi and Limousine Commission:

[NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)

The following files were used:

- Yellow Taxi Trip Records — January 2024
- Yellow Taxi Trip Records — February 2024
- Yellow Taxi Trip Records — March 2024
- Taxi Zone Lookup Table

## Data Availability

The complete raw and cleaned trip datasets are not stored in this repository because of their large file size.

To reproduce the analysis:

1. Download the three monthly Parquet files from the NYC TLC website.
2. Place the files in the local `data` directory.
3. Install the required Python packages.
4. Run the Jupyter Notebook in the documented order.
5. Execute the SQL scripts according to their sequence numbers.
6. Open the Power BI report or connect Power BI to the resulting analytical tables.

## Installation

Install the required Python packages:

```bash
pip install -r requirements.txt
```

## Reproducibility

The project is organized into three analytical layers:

- **Python:** data inspection, cleaning, feature engineering and exploratory analysis
- **MySQL and SQL:** dimensional modeling, query optimization and reusable business analysis
- **Power BI:** KPI monitoring, visualization and interactive reporting

Because the raw dataset contains more than nine million records, sufficient local memory and storage space are recommended.

## Limitations

- Transaction amount is an operating-performance indicator and does not represent net profit.
- Transaction amount per occupied hour excludes passenger waiting time and empty cruising time.
- Pickup-drop-off imbalance is a proxy for vehicle repositioning pressure rather than a direct measurement of available vehicles.
- The analysis includes only Yellow Taxi trips from the first quarter of 2024.
- Weather, holidays, traffic incidents and special events were not modeled separately.
- The project analyzes historical operational data and does not provide real-time dispatch recommendations.

## Author

**Yadong Liu**

Data Analysis Portfolio Project

Skills demonstrated:

- Large-scale data cleaning
- Feature engineering
- Exploratory data analysis
- Business indicator design
- SQL business analysis
- Dimensional data modeling
- Query optimization
- Power BI dashboard development
- Data visualization
- Business insight communication
