{{ config(alias='city') }}

with company as (
    select *
    from {{ ref('profile_company') }}
    where city_code is not null
),

company_summary as (
    select
        prefecture_code,
        min(prefecture_name) as prefecture_name,
        city_code,
        min(lg_code) as lg_code,
        min(city_name) as city_name,
        count(*) as company_count,
        count(*) filter (where is_listed) as listed_company_count,
        median(average_annual_salary) filter (
            where is_listed and average_annual_salary is not null
        ) as listed_average_annual_salary_median
    from company
    group by prefecture_code, city_code
),

funds_summary as (
    select
        c.city_code,
        sum(f.amount) filter (where f.fund_type = 'subsidy') as subsidy_total_amount,
        sum(f.amount) filter (where f.fund_type = 'procurement') as procurement_total_amount,
        max(f.event_date) as public_funds_as_of
    from company c
    join {{ ref('profile_public_funds') }} f using (corporate_number)
    group by c.city_code
),

history_summary as (
    select
        prefecture_code || city_code as city_code,
        count(distinct corporate_number) filter (
            where process = '01'
              and assignment_date between current_date - interval '1 year' and current_date
        ) as new_company_count_last_year,
        count(distinct corporate_number) filter (
            where process = '21'
              and close_date between current_date - interval '1 year' and current_date
        ) as closed_company_count_last_year
    from houjin_bangou.main.mart_houjin_bangou_history
    where prefecture_code is not null and city_code is not null
    group by prefecture_code, city_code
)

select
    c.prefecture_code,
    c.prefecture_name,
    c.city_code,
    c.lg_code,
    c.city_name,
    c.company_count,
    c.listed_company_count,
    c.listed_average_annual_salary_median,
    coalesce(f.subsidy_total_amount, 0) as subsidy_total_amount,
    coalesce(f.procurement_total_amount, 0) as procurement_total_amount,
    coalesce(h.new_company_count_last_year, 0) as new_company_count_last_year,
    coalesce(h.closed_company_count_last_year, 0) as closed_company_count_last_year,
    cast(current_date - interval '1 year' as date) as period_start,
    current_date as period_end,
    f.public_funds_as_of,
    'company_profile.profile.company' as company_source,
    'company_profile.profile.public_funds' as public_funds_source,
    'houjin_bangou.main.mart_houjin_bangou_history' as company_history_source
from company_summary c
left join funds_summary f using (city_code)
left join history_summary h using (city_code)
order by c.city_code
