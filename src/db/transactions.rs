use crate::http::errors::ApiError;
use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;

pub async fn insert_transaction(db: &PgPool, user: Uuid, drink: Uuid) -> Result<(), ApiError> {
    sqlx::query_scalar!(
        // language=postgresql
        r#"insert into transactions("user", drink) values ($1, $2)"#,
        user,
        drink
    )
    .execute(db)
    .await?;

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
