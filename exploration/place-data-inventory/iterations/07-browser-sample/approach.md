# Prompt: browser sample of the blocked sites (item 2). For a Claude session with Claude in Chrome, not Claude Code

Claude Code's fetcher is what gets blocked, so this has to run in a real browser: a Cowork or claude.ai chat with the Claude in Chrome extension, or Robert by hand. Paste everything below the line.

---

I need a **sample check of datasets whose websites block automated checkers**, to characterize that group for the place-based data inventory. The list is `D:\workspace\gaia\docs\discovery\browser-queue-2026-10-23.csv`: 130 rows on 72 domains, with columns `domain, id, dataset_name, organization, theme, priority, health_relevance, site_url, access_url, reason, http_status, what_to_confirm, archive_copy`.

1. **Pick 25 rows:**
   - every row with `priority` set, up to 15;
   - then fill to 25, spreading across domains: at most 4 from humdata.org and 2 from any other domain;
   - prefer `health_relevance` 3.
2. **For each row, open `site_url` in Chrome (a new tab) and record:**
   - `opens` (yes / no / login required / certificate warning);
   - `license` (as stated, or "not stated");
   - `years` and `latest_year`;
   - `finest_unit`;
   - `access` (open download / registration / API key / request);
   - `formats`;
   - `notes`.

   Only record what the page shows; don't guess. **Don't download anything, log in, accept cookie banners beyond "reject non-essential", or submit forms.** If a site shows a CAPTCHA, record `blocked (captcha)` and move on.
3. **Save the results** as `D:\workspace\gaia\docs\discovery\browser-sample-2026-10-28.csv`. Add a short `browser-sample-2026-10-28.md` with counts:
   - how many opened fine;
   - how many have open licenses;
   - how many would be Gold or Silver if read;
   - what the blocking was (bot challenge vs certificate vs genuinely down).

Pace it slowly. It's 25 pages, and that's fine.
