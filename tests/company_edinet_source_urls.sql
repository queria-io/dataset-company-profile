select corporate_number
from {{ ref('profile_company') }}
where (
        industry_source = 'edinet.main.mart_companies'
        and industry_source_url is distinct from
            'https://disclosure2dl.edinet-fsa.go.jp/searchdocument/codelist/Edinetcode.zip'
    )
    or (
        industry_source is distinct from 'edinet.main.mart_companies'
        and industry_source_url is not null
    )
    or (
        securities_code_source = 'edinet.main.mart_companies'
        and securities_code_source_url is distinct from
            'https://disclosure2dl.edinet-fsa.go.jp/searchdocument/codelist/Edinetcode.zip'
    )
    or (
        securities_code_source is distinct from 'edinet.main.mart_companies'
        and securities_code_source_url is not null
    )
    or (
        listing_source = 'edinet.main.mart_companies'
        and listing_source_url is distinct from
            'https://disclosure2dl.edinet-fsa.go.jp/searchdocument/codelist/Edinetcode.zip'
    )
    or (
        listing_source is distinct from 'edinet.main.mart_companies'
        and listing_source_url is not null
    )
    or (
        average_annual_salary_source = 'edinet.main.mart_human_capital'
        and (
            average_annual_salary_source_id is null
            or average_annual_salary_source_url is distinct from
                'https://disclosure2.edinet-fsa.go.jp/WZEK0040.aspx?'
                || average_annual_salary_source_id
        )
    )
    or (
        average_annual_salary_source is distinct from 'edinet.main.mart_human_capital'
        and average_annual_salary_source_url is not null
    )
    or (
        average_age_source = 'edinet.main.mart_human_capital'
        and (
            average_age_source_id is null
            or average_age_source_url is distinct from
                'https://disclosure2.edinet-fsa.go.jp/WZEK0040.aspx?'
                || average_age_source_id
        )
    )
    or (
        average_age_source is distinct from 'edinet.main.mart_human_capital'
        and average_age_source_url is not null
    )
    or (
        female_manager_ratio_source = 'edinet.main.mart_human_capital'
        and (
            female_manager_ratio_source_id is null
            or female_manager_ratio_source_url is distinct from
                'https://disclosure2.edinet-fsa.go.jp/WZEK0040.aspx?'
                || female_manager_ratio_source_id
        )
    )
    or (
        female_manager_ratio_source is distinct from 'edinet.main.mart_human_capital'
        and female_manager_ratio_source_url is not null
    )
