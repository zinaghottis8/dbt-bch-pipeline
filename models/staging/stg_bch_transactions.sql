with source as (

    select *
    from `bigquery-public-data.crypto_bitcoin_cash.transactions`
    where block_timestamp >= timestamp_sub(current_timestamp(), interval 3 month)

),

renamed as (

    select
        hash as transaction_hash,
        block_hash,
        block_number,
        block_timestamp,
        is_coinbase,
        input_count,
        output_count,
        inputs,
        outputs,
        size,
        virtual_size,
        version,
        lock_time,
        fee,
        input_value,
        output_value
    from source

)

select *
from renamed