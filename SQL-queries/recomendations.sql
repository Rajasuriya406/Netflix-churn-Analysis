-- ==============================================
-- 10. SPECIFIC ACTION PLANS BY SEGMENT
-- ==============================================

-- Action Plan 1: Immediate Win-Back Campaign
SELECT 
    'Win-Back Campaign Targets' as campaign_name,
    COUNT(*) as target_customers,
    ROUND(SUM(monthly_fee), 2) as monthly_revenue_opportunity,
    ROUND(SUM(monthly_fee * 3), 2) as qtr_revenue_potential,
    '30% discount for 3 months + content recommendations' as intervention,
    'Email + Push Notification + In-app message' as channels
FROM netflix_customers
WHERE churned = 0  -- Still active
  AND last_login_days BETWEEN 15 AND 30  -- Showing disengagement
  AND watch_hours > 10  -- Previously engaged
  AND monthly_fee > 10;

-- Action Plan 2: Subscription Optimization
SELECT 
    'Subscription Optimization Targets' as campaign_name,
    subscription_type as current_plan,
    COUNT(*) as customers,
    ROUND(AVG(monthly_fee), 2) as avg_current_price,
    CASE 
        WHEN subscription_type = 'Premium' AND watch_hours < 10 THEN 'Downgrade to Standard'
        WHEN subscription_type = 'Basic' AND watch_hours > 25 THEN 'Upgrade to Standard'
        WHEN subscription_type = 'Standard' AND number_of_profiles > 3 THEN 'Upgrade to Premium'
        ELSE 'Keep Current'
    END as recommended_action,
    ROUND(AVG(CASE 
        WHEN subscription_type = 'Premium' AND watch_hours < 10 THEN 13.99  -- Downgrade savings
        WHEN subscription_type = 'Basic' AND watch_hours > 25 THEN 5.00     -- Upgrade cost
        ELSE monthly_fee
    END), 2) as recommended_price
FROM netflix_customers
WHERE churned = 0
GROUP BY subscription_type,
    CASE 
        WHEN subscription_type = 'Premium' AND watch_hours < 10 THEN 'Downgrade to Standard'
        WHEN subscription_type = 'Basic' AND watch_hours > 25 THEN 'Upgrade to Standard'
        WHEN subscription_type = 'Standard' AND number_of_profiles > 3 THEN 'Upgrade to Premium'
        ELSE 'Keep Current'
    END
HAVING COUNT(*) > 10;

-- Action Plan 3: Payment Method Optimization
SELECT 
    'Payment Method Conversion Targets' as initiative,
    payment_method as current_method,
    region,
    COUNT(*) as customers,
    SUM(churned) as churned_from_this_method,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    CASE 
        WHEN payment_method = 'Gift Card' THEN 'Convert to Credit Card with 1-month free'
        WHEN payment_method = 'Crypto' THEN 'Convert to PayPal with enhanced security'
        WHEN payment_method = 'Debit Card' THEN 'Offer annual subscription discount'
        ELSE 'No action needed'
    END as conversion_strategy,
    CASE 
        WHEN payment_method IN ('Gift Card', 'Crypto') THEN 'High Priority'
        WHEN churn_rate > 20 THEN 'Medium Priority'
        ELSE 'Low Priority'
    END as priority
FROM netflix_customers
GROUP BY payment_method, region
ORDER BY priority, churn_rate DESC;

-- ==============================================
-- 11. ROI CALCULATION FOR RETENTION EFFORTS
-- ==============================================

-- Calculate potential ROI of different interventions
WITH intervention_costs AS (
    SELECT 
        'Personalized Content Recommendations' as intervention,
        0.50 as cost_per_customer,
        0.15 as expected_success_rate  -- 15% reduction in churn
    UNION ALL
    SELECT '30% Discount for 3 Months', 4.00, 0.25
    UNION ALL
    SELECT 'Free Month Offer', 13.99, 0.30
    UNION ALL
    SELECT 'Subscription Downgrade Assistance', 1.00, 0.20
    UNION ALL
    SELECT 'Payment Method Conversion Bonus', 5.00, 0.18
),
at_risk_customers AS (
    SELECT 
        COUNT(*) as total_at_risk,
        ROUND(SUM(monthly_fee), 2) as monthly_revenue_at_risk,
        ROUND(AVG(monthly_fee), 2) as avg_monthly_value
    FROM netflix_customers
    WHERE churned = 0 
      AND (last_login_days > 20 OR watch_hours < 5)
)
SELECT 
    i.intervention,
    a.total_at_risk as applicable_customers,
    ROUND(a.avg_monthly_value * 12, 2) as avg_annual_value_per_customer,
    ROUND(i.cost_per_customer * a.total_at_risk, 2) as total_intervention_cost,
    ROUND(a.monthly_revenue_at_risk * 12 * i.expected_success_rate, 2) as annual_revenue_saved,
    ROUND(
        (a.monthly_revenue_at_risk * 12 * i.expected_success_rate) - 
        (i.cost_per_customer * a.total_at_risk), 2
    ) as net_annual_benefit,
    ROUND(
        ((a.monthly_revenue_at_risk * 12 * i.expected_success_rate) - 
        (i.cost_per_customer * a.total_at_risk)) / 
        (i.cost_per_customer * a.total_at_risk) * 100, 2
    ) as roi_percentage
FROM intervention_costs i
CROSS JOIN at_risk_customers a
ORDER BY roi_percentage DESC;

-- ==============================================
-- 12. IMPLEMENTATION ROADMAP
-- ==============================================

-- Phase-based implementation plan
SELECT 
    'Phase 1: Quick Wins (Month 1-2)' as phase,
    'Target inactive Premium users' as initiative,
    COUNT(*) as target_customers,
    ROUND(SUM(monthly_fee * 3), 2) as qtr_revenue_opportunity
FROM netflix_customers
WHERE churned = 0 
  AND subscription_type = 'Premium'
  AND last_login_days > 20

UNION ALL

SELECT 
    'Phase 2: Value Optimization (Month 3-4)' as phase,
    'Right-size subscription plans' as initiative,
    COUNT(*) as target_customers,
    ROUND(SUM(
        CASE 
            WHEN subscription_type = 'Premium' AND watch_hours < 10 THEN 13.99 - monthly_fee
            WHEN subscription_type = 'Basic' AND watch_hours > 25 THEN monthly_fee - 8.99
            ELSE 0
        END
    ), 2) as revenue_impact
FROM netflix_customers
WHERE churned = 0

UNION ALL

SELECT 
    'Phase 3: Payment Stability (Month 5-6)' as phase,
    'Convert high-risk payment methods' as initiative,
    COUNT(*) as target_customers,
    ROUND(SUM(monthly_fee * 0.15), 2) as incentive_cost
FROM netflix_customers
WHERE churned = 0 
  AND payment_method IN ('Gift Card', 'Crypto')

UNION ALL

SELECT 
    'Phase 4: Proactive Retention (Month 7-12)' as phase,
    'Implement predictive churn model' as initiative,
    COUNT(*) as target_customers,
    50000.00 as implementation_cost  -- Estimated ML model cost
FROM netflix_customers
WHERE churned = 0
LIMIT 1;