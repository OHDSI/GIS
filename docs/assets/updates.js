(function () {
  "use strict";

  function el(tag, attrs, children) {
    var e = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === "class") e.className = attrs[k];
      else if (k === "text") e.textContent = attrs[k];
      else e.setAttribute(k, attrs[k]);
    });
    [].concat(children || []).forEach(function (c) { if (c) e.appendChild(c); });
    return e;
  }

  var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  function formatDate(iso) {
    var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso);
    return m ? parseInt(m[3], 10) + " " + MONTHS[parseInt(m[2], 10) - 1] + " " + m[1] : iso;
  }

  // Only absolute http(s) URLs and relative site paths become links.
  function safeUrl(u) {
    return /^https?:\/\//i.test(u) || /^[\w./#-][\w./#?=&%-]*$/.test(u) ? u : null;
  }

  function entry(u) {
    var box = el("div", { class: "update-entry" }, [
      el("div", { class: "update-date", text: formatDate(u.date) }),
      el("div", { class: "update-title", text: u.title }),
      el("p", { class: "update-body", text: u.body || "" })
    ]);
    var links = (u.links || []).filter(function (l) { return safeUrl(l.url); });
    if (links.length) {
      var ul = el("ul", { class: "update-links" });
      links.forEach(function (l) {
        var a = el("a", { href: safeUrl(l.url), text: l.label });
        if (/^https?:/i.test(l.url)) { a.target = "_blank"; a.rel = "noopener"; }
        ul.appendChild(el("li", {}, [a]));
      });
      box.appendChild(ul);
    }
    return box;
  }

  var hosts = document.querySelectorAll("[data-updates]");
  if (!hosts.length) return;

  fetch("data/updates.json")
    .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
    .then(function (d) {
      var all = (d.updates || []).filter(function (u) { return u.date && u.title; })
        .sort(function (a, b) { return a.date < b.date ? 1 : a.date > b.date ? -1 : 0; });
      Array.prototype.forEach.call(hosts, function (h) {
        var limit = parseInt(h.getAttribute("data-updates"), 10);
        (limit > 0 ? all.slice(0, limit) : all).forEach(function (u) { h.appendChild(entry(u)); });
      });
    })
    .catch(function (e) {
      Array.prototype.forEach.call(hosts, function (h) {
        h.appendChild(el("div", { class: "chart-error", text: "Could not load updates (" + e.message + ")." }));
      });
    });
})();
