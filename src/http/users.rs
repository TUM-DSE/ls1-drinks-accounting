use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::AuthUser;
use crate::types::users::User;
use anyhow::Result;
use axum::extract::State;
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::Deserialize;

#[derive(Deserialize)]
pub struct CreateUser {
    first_name: String,
    last_name: String,
    email: String,
}

pub async fn create_user(
    _user: AuthUser,
    State(state): State<ApiContext>,
    Json(body): Json<CreateUser>,
) -> Result<impl IntoResponse, ApiError> {
    let user_id =
        db::users::insert(&state.db, &body.first_name, &body.last_name, &body.email).await?;

    let user = User {
        id: user_id,
        first_name: body.first_name,
        last_name: body.last_name,
        email: body.email,
        balance: 0.0,
    };

    Ok((StatusCode::CREATED, Json(user)))
}

pub async fn get_users(
    _user: AuthUser,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    let users = db::users::get_all(&state.db).await?;

    Ok((StatusCode::OK, Json(users)))
}

pub fn router() -> Router<ApiContext> {
    Router::new()
        .route("/api/users", get(get_users))
        .route("/api/users", post(create_user))
}
