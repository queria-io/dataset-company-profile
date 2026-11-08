with coverage as (
    select
        count(*) filter (where city_code is not null)::double
            / nullif(count(*), 0) as ratio
    from {{ ref('profile_company') }}
    where is_listed
)

select ratio
from coverage
where ratio < 0.98
