# 📊 Startup Growth Metrics Dashboard

## Project Overview
End-to-end data analytics project analyzing growth metrics of a SaaS startup over 6 months (Jan–Jun 2024).

## Tools Used
- **SQL** (SQLite) — Data extraction & metric calculation
- **Python** (pandas) — Data cleaning & transformation
- **Power BI** — Interactive dashboard & visualization

## Key Metrics Analyzed
- Monthly Active Users (MAU) — grew from 79 → 494 (525% growth)
- DAU/MAU Stickiness Ratio — 3.3% (identified as key problem area)
- Conversion Funnel — 500 signups → 277 power users (55.4%)
- Feature Adoption — Dashboard 96%, Integrations 62%

## Key Finding
Users activate well (98.8%) but don't return daily (DAU/MAU = 3.3%).
Recommended daily habit features and re-engagement campaigns.

## Files
| File | Description |
|------|-------------|
| `analysis_queries.sql` | 8 SQL queries for all metrics |
| `export_for_powerbi.py` | Python script to export data to Excel |
| `startup_dashboard_data.xlsx` | Cleaned data ready for Power BI |
| `startup_metrics.db` | SQLite database |
| `Insights_Report.docx` | Full findings & recommendations |
