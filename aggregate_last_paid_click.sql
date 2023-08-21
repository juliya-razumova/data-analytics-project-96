with 
ads_visit as (
select distinct on (visitor_id) * 
from sessions 
where campaign is not null
order by visitor_id, visit_date desc
),
common_table as(
select * from ads_visit
union 
select distinct on (visitor_id) * 
from sessions 
where campaign is null
and 
not exists (select 1 from ads_visit where sessions.visitor_id = ads_visit.visitor_id)
order by visitor_id, visit_date desc
)
select 
cast (visit_date as date) as visit_date,
source as utm_source,
medium as utm_medium,
campaign as utm_campaign,
count(visitor_id) as visitors_count,
count(lead_id) as leads_count,
count (lead_id) filter (where closing_reason = 'Успешная продажа') as purchases_count,
sum(amount) as revenue
from common_table
left join leads
using (visitor_id)
group by cast(visit_date as date), utm_source, utm_medium, utm_campaign
order by purchases_count desc nulls last;