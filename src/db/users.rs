use crate::http::errors::ApiError;
use crate::types::users::User;
use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;

pub async fn insert(
    db: &PgPool,
    first_name: &str,
    last_name: &str,
    email: &str,
) -> Result<Uuid, ApiError> {
    let user_id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into users (first_name, last_name, email) values ($1, $2, $3) returning id"#,
        first_name,
        last_name,
        email,
    )
    .fetch_one(db)
    .await?;

    Ok(user_id)
}

pub async fn get_all(db: &PgPool) -> Result<Vec<User>, ApiError> {
    let users = sqlx::query!(
        // language=postgresql
        r#"select id, first_name, last_name, email, balances.sum from users left outer join balances on balances."user" = users.id"#
    )
        .map(|row| {
            User {
                id: row.id,
                first_name: row.first_name,
                last_name: row.last_name,
                email: row.email,
                balance: (row.sum.unwrap_or(0) as f64) / 100.0,
            }
        })
        .fetch_all(db)
        .await?;

    Ok(users)
}

pub async fn get(db: &PgPool, id: Uuid) -> Result<User, ApiError> {
    let user = sqlx::query!(
        // language=postgresql
        r#"select id, first_name, last_name, email, balances.sum from users left outer join balances on balances."user" = users.id where users.id = $1"#,
        id,
    )
        .map(|row| {
            User {
                id: row.id,
                first_name: row.first_name,
                last_name: row.last_name,
                email: row.email,
                balance: (row.sum.unwrap_or(0) as f64) / 100.0,
            }
        })
        .fetch_one(db)
        .await?;

    Ok(user)
}