# E-commerce Website Performance Analysis - SQL, BigQuery

![image](https://github.com/user-attachments/assets/93bd330a-0a29-49db-8546-131cf26f59cc)


Author: Nguyễn Thị Ánh Minh 

Date:  2025/01/10

Tools Used: SQL

***

# 📑 Table of Contents 

- [📌Background & Overview](#background--overview)

- [📂 Dataset Description & Data Structure](#dataset-description--data-structure)

- [🌈 Main Process](#main-process)

- [🔎Final Conclusions & Recommendations](#final-conclusions--recommendations)
  

***
# 📌Background & Overview

## Objective

**📖 What is this project about? What Business Questions will it solve?** 

This project focuses on analyzing data from an e-commerce website (based on Google Analytics Data), uncovering key performance metrics and user behavior insights. The SQL queries are designed to:

- **Evaluate the overall performance** of the website (visits, pageviews, transactions).

- **Analyze revenue performance** by traffic source and over time.

- **Compare behavior** between purchasers and non-purchasers.

- **Assess conversion rates** in the sales funnel (from product view to purchase).

**👤 Who is this project for?**

- **Aspiring Data Analysts**:

Those who want to practice and showcase their SQL skills.

Those looking to understand how to analyze e-commerce data.


- **E-commerce Business Owners:**

Those who want to gain insights into user behavior and sales performance.

Those seeking to identify optimization opportunities for their website.

***

# 📂Dataset Description & Data Structure

**📌 Data Source**

- Source: Ga_sessions (from Public dataset in Google Analytics Sample Dataset on BigQuery)

- Size: ~467260 rows

- Time Analyzed: January 2017 to July 2017

**📊 Data Structure & Relationships**

1️⃣ Tables Used:

1 table is used in the dataset.


2️⃣ Table Schema & Data Snapshot

Key Fields Used: `fullVisitorId`, `VisitorId`, `date`, `totals` (records with `visits`, `hits`, `pageviews`, `bounces`, `transactions`),`trafficSource.source`, `totals.transactions`, `totals.pageviews`, `product.productRevenue`, `product.productQuantity`, `product.v2ProductName`, `hits.eCommerceAction`. 

Table Scheme: [[UA] BigQuery Export schema [Legacy]](https://support.google.com/analytics/answer/3437719?hl=en)

---

# 🌈Main Process: 

## 1️⃣ Data Preparation (Cleaning & Processing) 

Important steps in preparing the data through SQL queires, for example: 

- **Schema Exploration:** Accessing nested fields such as `hits` and `hits.products` using the UNNEST() function.

- **Data Type Conversion:** `Date` field was converted from `String` format to `Datetime` format by using Parsing function.

- **Metric Calculation:** Computing key metrics such as total_visit, bounce_rate.

- **Data Filtering:** Narrowing down the dataset such as using query `WHERE _table_suffix BETWEEN '0101' AND '0331'` to get the data from Jan 01 to Mar 31.

## 2️⃣ Exploratory Data Analysis (EDA)

### SQL Analysis Tasks:

#### TASK 1: MONTHLY OVERVIEW (January, February, March 2017)

 - 📌 **Requirement:** Calculate total visit, pageview, transaction for Januart, February and March 2017 (order by month)
 
 - ️🎯 **Analytical Purpose:** This analysis aims to monitor key website metrics — total visits, pageviews, and transactions — aggregated monthly during Q1 2017. By transforming raw date strings into structured datetime formats, the query enables a clear month-over-month comparison. The goal is to uncover user interaction trends and evaluate how effectively the website drives engagement and conversions over time.
  
 -  📝**SQL Query:**

```sql
SELECT  
  FORMAT_DATE ('%Y%m', PARSE_DATE('%Y%m%d',date)) as month
  , COUNT (totals.visits) AS visit
  , SUM (totals.pageviews) as pageviews
  , SUM (totals.transactions) as transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;
```

- ️🖼 **Results Snapshot:**

![image](https://github.com/user-attachments/assets/5df25df0-b6d6-4d9d-9dd3-67fd3e46c2e2)

- **📊 Observation:**

    - During Q1 of 2017, there was **a gradual increase in total visits, pageviews, and transactions** over the three months:
    
    - Transactions rose from 713 in January to 993 in March.
    
    - Both visits and pageviews followed a similar upward trend, indicating improved website performance and better conversion capabilities toward the end of the quarter.
    
    ➡️ This may suggest **enhancements in user experience or more effective marketing campaigns** implemented in March.

#### TASK 2: BOUNCE RATE BY TRAFFIC SOURCE (July 2017)

 - 📌 **Requirement:** Analyze bounce rate by traffic source in July 2017 to evaluate the effectiveness of different acquisition channels.

 - 🎯 **Analytical Purpose:** This query helps identify which sources drive engaged users by calculating the bounce rate (percentage of single-page sessions) per traffic source. A lower bounce rate indicates better user engagement and potentially higher content relevance.

 - 📝**SQL Query:**
```sql
SELECT 
  trafficSource.source
  , COUNT (totals.visits) AS total_visits
  , COUNT (totals.bounces) AS total_no_of_bounces
  , ROUND (100.000* (COUNT (totals.bounces)/COUNT (totals.visits)),3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` 
GROUP BY 1
ORDER BY 2 DESC ;
```

 - 🖼 **Results Snapshot:**

![image](https://github.com/user-attachments/assets/b44099ce-761f-41d6-bcba-2e71215d44b0)


 - **📊 Observation:**

    - Google is the top traffic source with **38,400 visits** and **a bounce rate of 51.56%** , indicating **a moderate of user engagement**. 
    
    - Direct traffic performs relatively well with **a lower bounce rate of 43.27%**, suggesting that users who access the site directly are more engaged. 
    
    - Youtube shows **the highest bounce rate with 66.73%**, which may imply weaker intent or mismatched content expectations from users. 

#### TASK 3: REVENUE BY TRAFFIC SOURCE (June 2017) 

- 📌 **Requirement:** Track and compare revenue performance by traffic source, both on a weekly and monthly basis for June 2017.

- 🎯 **Analytical Purpose:** This query provides insights into how different traffic sources contribute to total revenue, broken down by **time granularity**. It helps identify high-performing sources and evaluate consistency in revenue generation over time.

- 📝**SQL Query:**
```sql
WITH 
month_data as(
  SELECT
    "Month" as time_type,
    FORMAT_DATE ("%Y%m", PARSE_DATE("%Y%m%d", date)) as month,
    trafficSource.source AS source,
    SUM(p.productRevenue)/1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST (hits) hits,
    UNNEST (product) p
  WHERE p.productRevenue IS NOT NULL
  GROUP BY 1,2,3
  ORDER BY revenue DESC
),

week_data AS(
  SELECT
    "Week" AS time_type,
    FORMAT_DATE format_date("%Y%W", PARSE_DATE ("%Y%m%d", date)) AS week,
    trafficSource.source AS source,
    SUM(p.productRevenue)/1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST (hits) hits,
    UNNEST (product) p
  WHERE p.productRevenue IS NOT NULL
  GROUP BY 1,2,3
  ORDER BY revenue DESC
)

SELECT *
FROM month_data
UNION ALL
SELECT *
FROM week_data;
ORDER BY time_type;
```

- 🖼 **Results Snapshot:**
   ![image](https://github.com/user-attachments/assets/d2890802-475a-4462-b9a3-3dc5a72a6e5d)


- **📊 Observation:**

    - The **direct traffic source** brought the **highest revenue** in June 2017: Monthly: $97,333.62
    
    - Weekly breakdown: Peaks in week 24 ($30,908.91) and week 25 ($27,295.32).
    
    - **Google** contributed **less revenue** in comparison with $18,757.18 for the whole month.
    
    - The fluctuation across weeks helps pinpoint which periods and sources were most profitable, suggesting the importance of direct user loyalty or effective offline/brand marketing.

#### TASK 4: AVERAGE NUMBER OF PAGEVIEWS BY PURCHASE TYPE ( June & July 2017) 

 - 📌 **Requirement:** Analyze user engagement by comparing the average number of pageviews between purchasers and non-purchasers during June and July 2017.

 - 🎯 **Analytical Purpose:** To understand whether users who make purchases interact more or less with the website compared to those who do not. This helps assess user behavior patterns and potential friction in the buying journey.

 - 📝**SQL Query:**
```sql
with 
purchaser_data as(
  select
      format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
      (sum(totals.pageviews)/count(distinct fullvisitorid)) as avg_pageviews_purchase,
  from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    ,unnest(hits) hits
    ,unnest(product) product
  where _table_suffix between '0601' and '0731'
  and totals.transactions>=1
  and product.productRevenue is not null
  group by month
),

non_purchaser_data as(
  select
      format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
      sum(totals.pageviews)/count(distinct fullvisitorid) as avg_pageviews_non_purchase,
  from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
      ,unnest(hits) hits
    ,unnest(product) product
  where _table_suffix between '0601' and '0731'
  and totals.transactions is null
  and product.productRevenue is null
  group by month
)

select
    pd.*,
    avg_pageviews_non_purchase
from purchaser_data pd
full join non_purchaser_data using(month)
order by pd.month;
```

 - 🖼 **Results Snapshot:**

 ![image](https://github.com/user-attachments/assets/56f4f946-5044-48cc-9590-77ef579873cf)

 - **📊 Observation:**

    - **Non-purchasers consistently viewed 3 to 4 times** more pages on average **than purchasers** in both months.

    - Purchasers had fewer pageviews per user, possibly indicating more efficient or direct paths to conversion.

    - In contrast, non-purchasers explored more pages but did not convert, suggesting potential barriers in the conversion funnel (e.g., pricing, navigation issues, or unclear CTAs).

    -  From June to July, both segments showed an increase in engagement, especially among purchasers (+32% in avg. pageviews).

#### TASK 5: AVERAGE NUMBER OF TRANSACTIONS PER USER (July 2017) 

- 📌 **Requirement:** Calculate the average number of transactions per user in July 2017.

 - 🎯 **Analytical Purpose:**

    - To measure the performance of users who made transactions during July.
    - This metric helps identify whether users tend to make repeated purchases or only transact once.

 - 📝**SQL Query:**
  
```sql
WITH data_raw as (
        SELECT 
                FORMAT_DATE ('%Y%m', PARSE_DATE('%Y%m%d',date)) as month
                ,COUNT (DISTINCT fullVisitorId) as num_user 
                , SUM (totals.transactions) as total_transaction_purchase
                , CASE 
                        WHEN totals.transactions>=1 AND product.productRevenue IS NOT NULL THEN 'purchase' END AS user_type
        FROM 
                `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
                UNNEST (hits) AS hits,
                UNNEST (hits.product) AS product
        WHERE product.productRevenue IS NOT NULL 
        GROUP BY month, user_type) 

SELECT 
    month
    ,ROUND (total_transaction_purchase/ num_user,9) as Avg_total_transactions_per_user
FROM data_raw;
```

 - 🖼 **Results Snapshot:**

![image](https://github.com/user-attachments/assets/d42b3077-1321-49b3-8f5e-ffb44a7f15ee)

 - **📊 Observation:**
   
      - In July 2017, each purchasing user made an average of **4.16 transactions.**
      
      - This is **a relatively high number**, indicating that these users are either: Returning for repeat purchases, or Purchasing multiple products in separate sessions.
      
      - It may reflect the success of marketing campaigns, strong user experience (UX), or increased seasonal demand.
      
      💡 This metric can be used to identify high-value customer segments for targeted remarketing or exclusive offers.
       

#### TASK 6: AVERAGE AMOUNT OF MONEY SPENT PER SESSION (July 2017) 

 - 📌 **Requirement:** Calculate the average amount of money spent per session in July 2017.

 - 🎯 **Analytical Purpose:**
     - Evaluate customer spending behavior per session.

    - Help identify monetary value per session to optimize marketing or site experience.

 - 📝**SQL Query:**
```sql
SELECT 
  FORMAT_DATE ('%Y%m', PARSE_DATE('%Y%m%d',date)) as month
  ,ROUND ((SUM (product.productRevenue)/1000000)/ SUM (totals.visits),2) AS avg_spend_per_session 
 FROM 
     `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST (hits) AS hits,
    UNNEST (hits.product) AS product
WHERE totals.transactions IS NOT NULL and product.productRevenue IS NOT NULL
GROUP BY month;
```
 - 🖼 **Results Snapshot:**

![image](https://github.com/user-attachments/assets/20a44697-6d48-4f27-8f61-3de623bd8f6d)

 - **📊 Observation:** Average revenue per session in July 2017 is **43.86**

#### TASK 7: OTHERS PRODUCTS PURCHASED BY CUSTOMER (July 2017)

 - 📌 **Requirement:** Find other products purchased by customers who bought "YouTube Men's Vintage Henley" during July 2017.

 - 🎯 **Analytical Purpose:**

    - Understand cross-sell opportunities by identifying which products are frequently bought together.
  
    - Reveal patterns in customer purchasing behavior for potential bundling strategies.


 - 📝**SQL Query:**
```sql
WITH customers AS (
        SELECT  DISTINCT fullVisitorId
        FROM 
            `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
            UNNEST(hits) AS hits,
            UNNEST(hits.product) as product
        WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
            AND product.productRevenue IS NOT NULL)

SELECT 
    product.v2ProductName
    , SUM (product.productQuantity) AS quantity
FROM      `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) as product
INNER JOIN customers 
USING (fullVisitorId)
WHERE   product.v2ProductName <> "YouTube Men's Vintage Henley"
        AND product.productRevenue is not null
GROUP BY product.v2ProductName
ORDER BY quantity DESC;
```
 - 🖼 **Results Snapshot:**

![image](https://github.com/user-attachments/assets/09c5bcd9-d9d1-45e4-aacb-6bec4b0df5d8)

 - **📊 Observation:**

    - Customers who bought YouTube Men's Vintage Henley often also bought Google Sunglasses, suggesting a strong cross-sell potential.

    - Apparel and accessories are frequently bought together, which can be useful for bundle promotions or recommendation systems.



#### TASK 8: COHORT ANALYSIS ( January, February, March 2017) 

 - 📌 **Requirement:**

    - Calculate the **conversion rates** by** monthly cohort** across the funnel stages:
  
    - Product View ➜ Add to Cart ➜ Purchase
  
    - Conversion formulas:
  
        add_to_cart_rate = num_addtocart / num_product_view
  
        purchase_rate = num_purchase / num_product_view


 - 🎯 **Analytical Purpose:**
   
   -  Understand performance across each e-commerce funnel stage.

   - Identify where customers drop off most (e.g., many views but few add-to-carts).

    - Use this insight to optimize actions such as product descriptions, UX improvements, or promotions for better conversions.


 - 📝**SQL Query:**
```sql
WITH product_addtocart_cte as (
      SELECT 
            FORMAT_DATE ('%Y%m', PARSE_DATE('%Y%m%d',date)) as month
            , SUM (CASE WHEN hits.eCommerceAction.action_type = '2' THEN 1 END) as num_product_view
            , SUM (CASE WHEN hits.eCommerceAction.action_type = '3' THEN 1 END) as num_addtocart
      FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` ,
            UNNEST (hits) as hits,
            UNNEST (hits.product) AS product
      WHERE _table_suffix BETWEEN '0101' AND '0331' 
      GROUP BY month
      ORDER BY month )
, 
purchase_cte as (
      SELECT 
            FORMAT_DATE ('%Y%m', PARSE_DATE('%Y%m%d',date)) as month
            , SUM (CASE WHEN hits.eCommerceAction.action_type = '6' THEN 1 END) as num_purchase
      FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` ,
            UNNEST (hits) as hits,
            UNNEST (hits.product) AS product
      WHERE _table_suffix BETWEEN '0101' AND '0331' 
            AND product.productRevenue is not NULL
      GROUP BY month
      ORDER BY month )

SELECT 
      *
      , ROUND (product_addtocart_cte.num_addtocart/product_addtocart_cte.num_product_view *100.00,2) AS add_to_cart_rate
      , ROUND (purchase_cte.num_purchase/product_addtocart_cte.num_product_view *100.00,2) AS purchase_rate
FROM product_addtocart_cte 
JOIN purchase_cte
USING (month)
ORDER BY month;
```
 - 🖼 **Results Snapshot:**

![image](https://github.com/user-attachments/assets/5301369b-4d83-4081-a679-dbb1626790f9)


 - **📊 Observation:**

    - Both **add-to-cart and purchase rates increased** over time **from January to March**.
  
    - **March 2017 performed the best**, with 37.29% of views leading to add-to-cart and 12.64% resulting in purchases.
  
    - This may reflect the success of marketing campaigns, UX improvements, or seasonal factors during March.


--- 

# 🔎Final Conclusions & Recommendations 

## ✅ Conclusion

**1. Website Performance & Engagement**

The website maintains **stable traffic**, with metrics such as **visits, pageviews, and transactions** providing a clear picture of overall health.

**Bounce rates** vary significantly across traffic sources, indicating differences in traffic quality.

**2.User Behavior & Conversion Funnel**

The **conversion funnel** from product view → add to cart → purchase shows a steep drop-off, with **only ~10% or less completing a purchase**.

Users who made a purchase in July 2017 performed **an average of 4.16 transactions per person**, suggesting the presence of **high-value, loyal customers.**

**3.Product Insights**

Certain products, such as YouTube Men's Vintage Henley, act as “magnet” products, often purchased alongside others.

Purchasers tend to view significantly more pages per session, reflecting stronger engagement before conversion.

## 💡 Recommendations

**1. Optimize Conversion Funnel**

Investigate drop-offs at the "add to cart" stage to understand friction points.

Test strategies like **remarketing ads, personalized product suggestions**, or **first-time buyer discounts** to improve conversion rates.

**2.Enhance User Experience & Product Content**

Improve product pages with **high-quality images, clear descriptions, and customer reviews** to retain interest and drive action.

Reduce bounce rate from underperforming traffic sources by customizing landing pages for relevance.

**3.Focus on High-Value Customers**

Launch **exclusive campaigns targeting users** with high transaction counts.

Consider implementing loyalty programs, bundle offers, or early access deals to encourage repeat purchases.

**4.Leverage Cross-Selling Opportunities**

Use high-performing items (like YouTube Men's Vintage Henley) as **lead products in bundling strategies**.

Feature them in product recommendations and email campaigns to boost average order value.


   
