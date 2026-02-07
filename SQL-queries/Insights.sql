-- 34% of customers watch less than 5 hours/month!
SELECT 
    CASE 
        WHEN watch_hours = 0 THEN 'Zero (34%)'
        WHEN watch_hours <= 5 THEN 'Very Low (20%)' 
        WHEN watch_hours <= 15 THEN 'Low (25%)'
        ELSE 'Engaged (21%)'
    END as usage_segment,
    COUNT(*) as customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate
FROM netflix_customers
GROUP BY 1;


-- Premium customers have HIGHEST churn!
SELECT 
    subscription_type,
    COUNT(*) as customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(monthly_fee), 2) as avg_fee,
    ROUND(AVG(watch_hours), 1) as avg_watch_hours
FROM netflix_customers
GROUP BY subscription_type
ORDER BY churn_rate DESC;

-- Gift Cards are churn machines
SELECT 
    payment_method,
    COUNT(*) as customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(monthly_fee), 2) as avg_fee
FROM netflix_customers
GROUP BY payment_method
ORDER BY churn_rate DESC;


-- Tablets have worst retention
SELECT 
    device,
    COUNT(*) as customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(watch_hours), 1) as avg_watch_hours
FROM netflix_customers
GROUP BY device
ORDER BY churn_rate DESC;


-- Some genres retain poorly
SELECT 
    favorite_genre,
    COUNT(*) as customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2) as churn_rate,
    ROUND(AVG(age), 1) as avg_age
FROM netflix_customers
WHERE favorite_genre != ''
GROUP BY favorite_genre
HAVING COUNT(*) > 10
ORDER BY churn_rate DESC
LIMIT 5;