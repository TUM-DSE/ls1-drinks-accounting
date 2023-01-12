use crate::db;
use chrono::{DateTime, Utc};
use serde::Serialize;
use uuid::Uuid;

#[derive(Serialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub balance: f64,
    pub has_pin: bool,
}

impl From<db::users::User> for UserResponse {
    fn from(value: db::users::User) -> Self {
        Self {
            id: value.id,
            first_name: value.first_name,
            last_name: value.last_name,
            email: value.email,
            balance: value.balance,
            has_pin: value.pin.is_some(),
        }
    }
}

#[derive(Serialize)]
pub struct Purchase {
    pub icon: String,
    pub name: String,
}

#[derive(Serialize)]
pub enum TransactionType {
    MoneyDeposit,
    Purchase(Purchase),
}

#[derive(Serialize)]
pub struct Transaction {
    pub id: Uuid,
    pub timestamp: DateTime<Utc>,
    pub amount: f64,
    pub transaction_type: TransactionType,
}
