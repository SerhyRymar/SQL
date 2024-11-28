-- Домашне завдання №7 (Тема 7)
/*1. Використай CTE з попереднього домашнього завдання в новому (другому) CTE для створення вибірки з такими даними:
ad_month - перше число місяця дати показу реклами (отримане з ad_date);
utm_campaign, загальна сума витрат, кількість показів, кількість кліків, 
value конверсій, CTR, CPC, CPM, ROMI - ті самі поля з тими самими умовами, що й у попередньому завданні.*/
/* 2. Зроби результуючу вибірку з наступними полями:
ad_month;
utm_campaign, загальна сума витрат, кількість показів, кількість кліків, value конверсій, CTR, CPC, CPM, ROMI;*/

with url_table as (
select fabd.ad_date, 
       fa.adset_name, 
       fc.campaign_name, 
       fabd.url_parameters,
       coalesce (fabd.spend, 0) as spend,
       coalesce (fabd.impressions, 0) as impressions,
       coalesce (fabd.reach, 0) as reach,
       coalesce (fabd.clicks, 0) as clicks,
       coalesce (fabd.leads, 0) as leads, 
       coalesce (fabd.value, 0) as value
from public.facebook_ads_basic_daily fabd 
inner join facebook_adset fa on fabd.adset_id = fa.adset_id
inner join facebook_campaign fc on fabd.campaign_id = fc.campaign_id 
union all
select gabd.ad_date, 
       gabd.adset_name, 
       gabd.campaign_name, 
       gabd.url_parameters, 
       coalesce (gabd.spend, 0) as spend, 
       coalesce (gabd.impressions, 0) as impressions,
       coalesce (gabd.reach, 0) as reach,
       coalesce (gabd.clicks, 0) as clicks, 
       coalesce (gabd.leads, 0) as leads, 
       coalesce (gabd.value, 0) as value
 from google_ads_basic_daily gabd ),   
total_cte as (
 select 
    date_trunc('month', ad_date) as ad_month, 
         url_parameters as utm_campaign,
    SUM (ut.spend) as total_spend,
    SUM (ut.impressions) as total_impressions,
    SUM (ut.clicks) as total_clicks,
    SUM (ut.value) as total_value,
case when SUM (ut.impressions) > 0 then ROUND (SUM (ut.clicks) / SUM (ut.impressions :: numeric) * 100, 3) else 0 end as CTR,
case when SUM (ut.clicks) > 0 then ROUND (SUM (ut.spend :: numeric) / SUM (ut.clicks), 3) else 0 end as CPC,
case when SUM (ut.impressions) > 0 then ROUND (SUM (ut.spend :: numeric) / SUM (ut.impressions) * 1000, 3) else 0 end as CPM,
case when SUM (ut.spend) > 0 then ROUND ((SUM (ut.value) / SUM (ut.spend :: numeric)) - 1, 3) else 0 end as ROMI
FROM url_table ut
group by ad_month, utm_campaign
order by ad_month
) 
select 
    ad_month,
    utm_campaign,
    total_spend,
    total_impressions,
    total_clicks,
    total_value,
    CTR,
    CPC,
    CPM,
    ROMI
from total_cte

--------------------------------------------------ФІНАЛЬНИЙ РЕЗУЛЬТАТ----------------------------------------------------
/*3. Для кожної utm_campaign в кожен місяць додай нове поле: ‘різниця CPM, CTR та ROMI’
в поточному місяці відносно попереднього у відсотках.*/

with url_table as (
select fabd.ad_date, 
       fa.adset_name, 
       fc.campaign_name, 
       fabd.url_parameters,
       coalesce (fabd.spend, 0) as spend,
       coalesce (fabd.impressions, 0) as impressions,
       coalesce (fabd.reach, 0) as reach,
       coalesce (fabd.clicks, 0) as clicks,
       coalesce (fabd.leads, 0) as leads, 
       coalesce (fabd.value, 0) as value
from public.facebook_ads_basic_daily fabd 
inner join facebook_adset fa on fabd.adset_id = fa.adset_id
inner join facebook_campaign fc on fabd.campaign_id = fc.campaign_id 
union all
select gabd.ad_date, 
       gabd.adset_name, 
       gabd.campaign_name, 
       gabd.url_parameters, 
       coalesce (gabd.spend, 0) as spend, 
       coalesce (gabd.impressions, 0) as impressions,
       coalesce (gabd.reach, 0) as reach,
       coalesce (gabd.clicks, 0) as clicks, 
       coalesce (gabd.leads, 0) as leads, 
       coalesce (gabd.value, 0) as value
from google_ads_basic_daily gabd ),   
total_cte as (
select 
    date(date_trunc('month', ad_date)) as ad_month, 
 case when LOWER(SUBSTRING(url_parameters, 'utm_campaign=([^&]+)')) = 'nan' then null else LOWER(SUBSTRING(url_parameters, 'utm_campaign=([^&]+)')) end as url,
    SUM (ut.spend) as total_spend,
    SUM (ut.impressions) as total_impressions,
    SUM (ut.clicks) as total_clicks,
    SUM (ut.value) as total_value,
case when SUM (ut.impressions) > 0 then ROUND (SUM (ut.clicks) / SUM (ut.impressions :: numeric) * 100, 3) else 0 end as CTR,
case when SUM (ut.clicks) > 0 then ROUND (SUM (ut.spend :: numeric) / SUM (ut.clicks), 3) else 0 end as CPC,
case when SUM (ut.impressions) > 0 then ROUND (SUM (ut.spend :: numeric) / SUM (ut.impressions) * 1000, 3) else 0 end as CPM,
case when SUM (ut.spend) > 0 then ROUND ((SUM (ut.value) / SUM (ut.spend :: numeric)) - 1, 3) else 0 end as ROMI
from url_table ut
group by ad_month, url
order by ad_month
), 
month_ago AS (
select  
        ad_month,
        url,
        CTR AS prev_CTR,
        CPM AS prev_CPM,
        ROMI AS prev_ROMI
from total_cte
)
select 
    tc.ad_month,
    tc.url,
    tc.total_spend,
    tc.total_impressions,
    tc.total_clicks,
    tc.total_value,
    tc.CTR,
    tc.CPC,
    tc.CPM,
    tc.ROMI,
      coalesce(tc.CTR - ma.prev_CTR, 0) as CTR_change,
      coalesce(tc.CPM - ma.prev_CPM, 0) as CPM_change,
      coalesce(tc.ROMI - ma.prev_ROMI, 0) as ROMI_change
from total_cte tc
left join month_ago ma on tc.url = ma.url and tc.ad_month = ma.ad_month + interval '1 month'
order by tc.url, tc.ad_month
;

