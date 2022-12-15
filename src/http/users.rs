use axum::http::StatusCode;
use axum::{Json, Router};
use axum::response::IntoResponse;
use axum::routing::{get, post};
use serde::{Serialize, Deserialize};
use uuid::Uuid;

#[derive(Deserialize, Clone)]
pub struct CreateUser {
    first_name: String,
    last_name: String,
    email: Option<String>,
    slack_id: Option<String>,
}

#[derive(Serialize, Clone)]
pub struct UserResponse {
    id: Uuid,
    first_name: String,
    last_name: String,
    email: Option<String>,
    slack_id: Option<String>,
}

static mut USERS: Vec<UserResponse> = vec![];

pub async fn create_user(Json(user): Json<CreateUser>) -> impl IntoResponse {
    let user = UserResponse {
        id: Uuid::new_v4(),
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        slack_id: user.slack_id,
    };

    unsafe { USERS.push(user.clone()) }

    (StatusCode::CREATED, Json(user))
}

pub async fn get_users() -> impl IntoResponse {
    let u = unsafe { &USERS };

    (StatusCode::OK, Json(u))
}

pub fn router<T: Send + Clone + Sync + 'static>() -> Router<T> {
    Router::new()
        .route("/api/users", get(get_users))
        .route("/api/users", post(create_user))
}
