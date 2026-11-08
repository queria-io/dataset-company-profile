with coverage as (
    select
        count(*) as listed_company_count,
        count(*) filter (where city_code is not null)::double
            / nullif(count(*), 0) as ratio
    from {{ ref('profile_company') }}
    where is_listed
)

select listed_company_count, ratio
from coverage
where listed_company_count = 0 or ratio < 0.98
