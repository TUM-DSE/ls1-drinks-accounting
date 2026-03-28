\set ON_ERROR_STOP on

with selected_users as (
    select id
    from users
    where deleted = false
),
selected_drinks as (
    select d.id as drink_id, d.price as price_id
    from drinks d
    where d.deleted = false
),
generated_transactions as (
    select
        (
            select id
            from selected_users
            order by random()
            limit 1
        ) as user_id,
        (
            select drink_id
            from selected_drinks
            order by random()
            limit 1
        ) as drink_id,
        now()
            - (random() * interval '14 days')
            + (random() * interval '59 minutes')
            + (random() * interval '59 seconds') as transaction_date
    from generate_series(1, :transaction_count)
)
insert into transactions ("user", drink, price, date)
select gt.user_id, gt.drink_id, sd.price_id, gt.transaction_date
from generated_transactions gt
inner join selected_drinks sd on sd.drink_id = gt.drink_id
where gt.user_id is not null and gt.drink_id is not null;
