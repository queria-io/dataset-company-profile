with subsidy as (
    select
        c.city_code,
        count(*) as subsidy_count,
        count(f.amount) as known_amount_count,
        sum(f.amount) as known_total_amount
    from {{ ref('profile_company') }} c
    join {{ ref('profile_public_funds') }} f using (corporate_number)
    where c.city_code is not null and f.fund_type = 'subsidy'
    group by c.city_code
)

select c.city_code
from {{ ref('profile_city') }} c
left join subsidy s using (city_code)
where c.subsidy_total_amount is distinct from case
    when s.subsidy_count is null then 0
    when s.subsidy_count = s.known_amount_count then s.known_total_amount
end
