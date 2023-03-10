FROM rust:latest as build

# create a new empty shell project
RUN USER=root cargo new --bin drinks-accounting
WORKDIR /drinks-accounting

# copy over your manifests
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

# this build step will cache the dependencies
RUN cargo build --release
RUN rm src/*.rs

# copy your source tree
COPY ./migrations ./migrations
COPY ./src ./src
COPY sqlx-data.json sqlx-data.json

# build for release
RUN rm target/release/deps/drinks_accounting*

# sqlx should not check sql queries when building for production
ENV SQLX_OFFLINE true
RUN cargo build --release

# our final base
FROM debian:latest

# copy the build artifact from the build stage
COPY --from=build /drinks-accounting/target/release/drinks-accounting /

# set the startup command to run your binary
CMD ["/drinks-accounting"]
