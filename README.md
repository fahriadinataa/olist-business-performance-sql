# The 2% Problem  
**Uncovering Business Performance and Customer Churn in Olist Brazilian Marketplace**

**[Click here to view the full interactive Power BI Dashboard](https://drive.google.com/file/d/1SB-oBzipjdEYXOk-72AJ5QayjU2Xh6mI/view?usp=sharing)**

## 1. The Problem Statement

Olist’s business exploded in the early period, achieving **700% YoY growth** in January 2018 compared to January 2017.  

However, within less than a year, growth slowed dramatically to only **50%** (August 2018 vs August 2017).  

Although revenue continued to rise, nearly all of that growth came from new customers.  
**Only 2.2% of customers ever made a repeat purchase.**  

Why?

## 2. Dataset Overview

- **Source** : Kaggle - Olist Brazilian E-Commerce  
- **Analysis Period** : September 2016 – August 2018 
- **Note** : September and October 2018 data were excluded due to negligible volume and not representative for analysis.                      
- **Scope** : Brazilian marketplace orders  
- **Data Model** : Star Schema (1 Fact Table + 5 Dimension Tables)

## 3. Objectives & Business Questions

- How is the overall business performance of Olist E-Commerce?  
- What is the customer retention rate?  
- Do delivery performance and seller performance influence customer churn?

## 4. Methodology

### Data Modeling
The original Olist dataset consisted of 3 fact tables (orders, order payments, order items) and 4 dimension tables (customers, sellers, products, order reviews).  

For this analysis, I consolidated them into **1 Fact Table** (`new_fact_order`) and **5 Dimension Tables** (customers, sellers, products, order reviews, and date range). This transformation was done to create a clean star schema, making it much easier to join tables and perform analysis.

### New Fact Table
I merged the orders, order payments, and order items tables into a single fact table. This new table combines all relevant keys into one place and includes only the columns needed for analysis. The result is a cleaner, more organized dataset that is easier to understand and query.

### Customer Retention Segmentation
Customers were divided into three segments:  
- **Churn Customer** : Made only one purchase, and that purchase occurred more than 5 months before the end of the analysis period.  
- **Repeat Customer** : Made more than one purchase during the entire analysis period.  
- **One-time Customer** : Made only one purchase within the last 5 months of the analysis period.  

The 5-month threshold was determined from cohort analysis, which showed that customers typically make their next purchase around 5 months after the previous one.

### Tools
- **MySQL** : Used for data understanding, cleaning, preparation, and exploratory data analysis.  
- **Power BI** : Used to build interactive dashboards for presenting the analysis results.

## 5. Key Findings

**Finding 1**  
Olist experienced strong growth in the early period, which gradually slowed over time. YoY GMV growth ranged from **50% to 700%**. Overall, 97% of orders were successfully delivered, with only about 1.2% of orders failed.

**Finding 2**  
Growth was driven almost entirely by new customers rather than retention.  
Customer composition: **65.8% churn customers**, **32.0% one-time customers**, and only **2.2% repeat customers**.  
The business is highly dependent on acquiring new buyers, which increases the risk of rising Customer Acquisition Cost (CAC) in the future.

**Finding 3**  
Delivery performance and product category had only a moderate impact on churn and were not the main drivers.
Churn customers experienced an average lead time of 13.84 days (19% longer than repeat customers) and a 54.5% higher late order rate. However, the top 5 product categories purchased by churn and repeat customers were almost identical, and review scores were also very similar. This indicates churn was not primarily driven by product type or one-time purchase intent.

**Finding 4**  
The most critical finding is that underperforming sellers represent 95% of the total seller base and contribute the vast majority of GMV and Even top-performing sellers struggled with delivery delays. Sellers with high review scores and large order volumes still had a late delivery rate of up to **11.3%**, worse than some lower-performing sellers. The platform needs strict, consistent SLA standards that apply to all sellers without exception. 

**Finding 5**  
Churn is likely driven by external factors.  
After ruling out delivery performance, review scores, and product category as primary causes, the main reason appears to be the **absence of retention strategies** such as loyalty programs and personalized recommendations.

## 6. Business Recommendations

### Retention & Customer Strategy
**Re-engagement Campaign Based on Customer Lifecycle**  
With an average repeat purchase occurring at 4.82 months, re-engagement campaigns should be triggered in the fourth month after the last purchase, before customers enter the churn zone. Waiting until the fifth month is already too late.

**Priority Targeting by RFM Segment**  
Cannot Lose Them (16.6%) : High-frequency customers with low recency. Offer exclusive vouchers or early access to new products to re-ignite their loyalty.
Hibernating (24.6%) : The largest at-risk segment. Use urgency-driven campaigns such as limited-time offers and flash sales.
Potential Loyalist (18.7%) : Customers with 1–2 purchases but still good recency. Focus on relevant cross-selling within the same product category rather than generic recommendations.
New Customers (13%) : Provide post-purchase nurturing through follow-up emails, satisfaction surveys, and limited-time discounts to encourage a second purchase.

**Loyalty Program Aligned with Payment Behavior**  
Since 74.75% of customers use credit cards as their primary payment method, the most effective loyalty program for this group is cashback or reward points per transaction. This approach feels familiar to credit card users and has a higher chance of influencing repeat behavior.

### Seller Management
**Implement Platform-Wide SLA Standards**  
A uniform Service Level Agreement (SLA) for delivery must be enforced across all seller segments without exception. High-volume Top Sellers with elevated late delivery rates pose a greater absolute risk than lower-volume Risky Sellers due to their large order contribution. Stricter SLA thresholds should be applied to sellers with more than 500 orders. 

**Tiered Warning System for Risky Sellers**   
Introduce a three-stage monitoring system:
Yellow Flag - Late rate > 7% in the last 30 days: Send warning notification.
Orange Flag - Late rate > 9% in the last 30 days: Temporarily lower seller ranking on the platform.
Red Flag - Late rate > 12% in the last 60 days: Initiate contract review.

**Seller Development Program for Underperformers**  
The most critical finding is that underperforming sellers represent 95% of the total seller base and contribute the vast majority of GMV. Prioritize the following:
Identify the top 50–100 underperforming sellers with the highest order volume and review scores close to 4.0 — these are the strongest candidates to become “Potential Sellers.”
Provide targeted onboarding, fulfillment training, and performance coaching for this group, as improving them will have significantly higher impact on overall GMV than focusing solely on the 19 existing Top Sellers.

### Operational and Delivery
**Eliminate Severe Late Deliveries (10+ days)**  
Severe late deliveries (10+ days) are 27 times higher among churn customers (1,775 cases) compared to repeat customers (64 cases). Focus investigation and intervention efforts specifically on these high-impact cases rather than minor delays.  
Action Steps:
- Analyze patterns to determine whether severe delays are concentrated by specific sellers, states, or product categories.
- If concentrated in certain states, increase local seller supply in those regions.
- If concentrated among specific sellers, escalate them into the warning system above.- Strengthen seller supply in states with the highest number of customers to reduce lead time.

**Strategic Seller Expansion Beyond São Paulo (SP)**  
While SP dominates with over 40,000 customers, other key states (RJ, MG, RS, and PR) also have significant customer bases. Orders shipped across states are likely contributing to longer lead times. Recruiting and onboarding local sellers in these four states will directly reduce delivery distance and improve overall lead time performance.

*All recommendations are designed to improve customer retention so the business is less dependent on constantly acquiring new buyers.*

## 7. Project Structure
<img width="262" height="336" alt="Screen Shot 2026-04-13 at 16 20 53" src="https://github.com/user-attachments/assets/a56478e4-8435-4136-a180-f4cf3b39beac" />

## 8. Dashboard Preview
**Business Health**
<img width="1111" height="628" alt="Screenshot 2026-04-18 021300" src="https://github.com/user-attachments/assets/b3e1a71e-f771-4e2e-99a5-9d2578779e3e" />

**Customer Composition**
<img width="1110" height="626" alt="Screenshot 2026-04-18 021408" src="https://github.com/user-attachments/assets/17ed830e-24c1-443f-861e-3fb2f6cca5f3" />

**Indentify Factors That Influence Churn**
<img width="1108" height="625" alt="Screenshot 2026-04-18 021600" src="https://github.com/user-attachments/assets/4cb90e1e-f3fe-474e-a6f9-95fc5de28ea1" />

**Seller Performance**
<img width="1107" height="626" alt="Screenshot 2026-04-18 022425" src="https://github.com/user-attachments/assets/89427b66-20f9-4496-9593-7bc153411319" />

## 9. Limitations & Next Steps
- The dataset only covers 2016–2018 and cannot capture more recent trends.  
- No competitor data is available, so market share cannot be measured.  
- External churn factors (pricing, competitors, other platforms) cannot be analyzed from this dataset.


