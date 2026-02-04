create index if not exists idx_transactions_user_date
    on transactions ("user", date desc, id desc);

create index if not exists idx_deposits_user_date
    on deposits ("user", date desc, id desc);
