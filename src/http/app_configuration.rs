use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::AuthUser;
use axum::extract::State;
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::get;
use axum::{Json, Router};
use serde::Serialize;

#[derive(Serialize)]
pub struct AppVersionResponse {
    version: Option<String>,
}

pub async fn app_version(
    _user: AuthUser,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    let version = db::app_configuration::get_app_version(&state.db)
        .await?
        .and_then(|config| config.value);

    Ok((StatusCode::OK, Json(AppVersionResponse { version })))
}

pub fn router() -> Router<ApiContext> {
    Router::new().route("/api/config/app/version", get(app_version))
}
