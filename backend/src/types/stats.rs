use chrono::NaiveDate;
use serde::Serialize;
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
