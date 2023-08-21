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
common_table.visitor_id as visitor_id,
visit_date,
source as utm_source,
medium as utm_medium,
campaign as utm_campaign,
lead_id,
created_at,
amount,
closing_reason,
status_id as status_code
from common_table
left join leads
using (visitor_id)
order by amount desc nulls last;

