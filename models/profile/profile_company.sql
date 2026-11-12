{{ config(alias='company') }}

with edinet_company as (
    select *
    from edinet.main.mart_companies
    where corporate_number is not null
    qualify row_number() over (
        partition by corporate_number
        order by (listing_status = '上場') desc, edinet_code
    ) = 1
),

mhlw_company as (
    select *
    from mhlw.josei_katsuyaku.company
    where corporate_number is not null
    qualify row_number() over (
        partition by corporate_number
        order by last_updated desc nulls last, company_name
    ) = 1
),

business_results as (
    select *
    from edinet.main.mart_business_results
    where corporate_number is not null and year_offset = 0
    qualify row_number() over (
        partition by corporate_number
        order by period_end desc nulls last, doc_id desc
    ) = 1
),

human_capital as (
    select *
    from edinet.main.mart_human_capital
    where corporate_number is not null
    qualify row_number() over (
        partition by corporate_number
        order by period_end desc nulls last, submit_date desc nulls last, doc_id desc
    ) = 1
),

subsidy as (
    select
        corporate_number,
        count(*) as subsidy_count,
        sum(amount) as subsidy_total_amount,
        max(certification_date) as subsidy_as_of
    from gbizinfo.main.mart_gbizinfo_subsidy
    where corporate_number is not null
    group by corporate_number
),

procurement as (
    select
        corporate_number,
        count(*) as procurement_count,
        sum(award_price) as procurement_total_amount,
        max(award_date) as procurement_as_of
    from p_portal.main.procurement_award
    where corporate_number is not null
    group by corporate_number
)

