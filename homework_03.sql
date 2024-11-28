-- Стоверння нової, загальної таблиці через WITH
WITH total_data_cte AS (
-- дані з таблиці гугла
    SELECT
        ad_date,
        campaign_name as campaign_name,
        'Google Ads' AS media_source,
        spend,
        impressions,
        reach,
        clicks,
        leads,
        value
    FROM public.google_ads_basic_daily
    -- об'єднуєм таблиці через union
union all 
-- дані з таблиці фейсбук
    SELECT
        ad_date,
        campaign_id as campaign_name,
        'Facebook Ads' AS media_source,
        spend,
        impressions,
        reach,
        clicks,
        leads,
        value
    FROM public.facebook_ads_basic_daily 
) 
--друга частина завдання
SELECT
    ad_date,
    media_source,
    campaign_name,
    SUM (spend) as total_spend,
    SUM (impressions) as total_impressions,
    SUM (clicks) as total_clicks,
    SUM (value) as total_value
FROM total_data_cte
GROUP by ad_date, media_source, campaign_name
ORDER BY ad_date, media_source;


    select *
    FROM public.facebook_ads_basic_daily 


