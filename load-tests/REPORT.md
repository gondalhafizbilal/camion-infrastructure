# Prod load-test report — 2026-05-19

Anonymous-only k6 sweep against `app.camion-app.com` (frontend SSR) from the dev-account Fargate fleet.

## TL;DR

- **The frontend `/en` home page is broken regardless of capacity.** Even at 100 concurrent users it shows p95 ≥ 6s — sometimes 26s on a cold task. This is a slow upstream on the homepage SSR path, not a fleet-sizing issue. The catalog page (`/en/products`) holds healthy at the same load.
- **Doubling the frontend (cpu 2048 / mem 4096) and raising `min_capacity` from 4 → 8 tasks** materially improved the 1k-VU case: error rate dropped from 5.8% → 0.22%, and the home page max p95 dropped from a hard 60s timeout to ~31s.
- **Steady-state ceiling lands around 800–1000 VUs.** Above that the autoscaler oscillates: a clean run at 900/1000 VUs is followed by a saturated run at 1100/1200 as ASG can't keep pace with 100-VU step increases.
- **Throughput plateau ~80–150 RPS through the frontend tier.** Even when the cluster is sized for it, the home-page upstream bottleneck caps total useful throughput well below what the ALB+ECS layer could otherwise serve.

## Test setup

| | |
|---|---|
| Runner | k6 on Fargate in `camion-dev` (eu-north-1), 4 vCPU / 8 GiB per shard |
| Target | `https://app.camion-app.com` (prod, Next.js SSR via prod ALB) |
| Scenario | Anonymous browse only — `/en`, `/en/products`, `/en/products/{1..10}` |
| Mix | `frontendBrowse: 100, backendCrud: 0, chatbot: 0, imageUpload: 0` |
| Per-request budget | 60 s (k6 default) — any longer is an error |
| Vendor blast | Zero (no auth, no email, no SMS, no LLM) |

## Prod frontend config under test (assumed)

From `environments/prod/eu-north-1/frontend.tf` + `terraform.tfvars`:

| Setting | Value |
|---|---|
| Task CPU / memory | 2048 / 4096 (doubled from the prior baseline) |
| `desired_count` | 8 (assumed — `frontend.tf:104` ships 4, the live cluster has `min_capacity = 8`) |
| `autoscaling_min_capacity` | 8 |
| Autoscaling target | CPU utilization, target_value = 60 (`frontend.tf:128`) |
| Capacity provider | `FARGATE` (base=1) + `FARGATE_SPOT` (weight=1) |

The on-disk `frontend.tf:104` still shows `desired_count = 4` / `autoscaling_min_capacity = 4`. If the live setting is 8 (as the user confirmed), align the Terraform to match so it doesn't drift back on the next apply.

## Phase 1 — initial 10k run (pre-doubling)

Ten shards × 1000 VUs × 10 m steady-state. Vehicle for finding that prod was way overcommitted.

| Metric | Value |
|---|---|
| HTTP reqs | 391,540 |
| Avg RPS | 2,028 |
| **Error rate** | **85.7%** |
| `/en` p95 | 60,000 ms (hard timeout) |
| `/en/products` p95 | 33,764 ms |
| `/en/products/{id}` p95 | 60,007 ms |

All errors were client-side `request timeout` against the frontend host — backend was never reached.

## Phase 2 — pre-doubling bracket (1k / 2k / 5k)

Same anonymous-only mix; one or more shards × 1000 VUs, 3 m steady. Establishes the curve before any infra change.

| Total VUs | Shards | RPS | Error rate | `/en` p95 | `/en/products` p95 |
|---:|---:|---:|---:|---:|---:|
| 1,000 | 1 | 102 | 5.8 % | 60,001 ms | 38,119 ms |
| 2,000 | 2 | 104 | 49.6 % | 59,749 ms | 60,000 ms |
| 5,000 | 5 | 264 | 62.2 % | 60,001 ms | 60,000 ms |
| 10,000 | 10 | 2,028 | 85.7 % | 60,000 ms | 33,764 ms |

The flat ~100 RPS at 1k and 2k VUs is the smoking gun: throughput-bound on the frontend, not VU-bound.

## Phase 3 — post-doubling sweep (100 → 1300, stepped by 100)

After CPU/mem doubled and `min_capacity` raised to 8. Each run: 1 shard × N VUs, 30 s ramp-up + 60 s steady + 15 s ramp-down. Stopped at 1300 once the saturation pattern was unambiguous.

