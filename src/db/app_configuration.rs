use crate::http::errors::ApiError;
use crate::types::app_configuration::AppConfiguration;
use anyhow::Result;
use sqlx::PgPool;

pub async fn get_app_version(db: &PgPool) -> Result<Option<AppConfiguration>, ApiError> {
    let price_id = sqlx::query!(
        // language=postgresql
        r#"select * from app_configuration where id = 'app_version'"#,
    )
    .map(|row| AppConfiguration {
        id: row.id,
        value: row.value,
    })
    .fetch_optional(db)
    .await?;

    Ok(price_id)
}
