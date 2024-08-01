#![allow(dead_code)]

#[derive(sqlx::FromRow)]
pub struct AppConfiguration {
    pub id: String,
    pub value: Option<String>,
}
