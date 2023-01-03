use crate::http::errors::ApiError;
use crate::types::drinks::{Drink, FullDrink};
use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;

pub async fn insert(db: &PgPool, name: &str, icon: &str, price: f64) -> Result<Uuid, ApiError> {
    let mut tx = db.begin().await?;

    let price_id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into drink_prices (sale_price) values ($1) returning id"#,
        (price * 100.0) as i32,
    )
    .fetch_one(&mut tx)
    .await?;

    let id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into drinks (name, icon, price) values ($1, $2, $3) returning id"#,
        name,
        icon,
        price_id,
    )
    .fetch_one(&mut tx)
    .await?;

    tx.commit().await?;
    Ok(id)
}

pub async fn update(
    db: &PgPool,
    id: Uuid,
    name: &str,
    icon: &str,
    price: f64,
) -> Result<Uuid, ApiError> {
    let mut tx = db.begin().await?;
    let (mut price_id, old_price) = sqlx::query!(
        // language=postgresql
        r#"select dp.id, dp.sale_price from drinks inner join drink_prices dp on drinks.price = dp.id where drinks.id = $1"#,
        id
    )
    .map(|row| (row.id, row.sale_price as f64 / 100.0))
    .fetch_one(&mut tx)
    .await?;

    if old_price != price {
        price_id = sqlx::query_scalar!(
            // language=postgresql
            r#"insert into drink_prices (sale_price) values ($1) returning id"#,
            (price * 100.0) as i32
        )
        .fetch_one(&mut tx)
        .await?;
    }

    sqlx::query_scalar!(
        // language=postgresql
        r#"update drinks set name = $2, icon = $3, price = $4 where id = $1"#,
        id,
        name,
        icon,
        price_id,
    )
    .fetch_one(&mut tx)
    .await?;

    tx.commit().await?;
    Ok(id)
}

pub async fn get_all(db: &PgPool) -> Result<Vec<Drink>, ApiError> {
    let drinks = sqlx::query!(
        // language=postgresql
        r#"select drinks.*, dp.sale_price from drinks inner join drink_prices dp on dp.id = drinks.price"#
    )
    .map(|row| Drink {
        id: row.id,
        name: row.name,
        icon: row.icon,
        price: (row.sale_price as f64) / 100.0,
        stock: row.amount.map(|val| val.max(0) as u32)
    })
    .fetch_all(db)
    .await?;

    Ok(drinks)
}

pub async fn get_all_full(db: &PgPool) -> Result<Vec<FullDrink>, ApiError> {
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
        stock: row.amount.map(|val| val.max(0) as u32)
    })
    .fetch_all(db)
    .await?;

    Ok(drinks)
}

pub async fn update_drinks_amount(db: &PgPool, id: Uuid, amount: u32) -> Result<(), ApiError> {
    let mut tx = db.begin().await?;

    let result = sqlx::query!(
        // language=postgresql
        r#"update drinks set amount = $1 where id = $2"#,
        amount as i32,
        id
    )
    .execute(&mut tx)
    .await?;

    if result.rows_affected() != 1 {
        tx.rollback().await?;
        return Err(ApiError::NotFound("drink not found".to_string()));
    }

    tx.commit().await?;
    Ok(())
}

pub async fn update_price(
    db: &PgPool,
    id: Uuid,
    sale_price: f64,
    buy_price: f64,
) -> Result<(), ApiError> {
    let mut tx = db.begin().await?;

    let price_id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into drink_prices (sale_price, buy_price) values ($1, $2) returning id"#,
        (sale_price * 100.0) as i32,
        (buy_price * 100.0) as i32
    )
    .fetch_one(&mut tx)
    .await?;

    let result = sqlx::query!(
        // language=postgresql
        r#"update drinks set price = $1 where id = $2"#,
        price_id,
        id
    )
    .execute(&mut tx)
    .await?;

    if result.rows_affected() != 1 {
        tx.rollback().await?;
        // TODO: properly separate api errors from db errors
        return Err(ApiError::NotFound("drink not found".to_string()));
    }

    tx.commit().await?;
    Ok(())
}
