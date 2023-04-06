use crate::db::errors::DbError;
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde::Serialize;
use std::fmt::{Display, Formatter};

#[derive(Debug)]
pub enum ApiError {
    DatabaseError(sqlx::Error),
    NotFound(String),
    BadRequest(String),
    Unauthorized,
    Internal(String),
}

impl Display for ApiError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            ApiError::DatabaseError(e) => write!(f, "DatabaseError: {e}"),
            ApiError::NotFound(e) => write!(f, "NotFound: {e}"),
            ApiError::BadRequest(e) => write!(f, "BadRequest: {e}"),
            ApiError::Unauthorized => write!(f, "Unauthorized"),
            ApiError::Internal(e) => write!(f, "Internal: {e}"),
        }
    }
}

#[derive(Serialize)]
pub struct ErrorResponse {
    message: String,
}

impl ErrorResponse {
    fn new(message: impl Into<String>) -> Json<Self> {
        Json(Self {
            message: message.into(),
        })
    }
}

impl From<DbError> for ApiError {
    fn from(value: DbError) -> Self {
        match value {
            DbError::NotFound(msg) => Self::NotFound(msg),
            DbError::ConstraintUnsatisfied(constraint) => {
                Self::BadRequest(format!("Constraint {constraint} not satisfied"))
            }
            DbError::DatabaseError(e) => Self::DatabaseError(e),
        }
    }
}

impl From<argon2::Error> for ApiError {
    fn from(e: argon2::Error) -> Self {
        ApiError::Internal(e.to_string())
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        match self {
            ApiError::DatabaseError(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                ErrorResponse::new("An unexpected exception has occured"),
            )
                .into_response(),
            ApiError::BadRequest(msg) => {
                (StatusCode::BAD_REQUEST, ErrorResponse::new(msg)).into_response()
            }
            ApiError::NotFound(msg) => {
                (StatusCode::NOT_FOUND, ErrorResponse::new(msg)).into_response()
            }
            ApiError::Unauthorized => (
                StatusCode::UNAUTHORIZED,
                ErrorResponse::new("Unauthorized".to_string()),
            )
                .into_response(),
            ApiError::Internal(msg) => {
                (StatusCode::INTERNAL_SERVER_ERROR, ErrorResponse::new(msg)).into_response()
            }
        }
    }
}
