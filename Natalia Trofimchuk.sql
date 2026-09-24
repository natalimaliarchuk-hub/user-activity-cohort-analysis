WITH users_parsed AS (
    SELECT
        u.user_id,
        u.signup_datetime,
        u.promo_signup_flag,
        CASE 
            WHEN REGEXP_REPLACE(SPLIT_PART(TRIM(u.signup_datetime), ' ', 1), '[/-]', '.', 'g') ~ '\.\d{2}$' 
            THEN TO_DATE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(SPLIT_PART(TRIM(u.signup_datetime), ' ', 1), '[/-]', '.', 'g'), 
                        '\.(\d{2})$', '.20\1'
                    ), 
                    'DD.MM.YYYY'
                 )::date
            ELSE TO_DATE(
                    REGEXP_REPLACE(SPLIT_PART(TRIM(u.signup_datetime), ' ', 1), '[/-]', '.', 'g'), 
                    'DD.MM.YYYY'
                 )::date
        END AS signup_ts
    FROM cohort_users_raw u
),

events_parsed AS (
    SELECT 
        e.user_id,
        e.event_id,
        e.event_datetime,
        e.event_type, 
        CASE  
         
            WHEN REGEXP_REPLACE(SPLIT_PART(TRIM(e.event_datetime), ' ', 1), '[/-]', '.', 'g') ~ '\.\d{2}$' 
            THEN TO_DATE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(SPLIT_PART(TRIM(e.event_datetime), ' ', 1), '[/-]', '.', 'g'), 
                        '\.(\d{2})$', '.20\1'
                    ), 
                    'DD.MM.YYYY'
                 )::date
            ELSE TO_DATE(
                    REGEXP_REPLACE(SPLIT_PART(TRIM(e.event_datetime), ' ', 1), '[/-]', '.', 'g'), 
                    'DD.MM.YYYY'
                 )::date
        END AS events_ts
    FROM cohort_events_raw e
),

user_activity AS (
    SELECT 
        u.user_id,
        u.promo_signup_flag,
        DATE_TRUNC('month', u.signup_ts)::date AS cohort_month,
        DATE_TRUNC('month', e.events_ts)::date AS activity_month,
        (EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', e.events_ts), DATE_TRUNC('month', u.signup_ts))) * 12 + 
         EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', e.events_ts), DATE_TRUNC('month', u.signup_ts))))::int AS month_offset
    FROM users_parsed u
    JOIN events_parsed e ON u.user_id = e.user_id
    WHERE
        u.signup_ts IS NOT NULL 
        AND e.events_ts IS NOT NULL 
        AND e.event_type IS NOT NULL 
        AND e.event_type <> 'test_event'
)

SELECT 
    promo_signup_flag,
    cohort_month,
    month_offset,
    COUNT(DISTINCT user_id) AS users_total
FROM user_activity
WHERE activity_month BETWEEN '2025-01-01' AND '2025-06-01'
GROUP BY 
    promo_signup_flag,
    cohort_month,
    month_offset
ORDER BY 
    promo_signup_flag,
    cohort_month,
    month_offset;
