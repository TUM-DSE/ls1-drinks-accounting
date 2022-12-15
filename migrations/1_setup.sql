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

create table drinks
(
    id     UUID primary key not null default uuid_generate_v4(),
    icon   text             not null default '',
    name   text             not null,
    price  int              not null,
    hidden boolean          not null default false
);

create table deposits
(
    id     UUID primary key not null default uuid_generate_v4(),
    "user" UUID             not null,
    date   timestamp        not null default now(),
    amount int              not null,

    constraint fk_user foreign key ("user") references users (id)
);

create table transactions
(
    id     UUID primary key not null default uuid_generate_v4(),
    "user" UUID             not null,
    date   timestamp        not null default now(),
    drink  UUID             not null,

    constraint fk_drink foreign key (drink) references drinks (id)
);

create view balances as
select "user", sum(amount)
from (select deposits.user as "user", deposits.amount as amount
      from deposits

      union all
      select transactions.user as "user", 0 - drinks.price as amount
      from transactions
               inner join drinks on drinks.id = transactions.drink) as all_transactions
group by "user";
