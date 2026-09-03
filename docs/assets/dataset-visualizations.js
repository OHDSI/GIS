/*
 * Renders the charts on tutorial-data-visualization.html from the precomputed
 * CSV extracts in data/synthetic-dataset/. Loaded via a plain <script> tag
 * (no bundler) so this stays a static-site-friendly, dependency-light file:
 * only external dependency is Chart.js (loaded before this file).
 */
(function () {
  "use strict";

  var DATA_DIR = "data/synthetic-dataset/";
  var CATEGORY_COLORS = {
    Respiratory: "#4C9AFF",
    Cardiometabolic: "#FF7452"
  };
  var DENSITY_COLORS = {
    "Urban Core": "#C0392B",
    Suburban: "#E67E22",
    "Small Town": "#27AE60",
    Rural: "#2E86C1"
  };

  function parseCsv(text) {
    var lines = text.replace(/\r/g, "").split("\n").filter(function (l) {
      return l.length > 0;
    });
    var headers = lines[0].split(",");
    return lines.slice(1).map(function (line) {
      var cells = line.split(",");
      var row = {};
      headers.forEach(function (h, i) {
        var v = cells[i];
        row[h] = v !== undefined && v !== "" && !isNaN(v) ? Number(v) : v;
      });
      return row;
    });
  }

  function loadCsv(name) {
    return fetch(DATA_DIR + name).then(function (resp) {
      if (!resp.ok) {
        throw new Error("Failed to load " + name + ": " + resp.status);
      }
      return resp.text();
    }).then(parseCsv);
  }

  function showError(canvasId, err) {
    var canvas = document.getElementById(canvasId);
    if (!canvas) return;
    var wrap = canvas.closest(".chart-wrap") || canvas.parentNode;
    wrap.innerHTML =
      '<p class="chart-error">Could not load chart data (' + err.message +
      "). If you are viewing this file directly from disk, serve the docs/ " +
      "folder over HTTP instead (e.g. <code>python3 -m http.server</code> " +
      "from within docs/) — browsers block fetch() of local files.</p>";
  }

  function renderConditions(rows) {
    var sorted = rows.slice().sort(function (a, b) { return b.pct_of_population - a.pct_of_population; });
    new Chart(document.getElementById("chartConditions"), {
      type: "bar",
      data: {
        labels: sorted.map(function (r) { return r.condition_name; }),
        datasets: [{
          label: "% of cohort",
          data: sorted.map(function (r) { return r.pct_of_population; }),
          backgroundColor: sorted.map(function (r) { return CATEGORY_COLORS[r.category]; })
        }]
      },
      options: {
        indexAxis: "y",
        plugins: {
          title: { display: true, text: "Condition prevalence (% of 10,000 patients)" },
          legend: { display: false },
          tooltip: {
            callbacks: {
              afterLabel: function (ctx) { return sorted[ctx.dataIndex].category; }
            }
          }
        },
        scales: { x: { title: { display: true, text: "% of cohort" } } }
      }
    });
  }

  function renderDensity(rows) {
    var order = ["Urban Core", "Suburban", "Small Town", "Rural"];
    var sorted = rows.slice().sort(function (a, b) {
      return order.indexOf(a.urban_density_category) - order.indexOf(b.urban_density_category);
    });
    new Chart(document.getElementById("chartDensity"), {
      type: "bar",
      data: {
        labels: sorted.map(function (r) { return r.urban_density_category + " (n=" + r.n_counties + ")"; }),
        datasets: [
          { label: "Avg PM2.5 (µg/m³)", data: sorted.map(function (r) { return r.avg_pm25; }), backgroundColor: "#8E44AD" },
          { label: "Avg SES index", data: sorted.map(function (r) { return r.avg_ses; }), backgroundColor: "#16A085" }
        ]
      },
      options: {
        plugins: { title: { display: true, text: "PM2.5 and SES by county urban density" } },
        scales: { y: { beginAtZero: true } }
      }
    });
  }

  function renderAsthmaQuartile(rows) {
    var sorted = rows.slice().sort(function (a, b) { return a.pm25_quartile - b.pm25_quartile; });
    new Chart(document.getElementById("chartAsthmaQuartile"), {
      type: "line",
      data: {
        labels: sorted.map(function (r) { return "Q" + r.pm25_quartile + " (avg " + r.avg_pm25 + " µg/m³)"; }),
        datasets: [{
          label: "Asthma prevalence (%)",
          data: sorted.map(function (r) { return r.asthma_pct; }),
          borderColor: "#4C9AFF",
          backgroundColor: "#4C9AFF",
          tension: 0.2
        }]
      },
      options: {
        plugins: { title: { display: true, text: "Asthma prevalence by county PM2.5 exposure quartile" } },
        scales: {
          x: { title: { display: true, text: "PM2.5 quartile (Q1 = lowest exposure)" } },
          y: { title: { display: true, text: "% with asthma diagnosis" } }
        }
      }
    });
  }

  function renderSdoh(rows) {
    var sorted = rows.slice().sort(function (a, b) { return a.observation_name.localeCompare(b.observation_name); });
    new Chart(document.getElementById("chartSdoh"), {
      type: "bar",
      data: {
        labels: sorted.map(function (r) { return r.observation_name; }),
        datasets: [{
          label: "Mean value (see hover for units)",
          data: sorted.map(function (r) { return r.mean_value; }),
          backgroundColor: "#F39C12"
        }]
      },
      options: {
        indexAxis: "y",
        plugins: {
          title: { display: true, text: "County-level SDOH observations (cohort mean)" },
          legend: { display: false }
        }
      }
    });
  }

  function renderCountBar(canvasId, rows, labelField, valueField, title, color) {
    var sorted = rows.slice().sort(function (a, b) { return b[valueField] - a[valueField]; });
    new Chart(document.getElementById(canvasId), {
      type: "bar",
      data: {
        labels: sorted.map(function (r) { return r[labelField]; }),
        datasets: [{ label: "Records", data: sorted.map(function (r) { return r[valueField]; }), backgroundColor: color }]
      },
      options: {
        indexAxis: "y",
        plugins: { title: { display: true, text: title }, legend: { display: false } }
      }
    });
  }

  function renderCountyMap(rows) {
    var byDensity = {};
    rows.forEach(function (r) {
      var cat = r.urban_density_category;
      byDensity[cat] = byDensity[cat] || [];
      byDensity[cat].push({ x: r.centroid_lon, y: r.centroid_lat, r: 2 + Math.sqrt(r.patient_count || 0) });
    });
    var datasets = Object.keys(byDensity).map(function (cat) {
      return {
        label: cat,
        data: byDensity[cat],
        backgroundColor: (DENSITY_COLORS[cat] || "#999") + "AA",
        borderColor: DENSITY_COLORS[cat] || "#999",
        borderWidth: 1
      };
    });
    new Chart(document.getElementById("chartCountyMap"), {
      type: "bubble",
      data: { datasets: datasets },
      options: {
        plugins: {
          title: { display: true, text: "County centroids (bubble size = assigned patient count)" },
          tooltip: {
            callbacks: {
              label: function (ctx) {
                return ctx.dataset.label + ": (" + ctx.raw.x.toFixed(1) + ", " + ctx.raw.y.toFixed(1) + ")";
              }
            }
          }
        },
        scales: {
          x: { title: { display: true, text: "Longitude" } },
          y: { title: { display: true, text: "Latitude" } }
        }
      }
    });
  }

  function safe(fn, canvasId) {
    return function (rows) {
      try { fn(rows); } catch (err) { showError(canvasId, err); }
    };
  }

  loadCsv("condition_prevalence.csv").then(safe(renderConditions, "chartConditions")).catch(function (e) { showError("chartConditions", e); });
  loadCsv("pm25_by_density.csv").then(safe(renderDensity, "chartDensity")).catch(function (e) { showError("chartDensity", e); });
  loadCsv("asthma_by_pm25_quartile.csv").then(safe(renderAsthmaQuartile, "chartAsthmaQuartile")).catch(function (e) { showError("chartAsthmaQuartile", e); });
  loadCsv("sdoh_summary.csv").then(safe(renderSdoh, "chartSdoh")).catch(function (e) { showError("chartSdoh", e); });
  loadCsv("drug_counts.csv").then(safe(function (rows) {
    renderCountBar("chartDrugs", rows, "drug_name", "exposure_count", "Drug exposure records by concept", "#27AE60");
  }, "chartDrugs")).catch(function (e) { showError("chartDrugs", e); });
  loadCsv("procedure_counts.csv").then(safe(function (rows) {
    renderCountBar("chartProcedures", rows, "procedure_name", "procedure_count", "Procedure records by concept", "#2980B9");
  }, "chartProcedures")).catch(function (e) { showError("chartProcedures", e); });
  loadCsv("measurement_counts.csv").then(safe(function (rows) {
    renderCountBar("chartMeasurements", rows, "measurement_name", "measurement_count", "Measurement records by concept", "#8E44AD");
  }, "chartMeasurements")).catch(function (e) { showError("chartMeasurements", e); });
  loadCsv("county_summary.csv").then(safe(renderCountyMap, "chartCountyMap")).catch(function (e) { showError("chartCountyMap", e); });
})();
