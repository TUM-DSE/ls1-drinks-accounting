use crate::db::errors::DbError;
use crate::types::users::{Purchase, Transaction, TransactionType};
use anyhow::Result;
use chrono::{DateTime, Utc};
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
        .fetch_one(&mut *tx)
        .await?;

    sqlx::query_scalar!(
        // language=postgresql
        r#"insert into transactions("user", drink, price) values ($1, $2, $3)"#,
        user,
        drink,
        price
    )
    .execute(&mut *tx)
    .await?;

    sqlx::query_scalar!(
        // language=postgresql
        r#"update drinks set amount = amount - 1 where id = $1 and amount is not null"#,
        drink
    )
    .execute(&mut *tx)
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

pub async fn get_transactions(
    db: &PgPool,
    user: Uuid,
    limit: Option<i64>,
    before: Option<DateTime<Utc>>,
    before_id: Option<Uuid>,
) -> Result<Vec<Transaction>, DbError> {
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

    // some arbitrary limit, will remove this later on when we have migrated
    // all apps.
    let limit = limit.unwrap_or(2000);
    let rows = sqlx::query!(
        // language=postgresql
        r#"
        select
            t.id as "id!",
            t.date as "date!",
            (-dp.sale_price) as "amount_cents!",
            d.name as "name?",
            d.icon as "icon?"
        from transactions t
        inner join drinks d on d.id = t.drink
        inner join drink_prices dp on dp.id = t.price
        where t."user" = $1
            and ($2::timestamptz is null or $3::uuid is null or (t.date, t.id) < ($2, $3))
        union all
        select
            d.id as "id!",
            d.date as "date!",
            d.amount as "amount_cents!",
            null::text as "name?",
            null::text as "icon?"
        from deposits d
        where d."user" = $1
            and ($2::timestamptz is null or $3::uuid is null or (d.date, d.id) < ($2, $3))
        order by 2 desc, 1 desc
        limit $4
        "#,
        user,
        before,
        before_id,
        limit
    )
    .fetch_all(db)
    .await?;

    let transactions = rows
        .into_iter()
        .map(|row| {
            let transaction_type = match (row.name, row.icon) {
                (Some(name), Some(icon)) => TransactionType::Purchase(Purchase { icon, name }),
                _ => TransactionType::MoneyDeposit,
            };

            Transaction {
                id: row.id,
                timestamp: row.date,
                amount: (row.amount_cents as f64) / 100.0,
                transaction_type,
            }
        })
        .collect();

    Ok(transactions)
}

pub async fn get_drink_purchase_timestamps_between(
    db: &PgPool,
    from: DateTime<Utc>,
    to: DateTime<Utc>,
) -> Result<Vec<DateTime<Utc>>, DbError> {
    let rows = sqlx::query_scalar(
        // language=postgresql
        r#"
        select t.date
        from transactions t
        where t.date >= $1 and t.date < $2
        order by t.date asc
        "#,
    )
    .bind(from)
    .bind(to)
    .fetch_all(db)
    .await?;

    Ok(rows)
}
