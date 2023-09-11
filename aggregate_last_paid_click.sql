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
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        count(distinct tab.visitor_id) as visitors_count,
        count(l.lead_id) filter (
            where l.created_at >= tab.visit_date
        ) as leads_count,
        count(l.lead_id) filter (
            where l.created_at >= tab.visit_date and l.amount > 0
        ) as purchases_count,
        sum(l.amount) filter (where l.created_at >= tab.visit_date) as revenue
    from tab
    left join sessions s
    on tab.visitor_id = s.visitor_id and tab.visit_date = s.visit_date
    left join leads l
    on tab.visitor_id = l.visitor_id
    group by cast(tab.visit_date as date), s.source, s.medium, s.campaign
)
select
    d.visit_date,
    d.visitors_count,
    d.utm_source,
    d.utm_medium,
    d.utm_campaign,
    case
        when d.utm_source = 'yandex' then y.total_cost
        when d.utm_source = 'vk' then v.total_cost
    end as total_cost,
    d.leads_count,
    d.purchases_count,
    d.revenue
from display d
left join ya y
    on d.visit_date = y.visit_date and
        d.utm_source = y.utm_source and
        d.utm_medium = y.utm_medium and
        d.utm_campaign = y.utm_campaign
left join vk as v
    on d.visit_date = v.visit_date and
        d.utm_source = v.utm_source and
        d.utm_medium = v.utm_medium and
        d.utm_campaign = v.utm_campaign
order by 
    d.revenue desc nulls last, 
    d.visit_date, 
    d.visitors_count desc, 
    d.utm_source, 
    d.utm_medium, 
    d.utm_campaign;
