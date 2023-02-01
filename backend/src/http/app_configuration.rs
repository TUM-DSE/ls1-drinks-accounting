use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::AuthUser;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::get;
use axum::{Json, Router};
use semver::Version;

pub async fn app_version(
    _user: AuthUser,
    Path(requested_version): Path<Version>,
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    let is_latest = db::app_configuration::get_app_version(&state.db)
        .await?
        .and_then(|config| config.value)
        .and_then(|version| Version::parse(&version).ok())
        .map(|latest_version| requested_version >= latest_version)
        .unwrap_or(true);

    Ok((StatusCode::OK, Json(is_latest)))
}

pub fn router() -> Router<ApiContext> {
    Router::new().route("/api/config/app/:version/is_latest", get(app_version))
}
