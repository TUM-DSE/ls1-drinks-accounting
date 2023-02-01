#[derive(sqlx::FromRow)]
pub struct AppConfiguration {
    pub id: String,
    pub value: Option<String>,
}
