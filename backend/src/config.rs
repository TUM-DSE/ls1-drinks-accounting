use clap::Parser;

#[derive(Parser, Debug)]
pub struct Config {
    /// The connection URL for the Postgres database this application should use.
    #[clap(long, env)]
    pub database_url: String,

    /// The HMAC signing and verification key used for login tokens (JWTs).
    ///
    /// There is no required structure or format to this key as it's just fed into a hash function.
    /// In practice, it should be a long, random string that would be infeasible to brute-force.
    #[clap(long, env)]
    pub jwt_secret: String,

    /// Enable email notifications if users have negative balance
    #[clap(long, env, default_value_t = false)]
    pub enable_email: bool,

    /// Sender address which is used in the "From" field
    /// Can be an email address only, or in the format "Name <email address>" (without quotes)
    #[clap(env)]
    pub mail_sender: Option<String>,

    /// The smtp username from which emails are sent
    #[clap(env)]
    pub smtp_user: Option<String>,

    /// The smtp password for the user specified in smtp_user
    #[clap(env)]
    pub smtp_password: Option<String>,

    /// Host from which the emails are sent
    #[clap(env)]
    pub smtp_host: Option<String>,
}
