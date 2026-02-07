# Netflix Customer Churn Analysis — Revenue Loss & Retention Optimization

## Project Overview

This project analyzes customer churn data from a Netflix-style subscription platform to identify *why customers churn*, *which segments drive the most revenue loss*, and *where retention actions deliver the highest ROI*.

The analysis reveals **~$30,000–33,000 USD in recurring monthly revenue loss due to churn**. Instead of treating churn as a single KPI, this project decomposes churn into **engagement behavior, subscription mismatch, payment stability, and usage patterns** to produce business-actionable insights.

---

## Business Problem

Despite strong content availability and global reach, the platform experiences **~50% churn across all regions**.

Key leadership challenges:

* What *actually* causes customers to churn?
* Which customer segments are responsible for most revenue loss?
* Is churn driven by pricing, engagement, payments, or platform usage?
* Where should retention investment be focused for maximum financial impact?

---

## Key Business Questions

* Do low-engagement users churn because of poor value perception?
* Are certain subscription plans mismatched with actual usage?
* Do payment methods signal short-term vs long-term intent?
* When does churn become irreversible in the customer lifecycle?
* Is churn region-specific or systemic?

---

## Insights Summary (TL;DR)

* **~$33K lost per month** due to customer churn
* **Premium plan overpayment + risky payment methods** drive most revenue loss
* **First 30 days** are critical for retention
* Churn is **platform-wide**, not region-specific
* **~43% of users cause >60% of revenue loss (80–20 confirmed)**

---

## Key Insights & Business Interpretation

### 1. Payment Method Drives Churn Risk

**Insight**

* Gift Card / Crypto users: **58–60% churn**
* Credit/Debit users: **30–40% churn**
* These users form **24.4% of customers** but cause **29.2% of revenue loss**

**Business Meaning**
Prepaid and unstable payment methods correlate with short-term usage behavior and weak retention intent.

---

### 2. Premium Subscription Mismatch Is the Largest Revenue Leak

**Insight**

* **19.3%** of users pay for Premium but watch **<10 hours**
* Their churn rate: **61.1%**
* Revenue loss contribution: **32.2%**

**Business Meaning**
Customers overpay for unused value and churn instead of downgrading.

---

### 3. First 30 Days Decide Retention

**Insight**

* Churn spikes during **Day 7–30**
* After 30 days of low engagement → **~75% churn**
* Retained users watch **~5× more content** in the first month

**Business Meaning**
Retention is a *front-loaded* problem. Early engagement determines lifetime value.

---

### 4. Device Experience Impacts Engagement

**Insight**

* Mobile/Tablet low-usage users → **81.5% churn**
* TV users retain best

**Business Meaning**
Poor viewing experience or friction on mobile accelerates disengagement.

---

### 5. Region Is Not the Root Cause

**Insight**

* All regions show **~48–52% churn**

**Business Meaning**
Churn is driven by platform behavior, not geography.

---

### 6. Multiple Profiles Improve Retention

**Insight**

* 1–3 profiles: **~58% churn**
* 4–5 profiles: **~40% churn**

**Business Meaning**
Household adoption increases stickiness and switching cost.

---

## 80–20 Rule Validation

| Segment             | % Customers | % Revenue Loss |
| ------------------- | ----------- | -------------- |
| Premium Overpayers  | 19.3%       | 32.2%          |
| Risky Payment Users | 24.4%       | 29.2%          |

**~43% of users drive >60% of revenue loss**

---

## Final Business Problem Statement

Customer churn is driven by **subscription-value mismatch, low early engagement, and payment instability**, not content availability or region.

---

## Strategic Recommendations

1. **Reduce Payment Risk**
   Incentivize Credit/Debit payments, limit long-term reliance on prepaid methods

2. **Fix Premium Plan Mismatch**
   Detect low-usage Premium users early and proactively downgrade

3. **Optimize First-Month Engagement**
   Trigger onboarding nudges in first 7–14 days

4. **Improve Mobile & Tablet Experience**
   Reduce friction, optimize streaming UX

5. **Promote Multi-Profile Adoption**
   Encourage household usage early

---

## Business Impact

* **Monthly revenue loss:** ~$33,000
* **Annual recoverable revenue:** ~$126,688
* **Estimated implementation cost:** ~$25,470
* **Projected ROI:** ~5×

---

## Analytical Approach (End-to-End)

1. Data understanding & metric definition
2. Data cleaning & validation (Python)
3. Exploratory analysis (SQL + Python)
4. Feature engineering (engagement, churn segments)
5. Churn segmentation & revenue impact analysis
6. Tableau dashboards with interactive KPIs
7. Business recommendations framed in revenue terms

---

## Tools & Technologies

* SQL
* Python (Pandas, Matplotlib)
* Excel
* Tableau Public
* GitHub

---

## Why This Project Matters

This project demonstrates the ability to:

* Translate churn metrics into **revenue impact**
* Apply **business-first analytics**, not just dashboards
* Identify **actionable retention levers** without ML overengineering

---

