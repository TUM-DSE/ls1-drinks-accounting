create table drink_restocks
(
    id uuid primary key not null default uuid_generate_v4(),
    date timestamp with time zone not null default now(),
    drink uuid not null,
    amount int not null,

    constraint fk_drink foreign key (drink) references drinks (id)
);
