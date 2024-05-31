use crate::config::Config;
use anyhow::Context;
use axum::Router;
use log::info;
use sqlx::PgPool;
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::signal;
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
    let socket_addr: SocketAddr = format!("{}:{}", config.address, config.port)
        .as_str()
        .parse()?;

    let app = api_router()
        .with_state(ApiContext {
            config: Arc::new(config),
            db,
        })
        .layer(CorsLayer::permissive())
        .layer(ServiceBuilder::new().layer(TraceLayer::new_for_http()));

    info!("Listening on {}", socket_addr);
    let listener = tokio::net::TcpListener::bind(socket_addr).await?;

    axum::serve(listener, app.into_make_service())
        .with_graceful_shutdown(shutdown_signal())
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

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("failed to install signal handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }
}
