use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::drinks::Drink;
use anyhow::Result;
use axum::extract::Path;
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::{get, post, put};
use axum::{Extension, Json, Router};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Deserialize)]
pub struct CreateDrink {
    name: String,
    icon: String,
    price: f64,
}

pub async fn create_drink(
    state: Extension<ApiContext>,
    Json(body): Json<CreateDrink>,
) -> Result<impl IntoResponse, ApiError> {
    let id = db::drinks::insert(&state.db, &body.name, &body.icon, body.price).await?;

    let drink = Drink {
        id,
        name: body.name,
        icon: body.icon,
        price: body.price,
    };

    Ok((StatusCode::CREATED, Json(drink)))
}

pub async fn update_drink(
    state: Extension<ApiContext>,
    Path(drink_id): Path<Uuid>,
    Json(body): Json<CreateDrink>,
) -> Result<impl IntoResponse, ApiError> {
    let id = db::drinks::update(&state.db, drink_id, &body.name, &body.icon, body.price).await?;

    let drink = Drink {
        id,
        name: body.name,
        icon: body.icon,
        price: body.price,
    };

    Ok((StatusCode::OK, Json(drink)))
}

pub async fn get_drinks(state: Extension<ApiContext>) -> Result<impl IntoResponse, ApiError> {
    let drinks = db::drinks::get_all(&state.db).await?;

    Ok((StatusCode::OK, Json(drinks)))
}

pub fn router<T: Send + Clone + Sync + 'static>() -> Router<T> {
    Router::new()
        .route("/api/drinks", get(get_drinks))
        .route("/api/drinks", post(create_drink))
        .route("/api/drinks/:id", put(update_drink))
}
