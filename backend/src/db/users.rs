use crate::http::errors::ApiError;
use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;

pub struct User {
    pub id: Uuid,
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub balance: f64,
    pub pin: Option<String>,
}

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

pub async fn update_pin(db: &PgPool, id: Uuid, pin: Option<String>) -> Result<(), ApiError> {
    let mut tx = db.begin().await?;
    let result = sqlx::query!(
        // language=postgresql
        r#"update users set pin = $1 where id = $2"#,
        pin,
        id
    )
    .execute(&mut tx)
    .await?;

    if result.rows_affected() != 1 {
        return Err(ApiError::NotFound("user not found".to_string()));
    }

    tx.commit().await?;

    Ok(())
}

pub async fn get_all(db: &PgPool) -> Result<Vec<User>, ApiError> {
    let users = sqlx::query!(
        // language=postgresql
        r#"select id, first_name, last_name, email, balances.sum, pin from users
            left outer join balances on balances."user" = users.id
            where users.deleted = false"#
    )
    .map(|row| User {
        id: row.id,
        first_name: row.first_name,
        last_name: row.last_name,
        email: row.email,
        balance: (row.sum.unwrap_or(0) as f64) / 100.0,
        pin: row.pin,
    })
    .fetch_all(db)
    .await?;

    Ok(users)
}

pub async fn get(db: &PgPool, id: Uuid) -> Result<User, ApiError> {
    let user = sqlx::query!(
        // language=postgresql
        r#"select id, first_name, last_name, email, balances.sum, pin from users
            left outer join balances on balances."user" = users.id
            where users.id = $1 and users.deleted = false"#,
        id,
    )
    .map(|row| User {
        id: row.id,
        first_name: row.first_name,
        last_name: row.last_name,
        email: row.email,
        balance: (row.sum.unwrap_or(0) as f64) / 100.0,
        pin: row.pin,
    })
    .fetch_one(db)
    .await?;

    Ok(user)
}

pub async fn get_all_with_negative_balance(db: &PgPool) -> Result<Vec<User>, ApiError> {
    let users = sqlx::query!(
        // language=postgresql
        r#"select id, first_name, last_name, email, balances.sum, pin from users
            left outer join balances on balances."user" = users.id
            where users.deleted = false and balances.sum < 0"#
    )
    .map(|row| User {
        id: row.id,
        first_name: row.first_name,
        last_name: row.last_name,
        email: row.email,
        balance: (row.sum.unwrap_or(0) as f64) / 100.0,
        pin: row.pin,
    })
    .fetch_all(db)
    .await?;

    Ok(users)
}

pub async fn delete_user(db: &PgPool, id: Uuid) -> Result<(), ApiError> {
    let mut tx = db.begin().await?;

    let result = sqlx::query!(
        // language=postgresql
        r#"update users set deleted = true where id = $1"#,
        id
    )
    .execute(&mut tx)
    .await?;

    if result.rows_affected() != 1 {
        Err(ApiError::NotFound("user not found".to_string()))
    } else {
        tx.commit().await?;
        Ok(())
    }
}
