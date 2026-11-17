// Data Inventory explorer for the OHDSI GIS site. Reads data/inventory.json and data/inventory-history.json
// (both built by scripts/build_publish_package.py in the Gaia workspace).
(function () {
  "use strict";
  const $ = id => document.getElementById(id);
  const esc = s => String(s ?? "").replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const TIERS = ["Gold", "Silver", "Bronze", "Browser needed", "Failed"];
  const GEO = { embedded: "own geometry", reference_standard: "standard geography", reference_specific: "specific dataset", none: "none", unknown: "unknown" };
  const GEO_SHORT = { embedded: "own", reference_standard: "standard", reference_specific: "specific", none: "none" };
  const LV_SHORT = { "file-verified": "file", "file-verified (partly)": "file (partly)", "page-verified": "page", "not verified": "–" };
  // Filters in two groups: what the data is (d), then where its review stands (r).
  const FACETS = [["thl", "Category", "d"], ["rg", "Region", "d"], ["gsl", "Geometry", "d"], ["lcl", "Licence", "d"],
                  ["t", "Tier", "r"], ["open", "Open item", "r"], ["lv", "Verification", "r"], ["wgf", "Working group request", "r"], ["gcl", "Gaia catalog", "r"]];
  const GROUPS = [["d", "About the data", ""], ["r", "Review status", "How far each dataset has been checked"]];
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
      r.gcl = r.gc ? "in the catalog" : "not yet";
    });
    return rows;
  }

  function renderFacets() {
    $("gi-facets").innerHTML = GROUPS.map(([g, gl, gd]) => `<div class="gi-group gi-group-${g}"><div class="gi-gh">${gl}${gd ? `<small>${gd}</small>` : ""}</div>` + FACETS.filter(f => f[2] === g).map(([k, label]) => {
      const cnt = {};
      R.filter(r => match(r, k)).forEach(r => val(r, k).forEach(v => (cnt[v] = (cnt[v] || 0) + 1)));
      const all = new Set();
      R.forEach(r => val(r, k).forEach(v => all.add(v)));
      const vals = order(k, [...all].sort((a, b) => (cnt[b] || 0) - (cnt[a] || 0) || String(a).localeCompare(b)));
      const lim = showAll[k] ? vals.length : 7;
      return `<div class="gi-facet"><h4>${label}</h4>` +
        vals.slice(0, lim).map(v => `<label class="${cnt[v] ? "" : "gi-zero"}"><input type="checkbox" data-k="${k}" value="${esc(v)}" ${sel[k].has(v) ? "checked" : ""}> ${k === "t" ? `<i class="gi-dot gi-t-${v.split(" ")[0]}"></i>` : ""}${esc(v)}<span class="gi-c">${cnt[v] || 0}</span></label>`).join("") +
        (vals.length > 7 ? `<button class="gi-more" data-k="${k}" type="button">${showAll[k] ? "Show fewer" : "Show all " + vals.length}</button>` : "") + "</div>";
    }).join("") + "</div>").join("");
  }

  function renderBar(list) {
    const chips = [];
    FACETS.forEach(([k, l]) => sel[k].forEach(v => chips.push(`<span class="gi-chip">${esc(l)}: ${esc(v)}<button data-k="${k}" data-v="${esc(v)}" aria-label="Remove filter">×</button></span>`)));
    if (q) chips.push(`<span class="gi-chip">Search: ${esc(q)}<button data-q="1" aria-label="Remove search">×</button></span>`);
    $("gi-bar").innerHTML = chips.length ? `<span class="gi-total">Showing ${list.length} of ${R.length}</span>` + chips.join("") + `<button class="gi-clear" id="gi-clr" type="button">Clear all</button>` : "";
    document.querySelectorAll("#gi-tierkey .gi-tk").forEach(b => b.setAttribute("aria-pressed", sel.t.has(b.dataset.t)));
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
        <td><span class="gi-tier gi-t-${r.t.split(" ")[0]}">${esc(r.t)}</span></td><td>${esc(LV_SHORT[r.lv] || r.lv)}</td><td>${strip(r.c)}<span class="gi-done${r.gc ? " on" : ""}" title="${r.gc ? "In the Gaia catalog: " + esc(r.gc) : "Not yet in the Gaia catalog"}">${r.gc ? "✓" : ""}</span></td>
        <td>${esc(r.u)}</td><td class="gi-mono">${esc(r.ly)}</td><td>${esc(GEO_SHORT[r.gs] || r.gs)}</td><td>${esc(r.rg)}</td></tr>`;
      if (open === r.id) {
        s += `<tr class="gi-det"><td colspan="8"><dl>
          <dt>Open</dt><dd>${esc(r.open.join("; "))}</dd>
          <dt>Years</dt><dd>${esc(r.y || "–")}</dd>
          <dt>Licence</dt><dd>${esc(r.lcl)}</dd>
          <dt>Joins via</dt><dd>${esc(r.gsl)}${r.gd ? " → " + esc(r.gd) : ""}${r.pk ? " (key: " + esc(r.pk) + ")" : ""}</dd>
          ${r.fv ? `<dt>File check</dt><dd>${esc(r.fv)}${r.fk ? "; key: " + esc(r.fk) : ""}${r.fg ? "; geometry: " + esc(r.fg) : ""}${r.fy ? "; years: " + esc(r.fy) : ""}${r.fm ? "; mismatch: " + esc(r.fm) : ""}</dd>` : ""}
          ${r.bl ? `<dt>Blocking</dt><dd>${esc(r.bl)}</dd>` : ""}
          <dt>Gaia catalog</dt><dd>${r.gc ? "metadata and recipe written: " + esc(r.gc.split(";").join(", ")) : "not yet"}</dd>
          <dt>Links</dt><dd>${r.url ? `<a href="${esc(r.url)}" target="_blank" rel="noopener">source</a>` : ""}${r.ev ? ` · <a href="${esc(r.ev)}" target="_blank" rel="noopener">evidence</a>` : ""}${r.vo ? ` · checked ${esc(r.vo)}` : ""}</dd>
        </dl></td></tr>`;
      }
      return s;
    }).join("") || `<tr><td colspan="8">No datasets match. Remove a filter above.</td></tr>`;
    $("gi-pg").textContent = `Page ${page + 1} of ${pages}`;
    $("gi-prev").disabled = page === 0;
    $("gi-next").disabled = page >= pages - 1;
  }

  function render() {
    const list = filtered(); renderFacets(); renderBar(list); renderPivot(list); renderTable(list);
    $("gi-nd").textContent = list.length;
    $("gi-nb").textContent = $("gi-axr").selectedOptions[0].text + " × " + $("gi-axc").selectedOptions[0].text;
    renderGrowth(list);
  }

  // Growth: today's (filtered) datasets at every saved run, stacked by category (top 7 + other) or by the tier each had then.
  // "All time" puts the runs on a date axis and adds the gaiaCatalog's own growth before the inventory began (whole catalog; ignores filters).
  let H = null, TC = ["G", "S", "B", "N", "F"], TN = { G: "Gold", S: "Silver", B: "Bronze", N: "Browser needed", F: "Failed" };
  const CATC = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300", "#6250d6"], OTHERC = "#a9b2ba";
  let gMode = "n", gBy = "cat", gSpan = "all", gOn = -1, CAT7 = null;
  const fmtD = d => new Date(d + "T00:00:00").toLocaleDateString("en-GB", { day: "numeric", month: "short" });
  const fmtDY = d => new Date(d + "T00:00:00").toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
  const tms = d => new Date(d + "T00:00:00").getTime();
  const prim = r => r.thl[0] || "Other";
  function series() {
    if (!CAT7) { const c = {}; R.forEach(r => (c[prim(r)] = (c[prim(r)] || 0) + 1)); CAT7 = Object.keys(c).sort((a, b) => c[b] - c[a]).slice(0, 7); }
    if (gBy === "tier") return TC.map(t => ({ k: t, l: TN[t], col: `var(--gi-c-${t})` }));
    return CAT7.map((k, i) => ({ k, l: k, col: CATC[i] })).concat([{ k: "_o", l: "All other categories", col: OTHERC }]);
  }
  // The "Last 3 months" view starts three months before the latest run; the catalog count carries over from its last commit before that.
  const GSTART = () => { const d = new Date(H.snaps[H.snaps.length - 1].d + "T00:00:00"); d.setMonth(d.getMonth() - 3); return d.toISOString().slice(0, 10); };
  const anyFilter = () => q || FACETS.some(([k]) => sel[k].size);
  function renderGrowth(list) {
    const S = H.snaps, SR = series(), keyOf = (r, c) => gBy === "tier" ? c : (CAT7.includes(prim(r)) ? prim(r) : "_o");
    const cnt = S.map(() => { const o = { all: 0, ver: 0, det: {} }; SR.forEach(s => (o[s.k] = 0)); return o; });
    list.forEach(r => { const h = H.t[r.id]; if (!h) return; [...h].forEach((c, i) => { if (c === "-") return; const o = cnt[i]; o[keyOf(r, c)]++; o.all++; if (c === "G" || c === "S") o.ver++; o.det[prim(r)] = (o.det[prim(r)] || 0) + 1; }); });
    const first = cnt.findIndex(c => c.all > 0), last = cnt[cnt.length - 1];
    const showCat = gSpan === "all" && gMode === "n" && !anyFilter();
    // points: one per run ("runs"), or one per date with the catalog history in front ("all")
    let P;
    if (gSpan === "runs") P = S.map((s, i) => ({ d: s.d, run: i, inv: cnt[i], lab: s.it }));
    else {
      const byDate = {}; S.forEach((s, i) => (byDate[s.d] = i));
      const catAt = d => { let v = null; H.cat.forEach(([cd, n]) => { if (cd <= d) v = n; }); return v; };
      const dates = [...new Set([GSTART()].concat(H.cat.map(c => c[0]).filter(d => d > GSTART()), Object.keys(byDate)))].sort();
      P = dates.map(d => ({ d, run: d in byDate ? byDate[d] : null, inv: d in byDate ? cnt[byDate[d]] : null, cat: catAt(d) }));
    }
    $("gi-ng").textContent = last.all;
    const catFirst = [GSTART(), (H.cat.filter(c => c[0] <= GSTART()).pop() || H.cat[0])[1]];
    $("gi-gsum").innerHTML = first < 0 ? "No datasets match these filters." : (showCat
      ? `From <b>${catFirst[1]}</b> catalog entries three months ago to <b>${last.all}</b> assessed datasets today; <b>${last.ver}</b> verified.`
      : `<b>${last.all}</b> datasets now, up from <b>${cnt[first].all}</b> on ${fmtD(S[first].d)}. Verified (Gold or Silver): <b>${cnt[first].ver}</b> → <b>${last.ver}</b>.`);
    $("gi-glegend").innerHTML = (showCat ? `<span><i class="gi-sw gi-sw-cat"></i>gaiaCatalog entries (before the inventory)</span>` : "") + SR.map(s => `<span><i class="gi-sw" style="background:${s.col}"></i>${esc(s.l)}</span>`).join("");
    const W = 760, Ht = 300, m = { l: 40, r: 14, t: 18, b: 46 }, iw = W - m.l - m.r, ih = Ht - m.t - m.b, n = P.length;
    const t0 = tms(P[0].d), t1 = tms(P[n - 1].d);
    const xs = gSpan === "runs" ? (i => m.l + (n > 1 ? i * iw / (n - 1) : iw / 2)) : (i => m.l + (tms(P[i].d) - t0) / Math.max(1, t1 - t0) * iw);
    const ymax = gMode === "p" ? 100 : Math.max(1, ...cnt.map(c => c.all), ...(showCat ? H.cat.map(c => c[1]) : [0]));
    const nice = v => { const p = Math.pow(10, Math.floor(Math.log10(v))), f = v / p; return (f <= 1 ? 1 : f <= 2 ? 2 : f <= 5 ? 5 : 10) * p; };
    const tstep = gMode === "p" ? 25 : nice(ymax / 4), top = gMode === "p" ? 100 : Math.ceil(ymax / tstep) * tstep;
    const y = v => m.t + ih - v / top * ih;
    let g = `<g class="gi-ax">`;
    for (let v = 0; v <= top + 1e-9; v += tstep) g += `<line x1="${m.l}" x2="${W - m.r}" y1="${y(v)}" y2="${y(v)}"></line><text x="${m.l - 6}" y="${y(v) + 4}" text-anchor="end">${v}${gMode === "p" ? "%" : ""}</text>`;
    g += `</g>`;
    // x labels
    if (gSpan === "runs") P.forEach((p, i) => {
      g += `<text x="${xs(i)}" y="${Ht - m.b + 16}" text-anchor="middle">${p.lab}</text>`;
      if (i === 0 || p.d !== P[i - 1].d) g += `<text x="${xs(i)}" y="${Ht - m.b + 30}" text-anchor="middle">${fmtD(p.d)}</text>`;
    });
    else {
      const a = new Date(P[0].d + "T00:00:00"), b = new Date(P[n - 1].d + "T00:00:00");
      for (let dt = new Date(a.getFullYear(), a.getMonth(), 1); dt <= b; dt.setMonth(dt.getMonth() + 1)) {
        const x = m.l + (dt.getTime() - t0) / Math.max(1, t1 - t0) * iw;
        g += `<line class="gi-vt" x1="${x}" x2="${x}" y1="${m.t + ih}" y2="${m.t + ih + 4}"></line><text x="${x}" y="${Ht - m.b + 18}" text-anchor="middle">${dt.toLocaleDateString("en-GB", { month: "short" })}${dt.getMonth() === 0 || x < m.l + 40 ? " " + dt.getFullYear() : ""}</text>`;
      }
      const s0 = P.findIndex(p => p.run === 0);
      if (s0 >= 0) g += `<line class="gi-start" x1="${xs(s0)}" x2="${xs(s0)}" y1="${m.t}" y2="${m.t + ih}"></line><text class="gi-start-l" x="${xs(s0) - 6}" y="${m.t + 10}" text-anchor="end">Inventory begins, 20 Oct 2026</text>`;
    }
    // stacked inventory areas over the points that have a run
    const vv = (c, k) => gMode === "p" ? (c.all ? c[k] / c.all * 100 : 0) : c[k];
    const PI = P.map((p, i) => i).filter(i => P[i].inv), tops = {};
    const base = PI.map(() => 0);
    SR.forEach(s => {
      const lo = base.slice(), hi = PI.map((i, j) => (base[j] += vv(P[i].inv, s.k)));
      tops[s.k] = {}; PI.forEach((i, j) => (tops[s.k][i] = hi[j]));
      const tp = PI.map((i, j) => `${xs(i).toFixed(1)},${y(hi[j]).toFixed(1)}`), bt = PI.map((i, j) => `${xs(i).toFixed(1)},${y(lo[j]).toFixed(1)}`).reverse();
      g += `<path class="gi-area" fill="${s.col}" d="M${tp.join("L")}L${bt.join("L")}Z"></path>`;
    });
    // gaiaCatalog line (step: the count holds until the next commit)
    if (showCat) {
      const CI = P.map((p, i) => i).filter(i => P[i].cat != null);
      let d = ""; CI.forEach((i, j) => { const X = xs(i).toFixed(1), Y = y(P[i].cat).toFixed(1); d += j ? `H${X}V${Y}` : `M${X},${Y}`; });
      g += `<path class="gi-catline" d="${d}"></path>` + CI.filter(i => !P[i].inv).map(i => `<circle class="gi-catpt" cx="${xs(i)}" cy="${y(P[i].cat)}" r="3"></circle>`).join("");
      const c0 = CI[0], cm = CI.reduce((a, i) => (P[i].cat > P[a].cat ? i : a), c0);
      g += `<text class="gi-tot" x="${xs(c0) + 4}" y="${y(P[c0].cat) - 8}">${P[c0].cat}</text><text class="gi-tot" x="${xs(cm) - 8}" y="${y(P[cm].cat) + 4}" text-anchor="end">${P[cm].cat} catalog entries</text>`;
    }
    if (gMode === "n" && first >= 0) { const L = PI[PI.length - 1], F = PI.find(i => P[i].inv.all); [F, L].forEach(i => { if (i == null || (gSpan === "all" && i === F)) return; g += `<text class="gi-tot" x="${xs(i)}" y="${y(P[i].inv.all) - 6}" text-anchor="${i === L ? "end" : "start"}">${P[i].inv.all}</text>`; }); }
    g += `<g id="gi-xh" visibility="hidden"><line class="gi-xh" y1="${m.t}" y2="${m.t + ih}"></line>${SR.map(s => `<circle class="gi-pt" r="4" fill="${s.col}" data-k="${esc(s.k)}"></circle>`).join("")}<circle class="gi-pt gi-catpt" r="4" data-k="_cat"></circle></g>`;
    g += `<rect id="gi-ghit" x="${m.l - 10}" y="${m.t}" width="${iw + 20}" height="${ih + 34}" fill="transparent" tabindex="0" aria-label="Chart: use left and right arrow keys to step through the points"></rect>`;
    const svg = $("gi-gsvg"); svg.setAttribute("viewBox", `0 0 ${W} ${Ht}`); svg.innerHTML = g;
    svg._g = { P, xs, y, tops, n, W, SR, showCat };
    const cats = [...new Set(list.map(prim))].sort((a, b) => (last.det[b] || 0) - (last.det[a] || 0));
    $("gi-gtbl").innerHTML = `<thead><tr><th>Run</th><th>Date</th><th>Step</th>${(gBy === "tier" ? SR.map(s => s.l) : cats).map(l => `<th>${esc(l)}</th>`).join("")}<th>Total</th></tr></thead><tbody>` +
      H.cat.map(([d, n2, l]) => `<tr><td>–</td><td>${fmtDY(d)}</td><td>gaiaCatalog: ${esc(l)}</td>${(gBy === "tier" ? SR : cats).map(() => "<td></td>").join("")}<td><b>${n2}</b></td></tr>`).join("") +
      S.map((s, i) => `<tr><td class="gi-mono">${s.it}</td><td>${fmtDY(s.d)}</td><td>${esc(s.l)}</td>${(gBy === "tier" ? SR.map(x => cnt[i][x.k]) : cats.map(c => cnt[i].det[c] || 0)).map(v => `<td>${v}</td>`).join("")}<td><b>${cnt[i].all}</b></td></tr>`).join("") + "</tbody>";
    if (gOn >= n) gOn = -1;
    if (gOn >= 0) tip(gOn);
  }
  function tip(i) {
    const svg = $("gi-gsvg"), t = $("gi-tip"), G = svg._g, xh = $("gi-xh");
    gOn = i;
    if (i < 0 || !G) { t.hidden = true; if (xh) xh.setAttribute("visibility", "hidden"); return; }
    const x = G.xs(i), p = G.P[i];
    xh.setAttribute("visibility", "visible");
    xh.querySelector("line").setAttribute("x1", x); xh.querySelector("line").setAttribute("x2", x);
    xh.querySelectorAll("circle").forEach(cc => {
      const k = cc.dataset.k, v = k === "_cat" ? (G.showCat ? p.cat : null) : (p.inv ? G.tops[k][i] : null);
      cc.setAttribute("visibility", v == null ? "hidden" : "visible"); if (v != null) { cc.setAttribute("cx", x); cc.setAttribute("cy", G.y(v)); }
    });
    let h = "";
    if (p.inv) {
      const s = H.snaps[p.run], c = p.inv, pv = p.run > 0 ? H.snaps[p.run - 1] && G.P.find(q => q.run === p.run - 1) : null, prev = pv ? pv.inv : null;
      const d = k => prev ? ` <small>(${c[k] - prev[k] >= 0 ? "+" : ""}${c[k] - prev[k]})</small>` : "";
      h = `<b>${s.it} · ${fmtDY(s.d)} · ${esc(s.l)}</b>` + G.SR.slice().reverse().map(x2 => `<div><span><i class="gi-sw" style="background:${x2.col}"></i>${esc(x2.l)}</span><span>${c[x2.k]}${d(x2.k)}</span></div>`).join("") +
        `<div><span>Total</span><span><b style="display:inline">${c.all}</b>${d("all")}</span></div><div><span>Verified</span><span>${c.ver}${d("ver")}</span></div>`;
    } else h = `<b>${fmtDY(p.d)}</b>`;
    if (G.showCat && p.cat != null) { const e = H.cat.find(c => c[0] === p.d); h += `<div><span><i class="gi-sw gi-sw-cat"></i>gaiaCatalog entries${e ? ": " + esc(e[2]) : ""}</span><span>${p.cat}</span></div>`; }
    t.innerHTML = h; t.hidden = false;
    const wrap = $("gi-gwrap").getBoundingClientRect(), px = x / G.W * wrap.width;
    let left = px + 12; if (left + t.offsetWidth > wrap.width) left = px - t.offsetWidth - 12;
    t.style.left = Math.max(0, left) + "px"; t.style.top = "10px";
  }
  const nearest = e => { const G = $("gi-gsvg")._g, r = $("gi-gsvg").getBoundingClientRect(), x = (e.clientX - r.left) / r.width * G.W; let b = 0; for (let i = 1; i < G.n; i++) if (Math.abs(G.xs(i) - x) < Math.abs(G.xs(b) - x)) b = i; return b; };
  const VIEWS = ["breakdown", "datasets", "growth"];
  function show(v, focus) {
    if (!VIEWS.includes(v)) v = "breakdown";
    VIEWS.forEach(w => {
      const t = $("gi-tab-" + w), on = w === v;
      t.setAttribute("aria-selected", on); t.tabIndex = on ? 0 : -1; $("gi-p-" + w).hidden = !on;
    });
    if (focus) $("gi-tab-" + v).focus();
    if (location.hash.slice(1) !== v) history.replaceState(null, "", "#" + v);
  }

  function init(data) {
    DATA = data; R = prepare(data.rows);
    $("gi-asof").dateTime = data.asof; $("gi-asof").textContent = new Date(data.asof + "T00:00:00").toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" }) + (H ? " · after iteration " + H.snaps[H.snaps.length - 1].it + ": " + H.snaps[H.snaps.length - 1].l : "");
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
      show("datasets");
    });
    $("gi-tbl").tHead.addEventListener("click", e => { const k = e.target.dataset.k; if (!k) return; sortD = sortK === k ? -sortD : 1; sortK = k; render(); });
    const tb = $("gi-tbl").tBodies[0];
    const toggle = row => { if (!row) return; open = open === row.dataset.id ? null : row.dataset.id; renderTable(filtered()); };
    tb.addEventListener("click", e => { if (e.target.closest("a")) return; toggle(e.target.closest("tr.gi-row")); });
    tb.addEventListener("keydown", e => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); toggle(e.target.closest("tr.gi-row")); } });
    $("gi-prev").onclick = () => { page--; renderTable(filtered()); };
    $("gi-next").onclick = () => { page++; renderTable(filtered()); };
    document.querySelector("#gis-inv .gi-tabs").addEventListener("click", e => { const b = e.target.closest(".gi-tab"); if (b) show(b.dataset.view); });
    document.querySelector("#gis-inv .gi-tabs").addEventListener("keydown", e => {
      if (e.key !== "ArrowRight" && e.key !== "ArrowLeft") return;
      const i = VIEWS.indexOf(document.activeElement.dataset.view); if (i < 0) return;
      e.preventDefault(); show(VIEWS[(i + (e.key === "ArrowRight" ? 1 : VIEWS.length - 1)) % VIEWS.length], true);
    });
    window.addEventListener("hashchange", () => show(location.hash.slice(1)));
    const gs = $("gi-gsvg");
    gs.addEventListener("mousemove", e => tip(nearest(e)));
    gs.addEventListener("mouseleave", () => tip(-1));
    gs.addEventListener("focusin", () => tip(gOn >= 0 ? gOn : gs._g.n - 1));
    gs.addEventListener("focusout", () => tip(-1));
    gs.addEventListener("keydown", e => {
      if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;
      e.preventDefault(); tip(Math.max(0, Math.min(gs._g.n - 1, (gOn < 0 ? gs._g.n - 1 : gOn) + (e.key === "ArrowRight" ? 1 : -1))));
    });
    // header: whole-inventory numbers and the tier key (click a tier to filter)
    const TD = { Gold: "Link, licence, unit, years and access all confirmed on the publisher's pages.", Silver: "Link works and nothing fails; at least one check only partly confirmed.", Bronze: "Link works, but the content isn't read yet or a check failed (often an unstated licence).", "Browser needed": "The site blocks automated checks; a person needs to open it.", Failed: "Dead, withdrawn, archived, or data ending before 2000." };
    const tc = {}; R.forEach(r => (tc[r.t] = (tc[r.t] || 0) + 1));
    $("gi-s-n").textContent = R.length; $("gi-s-v").textContent = (tc.Gold || 0) + (tc.Silver || 0);
    $("gi-s-f").textContent = R.filter(r => r.gc).length;
    $("gi-s-it").textContent = H.iterations || H.snaps.length; $("gi-s-itl").textContent = `iterations since ${fmtD(H.since || H.snaps[0].d)}`;
    const TK = { Gold: "G", Silver: "S", Bronze: "B", "Browser needed": "N", Failed: "F" };
    $("gi-tierbar").innerHTML = TIERS.map(t => `<i style="flex:${tc[t] || 0};background:var(--gi-c-${TK[t]})" title="${t}: ${tc[t] || 0}"></i>`).join("");
    $("gi-tierkey").innerHTML = TIERS.map(t => `<button type="button" class="gi-tk" data-t="${t}" aria-pressed="false"><span class="gi-tk-h"><span><i class="gi-sw" style="background:var(--gi-c-${TK[t]})"></i>${t}</span><b>${tc[t] || 0}</b></span><small>${TD[t]}</small></button>`).join("");
    $("gi-tierkey").addEventListener("click", e => { const b = e.target.closest(".gi-tk"); if (!b) return; const t = b.dataset.t; sel.t.has(t) ? sel.t.delete(t) : sel.t.add(t); page = 0; render(); });
    $("gi-gby").addEventListener("change", e => { gBy = e.target.value; renderGrowth(filtered()); });
    $("gi-gspan").addEventListener("change", e => { gSpan = e.target.value; gOn = -1; renderGrowth(filtered()); });
    [["gi-gm-n", "n"], ["gi-gm-p", "p"]].forEach(([id, mo]) => $(id).addEventListener("click", () => {
      gMode = mo; $("gi-gm-n").setAttribute("aria-pressed", mo === "n"); $("gi-gm-p").setAttribute("aria-pressed", mo === "p"); renderGrowth(filtered());
    }));
    show(location.hash.slice(1));
    render();
  }

  Promise.all([fetch("data/inventory.json").then(r => r.json()), fetch("data/inventory-history.json").then(r => r.json())])
    .then(([d, h]) => { H = h; init(d); }).catch(() => {
    $("gi-tbl").tBodies[0].innerHTML = '<tr><td colspan="8">The inventory data could not be loaded.</td></tr>';
  });
})();
