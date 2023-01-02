use crate::http::errors::ApiError;
use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;

pub async fn buy_drink(db: &PgPool, user: Uuid, drink: Uuid) -> Result<(), ApiError> {
    let mut tx = db.begin().await?;

    let price = sqlx::query!(
        // language=postgresql
        r#"select dp.* from drinks inner join drink_prices dp on dp.id = drinks.price where drinks.id = $1"#,
        drink
    )
        .map(|row| row.id)
        .fetch_one(&mut tx)
        .await?;

    sqlx::query_scalar!(
        // language=postgresql
        r#"insert into transactions("user", drink, price) values ($1, $2, $3)"#,
        user,
        drink,
        price
    )
    .execute(&mut tx)
    .await?;

    sqlx::query_scalar!(
        // language=postgresql
        r#"update drinks set amount = amount - 1 where id = $1 and amount is not null"#,
        drink
    )
    .execute(&mut tx)
    .await?;

    tx.commit().await?;

    Ok(())
}

pub async fn insert_deposit(db: &PgPool, user: Uuid, amount: f64) -> Result<(), ApiError> {
    sqlx::query_scalar!(
        // language=postgresql
        r#"insert into deposits("user", amount) values ($1, $2)"#,
        user,
        (amount * 100.0) as i32,
    )
    .execute(db)
    .await?;

    Ok(())
}
