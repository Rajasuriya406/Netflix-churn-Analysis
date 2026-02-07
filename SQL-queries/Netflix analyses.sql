-- ==============================================
-- 1. IDENTIFY CHURN PATTERNS & CORRELATIONS


-- Top 5 most  combinations features for churn
SELECT 
    subscription_type,
    payment_method,
    region,
    device,
    COUNT(*) as total_customers,
    SUM(churned) as churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(last_login_days), 1) as avg_inactivity_days,
    ROUND(AVG(watch_hours), 1) as avg_watch_hours
FROM netflix_customers
GROUP BY subscription_type, payment_method, region, device
HAVING COUNT(*) >= 10 AND SUM(churned) > 0
ORDER BY churn_rate DESC
LIMIT 10;

-- The "Perfect Storm" for churn - customers with multiple risk factors
SELECT 
    CASE 
        WHEN last_login_days > 30 THEN 1 ELSE 0 END as risk_inactive,
    CASE 
        WHEN watch_hours < 5 THEN 1 ELSE 0 END as risk_low_usage,
    CASE 
        WHEN payment_method IN ('Gift Card', 'Crypto') THEN 1 ELSE 0 END as risk_payment,
    CASE 
        WHEN avg_watch_time_per_day < 0.5 THEN 1 ELSE 0 END as risk_low_daily_engagement,
    COUNT(*) as total_customers,
    SUM(churned) as churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate
FROM netflix_customers
GROUP BY 
    CASE WHEN last_login_days > 30 THEN 1 ELSE 0 END,
    CASE WHEN watch_hours < 5 THEN 1 ELSE 0 END,
    CASE WHEN payment_method IN ('Gift Card', 'Crypto') THEN 1 ELSE 0 END,
    CASE WHEN avg_watch_time_per_day < 0.5 THEN 1 ELSE 0 END
ORDER BY churn_rate DESC;

-- ==============================================
-- 2. VALUE MISMATCH ANALYSIS
-- ==============================================

-- Customers paying premium price for basic usage
SELECT 
    'High Cost, Low Usage' as segment,
    COUNT(*) as customers,
    SUM(churned) as churned,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(monthly_fee), 2) as avg_monthly_fee,
    ROUND(AVG(watch_hours), 2) as avg_watch_hours,
    ROUND(AVG(monthly_fee / NULLIF(watch_hours, 0)), 2) as cost_per_watch_hour
FROM netflix_customers
WHERE subscription_type = 'Premium' 
  AND watch_hours < 10
  AND monthly_fee > 15;

-- Subscription tier mismatch analysis
SELECT 
    CASE 
        WHEN watch_hours > 30 AND subscription_type = 'Basic' THEN 'Heavy User on Basic Plan'
        WHEN watch_hours < 5 AND subscription_type = 'Premium' THEN 'Light User on Premium Plan'
        WHEN watch_hours BETWEEN 10 AND 20 AND subscription_type = 'Standard' THEN 'Ideal Fit - Standard'
        ELSE 'Other'
    END as subscription_fit,
    COUNT(*) as total_customers,
    SUM(churned) as churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(monthly_fee / NULLIF(watch_hours, 0)), 2) as cost_per_hour
FROM netflix_customers
WHERE watch_hours > 0
GROUP BY 
    CASE 
        WHEN watch_hours > 30 AND subscription_type = 'Basic' THEN 'Heavy User on Basic Plan'
        WHEN watch_hours < 5 AND subscription_type = 'Premium' THEN 'Light User on Premium Plan'
        WHEN watch_hours BETWEEN 10 AND 20 AND subscription_type = 'Standard' THEN 'Ideal Fit - Standard'
        ELSE 'Other'
    END
ORDER BY churn_rate DESC;

-- ==============================================
-- 3. ENGAGEMENT DECAY ANALYSIS
-- ==============================================

-- How inactivity leads to churn (progressive analysis)
WITH activity_stages AS (
    SELECT 
        customer_id,
        churned,
        CASE 
            WHEN last_login_days <= 7 THEN 'Week 1'
            WHEN last_login_days <= 14 THEN 'Week 2'
            WHEN last_login_days <= 30 THEN 'Month 1'
            WHEN last_login_days <= 60 THEN 'Month 2'
            ELSE 'Month 3+'
        END as inactivity_stage,
        watch_hours,
        avg_watch_time_per_day
    FROM netflix_customers
)
SELECT 
    inactivity_stage,
    COUNT(*) as customers,
    SUM(churned) as churned,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(watch_hours), 1) as avg_total_watch_hours,
    ROUND(AVG(avg_watch_time_per_day), 2) as avg_daily_engagement
FROM activity_stages
GROUP BY inactivity_stage
ORDER BY 
    CASE inactivity_stage
        WHEN 'Week 1' THEN 1
        WHEN 'Week 2' THEN 2
        WHEN 'Month 1' THEN 3
        WHEN 'Month 2' THEN 4
        ELSE 5
    END;

