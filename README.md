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
## Phase 6 - Monitoring

Prometheus and Grafana installed via Helm.

Start monitoring stack:
```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```
Open http://localhost:3000 — login with admin credentials.

Available dashboards:
- Kubernetes Cluster resources
- Pod CPU and memory usage  
- Alertmanager overview