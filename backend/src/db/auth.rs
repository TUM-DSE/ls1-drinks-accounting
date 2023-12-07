use crate::db::errors::DbError;
use crate::types::auth::{AuthUserData, Role};
use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;

pub async fn get_user_by_username(db: &PgPool, username: &str) -> Result<AuthUserData, DbError> {
    let user = sqlx::query!(
        // language=postgresql
        r#"select * from auth_users where username = $1"#,
        username,
    )
    .map(|row| AuthUserData {
        id: row.id,
        privilege: row.privilege,
        username: row.username,
        password: row.password,
    })
    .fetch_one(db)
    .await?;

    Ok(user)
}

pub async fn get_user_by_id(db: &PgPool, id: Uuid) -> Result<AuthUserData, DbError> {
    let user =
        sqlx::query!(
            // language=postgresql
            r#"select * from auth_users where id = $1"#,
            id,
        )
        .map(|row| AuthUserData {
            id: row.id,
            privilege: row.privilege,
            username: row.username,
            password: row.password,
        })
        .fetch_one(db)
        .await?;

    Ok(user)
}

pub async fn create_user(
    db: &PgPool,
    username: String,
    hashed_password: String,
    role: Role,
) -> Result<Uuid, DbError> {
    let id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into auth_users (username, password, privilege) values ($1, $2, $3) returning id"#,
        username,
        hashed_password,
        role.to_string(),
    )
        .fetch_one(db)
        .await?;

    Ok(id)
}
