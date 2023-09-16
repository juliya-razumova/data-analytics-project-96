/*РАСЧЁТ МЕТРИК ПО ДНЯМ */

with ads_visit as (
    select
        sessions.visitor_id,
        max(sessions.visit_date) filter (
            where sessions.medium = 'organic'
        ) as organic_date,
        max(sessions.visit_date) filter (
            where sessions.medium != 'organic'
        ) as ads_date
    from sessions
    group by sessions.visitor_id
),

tab as (
    select
        case
            when ads_visit.ads_date is null
                then cast(ads_visit.organic_date as date)
            else cast(ads_visit.ads_date as date),
        end as visit_date,
        ads_visit.visitor_id,
        sessions.source as utm_source,
        sessions.medium as utm_medium,
        sessions.campaign as utm_campaign,
        leads.lead_id,
        leads.created_at,
        leads.amount
    from ads_visit
    left join sessions
        on
            sessions.visitor_id = ads_visit.visitor_id
            and ads_visit.ads_date = sessions.visit_date
    left join leads
        on
            ads_visit.visitor_id = leads.visitor_id
            and ads_visit.ads_date < leads.created_at
)

select
    cast(tab.visit_date as date) as visit_date,
    coalesce(tab.utm_source, 'organic') as utm_source,
    coalesce(tab.utm_medium, 'organic') as utm_medium,
    coalesce(tab.utm_campaign, 'organic') as utm_campaign,
    count(distinct tab.visitor_id) as visitors_count,
    count(tab.lead_id) as leads_count,
    count(tab.lead_id) filter (
        where tab.amount > 0
    ) as purchases_count,
    sum(tab.amount) as revenue
from tab
group by
    cast(tab.visit_date as date),
    tab.utm_source,
    tab.utm_medium,
    tab.utm_campaign
order by revenue desc nulls last;


/*РАСЧЁТ КОНВЕРСИЙ ПО КУРСАМ ШКОЛЫ*/

with ads_visit as (
    select
        sessions.visitor_id,
        max(sessions.visit_date) filter (
            where sessions.medium = 'organic'
        ) as organic_date,
        max(sessions.visit_date) filter (
            where sessions.medium != 'organic'
        ) as ads_date
    from sessions
    group by sessions.visitor_id
),

tab as (
    select
        case
            when ads_visit.ads_date is null
                then cast(ads_visit.organic_date as date)
            else cast(ads_visit.ads_date as date),
        end as visit_date,
	ads_visit.visitor_id,
        sessions.source as utm_source,
        sessions.medium as utm_medium,
        sessions.campaign as utm_campaign,
        leads.lead_id,
        leads.created_at,
        leads.amount
    from ads_visit
    left join sessions
        on
            sessions.visitor_id = ads_visit.visitor_id
            and ads_visit.ads_date = sessions.visit_date
    left join leads
        on
            ads_visit.visitor_id = leads.visitor_id
            and ads_visit.ads_date < leads.created_at
)

select
    coalesce(tab.utm_campaign, 'organic') as utm_campaign,
    count(distinct tab.visitor_id) as visitors_count,
    count(tab.lead_id) as leads_count,
    count(tab.lead_id) filter (
        where tab.amount > 0
    ) as purchases_count,
    sum(tab.amount) as revenue,
    round(100.0 * count(tab.lead_id) / count(tab.visitor_id), 2) as lead_conv,
    round(
        100.0
        * count(tab.lead_id) filter (where tab.amount > 0)
        / count(tab.lead_id),
        2
    ) as purchases_conv
from tab
group by tab.utm_campaign
having count(tab.lead_id) > 0;


/*РАСЧЁТ КОНВЕРСИЙ ПО ИСТОЧНИКУ ПРИХОДА*/

with ads_visit as (
    select
        sessions.visitor_id,
        max(sessions.visit_date) filter (
            where sessions.medium = 'organic'
        ) as organic_date,
        max(sessions.visit_date) filter (
            where sessions.medium != 'organic'
        ) as ads_date
    from sessions
    group by sessions.visitor_id
),

tab as (
    select
        case
            when ads_visit.ads_date is null
                then cast(ads_visit.organic_date as date)
            else cast(ads_visit.ads_date as date)
        end as visit_date,
        ads_visit.visitor_id,
        sessions.source as utm_source,
        sessions.medium as utm_medium,
        sessions.campaign as utm_campaign,
        leads.lead_id,
        leads.created_at,
        leads.amount
    from ads_visit
    left join sessions
        on
            sessions.visitor_id = ads_visit.visitor_id
            and ads_visit.ads_date = sessions.visit_date
    left join leads
        on
            ads_visit.visitor_id = leads.visitor_id
            and ads_visit.ads_date < leads.created_at
)

select
    coalesce(tab.utm_source, 'organic') as utm_source,
    count(distinct tab.visitor_id) as visitors_count,
    count(tab.lead_id) as leads_count,
    count(tab.lead_id) filter (
        where tab.amount > 0
    ) as purchases_count,
    sum(tab.amount) as revenue,
    round(100.0 * count(tab.lead_id) / count(tab.visitor_id), 2) as lead_conv,
    round(
        100.0
        * count(tab.lead_id) filter (where tab.amount > 0)
        / count(tab.lead_id),
        2
    ) as purchases_conv
