(function () {
  "use strict";
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var lang = "bn";
  var rerender = [];

  // ---------- i18n ----------
  var bnDigits = "০১২৩৪৫৬৭৮৯";
  function L(bn, en) { return lang === "bn" ? bn : en; }
  function digits(s) { return lang === "bn" ? String(s).replace(/\d/g, function (d) { return bnDigits[d]; }) : String(s); }
  function num(n) { return digits(n); }
  function money(n) {
    var p = (Number.isInteger(n) ? String(n) : n.toFixed(2)).split(".");
    p[0] = p[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    return digits(p.join("."));
  }
  function half(v) { return v === 0 ? num(0) : v === 0.5 ? "½" : num(Math.floor(v)) + (v % 1 ? "½" : ""); }

  function applyLang(l) {
    lang = l;
    document.documentElement.lang = l;
    $$("[data-en]").forEach(function (el) {
      if (el.dataset.bn === undefined) el.dataset.bn = el.innerHTML;
      el.innerHTML = l === "en" ? el.dataset.en : el.dataset.bn;
    });
    $$("[data-en-label]").forEach(function (el) {
      if (el.dataset.bnLabel === undefined) el.dataset.bnLabel = el.getAttribute("aria-label");
      el.setAttribute("aria-label", l === "en" ? el.dataset.enLabel : el.dataset.bnLabel);
    });
    $$("[data-lang]").forEach(function (b) { b.setAttribute("aria-pressed", String(b.dataset.lang === l)); });
    document.title = L("মিল বাজার — মেসের হিসাব, ফোনে", "Meal Bazar — mess accounts on your phone");
    var d = L("মিল, বাজার, জমা আর মাস শেষের বিল, সব এক জায়গায়, বাংলায়। নেট না থাকলেও চলে। অ্যান্ড্রয়েডের জন্য বিনামূল্যে APK।",
      "Meals, bazar, deposits and the month-end bill in one place, in Bangla. Works without a network. Free APK for Android.");
    $('meta[name="description"]').content = d;
    $('meta[property="og:title"]').content = document.title;
    $('meta[property="og:description"]').content = d;
    rerender.forEach(function (f) { f(); });
  }
  $$("[data-lang]").forEach(function (b) {
    b.addEventListener("click", function () {
      applyLang(b.dataset.lang);
      try { localStorage.setItem("mb-lang", b.dataset.lang); } catch (e) {}
    });
  });

  // ---------- bill slip ----------
  $$(".ln-b").forEach(function (b) {
    b.addEventListener("click", function () {
      b.setAttribute("aria-expanded", String(b.getAttribute("aria-expanded") !== "true"));
    });
  });

  // ---------- 1. meals ----------
  var members = [["রাকিব", "Rakib"], ["সুমন", "Sumon"], ["তানভীর", "Tanvir"]];
  var slots = [["সকাল", "Breakfast"], ["দুপুর", "Lunch"], ["রাত", "Dinner"]];
  var steps = [0, 0.5, 1, 1.5, 2];
  var meals = [[1, 1, 1], [0, 1, 1], [0.5, 1, 2]];
  var mt = $("#meals tbody");
  members.forEach(function (m, r) {
    var tr = document.createElement("tr");
    tr.innerHTML = '<th scope="row"></th>' + slots.map(function (_, c) {
      return '<td><button type="button" class="cell" data-r="' + r + '" data-c="' + c + '"></button></td>';
    }).join("") + '<td class="rt"></td>';
    mt.appendChild(tr);
  });
  function drawMeals() {
    var tot = 0, colT = [0, 0, 0];
    $$("#meals tbody tr").forEach(function (tr, r) {
      $("th", tr).textContent = L(members[r][0], members[r][1]);
      var rt = 0;
      $$(".cell", tr).forEach(function (b, c) {
        var v = meals[r][c];
        b.textContent = half(v);
        b.classList.toggle("on", v > 0);
        b.setAttribute("aria-label", L(members[r][0] + ", " + slots[c][0] + ": " + half(v) + "। ট্যাপ করে বদলান",
          members[r][1] + ", " + slots[c][1] + ": " + half(v) + ". Tap to change"));
        rt += v; colT[c] += v;
      });
      $(".rt", tr).textContent = half(rt);
      tot += rt;
    });
    $$("#meals tfoot td").forEach(function (td, i) { if (i < 3) td.textContent = half(colT[i]); });
    $("#m-all").textContent = half(tot);
  }
  mt.addEventListener("click", function (e) {
    var b = e.target.closest(".cell"); if (!b) return;
    var r = +b.dataset.r, c = +b.dataset.c;
    meals[r][c] = steps[(steps.indexOf(meals[r][c]) + 1) % steps.length];
    drawMeals();
  });
  rerender.push(drawMeals);

  // ---------- 2. bazar list ----------
  var items = [
    { n: ["চাল", "Rice"], q: ["২ কেজি", "2 kg"], on: false, p: "" },
    { n: ["ডিম", "Eggs"], q: ["১ ডজন", "1 dozen"], on: false, p: "" },
    { n: ["আলু", "Potato"], q: ["২ কেজি", "2 kg"], on: false, p: "" },
    { n: ["মসুর ডাল", "Lentils"], q: ["১ কেজি", "1 kg"], on: false, p: "" }
  ];
  var blState = "draft"; // draft | waiting | approved
  var bl = $("#bl");
  items.forEach(function (it, i) {
    var li = document.createElement("li");
    li.innerHTML = '<button type="button" role="checkbox" class="chk" data-i="' + i + '" aria-checked="false"><svg class="i" aria-hidden="true" style="width:18px;height:18px"><use href="#i-check"/></svg></button>' +
      '<label for="p' + i + '"></label><span class="price">৳<input id="p' + i + '" inputmode="decimal" autocomplete="off" data-i="' + i + '"></span>';
    bl.appendChild(li);
  });
  function blSum() { return items.reduce(function (s, it) { return s + (it.on ? parseFloat(it.p) || 0 : 0); }, 0); }
  function drawBl() {
    $$("li", bl).forEach(function (li, i) {
      var it = items[i], chk = $(".chk", li), inp = $("input", li);
      chk.setAttribute("aria-checked", String(it.on));
      chk.setAttribute("aria-label", L(it.n[0] + " কেনা হয়েছে", "Bought: " + it.n[1]));
      li.classList.toggle("done", it.on);
      $("label", li).innerHTML = L(it.n[0], it.n[1]) + "<small>" + L(it.q[0], it.q[1]) + "</small>";
      inp.placeholder = L("দাম", "price");
      inp.disabled = blState !== "draft";
      chk.style.pointerEvents = blState !== "draft" ? "none" : "";
    });
    var sum = blSum();
    $("#bl-t").textContent = "৳" + money(sum);
    var send = $("#bl-send");
    send.disabled = blState !== "draft" || sum <= 0;
    var s = $("#bl-s");
    if (blState === "draft") s.innerHTML = '<span class="pill off">' + L("খসড়া: এখনো পাঠানো হয়নি", "Draft: not sent yet") + "</span>";
    else if (blState === "waiting") s.innerHTML = '<span class="pill">' + L("ম্যানেজারের অনুমোদনের অপেক্ষায়", "Waiting for the manager") + '</span><button class="btn sm" type="button" id="bl-ok">' + L("ম্যানেজার হিসেবে অনুমোদন করুন", "Approve as manager") + '</button><button class="reset" type="button" id="bl-re">' + L("আবার শুরু থেকে", "Start over") + "</button>";
    else s.innerHTML = '<span class="pill ok"><svg class="i" aria-hidden="true"><use href="#i-check"/></svg>' + L("অনুমোদিত, বাজার হিসাবে যোগ হয়েছে", "Approved and added to the accounts") + '</span><button class="reset" type="button" id="bl-re">' + L("আবার শুরু থেকে", "Start over") + "</button>";
  }
  bl.addEventListener("click", function (e) {
    var b = e.target.closest(".chk"); if (!b) return;
    items[+b.dataset.i].on = !items[+b.dataset.i].on; drawBl();
  });
  bl.addEventListener("input", function (e) {
    var i = e.target.dataset.i; if (i === undefined) return;
    items[+i].p = e.target.value.replace(/[^\d.]/g, "");
    if (items[+i].p && !items[+i].on) items[+i].on = true;
    // keep focus: update only what depends on the value
    $$("li", bl)[+i].classList.add("done");
    $(".chk", $$("li", bl)[+i]).setAttribute("aria-checked", "true");
    var sum = blSum(); $("#bl-t").textContent = "৳" + money(sum); $("#bl-send").disabled = sum <= 0;
  });
  $("#bl-send").addEventListener("click", function () { blState = "waiting"; drawBl(); });
  $("#bl-s").addEventListener("click", function (e) {
    if (e.target.closest("#bl-ok")) { blState = "approved"; drawBl(); $("#bl-re").focus(); }
    else if (e.target.closest("#bl-re")) {
      blState = "draft"; items.forEach(function (it) { it.on = false; it.p = ""; });
      $$("input", bl).forEach(function (i) { i.value = ""; }); drawBl();
    }
  });
  rerender.push(drawBl);

  // ---------- 3. deposits ----------
  var verified = false;
  function drawDep() {
    var bal = verified ? 200 : 1200;
    $("#d-amt").textContent = money(1000);
    $("#d-who").textContent = L("সুমন · বিকাশ · TrxID 8N7A4K2L", "Sumon · bKash · TrxID 8N7A4K2L");
    $("#d-act").innerHTML = verified
      ? '<span class="pill ok"><svg class="i" aria-hidden="true"><use href="#i-check"/></svg>' + L("যাচাই হয়েছে", "Verified") + "</span>"
      : '<span class="pill" style="margin-right:.5rem">' + L("যাচাইয়ের অপেক্ষায়", "Pending") + '</span><button class="btn sm" type="button" id="d-ok">' + L("যাচাই করুন", "Verify") + "</button>";
    $("#d-lbl").textContent = L("সুমনের বাকি", "Sumon owes");
    var b = $("#d-bal"); b.textContent = "৳" + money(bal); b.className = verified ? "paid" : "due";
    $("#d-reset").hidden = !verified;
  }
  $("#d-act").addEventListener("click", function (e) {
    if (e.target.closest("#d-ok")) { verified = true; drawDep(); $("#d-reset").focus(); }
  });
  $("#d-reset").addEventListener("click", function () { verified = false; drawDep(); $("#d-ok").focus(); });
  rerender.push(drawDep);

  // ---------- 4. offline ----------
  var offline = false, queue = [], sentTimer = 0, sentCount = 0;
  var pool = [["দুপুরের মিল ১", "Lunch meal 1"], ["বাজার ৳৪২০", "Bazar ৳420"], ["জমা ৳৫০০ (নগদ)", "Deposit ৳500 (Nagad)"], ["রাতের মিল ২", "Dinner meal 2"], ["ভাড়ার নোটিস", "Rent notice"]];
  var sw = $("#sw"), strip = $("#strip");
  function drawOff() {
    sw.setAttribute("aria-checked", String(offline));
    $("#sw-l").textContent = offline ? L("নেটওয়ার্ক বন্ধ", "Network off") : L("নেটওয়ার্ক চালু", "Network on");
    var ic = function (id) { return '<svg class="i" aria-hidden="true"><use href="#' + id + '"/></svg>'; };
    if (offline) { strip.className = "strip off"; strip.innerHTML = ic("i-phone") + L("অফলাইন · " + num(queue.length) + "টি পরিবর্তন এই ফোনে সেভ আছে", "Offline · " + queue.length + " changes saved on this phone"); }
    else if (sentTimer) { strip.className = "strip sent"; strip.innerHTML = ic("i-check") + L(num(sentCount) + "টি পরিবর্তন পাঠানো হয়েছে", sentCount + " changes sent"); }
    else { strip.className = "strip"; strip.innerHTML = ic("i-cloud") + L("অনলাইন · সব পাঠানো হয়েছে", "Online · everything is sent"); }
    $("#q").innerHTML = queue.length ? queue.map(function (x, i) { return "<li><span>" + L(x[0], x[1]) + "</span><span>" + L("ফোনে সেভ", "on this phone") + "</span></li>"; }).join("")
      : '<li class="empty">' + L("অপেক্ষায় কোনো পরিবর্তন নেই।", "No changes waiting.") + "</li>";
    $("#q-add").disabled = !offline;
  }
  sw.addEventListener("click", function () {
    offline = !offline;
    clearTimeout(sentTimer); sentTimer = 0;
    if (offline) queue = pool.slice(0, 2);
    else {
      sentCount = queue.length; queue = [];
      sentTimer = setTimeout(function () { sentTimer = 0; drawOff(); }, 2800);
    }
    drawOff();
  });
  $("#q-add").addEventListener("click", function () { if (queue.length < pool.length) queue.push(pool[queue.length]); drawOff(); });
  rerender.push(drawOff);

  // ---------- reveal on scroll (content stays visible without JS) ----------
  if (!matchMedia("(prefers-reduced-motion: reduce)").matches && "IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.remove("pre"); io.unobserve(e.target); } });
    }, { threshold: 0.12 });
    $$("[data-rv]").forEach(function (el) {
      if (el.getBoundingClientRect().top > innerHeight * 0.9) { el.classList.add("pre"); io.observe(el); }
    });
  }

  var saved = "bn";
  try { saved = localStorage.getItem("mb-lang") || "bn"; } catch (e) {}
  applyLang(saved === "en" ? "en" : "bn");
})();
