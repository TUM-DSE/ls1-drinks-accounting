use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::{AdminUser, AuthUser};
use crate::types::stats::{DrinkStatsResponse, UserStatsResponse};
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::get;
use axum::{Json, Router};
use chrono::NaiveDate;
use uuid::Uuid;

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

pub async fn get_user_stats(
    _user: AuthUser,
    State(state): State<ApiContext>,
    Path((drink, from, to)): Path<(Uuid, NaiveDate, NaiveDate)>,
) -> Result<impl IntoResponse, ApiError> {
    let results = db::drinks::get_user_stats_between(&state.db, drink, from, to).await?;

    Ok((StatusCode::OK, Json(UserStatsResponse {
        from,
        to,
        users: results,
    })))
}

pub fn router() -> Router<ApiContext> {
    Router::new()
    .route("/api/stats/drinks/:from/:to", get(get_drink_stats))
    .route("/api/stats/drinks/by-user/:id/:from/:to", get(get_user_stats))
}