-- Early warning signals: First month behavior of churned vs retained customers
SELECT 
    CASE WHEN churned = 1 THEN 'Churned' ELSE 'Retained' END as status,
    ROUND(AVG(CASE WHEN last_login_days <= 30 THEN watch_hours END), 1) as first_month_watch_hours,
    ROUND(AVG(CASE WHEN last_login_days <= 30 THEN avg_watch_time_per_day END), 2) as first_month_daily_avg,
    COUNT(DISTINCT CASE WHEN watch_hours = 0 THEN customer_id END) as never_watched_count,
    ROUND(AVG(age), 1) as avg_age,
    ROUND(AVG(monthly_fee), 2) as avg_monthly_fee
FROM netflix_customers
WHERE last_login_days <= 30 OR churned = 1
GROUP BY churned;

-- ==============================================
-- 4. PAYMENT & BILLING INSIGHTS
-- ==============================================

-- Payment method risk analysis with seasonality patterns
SELECT 
    payment_method,
    region,
    COUNT(*) as total_customers,
    SUM(churned) as churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    -- Identify if certain payment methods fail in specific regions
    ROUND(AVG(CASE WHEN churned = 1 THEN monthly_fee END), 2) as avg_lost_revenue,
    ROUND(AVG(age), 1) as avg_age_demographic
FROM netflix_customers
GROUP BY payment_method, region
HAVING COUNT(*) > 5
ORDER BY churn_rate DESC;

-- Gift Card expiration analysis (assuming 30-day gift cards)
WITH gift_card_users AS (
    SELECT 
        *,
        CASE 
            WHEN payment_method = 'Gift Card' AND last_login_days > 25 THEN 'Near Expiry'
            WHEN payment_method = 'Gift Card' AND last_login_days > 15 THEN 'Mid-cycle'
            ELSE 'Other'
        END as gift_card_status
    FROM netflix_customers
    WHERE payment_method = 'Gift Card'
)
SELECT 
    gift_card_status,
    COUNT(*) as customers,
    SUM(churned) as churned,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(watch_hours), 1) as avg_watch_hours
FROM gift_card_users
GROUP BY gift_card_status
ORDER BY 
    CASE gift_card_status
        WHEN 'Near Expiry' THEN 1
        WHEN 'Mid-cycle' THEN 2
        ELSE 3
    END;

-- ==============================================
-- 5. CONTENT & GENRE INSIGHTS
-- ==============================================

-- Genre preferences and their impact on retention
SELECT 
    favorite_genre,
    COUNT(*) as total_customers,
    SUM(churned) as churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(watch_hours), 1) as avg_watch_hours,
    ROUND(AVG(age), 1) as avg_age,
    -- Content diversity score (how many genres correlate with retention)
    CASE 
        WHEN favorite_genre IN ('Documentary', 'Sci-Fi', 'Drama') THEN 'High Retention Genres'
        WHEN favorite_genre IN ('Horror', 'Action', 'Comedy') THEN 'Medium Retention Genres'
        ELSE 'Variable Retention'
    END as genre_retention_category
FROM netflix_customers
WHERE favorite_genre IS NOT NULL AND favorite_genre != ''
GROUP BY favorite_genre
ORDER BY churn_rate;

-- Content consumption patterns by demographic
SELECT 
    CASE 
        WHEN age < 25 THEN 'Gen Z'
        WHEN age BETWEEN 25 AND 40 THEN 'Millennials'
        WHEN age BETWEEN 41 AND 55 THEN 'Gen X'
        ELSE 'Boomers'
    END as generation,
    favorite_genre,
    COUNT(*) as customers,
    ROUND(AVG(watch_hours), 1) as avg_watch_hours,
    ROUND(AVG(CASE WHEN churned = 1 THEN watch_hours END), 1) as avg_watch_hours_churned,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate
FROM netflix_customers
WHERE favorite_genre IS NOT NULL
GROUP BY 
    CASE 
        WHEN age < 25 THEN 'Gen Z'
        WHEN age BETWEEN 25 AND 40 THEN 'Millennials'
        WHEN age BETWEEN 41 AND 55 THEN 'Gen X'
        ELSE 'Boomers'
    END,
    favorite_genre
HAVING COUNT(*) > 5
ORDER BY generation, customers DESC;

-- ==============================================
-- 6. DEVICE & PLATFORM EXPERIENCE
-- ==============================================

-- Device-specific engagement patterns
SELECT 
    device,
    region,
    COUNT(*) as customers,
    SUM(churned) as churned,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(watch_hours), 1) as avg_watch_hours,
    ROUND(AVG(avg_watch_time_per_day), 2) as avg_daily_engagement,
    -- Session length insights
    CASE 
        WHEN device IN ('Mobile', 'Tablet') THEN 'Mobile Platform'
        WHEN device IN ('TV', 'Desktop') THEN 'Fixed Platform'
        ELSE 'Other'
    END as platform_type
