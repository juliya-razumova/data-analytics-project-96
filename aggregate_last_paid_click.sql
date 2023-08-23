with ads_visit as (
select 
visitor_id,
max(visit_date) filter (where campaign is not null) as ads_date,
max (visit_date) filter (where campaign is null) as organic_date
from sessions s 
group by visitor_id
),
tab as (
select 
visitor_id,
case
	when ads_date is null then organic_date
	else ads_date
end as visit_date
from ads_visit
)
select
cast (tab.visit_date as date) as visit_date,
source as utm_source,
medium as utm_medium,
campaign as utm_campaign,
count(tab.visitor_id) as visitors_count,
count(lead_id) as leads_count,
count (lead_id) filter (where closing_reason = 'Успешная продажа') as purchases_count,
sum(amount) as revenue
from tab
left join sessions
on tab.visitor_id = sessions.visitor_id and tab.visit_date = sessions.visit_date
left join leads
on tab.visitor_id = leads.visitor_id
group by cast(tab.visit_date as date), utm_source, utm_medium, utm_campaign
order by purchases_count desc nulls last;