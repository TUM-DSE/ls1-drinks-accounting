use std::fmt::{Display, Formatter};

#[derive(Debug)]
pub enum DbError {
    NotFound(String),
    ConstraintUnsatisfied(String),
    DatabaseError(sqlx::Error),
}

impl Display for DbError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            DbError::NotFound(msg) => write!(f, "Not found: {msg}"),
            DbError::DatabaseError(msg) => write!(f, "DbError: {msg}"),
            DbError::ConstraintUnsatisfied(msg) => write!(f, "Constraint unsatisifed: {msg}"),
        }
    }
}

impl From<sqlx::Error> for DbError {
    fn from(e: sqlx::Error) -> Self {
        if let sqlx::Error::Database(e) = &e {
            if let Some(constraint) = e.constraint() {
                return Self::ConstraintUnsatisfied(format!("Constraint {constraint} not satisfied"));
            }
        }

        DbError::DatabaseError(e)
    }
}

impl std::error::Error for DbError {}
