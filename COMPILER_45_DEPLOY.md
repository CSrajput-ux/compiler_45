# Compiler 45 — Judge0 CE deployment

This is the Judge0 CE source with an initial database-seed allowlist for seven requested languages. Judge0 is GPL-3.0; keep the upstream license and notices when redistributing or modifying it.

## Enabled languages

| Language | Judge0 ID | Seed version |
|---|---:|---|
| C | 50 | GCC 9.2.0 |
| C++ | 54 | GCC 9.2.0 |
| Go | 60 | Go 1.13.5 |
| Java | 62 | OpenJDK 13.0.1 |
| JavaScript | 63 | Node.js 12.14.0 |
| Python 3 | 71 | Python 3.8.1 |
| SQL (SQLite) | 82 | SQLite 3.27.2 |

These are upstream seed versions and are old. Test current compatibility, review security advisories, and upgrade toolchains intentionally before production use.

**Note:** the allowlist changes the language table when the database is seeded/initialized. Use a fresh database on first setup. If you already initialized a persistent database, follow the manual migration steps in the upstream Judge0 docs or recreate only the intended disposable database volume after backing up any data.

## Requirements and deployment

Use a Docker-capable Linux VM/server with persistent disk and sufficient CPU and RAM. Render's ordinary free web service alone is not a full Judge0 deployment: the official stack needs the API server, sandbox worker, PostgreSQL and Redis. The Compose stack builds the local source code so the modified language seed is included. It binds the API to localhost by default; publish it only through a TLS reverse proxy/load balancer.

1. Install Docker Engine and the Docker Compose plugin on the Linux server.
2. Clone this repository and enter the directory.
3. Create a private config file:
   ```bash
   cp judge0.conf.example judge0.conf
   ```
4. Replace the three placeholders `AUTHN_TOKEN`, `REDIS_PASSWORD` and `POSTGRES_PASSWORD` in `judge0.conf` with unique long random secrets. Do not commit this file. Keep the API token private on your backend.
5. Set `ALLOW_ORIGIN` to the website hostnames that should be allowed, space-separated and without URL schemes, e.g. `ALLOW_ORIGIN="www.example.com example.com"`. Leave it empty only if you deliberately accept any origin and understand the risk.
6. Start the stack and check service status:
   ```bash
   docker compose up -d --build
   docker compose ps
   docker compose logs --tail=200 server worker
   ```
7. The API is available locally at `http://127.0.0.1:2358`. Set up TLS and an authenticated reverse proxy for your domain before public use. Do not expose PostgreSQL (5432) or Redis (6379) publicly.

Judge0's server and worker containers require elevated sandbox permissions in the upstream Compose setup. Deploy on a dedicated, patched Linux host; do not run untrusted user code in a container/VM that contains production secrets or other sensitive workloads.

## API usage

Keep the API token on your backend, never in frontend JavaScript or a mobile app bundle. Public clients should call your own authenticated backend proxy, which validates users, applies rate limits/quotas, and forwards approved requests to Judge0.

After TLS/reverse proxy setup, a test submission can be sent as follows:

```bash
export COMPILER_API="https://YOUR_API_DOMAIN"
export COMPILER_TOKEN="YOUR_PRIVATE_TOKEN"

curl -sS -X POST \
  "$COMPILER_API/submissions?base64_encoded=false&wait=true" \
  -H "Content-Type: application/json" \
  -H "X-Compiler-Token: $COMPILER_TOKEN" \
  -d '{"language_id":71,"source_code":"print(input())","stdin":"Hello Compiler 45"}'
```

With asynchronous submission, omit `wait=true`, save the returned submission token, then poll `GET /submissions/{token}` with the same authentication header. Use the API docs at `/docs` and confirm the exact result schema for the deployed version.

To check the active language list after database initialization, request `GET /languages` with the private auth header. It should list only the seven IDs above on a freshly initialized database.

## Capacity target: 10,000 requests/second

10,000 HTTP requests/second is a benchmark goal, not a guaranteed capacity of the source code, a free service plan, or a single VM. Also distinguish HTTP requests from **completed code executions**: compile/run workloads consume CPU, memory, process slots, worker capacity, Redis, PostgreSQL and disk I/O. 10,000 submissions accepted per second does not mean 10,000 submissions completed per second.

Before claiming the target:
- define whether the number means lightweight HTTP requests, accepted submissions or completed executions;
- start with low-rate tests and increase gradually using a realistic mix of C/C++ compilation, interpreted languages, stdin and polling;
- measure accepted/completed submissions per second, queue wait, p50/p95/p99 latency, HTTP 429/5xx/timeouts, worker saturation, CPU/RAM, disk, Redis and PostgreSQL;
- scale API replicas separately from execution workers, add a load balancer, HA/persistent data services where required, monitoring, alerts, backpressure, queue caps and per-user quotas;
- keep network access disabled for submitted programs unless there is a well-reviewed requirement to enable it.

Do not direct an uncontrolled 10,000-RPS test at a public endpoint. Run a staged test against infrastructure you control, set a stop condition, and only raise load after confirming the queue and worker fleet can cope. No throughput claim should be made until the workload has been measured.

## Upstream references

- Judge0 CE source: https://github.com/judge0/judge0
- Judge0 API documentation: https://ce.judge0.com
- GPL-3.0 license: see the bundled LICENSE file.
