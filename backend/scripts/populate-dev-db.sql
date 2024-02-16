-- insert two users, both with the password 'password'
insert into auth_users (username, privilege, password)
values ('admin', 'admin', '$argon2i$v=19$m=16,t=2,p=1$YjNkRjlKUERRejg4b3lIOA$Vcqg52BZVVxdlqiW7jTKow'),
       ('user', 'user', '$argon2i$v=19$m=16,t=2,p=1$YjNkRjlKUERRejg4b3lIOA$Vcqg52BZVVxdlqiW7jTKow');

INSERT INTO public.drink_prices (id, sale_price, buy_price, date)
VALUES ('0e7bedec-545f-41d8-a66f-cc919f5f31cc', 50, null, '2023-12-08 08:55:02.020382 +00:00');


INSERT INTO public.drinks (icon, name, price, amount)
VALUES ('☕️', 'Kaffee', '0e7bedec-545f-41d8-a66f-cc919f5f31cc', null);

INSERT INTO public.users (first_name, last_name, email, registered, pin, deleted)
VALUES ('Wilma', 'Bier', 'wilma@bier.com', '2023-12-08 08:54:33.535972 +00:00', null, false),
       ('Paul', 'Aner', 'aner.paul@gmail.com', '2023-12-08 08:54:33.535972 +00:00', null, false);
