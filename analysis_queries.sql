-- ============================================
-- STARTUP METRICS DASHBOARD - SQL ANALYSIS
-- Project by: [Your Name]
-- Dataset: Simulated SaaS Startup (Jan-Jun 2024)
-- ============================================

-- ============================================
-- SECTION 1: MONTHLY ACTIVE USERS (MAU)
-- Users who had at least 1 session in a month
-- ============================================

SELECT
    strftime('%Y-%m', event_date) AS month,
    COUNT(DISTINCT user_id) AS MAU
FROM events
GROUP BY month
ORDER BY month;


-- ============================================
-- SECTION 2: DAILY ACTIVE USERS (DAU)
-- Users active on each specific day
-- ============================================

SELECT
    event_date AS day,
    COUNT(DISTINCT user_id) AS DAU
FROM events
GROUP BY event_date
ORDER BY event_date;


-- ============================================
-- SECTION 3: DAU/MAU RATIO (Stickiness Score)
-- Higher = users come back more often
-- A ratio > 20% is considered healthy
-- ============================================

WITH monthly AS (
    SELECT
        strftime('%Y-%m', event_date) AS month,
        COUNT(DISTINCT user_id) AS MAU
    FROM events
    GROUP BY month
),
daily_avg AS (
    SELECT
        strftime('%Y-%m', event_date) AS month,
        COUNT(DISTINCT user_id) * 1.0 / COUNT(DISTINCT event_date) AS avg_DAU
    FROM events
    GROUP BY month
)
SELECT
    m.month,
    ROUND(d.avg_DAU, 1) AS avg_DAU,
    m.MAU,
    ROUND(d.avg_DAU * 100.0 / m.MAU, 1) AS dau_mau_ratio_pct
FROM monthly m
JOIN daily_avg d ON m.month = d.month
ORDER BY m.month;


-- ============================================
-- SECTION 4: USER RETENTION (Month 1 vs Month 2)
-- Of users who signed up in Jan, how many were
-- still active in Feb?
-- ============================================

WITH cohort AS (
    SELECT
        user_id,
        strftime('%Y-%m', signup_date) AS cohort_month
    FROM users
),
activity AS (
    SELECT
        user_id,
        strftime('%Y-%m', event_date) AS active_month
    FROM events
    GROUP BY user_id, active_month
)
SELECT
    c.cohort_month,
    COUNT(DISTINCT c.user_id) AS total_users,
    COUNT(DISTINCT CASE WHEN a.active_month = c.cohort_month THEN c.user_id END) AS active_month_0,
    COUNT(DISTINCT CASE WHEN a.active_month = strftime('%Y-%m', date(c.cohort_month || '-01', '+1 month')) THEN c.user_id END) AS active_month_1,
    COUNT(DISTINCT CASE WHEN a.active_month = strftime('%Y-%m', date(c.cohort_month || '-01', '+2 months')) THEN c.user_id END) AS active_month_2
FROM cohort c
LEFT JOIN activity a ON c.user_id = a.user_id
GROUP BY c.cohort_month
ORDER BY c.cohort_month;


-- ============================================
-- SECTION 5: CONVERSION FUNNEL
-- How many users move from signup → active → power user
-- ============================================

WITH user_sessions AS (
    SELECT
        user_id,
        COUNT(DISTINCT event_date) AS active_days
    FROM events
    GROUP BY user_id
)
SELECT
    'Total Signups'        AS stage, COUNT(*) AS users FROM users
UNION ALL
SELECT
    'Activated (1+ day active)', COUNT(*) FROM user_sessions WHERE active_days >= 1
UNION ALL
SELECT
    'Engaged (7+ days active)', COUNT(*) FROM user_sessions WHERE active_days >= 7
UNION ALL
SELECT
    'Power Users (30+ days active)', COUNT(*) FROM user_sessions WHERE active_days >= 30;


-- ============================================
-- SECTION 6: FEATURE ADOPTION
-- Which features are most/least used?
-- ============================================

SELECT
    feature,
    COUNT(*) AS total_uses,
    COUNT(DISTINCT user_id) AS unique_users,
    ROUND(COUNT(DISTINCT user_id) * 100.0 / (SELECT COUNT(*) FROM users), 1) AS adoption_pct
FROM feature_usage
GROUP BY feature
ORDER BY unique_users DESC;


-- ============================================
-- SECTION 7: NORTH STAR METRIC BREAKDOWN
-- Monthly growth: new users + active users by plan
-- ============================================

SELECT
    strftime('%Y-%m', signup_date) AS month,
    plan,
    COUNT(*) AS new_signups
FROM users
GROUP BY month, plan
ORDER BY month, plan;


-- ============================================
-- SECTION 8: WHERE ARE USERS DROPPING OFF?
-- Users who signed up but NEVER came back after day 1
-- ============================================

WITH first_activity AS (
    SELECT
        u.user_id,
        u.signup_date,
        MIN(e.event_date) AS first_active_date,
        MAX(e.event_date) AS last_active_date,
        COUNT(DISTINCT e.event_date) AS total_active_days
    FROM users u
    LEFT JOIN events e ON u.user_id = e.user_id
    GROUP BY u.user_id
)
SELECT
    CASE
        WHEN first_active_date IS NULL THEN 'Never activated'
        WHEN total_active_days = 1 THEN 'One-day wonder (never returned)'
        WHEN total_active_days BETWEEN 2 AND 6 THEN 'Low engagement (2-6 days)'
        WHEN total_active_days BETWEEN 7 AND 29 THEN 'Moderate (7-29 days)'
        ELSE 'Power user (30+ days)'
    END AS user_segment,
    COUNT(*) AS user_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 1) AS percentage
FROM first_activity
GROUP BY user_segment
ORDER BY user_count DESC;