select
    -- プロファイル API が法人番号から読むファイル (法人番号の下 3 桁ごとに分けて書く。dbt_project.yml)
    right(h.corporate_number, 3) as shard,
    h.corporate_number,
    h.name,
    h.kind as company_kind_code,
    case h.kind
        when '101' then '国の機関'
        when '201' then '地方公共団体'
        when '301' then '株式会社'
        when '302' then '有限会社'
        when '303' then '合名会社'
        when '304' then '合資会社'
        when '305' then '合同会社'
        when '399' then 'その他の設立登記法人'
        when '401' then '外国会社等'
        when '499' then 'その他'
    end as company_kind,
    h.prefecture_code,
    h.prefecture_name,
    h.prefecture_code || h.city_code as city_code,
    h.lg_code,
    h.city_name,
    h.assignment_date,
    'houjin_bangou.main.mart_houjin_bangou' as base_source,
    h.update_date as base_as_of,

    g.capital_stock,
    if(g.capital_stock is not null, 'gbizinfo.main.mart_gbizinfo_company', null) as capital_stock_source,
    cast(null as date) as capital_stock_as_of,
    g.employee_number,
    if(g.employee_number is not null, 'gbizinfo.main.mart_gbizinfo_company', null) as employee_number_source,
    cast(null as date) as employee_number_as_of,
    g.date_of_establishment as establishment_date,
    coalesce(year(g.date_of_establishment), g.founding_year) as establishment_year,
    if(
        g.date_of_establishment is not null or g.founding_year is not null,
        'gbizinfo.main.mart_gbizinfo_company',
        null
    ) as establishment_source,
    cast(null as date) as establishment_as_of,
    coalesce(e.industry, m.industry, g.business_items) as industry,
    case
        when e.industry is not null then 'edinet.main.mart_companies'
        when m.industry is not null then 'mhlw.josei_katsuyaku.company'
        when g.business_items is not null then 'gbizinfo.main.mart_gbizinfo_company'
    end as industry_source,
    if(e.industry is null and m.industry is not null, m.last_updated, null) as industry_as_of,

    case
        when e.listing_status is not null then e.listing_status = '上場'
        else m.market_segment is not null
    end as is_listed,
    coalesce(e.listing_status, if(m.market_segment is not null, '上場', null)) as listing_status,
    m.market_segment,
    if(m.market_segment is not null, 'mhlw.josei_katsuyaku.company', null) as market_segment_source,
    if(m.market_segment is not null, m.last_updated, null) as market_segment_as_of,
    coalesce(e.sec_code, m.securities_code) as securities_code,
    case
        when e.sec_code is not null then 'edinet.main.mart_companies'
        when m.securities_code is not null then 'mhlw.josei_katsuyaku.company'
    end as securities_code_source,
    if(e.sec_code is null and m.securities_code is not null, m.last_updated, null) as securities_code_as_of,
    case
        when e.listing_status is not null then 'edinet.main.mart_companies'
        when m.market_segment is not null then 'mhlw.josei_katsuyaku.company'
    end as listing_source,
    if(e.listing_status is null and m.market_segment is not null, m.last_updated, null) as listing_as_of,

    coalesce(b.net_sales, cast(g.latest_net_sales as decimal(38, 4))) as latest_net_sales,
    coalesce(cast(b.period_end as varchar), g.latest_fiscal_year) as latest_net_sales_period,
    case
        when b.net_sales is not null then 'edinet.main.mart_business_results'
        when g.latest_net_sales is not null then 'gbizinfo.main.mart_gbizinfo_company'
    end as latest_net_sales_source,
    if(b.net_sales is not null, b.doc_id, null) as latest_net_sales_source_id,

    hc.average_annual_salary,
    if(hc.average_annual_salary is not null, 'edinet.main.mart_human_capital', null) as average_annual_salary_source,
    if(hc.average_annual_salary is not null, hc.doc_id, null) as average_annual_salary_source_id,
    if(hc.average_annual_salary is not null, hc.period_end, null) as average_annual_salary_as_of,
    coalesce(hc.average_age, g.avg_age) as average_age,
    case
        when hc.average_age is not null then 'edinet.main.mart_human_capital'
        when g.avg_age is not null then 'gbizinfo.main.mart_gbizinfo_company'
    end as average_age_source,
    if(hc.average_age is not null, hc.doc_id, null) as average_age_source_id,
    if(hc.average_age is not null, hc.period_end, null) as average_age_as_of,
    coalesce(
        100.0 * hc.female_manager_ratio,
        m.women_in_management_pct,
        w.female_manager_ratio
    ) as female_manager_ratio,
    case
        when hc.female_manager_ratio is not null then 'edinet.main.mart_human_capital'
        when m.women_in_management_pct is not null then 'mhlw.josei_katsuyaku.company'
        when w.female_manager_ratio is not null then 'gbizinfo.main.mart_gbizinfo_workplace'
    end as female_manager_ratio_source,
    if(hc.female_manager_ratio is not null, hc.doc_id, null) as female_manager_ratio_source_id,
    case
        when hc.female_manager_ratio is not null then hc.period_end
        when m.women_in_management_pct is not null then m.last_updated
    end as female_manager_ratio_as_of,

    coalesce(s.subsidy_count, 0) as subsidy_count,
    coalesce(s.subsidy_total_amount, 0) as subsidy_total_amount,
    'gbizinfo.main.mart_gbizinfo_subsidy' as subsidy_source,
    s.subsidy_as_of,
    coalesce(p.procurement_count, 0) as procurement_count,
    coalesce(p.procurement_total_amount, 0) as procurement_total_amount,
    'p_portal.main.procurement_award' as procurement_source,
    p.procurement_as_of
from houjin_bangou.main.mart_houjin_bangou h
left join gbizinfo.main.mart_gbizinfo_company g using (corporate_number)
left join gbizinfo.main.mart_gbizinfo_workplace w using (corporate_number)
left join edinet_company e using (corporate_number)
left join mhlw_company m using (corporate_number)
left join business_results b using (corporate_number)
left join human_capital hc using (corporate_number)
left join subsidy s using (corporate_number)
left join procurement p using (corporate_number)
order by h.corporate_number
