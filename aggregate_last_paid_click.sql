with tab as (
    select
        visitor_id,
        max(visit_date) as visit_date
    from sessions
    where campaign is not null
    group by visitor_id
),

ya as (
    select
        cast(campaign_date as date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by campaign_date, utm_source, utm_medium, utm_campaign
),

vk as (
    select
        cast(campaign_date as date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by campaign_date, utm_source, utm_medium, utm_campaign
),

display as (
    select
        cast(tab.visit_date as date) as visit_date,
        sessions.source as utm_source,
        sessions.medium as utm_medium,
        sessions.campaign as utm_campaign,
        count(distinct tab.visitor_id) as visitors_count,
        count(leads.lead_id) filter (
            where leads.created_at >= tab.visit_date
        ) as leads_count,
        count(leads.lead_id) filter (
            where leads.created_at >= tab.visit_date and leads.amount > 0
        ) as purchases_count,
        sum(leads.amount) filter (where leads.created_at >= tab.visit_date) as revenue
    from tab
    left join sessions 
    on tab.visitor_id = sessions.visitor_id and tab.visit_date = sessions.visit_date
    left join leads
    on tab.visitor_id = leads.visitor_id
    group by cast(tab.visit_date as date), sessions.source, sessions.medium, sessions.campaign
)
select
    display.visit_date,
    display.visitors_count,
    display.utm_source,
    display.utm_medium,
    display.utm_campaign,
    case
        when display.utm_source = 'yandex' then ya.total_cost
        when display.utm_source = 'vk' then vk.total_cost
    end as total_cost,
    display.leads_count,
    display.purchases_count,
    display.revenue
from display
left join ya
    on
        display.visit_date = ya.visit_date and
        display.utm_source = ya.utm_source and
        display.utm_medium = ya.utm_medium and
        display.utm_campaign = ya.utm_campaign
left join vk
    on
        display.visit_date = vk.visit_date and
        display.utm_source = vk.utm_source and
        display.utm_medium = vk.utm_medium and
        display.utm_campaign = vk.utm_campaign
order by 
    display.revenue desc nulls last, 
    display.visit_date, 
    display.visitors_count desc, 
    display.utm_source, 
    display.utm_medium, 
    display.utm_campaign;
