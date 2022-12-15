use crate::config::Config;
use anyhow::Context;
use axum::{Extension, Router};
use sqlx::PgPool;
use std::sync::Arc;
use tower::ServiceBuilder;
use tower_http::trace::TraceLayer;

pub mod errors;
pub mod users;

#[derive(Clone)]
pub struct ApiContext {
    _config: Arc<Config>,
    db: PgPool,
}

pub async fn serve(config: Config, db: PgPool) -> anyhow::Result<()> {
    let app = api_router().layer(
        ServiceBuilder::new()
            .layer(Extension(ApiContext {
                _config: Arc::new(config),
                db,
            }))
            .layer(TraceLayer::new_for_http()),
    );

    axum::Server::bind(&"0.0.0.0:8080".parse()?)
        .serve(app.into_make_service())
        .await
        .context("error running HTTP server")
}

fn api_router<T: Send + Clone + Sync + 'static>() -> Router<T> {
    users::router()
}
