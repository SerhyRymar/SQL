--Домашнє завдання №4

/*В SQL запиті в CTE обʼєднай дані з таблиць facebook_ads_basic_daily, facebook_adset та facebook_campaign, щоб отримати таблицю, яка міститиме:
 - ad_date - дата показу реклами в Facebook
 - campaign_name - назва кампанії в Facebook
 - adset_name - назва набору оголошень в Facebook
 - spend, impressions, reach, clicks, leads, value - метрики кампаній та наборів оголошень у відповідні дні*/

with facebook_table_cte as (
select *
from public.facebook_ads_basic_daily fabd 
inner join facebook_adset fa on fabd.adset_id = fa.adset_id
inner join facebook_campaign fc on fabd.campaign_id = fc.campaign_id 
)
select 
  ad_date, campaign_name, adset_name, spend, impressions, reach, clicks, leads, value
from facebook_table_cte
where leads is not null
order by ad_date, campaign_name

/*2. В другому CTE обʼєднай дані з таблиці google_ads_basic_daily та першого CTE, 
щоб отримати єдину таблицю з інформацією про маркетингові кампанії Facebook та Google*/

with facebook_table_cte as (
select fabd.ad_date, 
       fc.campaign_name, 
       fa.adset_name, 
       fabd.spend, 
       fabd.impressions, 
       fabd.reach, 
       fabd.clicks, 
       fabd.leads, 
       fabd.value
from public.facebook_ads_basic_daily fabd 
inner join facebook_adset fa on fabd.adset_id = fa.adset_id
inner join facebook_campaign fc on fabd.campaign_id = fc.campaign_id 
), 
facebook_and_google_data_cte as (
select gabd.ad_date, 
       gabd.campaign_name, 
       gabd.adset_name, 
       gabd.spend, 
       gabd.impressions, 
       gabd.reach, 
       gabd.clicks, 
       gabd.leads, 
       gabd.value
 from google_ads_basic_daily gabd  
 union all
 select 
        ftc.ad_date,
        ftc.campaign_name,
        ftc.adset_name,
        ftc.spend,
        ftc.impressions,
        ftc.reach,
        ftc.clicks,
        ftc.leads,
        ftc.value
 from facebook_table_cte ftc       
)
select *
from facebook_and_google_data_cte

----------------------------------------------------------ФІНАЛЬНИЙ РЕЗУЛЬТАТ-----------------------------------------------------------------------

/*3. Аналогічно до попереднього домашнього завдання з отриманої обʼєднаної таблиці (CTE) зроби вибірку:
- ad_date - дата показу реклами
- media_source - назва джерела закупки (Google Ads / Facebook Ads) — цю колонку створи самостійно
- campaign_name - назва кампанії
- adset_name - назва набору оголошень
- агреговані за датою та назвою кампанії й набору оголошень значення для наступних показників:
загальна сума витрат,
кількість показів,
кількість кліків,
загальний Value конверсій
Для виконання цього завдання згрупуй таблицю за полями ad_date, media_source, campaign_name та adset_name.*/

with facebook_table_cte as (
select fabd.ad_date, 
       'Facebook Ads' as media_source,
       fc.campaign_name, 
       fa.adset_name, 
       fabd.spend, 
       fabd.impressions, 
       fabd.reach, 
       fabd.clicks, 
       fabd.leads, 
       fabd.value
from public.facebook_ads_basic_daily fabd 
inner join facebook_adset fa on fabd.adset_id = fa.adset_id
inner join facebook_campaign fc on fabd.campaign_id = fc.campaign_id 
), 
facebook_and_google_data_cte as (
select gabd.ad_date, 
       'Google Ads' as media_source,
       gabd.campaign_name, 
       gabd.adset_name, 
       gabd.spend, 
       gabd.impressions, 
       gabd.reach, 
       gabd.clicks, 
       gabd.leads, 
       gabd.value
 from google_ads_basic_daily gabd  
 union all
 select 
        ftc.ad_date,
        ftc.media_source,
        ftc.campaign_name,
        ftc.adset_name,
        ftc.spend,
        ftc.impressions,
        ftc.reach,
        ftc.clicks,
        ftc.leads,
        ftc.value
 from facebook_table_cte ftc       
)
SELECT
    ad_date,
    media_source,
    campaign_name,
    adset_name,
    SUM (spend) as total_spend,
    SUM (impressions) as total_impressions,
    SUM (clicks) as total_clicks,
    SUM (value) as total_value
FROM facebook_and_google_data_cte
GROUP by ad_date, media_source,  campaign_name, adset_name
ORDER BY ad_date, media_source;

------------------------------------------------------БОНУСНЕ ЗАВДАННЯ-------------------------------------------------------------------

/*Обʼєднавши дані з чотирьох таблиць, визнач кампанію з найвищим ROMI серед усіх кампаній з загальною сумою витрат більше 500 000. 
В цій кампанії визнач групу оголошень (adset_name) з найвищим ROMI*/

with facebook_table_cte as (
select fabd.ad_date, 
       'Facebook Ads' as media_source,
       fc.campaign_name, 
       fa.adset_name, 
       fabd.spend, 
       fabd.impressions, 
       fabd.reach, 
       fabd.clicks, 
       fabd.leads, 
       fabd.value
from public.facebook_ads_basic_daily fabd 
inner join facebook_adset fa on fabd.adset_id = fa.adset_id
inner join facebook_campaign fc on fabd.campaign_id = fc.campaign_id 
), 
facebook_and_google_data_cte as (
select gabd.ad_date, 
       'Google Ads' as media_source,
       gabd.campaign_name, 
       gabd.adset_name, 
       gabd.spend, 
       gabd.impressions, 
       gabd.reach, 
       gabd.clicks, 
       gabd.leads, 
       gabd.value
 from google_ads_basic_daily gabd  
 union all
 select 
        ftc.ad_date,
        ftc.media_source,
        ftc.campaign_name,
        ftc.adset_name,
        ftc.spend,
        ftc.impressions,
        ftc.reach,
        ftc.clicks,
        ftc.leads,
        ftc.value
 from facebook_table_cte ftc       
)
SELECT
    campaign_name,
    SUM (spend) as total_spend,
    SUM (impressions) as total_impressions,
    SUM (clicks) as total_clicks,
    SUM (value) as total_value,
    (sum (value::numeric) - sum (spend)) / sum (spend) * 100 as ROMI
FROM facebook_and_google_data_cte fagdc
where clicks > 0 and spend > 500000
GROUP by campaign_name
ORDER BY romi desc
limit 1;
