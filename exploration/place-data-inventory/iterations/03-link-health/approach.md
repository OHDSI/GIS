# Claude Code prompt: verification stage A only (URL health, scripted)

Paste everything below the line into Claude Code, run from `D:\workspace\gaia`, with web access on.

---

Read `docs/discovery/verify-prompt-2026-10-21.md`. It is the full design. **Do only part A (reachability and URL health, scripted) in this run.** Don't do parts B or C, and don't do the agent page reads.

What to do:

1. **Write `docs/discovery/scripts/verify_links.py`.** It implements every check in section A of the design:
   - `chk_link_live`, `chk_redirect`, `chk_tls`, `chk_soft404`, `chk_withdrawn`;
   - `chk_access_url`, `chk_format_match`;
   - `chk_machine_metadata`, `chk_persistent_id`, `chk_archived`.

   It also records `http_status`, `final_url`, `response_ms`, `content_type` and `checked_at`. Follow the design's rules: polite user agent, 1 request per second per domain, robots.txt, 20 s timeout with one retry, no dataset downloads (HEAD or a 1 KB range only for endpoints), no bypassing bot protection. Use threads across domains, but stay serial within a domain. Plain Python (requests, plus the standard library); no LLM in the loop.
2. **Run it on all 1,018 rows.** That's the 594 rows of `inventory-working.csv` plus the 424 inferred-unit leads; read the leads from the Inventory sheet of `place-data-inventory-2026-10-21.xlsx`. Save progress every 25 rows, so a re-run resumes where it stopped.
3. **Write the results:**
   - `docs/discovery/verify-A-2026-10-21.csv`: one row per dataset, with `id`, `tier`, `priority`, `site_url`, `access_url`, every `chk_*` / `_detail` column and the raw fields. Don't modify `inventory-working.csv` in this run.
   - Append every check result to `docs/discovery/verify-log.csv` (long form, with a `run_id`).
   - `docs/discovery/browser-queue-2026-10-21.csv`: the shortlist rows (priority set) that came back `blocked_bot` or `blocked_robots`.
   - The summary columns that part A can support: `checks_applicable`, `checks_passed`, `checks_warned`, `checks_failed`, `all_passing_A` (every applicable A check passes) and `url_health`. For `url_health`:
     - **healthy:** live, no soft-404, not withdrawn;
     - **moved:** live, but redirected to another domain;
     - **degraded:** live, but a soft-404 warning, a broken access URL, or no machine metadata;
     - **dead:** fail;
     - **blocked:** bot or robots.
4. **Write `docs/discovery/verify-A-report-2026-10-21.md` (one page):**
   - a pass/warn/fail/n.a. table per check;
   - `url_health` counts, overall, for the 211 shortlist rows, by tier (curated / lead) and by theme;
   - dead and withdrawn datasets, with their Wayback snapshot dates;
   - domains that blocked or timed out;
   - domains that moved;
   - how many pages expose machine-readable metadata, and which kind (schema.org, DCAT, CKAN, STAC);
   - run time;
   - how long a monthly re-run would take.
5. **Update `docs/discovery/README.md`:** a status line, plus the new files in the files table.

Stop after the report. Don't start part B.