FROM netflix_customers
GROUP BY device, region
ORDER BY churn_rate DESC;

-- Cross-device usage analysis (who uses multiple devices vs single device)
-- Note: This assumes one device per customer in current data
-- For real analysis, you'd need device history data
SELECT 
    device,
    ROUND(AVG(number_of_profiles), 1) as avg_profiles,
    ROUND(AVG(watch_hours), 1) as avg_watch_hours,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    CASE 
        WHEN device IN ('TV', 'Desktop') AND watch_hours < 10 THEN 'Underutilized Big Screen'
        WHEN device = 'Mobile' AND watch_hours > 20 THEN 'Heavy Mobile User'
        ELSE 'Typical Usage'
    END as usage_pattern
FROM netflix_customers
GROUP BY device;

-- ==============================================
-- 7. PREDICTIVE SEGMENTATION FOR INTERVENTION
-- ==============================================

-- High-Value Customers at Risk (Priority 1 for retention)
SELECT 
    customer_id,
    age,
    subscription_type,
    monthly_fee,
    watch_hours,
    last_login_days,
    region,
    payment_method,
    ROUND(monthly_fee * 12, 2) as annual_value,
    CASE 
        WHEN last_login_days > 20 THEN 'Immediate Risk'
        WHEN watch_hours < monthly_fee THEN 'Value Mismatch'
        WHEN payment_method = 'Gift Card' AND last_login_days > 15 THEN 'Gift Card Expiry Risk'
        ELSE 'Monitor'
    END as risk_category
FROM netflix_customers
WHERE churned = 0  -- Currently active
  AND monthly_fee >= 13.99  -- Standard or Premium
  AND (
      last_login_days > 20 
      OR watch_hours < 5 
      OR (payment_method = 'Gift Card' AND last_login_days > 15)
  )
ORDER BY monthly_fee DESC, last_login_days DESC
LIMIT 20;

-- ==============================================
-- 8. RETENTION OPPORTUNITY ANALYSIS
-- ==============================================

-- Most salvageable segments (high churn but high potential)
WITH salvageable_segments AS (
    SELECT 
        subscription_type,
        region,
        device,
        payment_method,
        COUNT(*) as total_customers,
        SUM(churned) as churned_customers,
        ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
        ROUND(AVG(monthly_fee), 2) as avg_monthly_fee,
        ROUND(AVG(watch_hours), 1) as avg_watch_hours,
        ROUND(AVG(last_login_days), 1) as avg_inactivity,
        -- Calculate salvage score (higher is more salvageable)
        ROUND(
            (AVG(monthly_fee) * 0.4 + 
            (30 - LEAST(AVG(last_login_days), 30)) * 0.3 +
            AVG(watch_hours) * 0.3), 2
        ) as salvage_score
    FROM netflix_customers
    GROUP BY subscription_type, region, device, payment_method
    HAVING COUNT(*) >= 5 AND SUM(churned) > 0
)
SELECT 
    *,
    CASE 
        WHEN salvage_score > 20 THEN 'High Priority - Very Salvageable'
        WHEN salvage_score BETWEEN 15 AND 20 THEN 'Medium Priority'
        ELSE 'Low Priority'
    END as intervention_priority
FROM salvageable_segments
ORDER BY salvage_score DESC
LIMIT 15;

-- ==============================================
-- 9. COMPETITIVE ANALYSIS SIMULATION
-- ==============================================

-- Price sensitivity analysis
SELECT 
    region,
    subscription_type,
    ROUND(AVG(monthly_fee), 2) as avg_price_paid,
    SUM(churned) as churned,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    -- Simulated price increase impact
    CASE 
        WHEN AVG(monthly_fee) < 10 AND churn_rate > 20 THEN 'Price Increase Risk'
        WHEN AVG(monthly_fee) >= 15 AND churn_rate > 15 THEN 'Premium Price Sensitivity'
        ELSE 'Stable Pricing'
    END as price_sensitivity
FROM netflix_customers
GROUP BY region, subscription_type
ORDER BY region, subscription_type;

-- Market penetration vs churn by region
SELECT 
    region,
    COUNT(*) as total_customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflix_customers), 2) as market_share,
    SUM(churned) as churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(monthly_fee), 2) as avg_price_point,
    CASE 
        WHEN COUNT(*) < 50 AND churn_rate > 25 THEN 'New Market - High Churn'
        WHEN COUNT(*) >= 50 AND churn_rate < 15 THEN 'Established Market - Stable'
        WHEN churn_rate > 20 THEN 'At-Risk Market'
        ELSE 'Developing Market'
    END as market_maturity
FROM netflix_customers
GROUP BY region
ORDER BY market_share DESC;