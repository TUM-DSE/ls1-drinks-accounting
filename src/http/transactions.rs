use axum::{Extension, Json, Router};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use serde::Deserialize;
use uuid::Uuid;
use crate::http::ApiContext;
use crate::http::errors::ApiError;
use crate::http::users::UserResponse;
use axum::routing::post;

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
    sqlx::query_scalar!(
        // language=postgresql
        r#"insert into transactions("user", drink) values ($1, $2)"#,
        body.user,
        body.drink
    )
        .execute(&state.db)
        .await?;

    let user = sqlx::query!(
        // language=postgresql
        r#"select id, first_name, last_name, email, balances.sum from users left outer join balances on balances."user" = users.id where users.id = $1"#,
        body.user,
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
        .fetch_one(&state.db)
        .await?;

    Ok((StatusCode::OK, Json(user)))
}

pub async fn deposit_money(
    state: Extension<ApiContext>,
    Json(body): Json<DepositMoneyRequest>,
) -> Result<impl IntoResponse, ApiError> {
    sqlx::query_scalar!(
        // language=postgresql
        r#"insert into deposits("user", amount) values ($1, $2)"#,
        body.user,
        (body.amount * 100.0) as i32,
    )
        .execute(&state.db)
        .await?;

    let user = sqlx::query!(
        // language=postgresql
        r#"select id, first_name, last_name, email, balances.sum from users left outer join balances on balances."user" = users.id where users.id = $1"#,
        body.user,
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
        .fetch_one(&state.db)
        .await?;

    Ok((StatusCode::OK, Json(user)))
}

pub fn router<T: Send + Clone + Sync + 'static>() -> Router<T> {
    Router::new()
        .route("/api/transactions/buy", post(buy_drink))
        .route("/api/transactions/deposit", post(deposit_money))
}
