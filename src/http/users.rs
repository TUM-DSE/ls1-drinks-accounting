use crate::http::errors::ApiError;
use crate::http::ApiContext;
use anyhow::Result;
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Extension, Json, Router};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Deserialize, Clone)]
pub struct CreateUser {
    first_name: String,
    last_name: String,
    email: String,
}

#[derive(Serialize, Clone)]
pub struct UserResponse {
    id: Uuid,
    first_name: String,
    last_name: String,
    email: String,
    balance: f64,
}

pub async fn create_user(
    state: Extension<ApiContext>,
    Json(body): Json<CreateUser>,
) -> Result<impl IntoResponse, ApiError> {
    let user_id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into users (first_name, last_name, email) values ($1, $2, $3) returning id"#,
        body.first_name,
        body.last_name,
        body.email,
    )
    .fetch_one(&state.db)
    .await?;

    let user = UserResponse {
        id: user_id,
        first_name: body.first_name,
        last_name: body.last_name,
        email: body.email,
        balance: 0.0,
    };

    Ok((StatusCode::CREATED, Json(user)))
}

pub async fn get_users(state: Extension<ApiContext>) -> Result<impl IntoResponse, ApiError> {
    let users = sqlx::query!(
        // language=postgresql
        r#"select id, first_name, last_name, email, balances.sum from users left outer join balances on balances."user" = users.id"#
    )
        .map(|row| {
            UserResponse {
                id: row.id,
                first_name: row.first_name,
                last_name: row.last_name,
                email: row.email,
                balance: (row.sum.unwrap_or(0) as f64) / 100.0,
            }
        })
        .fetch_all(&state.db)
        .await?;

    Ok((StatusCode::OK, Json(users)))
}

pub fn router<T: Send + Clone + Sync + 'static>() -> Router<T> {
    Router::new()
        .route("/api/users", get(get_users))
        .route("/api/users", post(create_user))
}
