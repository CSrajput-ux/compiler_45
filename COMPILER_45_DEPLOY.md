# Compiler 45 — Judge0 CE deployment

This repository contains the upstream Judge0 CE source plus a seed allowlist for seven languages. Judge0 is GPL-3.0; retain the upstream LICENSE and notices when redistributing or modifying it.

## Languages enabled by the seed allowlist

| Language | Judge0 language ID | Seed version |
|---|---:|---|
| C | 50 | GCC 9.2.0 |
| C++ | 54 | GCC 9.2.0 |
| Go | 60 | Go 1.13.5 |
| Java | 62 | OpenJDK 13.0.1 |
| JavaScript | 63 | Node.js 12.14.0 |
| Python 3 | 71 | Python 3.8.1 |
| SQL | 82 | SQLite 3.27.2 |

These are the versions registered by the upstream language seed data; verify and upgrade toolchains deliberately rather than assuming they are current.

## Deploy on your own Linux VM/server

Use a Docker-capable Linux host with enough CPU/RAM and persistent disk. A free web-service container alone is not sufficient: the official Compose stack requires the API server, sandboxed worker, PostgreSQL and Redis. Keep PostgreSQL/Redis private; publish only the API through a TLS reverse proxy/firewall.

1. Install Docker Engine and the Docker Compose plugin.
2. Clone this repository and enter its directory.
3. Create your private config: COPY judge0.conf.example TO judge0.conf.
4. Replace AUTHN_TOKEN, REDIS_PASSWORD, and POSTGRES_PASSWORD with unique long random secrets. Do not commit judge0.conf, paste secrets in issues, or expose them in frontend JavaScript.
5. Set ALLOW_ORIGIN for your actual website/domain using the format documented in judge0.conf; leave it restrictive in production.
6. Start the stack with docker compose up -d.
7. Check docker compose ps and docker compose logs --tail=200 server worker.
8. Put a TLS reverse proxy/load balancer in front of port 2358 before exposing the API publicly.

The upstream Compose file runs the API on port 2358. Do not expose PostgreSQL (5432) or Redis (6379) to the public internet.

## API example

Keep the API token on your backend. Do not embed it in a browser app or public mobile bundle. A browser frontend should call your own authenticated backend proxy, which applies user quotas/rate limits and then forwards allowed requests to Judge0.

Example request:

curl -X POST "https://YOUR_API_DOMAIN/submissions?base64_encoded=false&wait=true" -H "Content-Type: application/json" -H "X-Compiler-Token: YOUR_PRIVATE_TOKEN" -d '{"language_id":71,"source_code":"print(input())","stdin":"Hello Compiler 45"}'

For asynchronous execution, omit wait=true, receive the submission token, then poll GET /submissions/{token} with the same authentication header. Check the exact response and route details in the bundled upstream API docs at /docs.

## Throughput and 10,000 requests/second

10,000 HTTP requests/second is a benchmark target, not a guarantee from this repository or from a single VM. 10,000 code executions/second is a dramatically larger compute requirement than 10,000 lightweight HTTP requests. Compile/run submissions consume CPU, memory, process slots, database I/O and worker capacity.

Before claiming this capacity:
- define whether the target means HTTP requests or completed code executions;
- run staged load tests with a realistic language mix and safe short/long programs;
- measure accepted submissions/sec, completed submissions/sec, queue latency, p95/p99 response time, CPU, memory, Redis, PostgreSQL and error rates;
- scale API replicas separately from worker capacity; use managed/HA Redis and PostgreSQL where appropriate, a load balancer, TLS, per-user rate limits, queue limits, alerts and autoscaling;
- retain Judge0's sandboxing and keep user code network access disabled unless explicitly needed.

Do not send an unlimited burst to a public endpoint without quotas. Increase worker count/queue size only after measuring resource use and verifying that the host can sustain it.
