mod config;
mod db;
mod http;
mod mail;
mod types;
mod utils;

use anyhow::Context;
use clap::Parser;
use config::Config;
use sqlx::postgres::PgPoolOptions;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenv::dotenv().ok();

    env_logger::init();

    let config = Config::parse();

    let db = PgPoolOptions::new()
        .max_connections(50)
        .connect(&config.database_url)
        .await
        .context("not connect to database_url")?;

    sqlx::migrate!().run(&db).await?;

    if config.enable_email {
        mail::setup_cron(
            mail::SmtpConfig {
                from: config
                    .mail_sender
                    .clone()
                    .context("Config option 'MAIL_SENDER' is missing")?,
                user: config
                    .smtp_user
                    .clone()
                    .context("Config option 'SMTP_USER' is missing")?,
                password: config
                    .smtp_password
                    .clone()
                    .context("Config option 'SMTP_PASSWORD' is missing")?,
                host: config
                    .smtp_host
                    .clone()
                    .context("Config option 'SMTP_HOST' is missing")?,
            },
            db.clone(),
        );
    }

    http::serve(config, db).await?;

    Ok(())
}
