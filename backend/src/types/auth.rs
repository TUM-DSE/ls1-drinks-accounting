use std::fmt::Display;
use uuid::Uuid;

#[derive(Clone)]
pub struct AdminUser {
    pub id: Uuid,
    pub username: String,
}

#[derive(Clone)]
pub struct AuthUser {
    pub id: Uuid,
    pub username: String,
}

#[derive(Clone, sqlx::FromRow)]
pub struct AuthUserData {
    pub id: Uuid,
    pub privilege: String,
    pub username: String,
    pub password: String,
}

#[allow(dead_code)]
pub enum Role {
    Admin,
    User,
}

impl Display for Role {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Role::Admin => write!(f, "admin"),
            Role::User => write!(f, "user"),
        }
    }
}
