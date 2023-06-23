use crate::db;
use crate::db::users::User;
use crate::types::users::{Transaction, TransactionType};
use anyhow::{anyhow, Context, Result};
use cronjob::CronJob;
use lettre::message::header::ContentType;
use lettre::transport::smtp::authentication::Credentials;
use lettre::{Message, SmtpTransport, Transport};
use log::{error, info};
use sqlx::PgPool;

#[derive(Debug, Clone)]
pub struct SmtpConfig {
    pub from: String,
    pub user: String,
    pub password: String,
    pub host: String,
}

pub fn setup_cron(config: SmtpConfig, pool: PgPool) {
    let mut cron = CronJob::new("", move |_: &str| {
        let config = config.clone();
        let pool = pool.clone();
        tokio::spawn(async move {
            process_users(&config, &pool)
                .await
                .context("Failed to send emails to users")
                .unwrap();
        });
    });
    cron.day_of_month("1");
    cron.seconds("0");
    cron.hours("0");
    cron.minutes("0");
    cron.start_job();
}

async fn process_users(config: &SmtpConfig, pool: &PgPool) -> Result<()> {
    info!("Sending mail to all users with negative balance.");
    let users = db::users::get_all_with_negative_balance(pool)
        .await
        .map_err(|e| anyhow!("Failed to get users: {e}"))?;

    info!("Found {} users with negative balance.", users.len());

    for user in &users {
        if let Err(e) = process_user(pool, config, user).await {
            error!("{}", e);
        }
    }

    if !users.is_empty() {
        info!("Successfully sent emails to all users.");
    }

    Ok(())
}

async fn process_user(pool: &PgPool, config: &SmtpConfig, user: &User) -> Result<()> {
    let mut transactions = db::transactions::get_transactions(pool, user.id)
        .await
        .map_err(|e| anyhow!("Failed to get users: {e}"))?;
    transactions.sort_by_key(|t| t.timestamp);
    transactions.reverse();

    eprintln!("{} transactions", transactions.len());

    send_balance_email(config, user, &transactions).context(format!(
        "Could not send balance email to user {} {} <{}>",
        user.first_name, user.last_name, user.email
    ))?;

    Ok(())
}

fn send_balance_email(
    config: &SmtpConfig,
    user: &User,
    transactions: &[Transaction],
) -> Result<()> {
    let formatted_transactions = transactions
        .iter()
        .map(|t| {
            let transaction_type = match &t.transaction_type {
                TransactionType::MoneyDeposit => "💶 Deposit".to_string(),
                TransactionType::Purchase(purchase) => {
                    format!("{} {}", purchase.icon, purchase.name)
                }
            };
            format!(
                // language=html
                r#"<tr><td>{}</td><td style="text-align: right !important;">{: >7.2} €</td><td>{transaction_type}</td></tr>"#,
                t.timestamp.format("%d.%m.%Y %T"),
                t.amount
            )
        })
        .collect::<Vec<_>>()
        .join("\n");

    let email = Message::builder()
        .from(
            config
                .from
                .parse()
                .context("Invalid sender email address")?,
        )
        .to(user
            .email
            .parse()
            .context("Invalid email address for user")?)
        .subject("LS1 Coffee Balance")
        .header(ContentType::TEXT_HTML)
        .body(format!(
            // language=html
            r#"
<head>
<style>
table {{
  font-family: arial, sans-serif;
  border-collapse: collapse;
}}

td, th {{
  border: 1px solid #000000;
  text-align: left;
  padding: 4px;
}}
</style>
</head>
<body>
<p>Hi {},</p>

<p>your balance has fallen to <b>{:.2} €</b>. Please come by Sophia's Office to top up your account.
Find a list of your transactions below:</p>

<table>
<tr>
<th>Date</th>
<th>Amount</th>
<th>Transaction</th>
</tr>
{}
</table>
</body>
"#,
            user.first_name, user.balance, formatted_transactions
        ))
        .context("Unable to construct message")?;

    let creds = Credentials::new(config.user.clone(), config.password.clone());

    let mailer = SmtpTransport::relay(&config.host)
        .context("Unable to connect to smtp host")?
        .credentials(creds)
        .build();

    mailer.send(&email).context("Could not send email")?;

    info!("Successfully sent email to {}", user.email);

    Ok(())
}
