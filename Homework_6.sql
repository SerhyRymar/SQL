-- Домашне завдання №6 (Тема 5)
/*1. В CTE запиті обʼєднай дані з таблиць facebook_ads_basic_daily, facebook_adset, facebook_campaign, 
  google_ads_basic_daily щоб отримати:
    - ad_date - дата показу реклами в Google та Facebook;
    - url_parameters - частина URL з посилання кампаній, що включає в себе UTM параметри;
    - spend, impressions, reach, clicks, 
    - leads, value - метрики кампаній та наборів оголошень у відповідні дні; 
!!! У випадку якщо в таблиці значення метрики відсутнє (тобто null), задай значення рівним нулю (тобто 0)*/

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
 from google_ads_basic_daily gabd     
)
select *
FROM url_table
--------------------------------------------------ФІНАЛЬНИЙ РЕЗУЛЬТАТ----------------------------------------------------
/*2. З отриманого CTE зроби вибірку:
- ad_date - дата показу реклами;
- utm_campaign - значення параметра utm_campaign з поля utm_parameters, що задовольняє наступним умовам:
воно зведене до нижнього регістра
якщо значення utm_campaign в utm_parameters дорівнює ‘nan’, то воно має бути пустим (тобто null) в результуючій таблиці
ПІДКАЗКА Використай функцію substring з регулярним виразом
- Загальна сума витрат, кількість показів, кількість кліків, а також загальний Value конверсій у відповідну дату по відповідній кампанії;
- CTR, CPC, CPM, ROMI у відповідну дату по відповідній кампанії. !!! 
При цьому, не використовуй WHERE, а уникни помилки ділення на нуль за допомогою оператора CASE*/

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
 from google_ads_basic_daily gabd     
)
select ad_date, 
case when LOWER(SUBSTRING(url_parameters, 'utm_campaign=([^&]+)')) = 'nan' then null else LOWER(SUBSTRING(url_parameters, 'utm_campaign=([^&]+)')) end as url,
    SUM (ut.spend) as total_spend,
    SUM (ut.impressions) as total_impressions,
    SUM (ut.clicks) as total_clicks,
    SUM (ut.value) as total_value,
case when SUM (ut.impressions) > 0 then ROUND (SUM (ut.clicks) / SUM (ut.impressions :: numeric) * 100, 3) else 0 end as CTR,
case when SUM (ut.clicks) > 0 then ROUND (SUM (ut.spend :: numeric) / SUM (ut.clicks), 3) else 0 end as CPC,
case when SUM (ut.impressions) > 0 then ROUND (SUM (ut.spend :: numeric) / SUM (ut.impressions) * 1000, 3) else 0 end as CPM,
case when SUM (ut.spend) > 0 then ROUND ((SUM (ut.value) / SUM (ut.spend :: numeric)) - 1, 3) else 0 end as ROMI
FROM url_table ut
group by ad_date, url
order by ad_date




