use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::{AdminUser, AuthUser};
use crate::types::drinks::FullDrink;
use anyhow::Result;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::{delete, get, post, put};
use axum::{Json, Router};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Deserialize)]
pub struct CreateDrinkAdmin {
    name: String,
    icon: String,
    sale_price: f64,
    buy_price: Option<f64>,
    stock: Option<i32>,
}

pub async fn get_drinks(
    _user: AuthUser,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    let mut drinks = db::drinks::get_all(&state.db).await?;

    drinks.sort_by_key(|drink| drink.name.to_lowercase());

    Ok((StatusCode::OK, Json(drinks)))
}

pub async fn get_drinks_admin(
    _admin: AdminUser,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    let mut drinks = db::drinks::get_all_full(&state.db).await?;

    drinks.sort_by_key(|drink| drink.name.to_lowercase());

    Ok((StatusCode::OK, Json(drinks)))
}

pub async fn delete_drink(
    _admin: AdminUser,
    State(state): State<ApiContext>,
    Path(drink_id): Path<Uuid>,
) -> Result<impl IntoResponse, ApiError> {
    let was_deleted = db::drinks::delete_drink(&state.db, drink_id).await?;

    if was_deleted {
        Ok((StatusCode::OK, Json(())))
    } else {
        Ok((StatusCode::NOT_FOUND, Json(())))
    }
}

pub async fn create_drink_admin(
    _admin: AdminUser,
    State(state): State<ApiContext>,
    Json(body): Json<CreateDrinkAdmin>,
) -> Result<impl IntoResponse, ApiError> {
    let id = db::drinks::insert(
        &state.db,
        &body.name,
        &body.icon,
        body.sale_price,
        body.buy_price,
        body.stock,
    )
    .await?;

    let drink = FullDrink {
        id,
        name: body.name,
        icon: body.icon,
        sale_price: body.sale_price,
        buy_price: body.buy_price,
        stock: None,
    };

    Ok((StatusCode::CREATED, Json(drink)))
}

pub async fn update_drink_admin(
    _admin: AdminUser,
    State(state): State<ApiContext>,
    Path(drink_id): Path<Uuid>,
    Json(body): Json<CreateDrinkAdmin>,
) -> Result<impl IntoResponse, ApiError> {
    db::drinks::update_admin(
        &state.db,
        drink_id,
        &body.name,
        &body.icon,
        body.sale_price,
        body.buy_price,
        body.stock,
    )
    .await?;

    let drink = FullDrink {
        id: drink_id,
        name: body.name,
        icon: body.icon,
        sale_price: body.sale_price,
        buy_price: body.buy_price,
        stock: None,
    };

    Ok((StatusCode::OK, Json(drink)))
}

pub fn router() -> Router<ApiContext> {
    Router::new()
        .route("/api/drinks", get(get_drinks))
        .route("/api/admin/drinks", get(get_drinks_admin))
        .route("/api/admin/drinks", post(create_drink_admin))
        .route("/api/admin/drinks/:id", put(update_drink_admin))
        .route("/api/admin/drinks/:id", delete(delete_drink))
}
