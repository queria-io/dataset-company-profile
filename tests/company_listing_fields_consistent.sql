select
    corporate_number,
    is_listed,
    listing_status,
    market_segment,
    securities_code
from {{ ref('profile_company') }}
where listing_status = '非上場'
  and (
      is_listed is distinct from false
      or market_segment is not null
      or market_segment_source is not null
      or market_segment_as_of is not null
      or securities_code is not null
      or securities_code_source is not null
      or securities_code_source_url is not null
      or securities_code_as_of is not null
  )
