use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::{AdminUser, AuthUser};
use axum::extract::State;
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::post;
use axum::{Json, Router};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Deserialize)]
pub struct BuyDrinkRequest {
    user: Uuid,
    drink: Uuid,
    user_pin: Option<String>,
}

#[derive(Deserialize)]
pub struct DepositMoneyRequest {
    user: Uuid,
    amount: f64,
}

pub async fn buy_drink(
    _user: AuthUser,
    State(state): State<ApiContext>,
    Json(body): Json<BuyDrinkRequest>,
) -> Result<impl IntoResponse, ApiError> {
    let user = db::users::get(&state.db, body.user).await?;

    if let Some(pin) = &user.pin {
        if let Some(true) = body.user_pin.and_then(|input| argon2::verify_encoded(pin, input.as_bytes()).ok()) {} else {
            return Err(ApiError::BadRequest("User pin incorrect!".to_string()));
        }
    }

    db::transactions::buy_drink(&state.db, body.user, body.drink).await?;

    Ok((StatusCode::OK, Json(user)))
}

pub async fn deposit_money(
    _user: AdminUser,
    State(state): State<ApiContext>,
    Json(body): Json<DepositMoneyRequest>,
) -> Result<impl IntoResponse, ApiError> {
    db::transactions::insert_deposit(&state.db, body.user, body.amount).await?;

    let user = db::users::get(&state.db, body.user).await?;

    Ok((StatusCode::OK, Json(user)))
}

pub fn router() -> Router<ApiContext> {
    Router::new()
    .route("/api/transactions/buy", post(buy_drink))
    .route("/api/transactions/deposit", post(deposit_money))
}
