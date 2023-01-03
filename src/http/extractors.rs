use crate::db;
use crate::http::errors::ApiError;
use axum::async_trait;
use axum::extract::FromRequestParts;
use axum::http::request::Parts;

use crate::http::ApiContext;
use crate::types::auth::{AdminUser, AuthUser, AuthUserData};
use crate::utils::jwt;

async fn extract_auth_user_data(
    parts: &mut Parts,
    state: &ApiContext,
) -> Result<AuthUserData, ApiError> {
    let auth_header = parts
        .headers
        .get("Authorization")
        .and_then(|header| header.to_str().ok())
        .ok_or(ApiError::Unauthorized)
        .map(|header| header.strip_prefix("Bearer ").unwrap_or(header))?;

    let claims = jwt::verify(auth_header, state.config.jwt_secret.as_bytes())
        .map_err(|_| ApiError::Unauthorized)?;

    let user = db::auth::get_user_by_id(&state.db, claims.sub)
        .await
        .map_err(|_| ApiError::Unauthorized)?;

    Ok(user)
}

#[async_trait]
impl FromRequestParts<ApiContext> for AuthUser {
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &ApiContext,
    ) -> Result<Self, Self::Rejection> {
        let user = extract_auth_user_data(parts, state).await?;

        Ok(AuthUser {
            id: user.id,
            username: user.username,
        })
    }
}

#[async_trait]
impl FromRequestParts<ApiContext> for AdminUser {
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &ApiContext,
    ) -> Result<Self, Self::Rejection> {
        let user = extract_auth_user_data(parts, state).await?;

        if user.privilege != "admin" {
            return Err(ApiError::Unauthorized);
        }

        Ok(AdminUser {
            id: user.id,
            username: user.username,
        })
    }
}
