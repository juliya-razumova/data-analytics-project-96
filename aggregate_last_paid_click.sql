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
        row_number() over (partition by sessions.visitor_id order by sessions.visit_date desc) as rn
    from  sessions
    left join leads
        on sessions.visitor_id = leads.visitor_id
        and sessions.visit_date < leads.created_at
    where sessions.medium != 'organic'
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
)

display as (
    select
        cast(tab.visit_date as date) as visit_date,
        tab.utm_source as utm_source,
        tab.utm_medium as utm_medium,
        tab.utm_campaign as utm_campaign,
        count(distinct tab.visitor_id) as visitors_count,
        count(tab.lead_id) as leads_count,
        count(tab.lead_id) filter (
            where tab.amount > 0
        ) as purchases_count,
        sum(tab.amount) as revenue
    from tab
    where rn = 1
    group by cast(tab.visit_date as date), tab.utm_source, tab.utm_medium, tab.utm_campaign
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
        display.visit_date = ya.visit_date
        and display.utm_source = ya.utm_source
        and display.utm_medium = ya.utm_medium
        and display.utm_campaign = ya.utm_campaign
    left join vk
    on
        display.visit_date = vk.visit_date
        and display.utm_source = vk.utm_source
        and display.utm_medium = vk.utm_medium
        and display.utm_campaign = vk.utm_campaign
    order by 
        display.revenue desc nulls last, 
        display.visit_date, 
        display.visitors_count desc, 
        display.utm_source, 
        display.utm_medium, 
        display.utm_campaign;
