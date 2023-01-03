use serde::Serialize;
use uuid::Uuid;

#[derive(Serialize)]
pub struct Drink {
    pub id: Uuid,
    pub name: String,
    pub icon: String,
    pub price: f64,
    pub stock: Option<u32>,
}
