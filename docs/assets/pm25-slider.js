/*
 * Frame sliders for tutorial-geo-data-visualization.html. Each figure is an empty
 * <div class="pm25-slider" data-folder data-count data-pad data-start data-step>
 * that this script fills with the image and controls (building the DOM here avoids
 * pandoc treating indented HTML as a code block). Frames are named 01.jpg, 02.jpg, ... in images/<folder>/.
 * data-step is "month" or "hour"; data-start is the date of frame 1 (YYYY-MM-DD).
 */
(function () {
  "use strict";

  var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  function pad(n, width) {
    var s = String(n);
    while (s.length < width) s = "0" + s;
    return s;
  }

  function frameLabel(start, step, index) {
    var p = start.split("-").map(Number);
    if (step === "month") {
      var m = p[1] - 1 + index;
      return MONTHS[m % 12] + " " + (p[0] + Math.floor(m / 12));
    }
    var d = new Date(Date.UTC(p[0], p[1] - 1, p[2], index));
    return d.getUTCFullYear() + "-" + pad(d.getUTCMonth() + 1, 2) + "-" + pad(d.getUTCDate(), 2) +
      " " + pad(d.getUTCHours(), 2) + ":00";
  }

  function init(root) {
    var folder = root.getAttribute("data-folder");
    var count = Number(root.getAttribute("data-count"));
    var width = Number(root.getAttribute("data-pad"));
    var start = root.getAttribute("data-start");
    var step = root.getAttribute("data-step");
    var fps = Number(root.getAttribute("data-fps") || 4);

    var kind = step === "month" ? "month" : "hour";
    root.innerHTML =
      '<img alt="">' +
      '<div class="pm25-controls">' +
      '<button type="button" class="pm25-prev" aria-label="Previous ' + kind + '">&#9664;</button>' +
      '<input type="range" aria-label="' + kind + ' slider" value="1">' +
      '<button type="button" class="pm25-next" aria-label="Next ' + kind + '">&#9654;</button>' +
      '<button type="button" class="pm25-play">Play</button>' +
      '</div>' +
      '<div class="pm25-label"></div>';

    var img = root.querySelector("img");
    var slider = root.querySelector("input[type=range]");
    var label = root.querySelector(".pm25-label");
    var playBtn = root.querySelector(".pm25-play");
    var prevBtn = root.querySelector(".pm25-prev");
    var nextBtn = root.querySelector(".pm25-next");
    var timer = null;
    var cache = {};

    slider.min = 1;
    slider.max = count;
    slider.step = 1;

    function src(i) { return "images/" + folder + "/" + pad(i, width) + ".jpg"; }

    function preload(i) {
      if (i < 1 || i > count || cache[i]) return;
      var im = new Image();
      im.src = src(i);
      cache[i] = im;
    }

    function show(i) {
      i = Math.max(1, Math.min(count, i));
      slider.value = i;
      img.src = src(i);
      img.alt = "PM2.5 map, " + frameLabel(start, step, i - 1);
      label.textContent = frameLabel(start, step, i - 1) + "  (frame " + i + " of " + count + ")";
      preload(i + 1);
      preload(i + 2);
      preload(i - 1);
    }

    function stop() {
      if (timer) { clearInterval(timer); timer = null; }
      playBtn.textContent = "Play";
    }

    function play() {
      playBtn.textContent = "Pause";
      timer = setInterval(function () {
        var next = Number(slider.value) + 1;
        if (next > count) next = 1;
        show(next);
      }, 1000 / fps);
    }

    slider.addEventListener("input", function () { show(Number(slider.value)); });
    prevBtn.addEventListener("click", function () { stop(); show(Number(slider.value) - 1); });
    nextBtn.addEventListener("click", function () { stop(); show(Number(slider.value) + 1); });
    playBtn.addEventListener("click", function () { if (timer) stop(); else play(); });

    show(1);
  }

  Array.prototype.forEach.call(document.querySelectorAll(".pm25-slider"), init);
})();
