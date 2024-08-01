# Coffee App for LS1

This monorepo hosts the code for the [coffee app](./ios), [backend](./backend), and [admin dashboard](./dashboard).

See the READMEs in the respective subdirectories for more information.

## Deployment

The backend, database, and admin dashboard are hosted in a VM provided by the chair admins.

## Contributing

To get a development instance up and running, you need Docker, Rust, npm (for the dashboard), and Xcode (for the app).

To start the backend, run:

```sh
cd backend
docker compose -f postgres-dev.yaml up -d
cargo run
```

To populate the database with some values (e.g. users, drinks, etc.), run the following.
This needs to be done **after** the backend has been run for the first time, as that takes care of running all migrations.
Alternatively, you can also run `cargo sqlx migrate run`.

```sh
./scripts/populate-dev-db.sh
```

To start the dashboard, run

```sh
cd dashboard
npm i
npm run dev
```

To run the ios app, open `ios/LS1DrinksAccounting.xcodeproj` in Xcode. If you're running the app on a real device, you need to update
`ios/LS1DrinksAccounting/Config/debug.xcconfig` to point at your machine.

You can then use the following credentials to log into the admin dashboard/ios app:


| Username |  Password  |  Purpose  |
| -------- | ---------- | --------- |
| `admin`  | `password` | Dashboard |
|  `user`  | `password` |  iOS App  |

## Deployment

We currently use a compose file similar to the following one.
Replace `$jwt_secret` and `postgres_password` with your own values.

### Docker Compose

```yaml
version: "3"

services:
  api:
    image: "mfink99/ls1-drinks-accounting:1.1.7"
    restart: on-failure
    ports:
      - "127.0.0.1:8001:8080"
    environment:
      - JWT_SECRET=$jwt_secret
      - DATABASE_URL=postgresql://drinks-api:$postgres_password@db/drinks-accounting
  dashboard:
    image: mfink99/ls1-drinks-accounting-dashboard
    restart: on-failure
    ports:
      - "127.0.0.1:8002:80"
  db:
    image: "postgres:14-alpine"
    volumes:
      - ./db-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=drinks-accounting
      - POSTGRES_USER=drinks-api
      - POSTGRES_PASSWORD=$postgres_password
    ports:
      - "127.0.0.1:5432:5432"
```

### Reverse Proxy

Replace `$domain` wit6h your own value.
```
server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;
	server_name $domain;

	ssl_certificate /etc/nginx/tls/fullchain.pem;  # cert + parent CAs except root CA
	ssl_certificate_key /etc/nginx/tls/key.pem;    # secret key
	ssl_session_timeout 1d;
	ssl_session_cache shared:SSL:50m;
	ssl_session_tickets off;

	# intermediate configuration
	ssl_protocols TLSv1.2 TLSv1.3;
	ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
	#ssl_prefer_server_ciphers off;

	# HSTS (ngx_http_headers_module is required) (63072000 seconds)
	add_header Strict-Transport-Security "max-age=63072000" always;

	# verify chain of trust of OCSP response using Root CA and Intermediate certs
	ssl_trusted_certificate /etc/nginx/tls/trusted.pem;

	add_header X-XSS-Protection "1; mode=block";
	add_header X-Content-Type-Options nosniff;

	access_log /var/log/nginx/coffee-tracker_access.log;
	error_log /var/log/nginx/coffee-tracker_error.log;

	gzip on;
	gzip_disable "msie6";

	gzip_vary on;
	gzip_proxied any;
	gzip_comp_level 6;
	gzip_buffers 16 8k;
	gzip_http_version 1.1;
	gzip_min_length 256;
	gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;

	location /api {
		client_max_body_size 100M;
		resolver 127.0.0.11 valid=5s;
		set $upstream_endpoint http://127.0.0.1:8001;

		proxy_pass $upstream_endpoint;
		proxy_http_version 1.1;

		proxy_set_header X-Real-Ip $remote_addr;
	}

	location / {
		client_max_body_size 100M;
		resolver 127.0.0.11 valid=5s;
		set $upstream_endpoint http://127.0.0.1:8002;

		proxy_pass $upstream_endpoint;
		proxy_http_version 1.1;

		proxy_set_header X-Real-Ip $remote_addr;
	}
}
```

### Links

- Dashboard: [https://ls1-coffee.dse.cit.tum.de](https://ls1-coffee.dse.cit.tum.de)
- Link to download the app: [https://ls1-coffee.dse.cit.tum.de/app/index.html](https://ls1-coffee.dse.cit.tum.de/app/index.html)

