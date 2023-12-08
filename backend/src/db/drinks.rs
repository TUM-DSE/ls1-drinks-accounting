use crate::db::errors::DbError;
use crate::types::drinks::{Drink, FullDrink};
use crate::types::stats::{DrinkStats, StatsDataPoint};
use anyhow::Result;
use chrono::NaiveDate;
use itertools::Itertools;
use sqlx::PgPool;
use uuid::Uuid;

fn to_cents(euros: f64) -> i32 {
    (euros * 100.0) as i32
}

fn to_euros(cents: i32) -> f64 {
    cents as f64 / 100.0
}

pub async fn insert(
    db: &PgPool,
    name: &str,
    icon: &str,
    sale_price: f64,
    buy_price: Option<f64>,
    count: Option<i32>,
) -> Result<Uuid, DbError> {
    let mut tx = db.begin().await?;

    let price_id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into drink_prices (sale_price, buy_price) values ($1, $2) returning id"#,
        to_cents(sale_price),
        buy_price.map(to_cents),
    )
    .fetch_one(&mut *tx)
    .await?;

    let id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into drinks (name, icon, price, amount) values ($1, $2, $3, $4) returning id"#,
        name,
        icon,
        price_id,
        count,
    )
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(id)
}

pub async fn update_admin(
    db: &PgPool,
    id: Uuid,
    name: &str,
    icon: &str,
    sale_price: f64,
    buy_price: Option<f64>,
    amount: Option<i32>,
) -> Result<Uuid, DbError> {
    let mut tx = db.begin().await?;
    let (mut price_id, old_sale_price, old_buy_price) = sqlx::query!(
        // language=postgresql
        r#"select dp.id, dp.sale_price, dp.buy_price from drinks inner join drink_prices dp on drinks.price = dp.id where drinks.id = $1"#,
        id
    )
    .map(|row| (row.id, to_euros(row.sale_price), row.buy_price.map(to_euros)))
    .fetch_one(&mut *tx)
    .await?;

    if old_sale_price != sale_price || old_buy_price != buy_price {
        price_id = sqlx::query_scalar!(
            // language=postgresql
            r#"insert into drink_prices (sale_price, buy_price) values ($1, $2) returning id"#,
            to_cents(sale_price),
            buy_price.map(to_cents),
        )
        .fetch_one(&mut *tx)
        .await?;
    }

    let old_amount = sqlx::query!(
        // language=postgresql
        r#"select d.amount from drinks d where d.id = $1"#,
        id
    )
    .map(|r| r.amount)
    .fetch_one(&mut *tx)
    .await?;

    if old_amount != amount {
        let diff = amount.unwrap_or(0) - old_amount.unwrap_or(0);
        sqlx::query!(
            // language=postgresql
            r#"insert into drink_restocks (drink, amount) values ($1, $2)"#,
            id,
            diff
        )
        .execute(&mut *tx)
        .await?;
    }

    sqlx::query_scalar!(
        // language=postgresql
        r#"update drinks set name = $2, icon = $3, price = $4, amount = $5 where id = $1"#,
        id,
        name,
        icon,
        price_id,
        amount,
    )
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(id)
}

pub async fn get_all(db: &PgPool) -> Result<Vec<Drink>, DbError> {
    let drinks = sqlx::query!(
        // language=postgresql
        r#"select drinks.*, dp.sale_price from drinks inner join drink_prices dp on dp.id = drinks.price"#
    )
    .map(|row| Drink {
        id: row.id,
        name: row.name,
        icon: row.icon,
        price: (row.sale_price as f64) / 100.0,
        stock: row.amount,
    })
    .fetch_all(db)
    .await?;

    Ok(drinks)
}

pub async fn get_all_full(db: &PgPool) -> Result<Vec<FullDrink>, DbError> {
    let drinks = sqlx::query!(
        // language=postgresql
        r#"select drinks.*, dp.sale_price, dp.buy_price from drinks inner join drink_prices dp on dp.id = drinks.price"#
    )
    .map(|row| FullDrink {
        id: row.id,
        name: row.name,
        icon: row.icon,
        sale_price: (row.sale_price as f64) / 100.0,
        buy_price: row.buy_price.map(|cents| (cents as f64) / 100.0),
        stock: row.amount,
    })
    .fetch_all(db)
    .await?;

    Ok(drinks)
}

pub async fn get_drink_stats_between(
    db: &PgPool,
    from: NaiveDate,
    to: NaiveDate,
) -> Result<Vec<DrinkStats>, DbError> {
    let result = sqlx::query!(
        // language=postgresql
        r#"(select d.id, d.name, dr.date::date as "date", SUM(dr.amount) as "amount" from drink_restocks dr
inner join drinks d on d.id = dr.drink
where date::date >= $1::date and date::date <= $2::date
group by d.id, d.name, date::date
union
select d.id, d.name, tr.date::date as "date", -count(*) as "amount" from transactions tr
inner join drinks d on d.id = tr.drink
where date::date >= $1::date and date::date <= $2::date
group by d.id, d.name, date::date)
order by id, date"#,
        from, to
    )
    .map(|row| (row.id.unwrap(), row.name.unwrap(), row.date.unwrap(), row.amount.unwrap() as i32))
    .fetch_all(db)
    .await?;

    let result = result
        .iter()
        .group_by(|row| (&row.0, &row.1))
        .into_iter()
        .map(|((id, name), values)| DrinkStats {
            id: *id,
            name: name.clone(),
            data: values
                .map(|(_, _, date, amount)| StatsDataPoint {
                    date: *date,
                    count: *amount,
                })
                .collect(),
        })
        .collect::<Vec<_>>();

    Ok(result)
}
