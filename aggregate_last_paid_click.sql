with tab as (
select 
visitor_id,
max(visit_date) as visit_date
from sessions s 
where medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
group by visitor_id
),
ya as (
select 
cast(campaign_date as date) as campaign_date,
utm_source,
utm_medium,
utm_campaign,
sum(daily_spent) as total_cost
from ya_ads
group by campaign_date, utm_source, utm_medium, utm_campaign
),
vk as (
select 
cast(campaign_date as date) as campaign_date,
utm_source,
utm_medium,
utm_campaign,
sum(daily_spent) as total_cost
from vk_ads
group by campaign_date, utm_source, utm_medium, utm_campaign
),
tab1 as (
select 
cast (tab.visit_date as date) as date,
source,
medium,
campaign,
count(tab.visitor_id) as visitors_count,
count(lead_id) filter (where created_at > tab.visit_date) as leads_count,
count(lead_id) filter (where amount > 0) as purchases_count,
sum(amount) as revenue
from tab
left join sessions
on tab.visitor_id = sessions.visitor_id and tab.visit_date = sessions.visit_date
left join leads
on tab.visitor_id = leads.visitor_id
group by date, source, medium, campaign
)
select 
tab1.date as visit_date,
tab1.visitors_count,
tab1.source as utm_source,
tab1.medium as utm_medium,
tab1.campaign as utm_campaign,
case 
	when source = 'yandex' then ya.total_cost
	when source = 'vk' then vk.total_cost
end as total_cost,
tab1.leads_count,
tab1.purchases_count,
tab1.revenue
from tab1
left join ya
on date = ya.campaign_date and source = ya.utm_source
and medium = ya.utm_medium and campaign = ya.utm_campaign
left join vk
on date = vk.campaign_date and source = vk.utm_source
and medium = vk.utm_medium and campaign = vk.utm_campaign
order by revenue desc nulls last
limit 15;

