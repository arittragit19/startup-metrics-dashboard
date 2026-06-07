import sqlite3
import pandas as pd
import os

conn = sqlite3.connect(r'C:\Users\HP\OneDrive\Documents\Arittra\projects\DA project\startup_metrics.db')

# --- 1. MAU Table ---
mau = pd.read_sql_query("""
    SELECT strftime('%Y-%m', event_date) AS month,
           COUNT(DISTINCT user_id) AS MAU
    FROM events GROUP BY month ORDER BY month
""", conn)

# --- 2. DAU/MAU Stickiness ---
stickiness = pd.read_sql_query("""
    WITH monthly AS (
        SELECT strftime('%Y-%m', event_date) AS month, COUNT(DISTINCT user_id) AS MAU FROM events GROUP BY month
    ),
    daily_avg AS (
        SELECT strftime('%Y-%m', event_date) AS month,
               COUNT(DISTINCT user_id) * 1.0 / COUNT(DISTINCT event_date) AS avg_DAU FROM events GROUP BY month
    )
    SELECT m.month, ROUND(d.avg_DAU,1) AS avg_DAU, m.MAU,
           ROUND(d.avg_DAU*100.0/m.MAU,1) AS dau_mau_ratio_pct
    FROM monthly m JOIN daily_avg d ON m.month=d.month ORDER BY m.month
""", conn)

# --- 3. Conversion Funnel ---
funnel = pd.read_sql_query("""
    WITH user_sessions AS (
        SELECT user_id, COUNT(DISTINCT event_date) AS active_days FROM events GROUP BY user_id
    )
    SELECT 'Total Signups' AS stage, COUNT(*) AS users FROM users
    UNION ALL SELECT 'Activated (1+ day)', COUNT(*) FROM user_sessions WHERE active_days>=1
    UNION ALL SELECT 'Engaged (7+ days)', COUNT(*) FROM user_sessions WHERE active_days>=7
    UNION ALL SELECT 'Power Users (30+ days)', COUNT(*) FROM user_sessions WHERE active_days>=30
""", conn)
# Add funnel order for sorting in Power BI
funnel['stage_order'] = [1, 2, 3, 4]

# --- 4. Feature Adoption ---
features = pd.read_sql_query("""
    SELECT feature,
           COUNT(*) AS total_uses,
           COUNT(DISTINCT user_id) AS unique_users,
           ROUND(COUNT(DISTINCT user_id)*100.0/(SELECT COUNT(*) FROM users),1) AS adoption_pct
    FROM feature_usage GROUP BY feature ORDER BY unique_users DESC
""", conn)

# --- 5. User Segments (Drop-off analysis) ---
segments = pd.read_sql_query("""
    WITH first_activity AS (
        SELECT u.user_id, u.plan, u.source,
               MIN(e.event_date) AS first_active,
               MAX(e.event_date) AS last_active,
               COUNT(DISTINCT e.event_date) AS total_days
        FROM users u LEFT JOIN events e ON u.user_id=e.user_id GROUP BY u.user_id
    )
    SELECT CASE
        WHEN first_active IS NULL THEN 'Never Activated'
        WHEN total_days=1 THEN 'One-day Wonder'
        WHEN total_days BETWEEN 2 AND 6 THEN 'Low Engagement'
        WHEN total_days BETWEEN 7 AND 29 THEN 'Moderate'
        ELSE 'Power User'
    END AS segment,
    plan, source,
    COUNT(*) AS users,
    ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM users),1) AS pct
    FROM first_activity GROUP BY segment, plan, source ORDER BY users DESC
""", conn)

# --- 6. New Signups by Month & Plan (North Star) ---
north_star = pd.read_sql_query("""
    SELECT strftime('%Y-%m', signup_date) AS month, plan,
           COUNT(*) AS new_signups
    FROM users GROUP BY month, plan ORDER BY month, plan
""", conn)

# --- 7. Daily Active Users (for trend chart) ---
dau_daily = pd.read_sql_query("""
    SELECT event_date, COUNT(DISTINCT user_id) AS DAU
    FROM events GROUP BY event_date ORDER BY event_date
""", conn)
dau_daily['event_date'] = pd.to_datetime(dau_daily['event_date'])

conn.close()

# --- Export all to one Excel file (one sheet per table) ---
output_path = r'C:\Users\HP\OneDrive\Documents\Arittra\projects\DA project\startup_dashboard_data.xlsx'
with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
    mau.to_excel(writer, sheet_name='MAU', index=False)
    stickiness.to_excel(writer, sheet_name='Stickiness', index=False)
    funnel.to_excel(writer, sheet_name='Funnel', index=False)
    features.to_excel(writer, sheet_name='Feature_Adoption', index=False)
    segments.to_excel(writer, sheet_name='User_Segments', index=False)
    north_star.to_excel(writer, sheet_name='North_Star', index=False)
    dau_daily.to_excel(writer, sheet_name='DAU_Daily', index=False)

print("✅ Excel file exported successfully!")
print(f"📁 Path: {output_path}")
print("\nSheets created:")
sheets = ['MAU', 'Stickiness', 'Funnel', 'Feature_Adoption', 'User_Segments', 'North_Star', 'DAU_Daily']
for s in sheets:
    print(f"  ✓ {s}")
