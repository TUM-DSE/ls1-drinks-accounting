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
    config: Arc<Config>,
    db: PgPool,
}

pub async fn serve(config: Config, db: PgPool) -> anyhow::Result<()> {
    let app = api_router()
        .layer(
            ServiceBuilder::new()
                .layer(Extension(ApiContext {
                    config: Arc::new(config),
                    db,
                }))
                // .add_extension(ApiContext {
                //     config: Arc::new(config),
                //     db,
                // })
                // The other reason for using a single object is because `AddExtensionLayer::new()` is
                // rather verbose compared to Actix-web's `Data::new()`.
                //
                // It seems very logically named, but that makes it a bit annoying to type over and over.
                // .layer(AddExtensionLayer::new())
                .layer(TraceLayer::new_for_http()),
        )
        // .with_state(Arc::new(ApiContext {
        //     config: Arc::new(config),
        //     db,
        // }));
        ;

    axum::Server::bind(&"0.0.0.0:8080".parse()?)
        .serve(app.into_make_service())
        .await
        .context("error running HTTP server")
}

fn api_router<T: Send + Clone + Sync + 'static>() -> Router<T> {
    users::router()
    // .merge(users::router())
}
