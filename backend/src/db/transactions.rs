use crate::db::errors::DbError;
use crate::types::users::{Purchase, Transaction, TransactionType};
use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;

pub async fn buy_drink(db: &PgPool, user: Uuid, drink: Uuid) -> Result<(), DbError> {
    let mut tx = db.begin().await?;

    let price = sqlx::query!(
        // language=postgresql
        r#"select dp.* from drinks inner join drink_prices dp on dp.id = drinks.price where drinks.id = $1"#,
        drink
    )
        .map(|row| row.id)
        .fetch_one(&mut tx)
        .await?;

    sqlx::query_scalar!(
        // language=postgresql
        r#"insert into transactions("user", drink, price) values ($1, $2, $3)"#,
        user,
        drink,
        price
    )
    .execute(&mut tx)
    .await?;

    sqlx::query_scalar!(
        // language=postgresql
        r#"update drinks set amount = amount - 1 where id = $1 and amount is not null"#,
        drink
    )
    .execute(&mut tx)
    .await?;

    tx.commit().await?;

    Ok(())
}

pub async fn insert_deposit(db: &PgPool, user: Uuid, amount: f64) -> Result<(), DbError> {
    sqlx::query_scalar!(
        // language=postgresql
        r#"insert into deposits("user", amount) values ($1, $2)"#,
        user,
        (amount * 100.0) as i32,
    )
    .execute(db)
    .await?;

    Ok(())
}

pub async fn get_transactions(db: &PgPool, user: Uuid) -> Result<Vec<Transaction>, DbError> {
    let count = sqlx::query_scalar!(
        // language=postgresql
        r#"select count(*) from users where id = $1"#,
        user
    )
    .fetch_one(db)
    .await?;

    let Some(1) = count else {
        return Err(DbError::NotFound("User not found".to_string()));
    };

    let mut deposits = sqlx::query!(
        // language=postgresql
        r#"select * from deposits where "user" = $1"#,
        user
    )
    .map(|row| Transaction {
        id: row.id,
        timestamp: row.date,
        amount: (row.amount as f64) / 100.0,
        transaction_type: TransactionType::MoneyDeposit,
    })
    .fetch_all(db)
    .await?;

    let transactions = sqlx::query!(
        // language=postgresql
        r#"select t.id, t.date, dp.sale_price, d.name, d.icon from transactions t inner join drinks d on d.id = t.drink inner join drink_prices dp on dp.id = t.price where t."user" = $1"#,
        user
    )
    .map(|row| {
       Transaction {
           id: row.id,
           timestamp: row.date,
           amount: (row.sale_price as f64) / -100.0,
           transaction_type: TransactionType::Purchase(Purchase {
               icon: row.icon,
               name: row.name,
           })
       }
    })
    .fetch_all(db)
    .await?;

    deposits.extend(transactions);

    Ok(deposits)
}
