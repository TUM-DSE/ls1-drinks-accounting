use crate::config::Config;
use anyhow::Context;
use axum::Router;
use sqlx::PgPool;
use std::sync::Arc;
use tower::ServiceBuilder;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;

pub mod app_configuration;
pub mod auth;
pub mod drinks;
pub mod errors;
pub mod extractors;
pub mod health;
pub mod stats;
pub mod transactions;
pub mod users;

#[derive(Clone)]
pub struct ApiContext {
    config: Arc<Config>,
    db: PgPool,
}

pub async fn serve(config: Config, db: PgPool) -> anyhow::Result<()> {
    let app = api_router()
        .with_state(ApiContext {
            config: Arc::new(config),
            db,
        })
        .layer(CorsLayer::permissive())
        .layer(ServiceBuilder::new().layer(TraceLayer::new_for_http()));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await?;
    axum::serve(listener, app.into_make_service())
        .await
        .context("error running HTTP server")
}

fn api_router() -> Router<ApiContext> {
    users::router()
        .merge(drinks::router())
        .merge(transactions::router())
        .merge(auth::router())
        .merge(app_configuration::router())
        .merge(health::router())
        .merge(stats::router())
}
