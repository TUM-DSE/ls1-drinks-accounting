use chrono::{NaiveDate, NaiveDateTime};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Serialize)]
pub struct StatsDataPoint {
    pub(crate) date: NaiveDate,
    pub(crate) count: i32,
}

#[derive(Serialize)]
pub struct DrinkStats {
    pub id: Uuid,
    pub name: String,
    pub data: Vec<StatsDataPoint>,
}

#[derive(Serialize)]
pub struct DrinkStatsResponse {
    pub from: NaiveDate,
    pub to: NaiveDate,
    pub drinks: Vec<DrinkStats>,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct WeeklyStatsPoint {
    pub slot_index: i32,
    pub day_label: String,
    pub count: i32,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct WeeklyStatsSeries {
    pub title: String,
    pub range_label: String,
    pub total: i32,
    pub points: Vec<WeeklyStatsPoint>,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct WeeklyDrinkStatsResponse {
    pub generated_at: NaiveDateTime,
    pub current_week: WeeklyStatsSeries,
    pub previous_week: WeeklyStatsSeries,
}
