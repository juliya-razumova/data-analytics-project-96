with tab as (
    select
        visitor_id,
        max(visit_date) as visit_date
    from sessions
    where campaign is not null
    group by visitor_id
)

select
    tab.visitor_id,
    tab.visit_date,
    source as utm_source,
    medium as utm_medium,
    campaign as utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
from tab
left join sessions
    on
        tab.visitor_id = sessions.visitor_id
        and tab.visit_date = sessions.visit_date
left join leads
    on tab.visitor_id = leads.visitor_id
order by
    amount desc nulls last, visit_date asc, utm_source asc, utm_medium asc, utm_campaign asc;
