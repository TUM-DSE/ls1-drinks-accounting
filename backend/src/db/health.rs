use crate::http::errors::ApiError;
use sqlx::PgPool;

pub async fn get_all(db: &PgPool) -> Result<bool, ApiError> {
    let result = sqlx::query_scalar!(
        // language=postgresql
        r#"select true"#
    )
    .fetch_one(db)
    .await?
    .unwrap_or(false);

    Ok(result)
}
