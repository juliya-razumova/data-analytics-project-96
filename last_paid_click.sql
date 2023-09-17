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
        leads.closing_reason,
        leads.status_id,
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
    tab.utm_source,
    tab.utm_medium,
    tab.utm_campaign,
    tab.lead_id,
    tab.created_at,
    tab.amount,
    tab.closing_reason,
    tab.status_id
from tab
where tab.rn = 1
order by
    tab.amount desc nulls last,
    tab.visit_date asc,
    tab.utm_source asc,
    tab.utm_medium asc,
    tab.utm_campaign asc;
