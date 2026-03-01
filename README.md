# AI DevOps Platform - Phase 1

## Run in 1 command
```
docker compose up --build
```

## Test
```
curl http://localhost/api/users
curl http://localhost/api/products
curl http://localhost/api/orders
```

## Services
| Service | Port |
|---|---|
| API Gateway | http://localhost:80 |
| User Service | http://localhost:5000 |
| Product Service | http://localhost:5001 |
| Order Service | http://localhost:5002 |

## Stop
```
docker compose down
```
