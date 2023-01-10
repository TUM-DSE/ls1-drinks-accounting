use chrono::{DateTime, Utc};
use serde::Serialize;
use uuid::Uuid;

#[derive(Serialize)]
pub struct User {
    pub id: Uuid,
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub balance: f64,
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
