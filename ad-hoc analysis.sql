/*
1. Provide a list of products with a base price greater than 500 and
 that are featured in promo type of 'BOGOF' (Buy One Get One Free). 
 This information will help us identify high-value products that are
 currently being heavily discounted, which can be useful for evaluating
 our pricing and promotion strategies.
 */
SELECT
	DISTINCT FE.product_code,
    DP.product_name
FROM fact_events FE
INNER JOIN dim_products DP
ON DP.PRODUCT_CODE = FE.PRODUCT_CODE
WHERE FE.base_price > 500 AND FE.promo_type = 'BOGOF';

/*
2. Generate a report that provides an overview of the number of
 stores in each city. The results will be sorted in descending
 order of store counts, allowing us to identify the cities with
 the highest store presence.The report includes two essential
 fields: city and store count, which will assist in optimizing our retail operations.
 */
 
SELECT
	CITY,
    COUNT(DISTINCT STORE_ID) AS store_count
FROM dim_stores
GROUP BY 1
ORDER BY store_count DESC;


/*
3. Generate a report that displays each campaign along with
 the total revenue generated before and after the campaign?
 The report includes three key fields: campaign_name, totaI_revenue(before_promotion),
 totaI_revenue(after_promotion). This report should help in evaluating the financial
 impact of our promotional campaigns. (Display the values in millions)
*/


-- 1M = 1000000
WITH CalculateRevenue AS(
	SELECT
	*,
    `base_price` * `quantity_sold(before_promo)` AS revenue_before_promo,
    (CASE
		WHEN promo_type = '33% OFF' THEN ROUND(base_price/3) * `quantity_sold(after_promo)`
		WHEN promo_type = '25% OFF' THEN ROUND(base_price * 0.75) * `quantity_sold(after_promo)`
		WHEN promo_type = '50% OFF' THEN ROUND(base_price * 0.5) * `quantity_sold(after_promo)`
		WHEN promo_type = 'BOGOF' THEN ROUND(base_price * 0.5) * `quantity_sold(after_promo)`
        WHEN promo_type = '500 Cashback' THEN ROUND(base_price - 500) * `quantity_sold(after_promo)`
	END) AS revenue_after_promo
FROM fact_events
)
SELECT
	DC.campaign_name,
    concat(cast(round(sum(revenue_before_promo)/1000000,2) AS char), "M") as revenue_before_promo,
    concat(cast(round(sum(revenue_after_promo)/1000000,2) AS char), "M") as revenue_after_promo
FROM CalculateRevenue
JOIN dim_campaigns DC
ON DC.campaign_id = CalculateRevenue.campaign_id
GROUP BY 1;

/*
4. Produce a report that calculates the Incremental Sold Quantity
 (ISU%) for each category during the Diwali campaign. Additionally,
 provide rankings for the categories based on their ISU%. The report
 will include three key fields: category, isu%, and rank order. This
 information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales.
*/


WITH DiwaliPromo AS (
	SELECT
		dp.category,
		SUM(`quantity_sold(before_promo)`) AS sales_before_promo,
		SUM(`quantity_sold(after_promo)`) AS sales_after_promo
	FROM fact_events FE
	JOIN dim_products DP
	ON DP.product_code = FE.product_code
	JOIN dim_campaigns DC
	ON DC.campaign_id = FE.campaign_id
	WHERE DC.campaign_name = 'Diwali'
	GROUP BY 1)
SELECT
	category,
    ROUND(((sales_after_promo - sales_before_promo)/sales_before_promo)*100,2) as `ISU%`,
    RANK() OVER(ORDER BY ROUND(((sales_after_promo - sales_before_promo)/sales_before_promo)*100,2) DESC) AS rank_order
FROM DiwaliPromo;

/*
5. Create a report featuring the Top 5 products,
 ranked by Incremental Revenue Percentage (IR%), across all
 campaigns. The report will provide essential information including
 product name, category, and ir%. This analysis helps identify the most
 successful products in terms of incremental revenue across our campaigns,
 assisting in product optimization.
*/
WITH CalculateRevenue AS(
	SELECT
		FE.*,
		DP.product_name,
		DP.category,
		`base_price` * `quantity_sold(before_promo)` AS revenue_before_promo,
		(CASE
			WHEN promo_type = '33% OFF' THEN ROUND(base_price/3) * `quantity_sold(after_promo)`
			WHEN promo_type = '25% OFF' THEN ROUND(base_price * 0.75) * `quantity_sold(after_promo)`
			WHEN promo_type = '50% OFF' THEN ROUND(base_price * 0.5) * `quantity_sold(after_promo)`
			WHEN promo_type = 'BOGOF' THEN ROUND(base_price * 0.5) * `quantity_sold(after_promo)`
			WHEN promo_type = '500 Cashback' THEN ROUND(base_price - 500) * `quantity_sold(after_promo)`
		END) AS revenue_after_promo
	FROM fact_events FE
	INNER JOIN dim_products DP
	ON DP.product_code = FE.product_code
)
SELECT
	product_name,
    category,
    ROUND((sum(revenue_after_promo) - sum(revenue_before_promo))*100/sum(revenue_before_promo),2) as `IR%`
FROM CalculateRevenue
GROUP BY 1,2
ORDER BY `IR%` DESC
LIMIT 5;