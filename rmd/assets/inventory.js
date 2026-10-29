// Data Inventory explorer for the OHDSI GIS site. Reads data/inventory.json (built by the discovery package script).
(function () {
  "use strict";
  const $ = id => document.getElementById(id);
  const esc = s => String(s ?? "").replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const TIERS = ["Gold", "Silver", "Bronze", "Browser needed", "Failed"];
  const GEO = { embedded: "own geometry", reference_standard: "standard geography", reference_specific: "specific dataset", none: "none", unknown: "unknown" };
  const GEO_SHORT = { embedded: "own", reference_standard: "standard", reference_specific: "specific", none: "none" };
  const LV_SHORT = { "file-verified": "file", "file-verified (partly)": "file (partly)", "page-verified": "page", "not verified": "–" };
  const FACETS = [["t", "Tier"], ["lv", "Verification"], ["open", "Open item"], ["thl", "Category"], ["rg", "Region"], ["gsl", "Geometry"], ["lcl", "Licence"], ["wgf", "Working group"]];
  const AX = [["thl", "Category"], ["rg", "Region"], ["t", "Tier"], ["lv", "Verification"], ["gsl", "Geometry"], ["lcl", "Licence"]];
  const PER = 25;
  let DATA, R, q = "", sortK = "t", sortD = 1, page = 0, open = null;
  const sel = {}, showAll = {};
  FACETS.forEach(([k]) => (sel[k] = new Set()));
  const val = (r, k) => (Array.isArray(r[k]) ? r[k] : [r[k]]);
  const order = (k, vals) => (k === "t" ? TIERS.filter(v => vals.includes(v)) : vals);
  const match = (r, skip) => {
    if (q && !(r.n + " " + r.o + " " + r.id).toLowerCase().includes(q)) return false;
    for (const [k] of FACETS) {
      if (k === skip || !sel[k].size) continue;
      if (!val(r, k).some(v => sel[k].has(v))) return false;
    }
    return true;
  };
  const filtered = () => R.filter(r => match(r));

  function prepare(rows) {
    rows.forEach(r => {
      r.open = [];
      if (r.t === "Browser needed") r.open.push("needs a browser");
      if (r.gd === "TBD" || /not identified/.test(r.gd || "")) r.open.push("geometry not found");
      if (r.fv === "gated") r.open.push("gated (login or registration)");
      if (r.fm) r.open.push("file disagrees with page");
      if (r.c.includes("f") && r.t !== "Failed") r.open.push("a check failed");
      if (r.t === "Bronze" && r.c.replace(/[^-]/g, "").length >= 5) r.open.push("content not read");
      if (!r.open.length) r.open.push("nothing open");
      r.wgf = r.wg ? "WG request" : "not requested";
      r.thl = Array.isArray(r.th) ? r.th : [(r.th || "Other").replace(/_/g, " ")];
      r.lcl = (r.lc || "unknown").replace(/_/g, " ");
      r.gsl = GEO[r.gs] || r.gs;
    });
    return rows;
  }

  function renderFacets() {
    $("gi-facets").innerHTML = FACETS.map(([k, label]) => {
      const cnt = {};
      R.filter(r => match(r, k)).forEach(r => val(r, k).forEach(v => (cnt[v] = (cnt[v] || 0) + 1)));
      const all = new Set();
      R.forEach(r => val(r, k).forEach(v => all.add(v)));
      const vals = order(k, [...all].sort((a, b) => (cnt[b] || 0) - (cnt[a] || 0) || String(a).localeCompare(b)));
      const lim = showAll[k] ? vals.length : 7;
      return `<div class="gi-facet"><h4>${label}</h4>` +
        vals.slice(0, lim).map(v => `<label class="${cnt[v] ? "" : "gi-zero"}"><input type="checkbox" data-k="${k}" value="${esc(v)}" ${sel[k].has(v) ? "checked" : ""}> ${esc(v)}<span class="gi-c">${cnt[v] || 0}</span></label>`).join("") +
        (vals.length > 7 ? `<button class="gi-more" data-k="${k}" type="button">${showAll[k] ? "Show fewer" : "Show all " + vals.length}</button>` : "") + "</div>";
    }).join("");
  }

  function renderBar(list) {
    const chips = [];
    FACETS.forEach(([k, l]) => sel[k].forEach(v => chips.push(`<span class="gi-chip">${esc(l)}: ${esc(v)}<button data-k="${k}" data-v="${esc(v)}" aria-label="Remove filter">×</button></span>`)));
    if (q) chips.push(`<span class="gi-chip">Search: ${esc(q)}<button data-q="1" aria-label="Remove search">×</button></span>`);
    $("gi-bar").innerHTML = `<span class="gi-total">${list.length} of ${R.length} datasets</span>` + chips.join("") + (chips.length ? `<button class="gi-clear" id="gi-clr" type="button">Clear all</button>` : "");
  }

  function renderPivot(list) {
    const rk = $("gi-axr").value, ck = $("gi-axc").value;
    const rows = new Set(), cols = new Set(), cnt = {};
    list.forEach(r => val(r, rk).forEach(a => val(r, ck).forEach(b => { rows.add(a); cols.add(b); cnt[a + "|" + b] = (cnt[a + "|" + b] || 0) + 1; })));
    const tot = (v, ax) => list.filter(r => val(r, ax).includes(v)).length;
    const rs = order(rk, [...rows].sort((a, b) => tot(b, rk) - tot(a, rk)));
    const cs = order(ck, [...cols].sort((a, b) => tot(b, ck) - tot(a, ck)));
    const max = Math.max(1, ...Object.values(cnt));
    let h = `<thead><tr><th></th>${cs.map(c => `<th class="gi-ch">${esc(c)}</th>`).join("")}<th class="gi-tot">Total</th></tr></thead><tbody>`;
    rs.forEach(a => {
      h += `<tr><td class="gi-rh">${esc(a)}</td>` + cs.map(b => {
        const v = cnt[a + "|" + b] || 0;
        return v ? `<td class="gi-cell" data-a="${esc(a)}" data-b="${esc(b)}" style="background:rgba(var(--gi-heat),${(0.06 + 0.55 * v / max).toFixed(2)})" title="${esc(a)} · ${esc(b)}: ${v}">${v}</td>` : `<td class="gi-cell gi-zero">·</td>`;
      }).join("") + `<td class="gi-tot">${tot(a, rk)}</td></tr>`;
    });
    $("gi-pivot").innerHTML = h + "</tbody>";
  }

  function renderTable(list) {
    list.sort((a, b) => {
      let x = a[sortK], y = b[sortK];
      if (sortK === "t") { x = TIERS.indexOf(x); y = TIERS.indexOf(y); }
      if (sortK === "ly") { x = +x || 0; y = +y || 0; }
      return (x > y ? 1 : x < y ? -1 : a.n.localeCompare(b.n)) * sortD;
    });
    const pages = Math.max(1, Math.ceil(list.length / PER));
    page = Math.min(page, pages - 1);
    const names = DATA.checks;
    const strip = c => `<span class="gi-strip" title="${names.map((n, i) => n + ": " + ({ p: "pass", w: "warn", f: "fail", "-": "not checked" })[c[i]]).join(", ")}">${[...c].map(x => `<i class="${x === "-" ? "" : x}"></i>`).join("")}</span>`;
    $("gi-tbl").tBodies[0].innerHTML = list.slice(page * PER, page * PER + PER).map(r => {
      let s = `<tr class="gi-row" data-id="${esc(r.id)}" tabindex="0" aria-expanded="${open === r.id}">
        <td class="gi-nm">${esc(r.n)}<small>${esc(r.o)} · <span class="gi-mono">${esc(r.id)}</span>${r.wg ? " · " + esc(r.wg) : ""}</small></td>
        <td><span class="gi-tier gi-t-${r.t.split(" ")[0]}">${esc(r.t)}</span></td><td>${esc(LV_SHORT[r.lv] || r.lv)}</td><td>${strip(r.c)}</td>
        <td>${esc(r.u)}</td><td class="gi-mono">${esc(r.ly)}</td><td>${esc(GEO_SHORT[r.gs] || r.gs)}</td><td>${esc(r.rg)}</td></tr>`;
      if (open === r.id) {
        s += `<tr class="gi-det"><td colspan="8"><dl>
          <dt>Open</dt><dd>${esc(r.open.join("; "))}</dd>
          <dt>Years</dt><dd>${esc(r.y || "–")}</dd>
          <dt>Licence</dt><dd>${esc(r.lcl)}</dd>
          <dt>Joins via</dt><dd>${esc(r.gsl)}${r.gd ? " → " + esc(r.gd) : ""}${r.pk ? " (key: " + esc(r.pk) + ")" : ""}</dd>
          ${r.fv ? `<dt>File check</dt><dd>${esc(r.fv)}${r.fk ? "; key: " + esc(r.fk) : ""}${r.fg ? "; geometry: " + esc(r.fg) : ""}${r.fy ? "; years: " + esc(r.fy) : ""}${r.fm ? "; mismatch: " + esc(r.fm) : ""}</dd>` : ""}
          ${r.bl ? `<dt>Blocking</dt><dd>${esc(r.bl)}</dd>` : ""}
          <dt>Links</dt><dd>${r.url ? `<a href="${esc(r.url)}" target="_blank" rel="noopener">source</a>` : ""}${r.ev ? ` · <a href="${esc(r.ev)}" target="_blank" rel="noopener">evidence</a>` : ""}${r.vo ? ` · checked ${esc(r.vo)}` : ""}</dd>
        </dl></td></tr>`;
      }
      return s;
    }).join("") || `<tr><td colspan="8">No datasets match. Remove a filter above.</td></tr>`;
    $("gi-pg").textContent = `Page ${page + 1} of ${pages}`;
    $("gi-prev").disabled = page === 0;
    $("gi-next").disabled = page >= pages - 1;
  }

  function render() { const list = filtered(); renderFacets(); renderBar(list); renderPivot(list); renderTable(list); }

  function init(data) {
    DATA = data; R = prepare(data.rows);
    $("gi-asof").textContent = "Data as of " + data.asof + ".";
    $("gi-chk").textContent = "(" + data.checks.join(" · ") + ")";
    const axr = $("gi-axr"), axc = $("gi-axc");
    AX.forEach(([k, l]) => { axr.add(new Option(l, k)); axc.add(new Option(l, k)); });
    axr.value = "thl"; axc.value = "t";
    [axr, axc].forEach(e => e.addEventListener("change", render));
    $("gi-q").addEventListener("input", e => { q = e.target.value.trim().toLowerCase(); page = 0; render(); });
    $("gi-facets").addEventListener("change", e => { const k = e.target.dataset.k; if (!k) return; e.target.checked ? sel[k].add(e.target.value) : sel[k].delete(e.target.value); page = 0; render(); });
    $("gi-facets").addEventListener("click", e => { if (e.target.classList.contains("gi-more")) { const k = e.target.dataset.k; showAll[k] = !showAll[k]; renderFacets(); } });
    $("gi-bar").addEventListener("click", e => {
      const b = e.target;
      if (b.id === "gi-clr") { FACETS.forEach(([k]) => sel[k].clear()); q = ""; $("gi-q").value = ""; }
      else if (b.dataset.q) { q = ""; $("gi-q").value = ""; }
      else if (b.dataset.k) sel[b.dataset.k].delete(b.dataset.v);
      else return;
      page = 0; render();
    });
    $("gi-pivot").addEventListener("click", e => {
      const c = e.target.closest("td.gi-cell"); if (!c || !c.dataset.a) return;
      sel[axr.value] = new Set([c.dataset.a]); sel[axc.value] = new Set([c.dataset.b]); page = 0; render();
      $("gi-tbl").scrollIntoView({ behavior: "smooth", block: "start" });
    });
    $("gi-tbl").tHead.addEventListener("click", e => { const k = e.target.dataset.k; if (!k) return; sortD = sortK === k ? -sortD : 1; sortK = k; render(); });
    const tb = $("gi-tbl").tBodies[0];
    const toggle = row => { if (!row) return; open = open === row.dataset.id ? null : row.dataset.id; renderTable(filtered()); };
    tb.addEventListener("click", e => { if (e.target.closest("a")) return; toggle(e.target.closest("tr.gi-row")); });
    tb.addEventListener("keydown", e => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); toggle(e.target.closest("tr.gi-row")); } });
    $("gi-prev").onclick = () => { page--; renderTable(filtered()); };
    $("gi-next").onclick = () => { page++; renderTable(filtered()); };
    render();
  }

  fetch("data/inventory.json").then(r => r.json()).then(init).catch(() => {
    $("gi-tbl").tBodies[0].innerHTML = '<tr><td colspan="8">The inventory data could not be loaded.</td></tr>';
  });
})();