from tab
group by tab.utm_source
having count(tab.lead_id) > 0;


/*РАСЧЁТ РАСХОДОВ НА РЕКЛАМНЫ КАМПАНИИ*/

select
    cast(campaign_date as date) as camp_date,
    utm_source,
    utm_medium,
    utm_campaign,
    sum(daily_spent) as total_cost
from ya_ads
group by
    cast(campaign_date as date),
    utm_source,
    utm_medium,
    utm_campaign
union
select
    cast(campaign_date as date) as camp_date,
    utm_source,
    utm_medium,
    utm_campaign,
    sum(daily_spent) as total_cost
from vk_ads
group by
    cast(campaign_date as date),
    utm_source,
    utm_medium,
    utm_campaign
order by
    camp_date,
    utm_source,
    utm_medium,
    utm_campaign;


/*РАСЧЁТ МЕТРИК РЕКЛАМНЫХ КАМПАНИЙ ПО КУРСАМ ШКОЛЫ*/

with tab as (
    select
        sessions.visitor_id,
        sessions.visit_date,
        sessions.source as utm_source,
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
            and sessions.visit_date <= leads.created_at
    where sessions.source in ('yandex', 'vk')
),

conv as (
    select
        tab.utm_source,
        tab.utm_campaign,
        count(distinct tab.visitor_id) as visitors_count,
        count(tab.lead_id) as leads_count,
        count(tab.lead_id) filter (where tab.amount > 0) as purchases_count,
        sum(tab.amount) as revenue
    from tab
    where tab.rn = 1
    group by tab.utm_source, tab.utm_campaign
),

ads as (
    select
        cast(campaign_date as date) as camp_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by
        cast(campaign_date as date),
        utm_source,
        utm_medium,
        utm_campaign
    union
    select
        cast(campaign_date as date) as camp_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by
        cast(campaign_date as date),
        utm_source,
        utm_medium,
        utm_campaign
)

select
    conv.utm_source,
    conv.utm_campaign,
    conv.visitors_count,
    conv.leads_count,
    conv.purchases_count,
    conv.revenue,
    ads.total_cost,
    case
        when conv.visitors_count > 0
            then round(100.0 * conv.leads_count / conv.visitors_count, 2)
    end as lead_conv,
    case
        when conv.leads_count > 0
            then round(100.0 * conv.purchases_count / conv.leads_count, 2)
    end as purchases_conv,
    round(ads.total_cost / conv.visitors_count, 2) as cpu,
    case
        when conv.leads_count > 0
            then round(ads.total_cost / conv.leads_count, 2)
    end as cpl,
    case
        when conv.purchases_count > 0
            then round(ads.total_cost / conv.purchases_count, 2)
    end as cppu,
    round(100.0 * (conv.revenue - ads.total_cost) / ads.total_cost, 2) as roi
from ads
left join conv
    on
        conv.utm_source = ads.utm_source
        and conv.utm_campaign = ads.utm_campaign;


/*ЗАКРЫТИЯ 90% ЛИДОВ ПОСЛЕ ЗАПУСКА РЕКЛАМНОЙ КАМПАНИИ*/

with tab as (
    select
        sessions.visitor_id,
        cast(sessions.visit_date as date) as visit_date,
        sessions.source as utm_source,
        leads.lead_id,
        cast(leads.created_at as date) as created_at,
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
            and sessions.visit_date <= leads.created_at
    where sessions.source in ('yandex', 'vk')
)

select
    tab.utm_source,
    case
        when
            tab.utm_source = 'yandex'
            then
                percentile_disc(0.9) within group (
                    order by tab.created_at - tab.visit_date
                )
        when
            tab.utm_source = 'vk'
            then
                percentile_disc(0.9) within group (
                    order by tab.created_at - tab.visit_date
                )
    end as percent_90
from tab
where tab.rn = 1
group by tab.utm_source;


/*ИТОГОВАЯ ТАБЛИЦА*/

with tab as (
    select
        sessions.visitor_id,
        sessions.visit_date,
        sessions.source as utm_source,
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
            and sessions.visit_date <= leads.created_at
    where sessions.source in ('yandex', 'vk')
),

conv as (
    select
        tab.utm_source,
        tab.utm_campaign,
        count(distinct tab.visitor_id) as visitors_count,
        count(tab.lead_id) as leads_count,
        count(tab.lead_id) filter (where tab.amount > 0) as purchases_count,
        sum(tab.amount) as revenue
    from tab
    where tab.rn = 1
    group by tab.utm_source, tab.utm_campaign
),

ads as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by
        utm_source,
        utm_medium,
        utm_campaign
    union
    select
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by
        utm_source,
        utm_medium,
        utm_campaign
)

select distinct
    conv.utm_source,
    conv.utm_campaign,
    conv.leads_count,
    conv.purchases_count,
    conv.revenue,
    ads.total_cost
from conv
left join ads
    on
        conv.utm_source = ads.utm_source
        and conv.utm_campaign = ads.utm_campaign
where conv.revenue > 0
order by conv.utm_campaign desc, conv.revenue desc;
