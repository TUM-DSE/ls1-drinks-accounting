use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::AdminUser;
use crate::types::stats::{
    DrinkStatsResponse, WeeklyDrinkStatsResponse, WeeklyStatsPoint, WeeklyStatsSeries,
};
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::get;
use axum::{Json, Router};
use chrono::{Datelike, Local, NaiveDate, TimeZone, Timelike, Utc};

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

pub async fn get_weekly_drink_stats(
    State(state): State<ApiContext>,
) -> Result<impl IntoResponse, ApiError> {
    let now = Local::now();
    let weekday_offset = now.weekday().num_days_from_monday() as i64;
    let current_week_start = now
        .date_naive()
        .and_hms_opt(0, 0, 0)
        .expect("midnight is valid")
        - chrono::Duration::days(weekday_offset);
    let previous_week_start = current_week_start - chrono::Duration::days(7);
    let current_week_end = current_week_start + chrono::Duration::days(7);

    let from = Local
        .from_local_datetime(&previous_week_start)
        .single()
        .ok_or_else(|| ApiError::Internal("Could not resolve previous week start".to_string()))?
        .with_timezone(&Utc);
    let to = Local
        .from_local_datetime(&current_week_end)
        .single()
        .ok_or_else(|| ApiError::Internal("Could not resolve current week end".to_string()))?
        .with_timezone(&Utc);

    let timestamps =
        db::transactions::get_drink_purchase_timestamps_between(&state.db, from, to).await?;

    let mut current_week_counts = [0i32; 7 * 24];
    let mut previous_week_counts = [0i32; 7 * 24];

    for timestamp in timestamps {
        let local_timestamp = timestamp.with_timezone(&Local);
        let slot_index = (local_timestamp.weekday().num_days_from_monday() * 24
            + local_timestamp.hour()) as usize;

        if local_timestamp.naive_local() >= current_week_start
            && local_timestamp.naive_local() < current_week_end
        {
            current_week_counts[slot_index] += 1;
        } else if local_timestamp.naive_local() >= previous_week_start
            && local_timestamp.naive_local() < current_week_start
        {
            previous_week_counts[slot_index] += 1;
        }
    }

    let day_labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    let mut current_cumulative = 0;
    let mut previous_cumulative = 0;
    let mut current_points = Vec::with_capacity(7 * 24);
    let mut previous_points = Vec::with_capacity(7 * 24);

    for slot_index in 0..(7 * 24) {
        current_cumulative += current_week_counts[slot_index];
        previous_cumulative += previous_week_counts[slot_index];

        current_points.push(WeeklyStatsPoint {
            slot_index: slot_index as i32,
            day_label: day_labels[slot_index / 24].to_string(),
            count: current_cumulative,
        });
        previous_points.push(WeeklyStatsPoint {
            slot_index: slot_index as i32,
            day_label: day_labels[slot_index / 24].to_string(),
            count: previous_cumulative,
        });
    }

    let format_range = |start: chrono::NaiveDateTime| {
        let end = start + chrono::Duration::days(6);
        format!("{} - {}", start.format("%b %-d"), end.format("%b %-d"))
    };

    Ok((
        StatusCode::OK,
        Json(WeeklyDrinkStatsResponse {
            generated_at: now.naive_local(),
            current_week: WeeklyStatsSeries {
                title: "This week".to_string(),
                range_label: format_range(current_week_start),
                total: current_week_counts.iter().sum(),
                points: current_points,
            },
            previous_week: WeeklyStatsSeries {
                title: "Last week".to_string(),
                range_label: format_range(previous_week_start),
                total: previous_week_counts.iter().sum(),
                points: previous_points,
            },
        }),
    ))
}

pub fn router() -> Router<ApiContext> {
    Router::new()
        .route("/api/stats/drinks/:from/:to", get(get_drink_stats))
        .route("/api/stats/weekly_drinks", get(get_weekly_drink_stats))
}
