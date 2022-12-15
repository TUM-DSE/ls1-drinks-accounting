use crate::http::errors::ApiError;
use crate::types::drinks::Drink;
use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;

pub async fn insert(db: &PgPool, name: &str, icon: &str, price: f64) -> Result<Uuid, ApiError> {
    let id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into drinks (name, icon, price) values ($1, $2, $3) returning id"#,
        name,
        icon,
        (price * 100.0) as i32,
    )
    .fetch_one(db)
    .await?;

    Ok(id)
}

pub async fn update(
    db: &PgPool,
    id: Uuid,
    name: &str,
    icon: &str,
    price: f64,
) -> Result<Uuid, ApiError> {
    let count = sqlx::query_scalar!(
        // language=postgresql
        r#"select count(*) from drinks where id = $1"#,
        id
    )
    .fetch_one(db)
    .await?
    .ok_or(ApiError::NotFound("drink not found".into()))?;

    if count != 1 {
        return Err(ApiError::NotFound("drink not found".into()))?;
    }

    sqlx::query_scalar!(
        // language=postgresql
        r#"update drinks set hidden = true where id = $1"#,
        id
    )
    .execute(db)
    .await?;

    let id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into drinks (icon, name, price) values ($1, $2, $3) returning id"#,
        icon,
        name,
        (price * 100.0) as i32,
    )
    .fetch_one(db)
    .await?;

    Ok(id)
}

pub async fn get_all(db: &PgPool) -> Result<Vec<Drink>, ApiError> {
    let drinks = sqlx::query!(
        // language=postgresql
        r#"select * from drinks where hidden = false"#
    )
    .map(|row| Drink {
        id: row.id,
        name: row.name,
        icon: row.icon,
        price: (row.price as f64) / 100.0,
    })
    .fetch_all(db)
    .await?;

    Ok(drinks)
}
