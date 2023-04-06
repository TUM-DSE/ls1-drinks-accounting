use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::AdminUser;
use crate::types::stats::DrinkStatsResponse;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::get;
use axum::{Json, Router};
use chrono::NaiveDate;

pub async fn get_drink_stats(
    _user: AdminUser,
    State(state): State<ApiContext>,
    Path((from, to)): Path<(NaiveDate, NaiveDate)>,
) -> Result<impl IntoResponse, ApiError> {
    let stats = db::drinks::get_drink_stats_between(&state.db, from, to).await?;

    Ok((
        StatusCode::OK,
        Json(DrinkStatsResponse {
            from,
            to,
            drinks: stats,
        }),
    ))
}

pub fn router() -> Router<ApiContext> {
    Router::new().route("/api/stats/drinks/:from/:to", get(get_drink_stats))
}
