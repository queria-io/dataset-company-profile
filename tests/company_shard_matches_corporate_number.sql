-- shard は法人番号の下 3 桁。ずれると、shard のファイルだけを読む利用者がその法人を引けない
select corporate_number, shard
from {{ ref('profile_company') }}
where shard is distinct from right(corporate_number, 3)
