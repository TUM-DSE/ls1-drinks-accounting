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
