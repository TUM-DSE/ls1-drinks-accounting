create table users
(
    id         UUID primary key not null,
    first_name text             not null,
    last_name  text             not null,
    email      text             not null,
);

