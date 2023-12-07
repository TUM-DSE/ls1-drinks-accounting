use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::{AdminUser, AuthUser};
use crate::types::users::UserResponse;
use anyhow::Result;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::{delete, get, post, put};
use axum::{Json, Router};
use rand::Rng;
use serde::Deserialize;
use uuid::Uuid;

#[derive(Deserialize)]
pub struct CreateUser {
    first_name: String,
    last_name: String,
    email: String,
}

#[derive(Deserialize)]
pub struct UpdatePin {
    old_pin: Option<String>,
    new_pin: Option<String>,
}
#[derive(Deserialize)]
pub struct CheckPin {
    user_pin: Option<String>,
}

pub async fn create_user(
    _user: AuthUser,
    State(state): State<ApiContext>,
    Json(body): Json<CreateUser>,
) -> Result<impl IntoResponse, ApiError> {
    let user_id =
        db::users::insert(&state.db, &body.first_name, &body.last_name, &body.email).await?;

    let user =
        UserResponse {
            id: user_id,
            first_name: body.first_name,
            last_name: body.last_name,
            email: body.email,
            balance: 0.0,
            has_pin: false,
        };

    Ok((StatusCode::CREATED, Json(user)))
}

pub async fn get_users(
    _user: AuthUser,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    let users = db::users::get_all(&state.db)
        .await?
        .into_iter()
        .map(UserResponse::from)
        .collect::<Vec<_>>();

    Ok((StatusCode::OK, Json(users)))
}

pub async fn get_user_transactions(
    _user: AuthUser,
    Path(user_id): Path<Uuid>,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    let transactions = db::transactions::get_transactions(&state.db, user_id).await?;

    Ok((StatusCode::OK, Json(transactions)))
}

pub async fn update_user_pin(
    _user: AuthUser,
    Path(user_id): Path<Uuid>,
    State(state): State<ApiContext>,
    Json(body): Json<UpdatePin>,
) -> Result<impl IntoResponse, ApiError> {
    let user = db::users::get(&state.db, user_id).await?;

    if let Some(pin) = &user.pin {
        if let Some(true) = body
            .old_pin
            .and_then(|input| argon2::verify_encoded(pin, input.as_bytes()).ok())
        {
        } else {
            return Err(ApiError::BadRequest("User pin incorrect!".to_string()));
        }
    }

    let new_pin = body.new_pin.and_then(|pin| {
        let salt: [u8; 32] = rand::thread_rng().gen();
        let config = argon2::Config::default();

        argon2::hash_encoded(pin.as_bytes(), &salt, &config).ok()
    });

    db::users::update_pin(&state.db, user_id, new_pin).await?;

    Ok((StatusCode::OK, Json(true)))
}

pub async fn check_user_pin(
    _user: AuthUser,
    Path(user_id): Path<Uuid>,
    State(state): State<ApiContext>,
    Json(body): Json<CheckPin>,
) -> Result<impl IntoResponse, ApiError> {
    let user = db::users::get(&state.db, user_id).await?;

    let result = user
        .pin
        .map(|pin| {
            matches!(
                body.user_pin
                    .and_then(|input| argon2::verify_encoded(&pin, input.as_bytes()).ok()),
                Some(true)
            )
        })
        .unwrap_or(true);

    Ok((StatusCode::OK, Json(result)))
}

pub async fn delete_user(
    _admin: AdminUser,
    Path(user_id): Path<Uuid>,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    db::users::delete_user(&state.db, user_id).await?;

    Ok(())
}

pub async fn reset_user_pin(
    _admin: AdminUser,
    Path(user_id): Path<Uuid>,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    db::users::update_pin(&state.db, user_id, None).await?;

    Ok(())
}

pub fn router() -> Router<ApiContext> {
    Router::new()
        .route("/api/users", get(get_users))
        .route("/api/users", post(create_user))
        .route("/api/users/:id", delete(delete_user))
        .route("/api/users/:id/transactions", get(get_user_transactions))
        .route("/api/users/:id/pin", put(update_user_pin))
        .route("/api/users/:id/check_pin", post(check_user_pin))
        .route("/api/users/:id/reset_pin", put(reset_user_pin))
}
