(function () {
  "use strict";

  function el(tag, attrs, children) {
    var e = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === "class") e.className = attrs[k];
      else if (k === "text") e.textContent = attrs[k];
      else e.setAttribute(k, attrs[k]);
    });
    [].concat(children || []).forEach(function (c) {
      if (c == null) return;
      e.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
    });
    return e;
  }

  function link(text, href) {
    return el("a", { href: href, text: text, target: "_blank", rel: "noopener" });
  }

  function person(p) {
    return link("@" + p.login, p.url);
  }

  function statusChip(item) {
    var cls = "status-chip status-" + item.status.toLowerCase().replace(/[^a-z]+/g, "-");
    var chip = el("span", { class: cls, text: item.status });
    if (item.status_note) chip.title = item.status_note;
    return chip;
  }

  function progress(item) {
    var wrap = el("div", { class: "status-progress" }, [statusChip(item)]);
    if (item.deps_total) {
      wrap.appendChild(el("div", { class: "status-sub",
        text: item.deps_closed + " of " + item.deps_total + " dependencies closed" }));
    }
    wrap.appendChild(el("div", { class: "status-sub",
      text: item.state === "closed" ? "Closed " + item.closed : "Updated " + item.updated }));
    if (item.status_note) wrap.appendChild(el("div", { class: "status-sub", text: item.status_note }));
    return wrap;
  }

  function depList(deps) {
    if (!deps.length) return el("span", { class: "status-none", text: "None listed" });
    var ul = el("ul", { class: "status-deps" });
    deps.forEach(function (d) {
      var label = d.repo + "#" + d.number + " " + d.title;
      ul.appendChild(el("li", { class: "status-dep-" + d.state }, [
        el("span", { class: "status-dep-mark", text: d.state === "closed" ? "✓ " : "○ " }),
        link(label, d.url)
      ]));
    });
    return ul;
  }

  function people(list) {
    if (!list.length) return el("span", { class: "status-none", text: "Not assigned" });
    var out = [];
    list.forEach(function (p, i) { if (i) out.push(", "); out.push(person(p)); });
    return el("span", {}, out);
  }

  function external(item) {
    return item.external_owner
      ? document.createTextNode(item.external_owner)
      : el("span", { class: "status-none", text: "Not recorded" });
  }

  function table(columns, rows) {
    var thead = el("thead", {}, [el("tr", {}, columns.map(function (c) {
      return el("th", { text: c.label });
    }))]);
    var tbody = el("tbody", {}, rows.map(function (r) {
      return el("tr", {}, columns.map(function (c) { return el("td", {}, [c.cell(r)]); }));
    }));
    return el("table", { class: "table table-striped status-table" }, [thead, tbody]);
  }

  var common = {
    rank: { label: "Rank", cell: function (i) {
      return i.rank == null ? el("span", { class: "status-none", text: "—" }) : document.createTextNode(String(i.rank));
    } },
    title: { label: "Request", cell: function (i) {
      return el("div", {}, [link(i.title, i.url), el("div", { class: "status-sub", text: i.repo + "#" + i.number })]);
    } },
    progress: { label: "Progress", cell: progress },
    requested: { label: "Requested", cell: function (i) { return document.createTextNode(i.requested); } },
    external: { label: "External owner", cell: external },
    internal: { label: "WG owner", cell: function (i) { return people(i.internal_owners); } }
  };

  var useCaseColumns = [
    common.rank, common.title, common.progress, common.requested, common.external, common.internal,
    { label: "Depends on", cell: function (i) { return depList(i.depends_on); } }
  ];

  var datasetColumns = [
    common.rank, common.title, common.progress, common.requested, common.external, common.internal,
    { label: "Needed by", cell: function (i) {
      return depList(i.needed_by.map(function (u) {
        var m = /github\.com\/OHDSI\/([^/]+)\/issues\/(\d+)/.exec(u.url);
        return { repo: m[1], number: m[2], title: u.title, state: u.state, url: u.url };
      }));
    } },
    { label: "Depends on", cell: function (i) { return depList(i.depends_on); } }
  ];

  function isDone(i) { return i.status === "Complete" || i.status === "Superseded"; }

  function render(target, columns, items, showDone, emptyText) {
    var host = document.getElementById(target);
    if (!items.some(function (i) { return i.rank != null; })) {
      columns = columns.filter(function (c) { return c !== common.rank; });  // no ranks on the board yet
    }
    var rows = items.filter(function (i) { return showDone || !isDone(i); });
    host.textContent = "";
    host.appendChild(rows.length ? table(columns, rows) : el("p", { text: emptyText }));
  }

  function summary(items, noun) {
    var counts = {};
    items.forEach(function (i) { counts[i.status] = (counts[i.status] || 0) + 1; });
    var parts = Object.keys(counts).map(function (k) { return counts[k] + " " + k.toLowerCase(); });
    return el("div", { class: "status-summary-card" }, [
      el("strong", { text: items.length + " " + noun }),
      el("div", { class: "status-sub", text: parts.join(" · ") })
    ]);
  }

  function showError(msg) {
    ["status-use-cases", "status-datasets"].forEach(function (id) {
      var h = document.getElementById(id);
      if (h) { h.textContent = ""; h.appendChild(el("div", { class: "chart-error", text: msg })); }
    });
  }

  fetch("data/status.json")
    .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
    .then(function (d) {
      document.getElementById("status-updated").textContent =
        "Data last refreshed " + d.generated_at.slice(0, 10) + ".";
      var s = document.getElementById("status-summary");
      s.appendChild(summary(d.use_cases, "use cases"));
      s.appendChild(summary(d.datasets, "dataset requests"));

      var ucBox = document.getElementById("uc-closed");
      var dsBox = document.getElementById("ds-closed");
      function draw() {
        render("status-use-cases", useCaseColumns, d.use_cases, ucBox.checked, "No open use cases.");
        render("status-datasets", datasetColumns, d.datasets, dsBox.checked, "No open dataset requests.");
      }
      ucBox.addEventListener("change", draw);
      dsBox.addEventListener("change", draw);
      draw();
    })
    .catch(function (e) {
      showError("Could not load the status data (" + e.message + "). See the GitHub issues linked above.");
    });
})();
