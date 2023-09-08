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
        cast(tab.visit_date as date) as visit_date,
        sessions.source as utm_source,
        sessions.medium as utm_medium,
        sessions.campaign as utm_campaign,
        count(distinct tab.visitor_id) as visitors_count,
        count(leads.lead_id) filter (
            where leads.created_at >= tab.visit_date
        ) as leads_count,
        count(leads.lead_id) filter (where leads.amount > 0) as purchases_count,
        sum(leads.amount) as revenue
    from tab
    left join sessions
        on
            tab.visitor_id = sessions.visitor_id
            and tab.visit_date = sessions.visit_date
    left join leads
        on tab.visitor_id = leads.visitor_id
    group by visit_date, utm_source, utm_medium, utm_campaign
)

select
    tab1.visit_date as visit_date,
    tab1.visitors_count,
    tab1.utm_source,
    tab1.utm_medium,
    tab1.utm_campaign,
    tab1.leads_count,
    tab1.purchases_count,
    tab1.revenue,
    case
        when tab1.utm_source = 'yandex' then ya.total_cost
        when tab1.utm_source = 'vk' then vk.total_cost
    end as total_cost
from tab1
left join ya
    on
        tab1.visit_date = ya.campaign_date and tab1.utm_source = ya.utm_source
        and tab1.utm_medium = ya.utm_medium
        and tab1.utm_campaign = ya.utm_campaign
left join vk
    on
        tab1.visit_date = vk.campaign_date and tab1.utm_source = vk.utm_source
        and tab1.utm_medium = vk.utm_medium
        and tab1.utm_campaign = vk.utm_campaign
where tab1.utm_source != 'admitad'
order by
    tab1.revenue desc nulls last,
    tab1.visitors_count desc,
    tab1.visit_date asc,
    tab1.utm_source asc,
    tab1.utm_medium asc,
    tab1.utm_campaign asc;
