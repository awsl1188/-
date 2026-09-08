# Data Description

## Data Source

This project uses the NYC Taxi & Limousine Commission (TLC)
Yellow Taxi Trip Record Data.

Analysis period:

- January 2024
- February 2024
- March 2024

Supporting data:

- NYC Taxi Zone Lookup Table

Official data source:

https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

## Data Volume

| Stage | Number of Records |
|---|---:|
| Raw data | 9,554,778 |
| Final analytical data | 9,092,942 |
| Data retention rate | 95.17% |

## Data Cleaning Rules

The following records were inspected or removed:

- Trips outside the first quarter of 2024
- Duplicate records
- Invalid pickup or drop-off timestamps
- Abnormal trip duration
- Invalid or extreme trip distance
- Abnormal average speed
- Invalid taxi zone identifiers
- Non-positive transaction amounts
- Missing or invalid passenger counts

## Main Fields

| Field | Description |
|---|---|
| tpep_pickup_datetime | Pickup timestamp |
| tpep_dropoff_datetime | Drop-off timestamp |
| passenger_count | Number of passengers |
| trip_distance | Trip distance in miles |
| PULocationID | Pickup taxi zone identifier |
| DOLocationID | Drop-off taxi zone identifier |
| fare_amount | Metered fare amount |
| tip_amount | Tip amount |
| tolls_amount | Toll amount |
| total_amount | Total transaction amount |
| trip_duration_minutes | Derived trip duration in minutes |
| average_speed_mph | Derived average speed |
| revenue_per_mile | Transaction amount per mile |
| revenue_per_hour | Transaction amount per occupied hour |

## Data Availability

The complete raw and cleaned trip datasets are not included in this
repository because of their large file size.

The original monthly Parquet files can be downloaded from the official
NYC TLC website. The analysis can be reproduced by placing the downloaded
files in the local `data` directory.

## Notes

The final Power BI overview uses 9,092,942 cleaned trip records.
Database validation identified one additional record in the MySQL fact
table; therefore, dashboard indicators are based on the deduplicated
analytical dataset.
