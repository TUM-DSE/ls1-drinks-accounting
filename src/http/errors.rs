use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde::Serialize;

pub enum ApiError {
    DatabaseError(sqlx::Error),
    BadRequest(String),
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

impl From<sqlx::Error> for ApiError {
    fn from(e: sqlx::Error) -> Self {
        if let sqlx::Error::Database(e) = &e {
            if let Some(constraint) = e.constraint() {
                return ApiError::BadRequest(format!("Constraint {constraint} not satisfied"));
            }
        }

        ApiError::DatabaseError(e)
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
        }
    }
}
