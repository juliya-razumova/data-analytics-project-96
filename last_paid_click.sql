with tab as (
    select
        sessions.visitor_id,
        sessions.visit_date,
        sessions.source as utm_source,
        sessions.medium as utm_medium,
        sessions.campaign as utm_campaign,
        leads.lead_id,
        leads.created_at,
        leads.amount,
        row_number()
        over (
            partition by sessions.visitor_id
            order by sessions.visit_date desc
        )
        as rn
    from sessions
    left join leads
        on
            sessions.visitor_id = leads.visitor_id
            and sessions.visit_date < leads.created_at
    where sessions.medium != 'organic'
)

select
    tab.visitor_id,
    tab.visit_date,
    sessions.source as utm_source,
    sessions.medium as utm_medium,
    sessions.campaign as utm_campaign,
    leads.lead_id,
    leads.created_at,
    leads.amount,
    leads.closing_reason,
    leads.status_id
from tab
left join sessions
    on
        tab.visitor_id = sessions.visitor_id
        and tab.visit_date = sessions.visit_date
left join leads
    on tab.visitor_id = leads.visitor_id
order by
    leads.amount desc nulls last,
    tab.visit_date asc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc;
