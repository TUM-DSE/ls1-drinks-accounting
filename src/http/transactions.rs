use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::post;
use axum::{Extension, Json, Router};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Deserialize)]
pub struct BuyDrinkRequest {
    user: Uuid,
    drink: Uuid,
}

#[derive(Deserialize)]
pub struct DepositMoneyRequest {
    user: Uuid,
    amount: f64,
}

pub async fn buy_drink(
    state: Extension<ApiContext>,
    Json(body): Json<BuyDrinkRequest>,
) -> Result<impl IntoResponse, ApiError> {
    db::transactions::insert_transaction(&state.db, body.user, body.drink).await?;

    let user = db::users::get(&state.db, body.user).await?;

    Ok((StatusCode::OK, Json(user)))
}

pub async fn deposit_money(
    state: Extension<ApiContext>,
    Json(body): Json<DepositMoneyRequest>,
) -> Result<impl IntoResponse, ApiError> {
    db::transactions::insert_deposit(&state.db, body.user, body.amount).await?;

    let user = db::users::get(&state.db, body.user).await?;

    Ok((StatusCode::OK, Json(user)))
}

pub fn router<T: Send + Clone + Sync + 'static>() -> Router<T> {
    Router::new()
        .route("/api/transactions/buy", post(buy_drink))
        .route("/api/transactions/deposit", post(deposit_money))
}
