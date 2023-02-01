create
extension if not exists "uuid-ossp";

create table users
(
    id         UUID primary key         not null default uuid_generate_v4(),
    first_name text                     not null,
    last_name  text                     not null,
    email      text                     not null,
    registered timestamp with time zone not null default now(),

    constraint unique_email unique (email)
);

create table drink_prices
(
    id         UUID primary key         not null default uuid_generate_v4(),
    sale_price int                      not null,
    buy_price  int                               default null,
    date       timestamp with time zone not null default now()
);

create table drinks
(
    id     UUID primary key not null default uuid_generate_v4(),
    icon   text             not null default '',
    name   text             not null,
    price  UUID             not null,
    amount int                       default null,

    constraint fk_price foreign key (price) references drink_prices (id)
);

create table deposits
(
    id     UUID primary key         not null default uuid_generate_v4(),
    "user" UUID                     not null,
    date   timestamp with time zone not null default now(),
    amount int                      not null,

    constraint fk_user foreign key ("user") references users (id)
);

create table transactions
(
    id     UUID primary key         not null default uuid_generate_v4(),
    "user" UUID                     not null,
    date   timestamp with time zone not null default now(),
    drink  UUID                     not null,
    price  UUID                     not null,

    constraint fk_drink foreign key (drink) references drinks (id),
    constraint fk_price foreign key (price) references drink_prices (id)
);

create table auth_users
(
    id        UUID primary key not null default uuid_generate_v4(),
    username  text             not null,
    password  text             not null,
    privilege text             not null default 'user',

    constraint unique_username unique (username)
);

create view balances as
select "user", sum(amount)
from (select deposits.user as "user", deposits.amount as amount
      from deposits

      union all
      select transactions.user as "user", 0 - drink_prices.sale_price as amount
      from transactions
               inner join drink_prices on drink_prices.id = transactions.price) as all_transactions
group by "user";
