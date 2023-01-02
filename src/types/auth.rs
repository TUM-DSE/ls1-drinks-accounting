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

impl ToString for Role {
    fn to_string(&self) -> String {
        match self {
            Role::Admin => "admin",
            Role::User => "user",
        }
        .into()
    }
}
