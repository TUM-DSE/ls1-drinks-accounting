use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use axum::extract::State;
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::get;
use axum::{Json, Router};

pub async fn health_check(State(state): State<ApiContext>) -> Result<impl IntoResponse, ApiError> {
    let result = db::health::get_all(&state.db).await?;

    Ok((StatusCode::OK, Json(result)))
}

pub fn router() -> Router<ApiContext> {
    Router::new().route("/api/health", get(health_check))
}
