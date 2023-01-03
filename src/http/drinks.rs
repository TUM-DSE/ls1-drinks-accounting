use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::{AdminUser, AuthUser};
use crate::types::drinks::Drink;
use anyhow::Result;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::{get, post, put};
use axum::{Json, Router};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Deserialize)]
pub struct CreateDrink {
    name: String,
    icon: String,
    price: f64,
}

#[derive(Deserialize)]
pub struct UpdateDrinkPrices {
    sale_price: f64,
    buy_price: f64,
}

#[derive(Deserialize)]
pub struct UpdateDrinksAmount {
    amount: u32,
}

pub async fn create_drink(
    _user: AuthUser,
    State(state): State<ApiContext>,
    Json(body): Json<CreateDrink>,
) -> Result<impl IntoResponse, ApiError> {
    let id = db::drinks::insert(&state.db, &body.name, &body.icon, body.price).await?;

    let drink = Drink {
        id,
        name: body.name,
        icon: body.icon,
        price: body.price,
        stock: None,
    };

    Ok((StatusCode::CREATED, Json(drink)))
}

pub async fn update_drink(
    _user: AuthUser,
    State(state): State<ApiContext>,
    Path(drink_id): Path<Uuid>,
    Json(body): Json<CreateDrink>,
) -> Result<impl IntoResponse, ApiError> {
    let id = db::drinks::update(&state.db, drink_id, &body.name, &body.icon, body.price).await?;

    let drink = Drink {
        id,
        name: body.name,
        icon: body.icon,
        price: body.price,
        stock: None,
    };

    Ok((StatusCode::OK, Json(drink)))
}

pub async fn get_drinks(
    _user: AuthUser,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    let drinks = db::drinks::get_all(&state.db).await?;

    Ok((StatusCode::OK, Json(drinks)))
}

pub async fn get_drinks_admin(
    _admin: AdminUser,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    let drinks = db::drinks::get_all_full(&state.db).await?;

    Ok((StatusCode::OK, Json(drinks)))
}

pub async fn update_drink_prices(
    _admin: AdminUser,
    State(state): State<ApiContext>,
    Path(drink_id): Path<Uuid>,
    Json(body): Json<UpdateDrinkPrices>,
) -> Result<impl IntoResponse, ApiError> {
    db::drinks::update_price(&state.db, drink_id, body.sale_price, body.buy_price).await?;

    Ok((StatusCode::OK, Json("ok")))
}

pub async fn update_drink_amount(
    _admin: AdminUser,
    State(state): State<ApiContext>,
    Path(drink_id): Path<Uuid>,
    Json(body): Json<UpdateDrinksAmount>,
) -> Result<impl IntoResponse, ApiError> {
    db::drinks::update_drinks_amount(&state.db, drink_id, body.amount).await?;

    Ok((StatusCode::OK, Json("ok")))
}

pub fn router() -> Router<ApiContext> {
    Router::new()
        .route("/api/drinks", get(get_drinks))
        .route("/api/drinks", post(create_drink))
        .route("/api/drinks/:id", put(update_drink))
        .route("/api/admin/drinks", get(get_drinks_admin))
        .route("/api/admin/drinks/:id/prices", put(update_drink_prices))
        .route("/api/admin/drinks/:id/amount", put(update_drink_amount))
}
