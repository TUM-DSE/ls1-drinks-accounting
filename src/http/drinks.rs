use axum::{Extension, Json, Router};
use axum::response::IntoResponse;
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::http::ApiContext;
use crate::http::errors::ApiError;
use anyhow::Result;
use axum::extract::Path;
use axum::http::StatusCode;
use axum::routing::{get, post, put};

#[derive(Deserialize)]
pub struct CreateDrink {
    name: String,
    icon: String,
    price: f64,
}

#[derive(Serialize)]
pub struct DrinkResponse {
    id: Uuid,
    name: String,
    icon: String,
    price: f64,
}

pub async fn create_drink(
    state: Extension<ApiContext>,
    Json(body): Json<CreateDrink>,
) -> Result<impl IntoResponse, ApiError> {
    let id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into drinks (icon, name, price) values ($1, $2, $3) returning id"#,
        body.icon,
        body.name,
        (body.price * 100.0) as i32,
    )
        .fetch_one(&state.db)
        .await?;

    let drink = DrinkResponse {
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
    let count = sqlx::query_scalar!(
        // language=postgresql
        r#"select count(*) from drinks where id = $1"#,
        drink_id
    )
        .fetch_one(&state.db)
        .await?
        .ok_or(ApiError::NotFound("drink not found".into()))?;

    if count != 1 {
        return Err(ApiError::NotFound("drink not found".into()));
    }

    sqlx::query_scalar!(
        // language=postgresql
        r#"update drinks set hidden = true where id = $1"#,
        drink_id
    )
        .execute(&state.db)
        .await?;

    let id = sqlx::query_scalar!(
        // language=postgresql
        r#"insert into drinks (icon, name, price) values ($1, $2, $3) returning id"#,
        body.icon,
        body.name,
        (body.price * 100.0) as i32,
    )
        .fetch_one(&state.db)
        .await?;

    let drink = DrinkResponse {
        id,
        name: body.name,
        icon: body.icon,
        price: body.price,
    };

    Ok((StatusCode::OK, Json(drink)))
}

pub async fn get_drinks(state: Extension<ApiContext>) -> Result<impl IntoResponse, ApiError> {
    let drinks = sqlx::query!(
        // language=postgresql
        r#"select * from drinks where hidden = false"#
    )
        .map(|row| {
            DrinkResponse {
                id: row.id,
                name: row.name,
                icon: row.icon,
                price: (row.price as f64) / 100.0,
            }
        })
        .fetch_all(&state.db)
        .await?;

    Ok((StatusCode::OK, Json(drinks)))
}

pub fn router<T: Send + Clone + Sync + 'static>() -> Router<T> {
    Router::new()
        .route("/api/drinks", get(get_drinks))
        .route("/api/drinks", post(create_drink))
        .route("/api/drinks/:id", put(update_drink))
}
