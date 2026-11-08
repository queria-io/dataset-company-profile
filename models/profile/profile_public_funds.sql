{{ config(alias='public_funds') }}

with funds as (
    select
        corporate_number,
        name as company_name,
        'subsidy' as fund_type,
        title,
        cast(amount as decimal(38, 2)) as amount,
        certification_date as event_date,
        issuer,
        'gbizinfo' as source_dataset,
        'main.mart_gbizinfo_subsidy' as source_table,
        cast(null as varchar) as source_record_id
    from gbizinfo.main.mart_gbizinfo_subsidy
    where corporate_number is not null

    union all

    select
        corporate_number,
        trade_name as company_name,
        'procurement' as fund_type,
        procurement_item_name as title,
        cast(award_price as decimal(38, 2)) as amount,
        award_date as event_date,
        ministry_name as issuer,
        'p_portal' as source_dataset,
        'main.procurement_award' as source_table,
        procurement_item_no as source_record_id
    from p_portal.main.procurement_award
    where corporate_number is not null
),

funds_with_id as (
    select
        *,
        md5(concat_ws(
            '|',
            source_dataset,
            source_table,
            coalesce(source_record_id, ''),
            corporate_number,
            coalesce(title, ''),
            coalesce(cast(amount as varchar), ''),
            coalesce(cast(event_date as varchar), ''),
            coalesce(issuer, '')
        )) as fund_id_base
    from funds
)

select
    fund_id_base || '-' || row_number() over (
        partition by fund_id_base
        order by source_dataset, source_table, corporate_number
    ) as fund_id,
    corporate_number,
    company_name,
    fund_type,
    title,
    amount,
    event_date,
    issuer,
    source_dataset,
    source_table,
    source_record_id
from funds_with_id
order by corporate_number, event_date, fund_type, fund_id
