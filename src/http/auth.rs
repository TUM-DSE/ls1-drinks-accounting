use crate::db;
use crate::http::errors::ApiError;
use crate::http::ApiContext;
use crate::types::auth::{AdminUser, Role};
use crate::utils::jwt;
use axum::extract::State;
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::post;
use axum::{Json, Router};
use rand::Rng;
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct LoginRequest {
    username: String,
    password: String,
}

#[derive(Serialize)]
pub struct TokenPayload {
    pub access_token: String,
    pub token_type: String,
}

pub async fn login(
    State(state): State<ApiContext>,
    Json(body): Json<LoginRequest>,
) -> Result<impl IntoResponse, ApiError> {
    let user = db::auth::get_user_by_username(&state.db, &body.username)
        .await
        .map_err(|_| ApiError::Unauthorized)?;

    let password = user.password;

    if !argon2::verify_encoded(&password, body.password.as_bytes())
        .map_err(|_| ApiError::Unauthorized)?
    {
        return Err(ApiError::Unauthorized);
    }

    let token = jwt::sign(user.id, state.config.jwt_secret.as_bytes())
        .map_err(|_| ApiError::Unauthorized)?;

    return Ok((
        StatusCode::OK,
        Json(TokenPayload {
            access_token: token,
            token_type: "BEARER".to_string(),
        }),
    ));
}

#[axum_macros::debug_handler]
pub async fn create_user(
    _user: AdminUser,
    State(state): State<ApiContext>,
    Json(body): Json<LoginRequest>,
) -> Result<impl IntoResponse, ApiError> {
    let salt: [u8; 32] = rand::thread_rng().gen();
    let config = argon2::Config::default();
    let hashed_password = argon2::hash_encoded(body.password.as_bytes(), &salt, &config)?;

    let _uuid = db::auth::create_user(&state.db, body.username, hashed_password, Role::User);

    return Ok((
        StatusCode::OK,
        Json("Success"),
    ));
}

pub fn router() -> Router<ApiContext> {
    Router::new()
        .route("/api/auth/login", post(login))
        .route("/api/auth/users", post(create_user))
}
