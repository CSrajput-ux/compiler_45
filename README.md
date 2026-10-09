# Compiler 45 — Self-hosted Online Compiler

Compiler 45 packages [Judge0 CE](https://github.com/judge0/judge0) with an initial allowlist for **C, C++, Go, Java, JavaScript, Python 3 and SQL (SQLite)**.

## Self-hosting

Start with [COMPILER_45_DEPLOY.md](COMPILER_45_DEPLOY.md). It explains deployment requirements, the API request shape, secrets, language IDs and the 10,000-RPS capacity target.

The upstream Judge0 GPL-3.0 license and notices are retained. Review the bundled LICENSE before redistribution.

## Important

A compiler API needs a reachable API service, sandboxed execution workers, PostgreSQL and Redis. The repository is not deployed just because it exists on GitHub. Deploy it on a Docker-capable Linux host, place it behind TLS, and keep the API token on your backend rather than in frontend code.

The 10,000 requests/second figure is a load-test target, not a guarantee. Compile/execute throughput depends on hardware, program length, language mix, queue and worker capacity. Measure it against your intended workload before claiming it.
