-- Query 01: calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month)--
SELECT  
  FORMAT_DATE ('%Y%m', PARSE_DATE('%Y%m%d',date)) as month
  , COUNT (totals.visits) AS visit
  , SUM (totals.pageviews) as pageviews
  , SUM (totals.transactions) as transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;


--Query 02: Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
SELECT 
  trafficSource.source
  , COUNT (totals.visits) AS total_visits
  , COUNT (totals.bounces) AS total_no_of_bounces
  , ROUND (100.000* (COUNT (totals.bounces)/COUNT (totals.visits)),3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` 
GROUP BY 1
ORDER BY 2 DESC ;


--Query 03: Revenue by traffic source by week, by month in June 2017

WITH 
month_data as(
  SELECT
    "Month" as time_type,
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    trafficSource.source AS source,
    SUM(p.productRevenue)/1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    unnest(hits) hits,
    unnest(product) p
  WHERE p.productRevenue is not null
  GROUP BY 1,2,3
  order by revenue DESC
),

week_data AS(
  SELECT
    "Week" AS time_type,
    format_date("%Y%W", parse_date("%Y%m%d", date)) AS week,
    trafficSource.source AS source,
    SUM(p.productRevenue)/1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    unnest(hits) hits,
    unnest(product) p
  WHERE p.productRevenue is not null
  GROUP BY 1,2,3
  ORDER BY revenue DESC
)

SELECT * FROM month_data
UNION ALL
SELECT * FROM week_data;
ORDER BY time_type


--Query 04: Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.

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



--Query 05: Average number of transactions per user that made a purchase in July 2017
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



--Query 06: Average amount of money spent per session. Only include purchaser data in July 2017
SELECT 
  FORMAT_DATE ('%Y%m', PARSE_DATE('%Y%m%d',date)) as month
  ,ROUND ((SUM (product.productRevenue)/1000000)/ SUM (totals.visits),2) AS avg_spend_per_session 
 FROM 
     `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST (hits) AS hits,
    UNNEST (hits.product) AS product
WHERE totals.transactions IS NOT NULL and product.productRevenue is not null
GROUP BY month;


--Query 07: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.
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



--Query 08: Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase.

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
ORDER BY month ;


--Cách 1:dùng CTE
with
product_view as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_product_view
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '2'
  GROUP BY 1
),

add_to_cart as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_addtocart
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '3'
  GROUP BY 1
),

purchase as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '6'
  and product.productRevenue is not null   --phải thêm điều kiện này để đảm bảo có revenue
  group by 1
)

select
    pv.*,
    num_addtocart,
    num_purchase,
    round(num_addtocart*100/num_product_view,2) as add_to_cart_rate,
    round(num_purchase*100/num_product_view,2) as purchase_rate
from product_view pv
left join add_to_cart a on pv.month = a.month
left join purchase p on pv.month = p.month
order by pv.month;
