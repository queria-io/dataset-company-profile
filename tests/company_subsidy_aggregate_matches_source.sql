with subsidy as (
    select
        corporate_number,
        count(*) as subsidy_count,
        count(*) filter (where amount is null) as null_amount_count,
        sum(amount) as known_total_amount
    from gbizinfo.main.mart_gbizinfo_subsidy
    where corporate_number is not null
    group by corporate_number
)

select c.corporate_number
from {{ ref('profile_company') }} c
left join subsidy s using (corporate_number)
where c.subsidy_count is distinct from coalesce(s.subsidy_count, 0)
   or c.subsidy_total_amount is distinct from case
       when s.subsidy_count is null then 0
       when s.null_amount_count = 0 then s.known_total_amount
   end
