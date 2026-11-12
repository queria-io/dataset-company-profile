with business_results as (
    select *
    from edinet.main.mart_business_results
    where corporate_number is not null and year_offset = 0
    qualify row_number() over (
        partition by corporate_number
        order by period_end desc nulls last, doc_id desc
    ) = 1
)

select c.corporate_number
from {{ ref('profile_company') }} c
left join business_results b using (corporate_number)
left join gbizinfo.main.mart_gbizinfo_company g using (corporate_number)
where (
        c.latest_net_sales_source = 'edinet.main.mart_business_results'
        and (
            c.latest_net_sales_period is distinct from cast(b.period_end as varchar)
            or c.latest_net_sales_source_id is distinct from b.doc_id
            or c.latest_net_sales_source_url is distinct from
                'https://disclosure2.edinet-fsa.go.jp/WZEK0040.aspx?' || b.doc_id
        )
    )
    or (
        c.latest_net_sales_source = 'gbizinfo.main.mart_gbizinfo_company'
        and (
            c.latest_net_sales_period is distinct from g.latest_fiscal_year
            or c.latest_net_sales_source_id is not null
            or c.latest_net_sales_source_url is not null
        )
    )
    or (
        c.latest_net_sales is null
        and (
            c.latest_net_sales_period is not null
            or c.latest_net_sales_source is not null
            or c.latest_net_sales_source_id is not null
            or c.latest_net_sales_source_url is not null
        )
    )
