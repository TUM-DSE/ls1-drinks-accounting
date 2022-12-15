use crate::http::errors::ApiError;
use crate::http::ApiContext;
use anyhow::Result;
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Extension, Json, Router};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A wrapper type for all requests/responses from these routes.
#[derive(serde::Serialize, serde::Deserialize)]
pub struct UserBody<T> {
    user: T,
}

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
}

static mut USERS: Vec<UserResponse> = vec![];

pub async fn create_user(
    state: Extension<ApiContext>,
    Json(body): Json<UserBody<CreateUser>>,
) -> Result<impl IntoResponse, ApiError> {
    let user_id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into users (first_name, last_name, email) values ($1, $2, $3) returning id"#,
        body.user.first_name,
        body.user.last_name,
        body.user.email,
    )
    .fetch_one(&state.db)
    .await?;

    let user = UserResponse {
        id: user_id,
        first_name: body.user.first_name,
        last_name: body.user.last_name,
        email: body.user.email,
    };

    Ok((StatusCode::CREATED, Json(user)))
}

pub async fn get_users() -> impl IntoResponse {
    let u = unsafe { &USERS };

    (StatusCode::OK, Json(u))
}

pub fn router<T: Send + Clone + Sync + 'static>() -> Router<T> {
    Router::new()
        .route("/api/users", get(get_users))
        .route("/api/users", post(create_user))
}
