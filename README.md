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
- **Analysis Period** : September 2016 – October 2018  
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
- **Churn Customer** : Made only one purchase, and that purchase occurred more than 6 months before the end of the analysis period.  
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
Even top-performing sellers struggled with delivery delays.  
Sellers with high review scores and large order volumes still had a late delivery rate of up to **11.3%**, worse than some lower-performing sellers. The platform needs strict, consistent SLA standards that apply to all sellers without exception.

**Finding 5**  
Churn is likely driven by external factors.  
After ruling out delivery performance, review scores, and product category as primary causes, the main reason appears to be the **absence of retention strategies** — such as loyalty programs and personalized recommendations.

## 6. Business Recommendations

### Retention
- Implement a **loyalty program based on RFM segmentation** and payment type. Prioritize high-potential customers and offer extra benefits for those who pay with credit cards (the most popular payment method).  
- Send targeted **email marketing campaigns** to new customers and create re-engagement campaigns with attractive promotions after 5 months of inactivity.

### Seller Management
- Establish a clear **SLA for delivery** that applies to all seller segments without exception.  
- Conduct regular monitoring of risky sellers with an early warning system before delivery issues affect customer experience.

### Operational
- Investigate and eliminate cases of delivery delays longer than **10 days** — these have the biggest negative impact on customer satisfaction.  
- Strengthen seller supply in states with the highest number of customers to reduce lead time.

All recommendations are designed to improve customer retention so the business is less dependent on constantly acquiring new buyers.

## 7. Project Structure
<img width="262" height="336" alt="Screen Shot 2026-04-13 at 16 20 53" src="https://github.com/user-attachments/assets/a56478e4-8435-4136-a180-f4cf3b39beac" />

## 8. Dashboard Preview
Business Health
<img width="1111" height="628" alt="Screenshot 2026-04-18 021300" src="https://github.com/user-attachments/assets/b3e1a71e-f771-4e2e-99a5-9d2578779e3e" />
Customer Composition
<img width="1110" height="626" alt="Screenshot 2026-04-18 021408" src="https://github.com/user-attachments/assets/17ed830e-24c1-443f-861e-3fb2f6cca5f3" />
Indentify Factors That Influence Churn
<img width="1108" height="625" alt="Screenshot 2026-04-18 021600" src="https://github.com/user-attachments/assets/4cb90e1e-f3fe-474e-a6f9-95fc5de28ea1" />
Seller Performance
<img width="1107" height="626" alt="Screenshot 2026-04-18 022425" src="https://github.com/user-attachments/assets/89427b66-20f9-4496-9593-7bc153411319" />


## 9. Limitations & Next Steps
- The dataset only covers 2016–2018 and cannot capture more recent trends.  
- No competitor data is available, so market share cannot be measured.  
- External churn factors (pricing, competitors, other platforms) cannot be analyzed from this dataset.


