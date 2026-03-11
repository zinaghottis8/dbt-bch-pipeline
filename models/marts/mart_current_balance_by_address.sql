{{ config(materialized='table') }}

with transactions as (

    select *
    from {{ ref('stg_bch_transactions') }}

),

output_addresses as (

    select
        output_address as address,
        cast(output.value as numeric) as received_value,
        0 as sent_value,
        t.is_coinbase
    from transactions t,
    unnest(t.outputs) as output,
    unnest(output.addresses) as output_address

),

input_addresses as (

    select
        input_address as address,
        0 as received_value,
        cast(input.value as numeric) as sent_value,
        t.is_coinbase
    from transactions t,
    unnest(t.inputs) as input,
    unnest(input.addresses) as input_address

),

address_movements as (

    select * from output_addresses
    union all
    select * from input_addresses

),

coinbase_addresses as (

    select distinct address
    from address_movements
    where is_coinbase = true

),

balances as (

    select
        address,
        sum(received_value) as total_received,
        sum(sent_value) as total_sent,
        sum(received_value) - sum(sent_value) as current_balance
    from address_movements
    where address is not null
    group by address

)

select
    b.address,
    b.total_received,
    b.total_sent,
    b.current_balance
from balances b
left join coinbase_addresses c
    on b.address = c.address
where c.address is null