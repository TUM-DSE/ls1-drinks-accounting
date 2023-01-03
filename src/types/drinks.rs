use serde::Serialize;
use uuid::Uuid;

#[derive(Serialize)]
pub struct Drink {
    pub id: Uuid,
    pub name: String,
    pub icon: String,
    pub price: f64,
    pub stock: Option<i32>,
}

#[derive(Serialize)]
pub struct FullDrink {
    pub id: Uuid,
    pub name: String,
    pub icon: String,
    pub sale_price: f64,
    pub buy_price: Option<f64>,
    pub stock: Option<i32>,
}