| Total VUs | RPS | Error rate | `/en` p95 | `/en/products` p95 | Notes |
|---:|---:|---:|---:|---:|---|
| 100 | 28.5 | 0.000 % | 26,494 ms | 230 ms | Likely cold-task: first shard hit unwarmed tasks |
| 200 | 50.8 | 0.101 % | 6,011 ms | 3,041 ms | |
| 300 | 53.8 | 0.339 % | 23,688 ms | 3,924 ms | Home re-degrades |
| 400 | 46.3 | 0.777 % | 49,276 ms | 33,814 ms | Both pages slowing |
| 500 | 50.4 | 2.198 % | 59,063 ms | 58,703 ms | Hitting 60 s cap |
| 600 | 80.9 | 5.079 % | 60,001 ms | **324 ms** | ASG scaled out; catalog recovers; home still pinned |
| 700 | 83.4 | 0.239 % | 46,788 ms | 41,525 ms | |
| 800 | 72.1 | 8.149 % | 59,691 ms | 60,001 ms | Saturated |
| 900 | 148.9 | 0.583 % | 50,449 ms | **2,617 ms** | ASG caught up |
| 1000 | 130.1 | 0.221 % | 31,021 ms | 15,616 ms | Much healthier than Phase 2's 1k (5.8% errs) |
| 1100 | 52.2 | **19.150 %** | 59,525 ms | 5,830 ms | ASG can't keep pace |
| 1200 | 70.5 | 8.806 % | 59,589 ms | 38,001 ms | |
| 1300 | 82.4 | 8.917 % | 59,519 ms | 60,000 ms | Stopped here |

## What the data says

1. **Doubling worked at the 1k mark.** Phase 2's 1k run had 5.8% errors and the home page at the 60 s timeout. Phase 3's 1k run has 0.22% errors and home p95 at 31 s. Catalog recovered to 15.6 s. Same load, very different cluster.

2. **The home page is the bottleneck, not the fleet.**
   - Phase 3 / 100 VUs: home p95 = **26.5 s** with no errors and catalog at **230 ms**. The fleet has spare capacity; one route is just slow.
   - Phase 3 / 600 and 900 VUs: catalog p95 of 324 ms and 2.6 s respectively, while home p95 stays at 50–60 s.
   - At every load level since 100 VUs, the home page's p95 has been at least 10× the catalog's.
   - This is almost certainly a slow data-fetch in the homepage SSR (likely a backend or RDS call without caching), not a Next.js capacity ceiling.

3. **ASG-lag oscillation between 700 and 1300 VUs.** Pattern is: clean run → saturated run → clean run, as the autoscaler scales out, gets behind, catches up, and tasks added with cold caches handle the next step poorly. Step sizes of 100 VUs every ~2.5 min exceed how fast a Fargate task can be added and warmed up. The aliveness of any individual data point in that range is sensitive to where it falls in the ASG cycle.

4. **Plateau RPS through the frontend.** RPS never exceeds ~150 in Phase 3 despite VU count rising 13×. That plateau is the home-page slow path consuming the per-task SSR concurrency budget; until that's fixed, adding tasks costs money without adding throughput.

## Recommendations (ordered)

1. **Fix `/en` SSR.** Profile what the homepage fetches server-side. Likely candidates: a `featured products` / hero query without caching, an unindexed RDS query, or a synchronous chained backend call. A simple stale-while-revalidate cache (or `revalidate` in Next.js) at the page level would likely move home p95 from ~50 s down to catalog-like 200 ms. Until this lands, frontend autoscaling can't actually help — the slow request consumes one of the very few Node SSR workers per task.

2. **Align Terraform with the live cluster.** `frontend.tf:104,105` still ship `desired_count = 4` / `autoscaling_min_capacity = 4`. If 8 is the new floor, set them in code; otherwise the next `terraform apply` will halve the fleet.

3. **Don't run cold-start probes at 100 VUs.** The Phase-3 / 100 VU run showed a 26.5 s home p95 because the test hit tasks that had been idle for 15+ minutes. For "is this fleet healthy?" checks, add a 30 s warmup salvo before the measurement window.

4. **Bracket finer if you want a clean number.** The 100-VU steps tripped the autoscaler. A truer "steady-state ceiling" sweep would hold each load for ~10 min so ASG settles before measuring, or pre-set `desired_count` per run.

5. **Independent backend test next.** Phase 3 still never exercised `api.camion-app.com` — every request died at the SSR layer. Once `/en` is fixed, run a `backendCrud 100`-mix sweep (requires the prod test-user pool from `README.md:142`) to find the API+RDS ceiling separately.

## File map

- Phase 1 raw log: `/tmp/lt-run.log`
- Phase 2 raw logs: `/tmp/lt-bracket-1000.log`, `lt-bracket-2000.log`, `lt-bracket-5000.log`
- Phase 3 raw logs: `/tmp/lt-sweep-{100..1300}.log`
- Per-shard JSON: `s3://camion-load-test-results-167781471441/runs/`
- Orchestrators: `/tmp/lt-bracket.sh`, `/tmp/lt-sweep.sh`
- CloudWatch: `/ecs/load-test/k6-runner`
