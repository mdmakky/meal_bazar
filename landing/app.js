(function () {
  "use strict";
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var RM = matchMedia("(prefers-reduced-motion: reduce)").matches;
  var lang = "en", all = [], phones = [];

  // ---------- helpers ----------
  var bnD = "০১২৩৪৫৬৭৮৯";
  function L(bn, en) { return lang === "bn" ? bn : en; }
  function dg(s) { return lang === "bn" ? String(s).replace(/\d/g, function (d) { return bnD[d]; }) : String(s); }
  function grp(n) { if (n.length <= 3) return n; var h = n.slice(0, -3), p = []; for (var e = h.length; e > 0; e -= 2) p.unshift(h.slice(Math.max(0, e - 2), e)); return p.join(",") + "," + n.slice(-3); }
  function mo(n) { var neg = n < 0 && Math.abs(n) >= 0.005, a = Math.abs(n).toFixed(2).split("."); return dg((neg ? "-" : "") + "৳" + grp(a[0]) + (a[1] === "00" ? "" : "." + a[1])); }
  function ml(v) { return dg(String(v)); } // meal counts: 0, 0.5, 1, 1.5, 2
  function ic(n, c) { return '<svg class="mi' + (c ? " " + c : "") + '" viewBox="0 0 24 24" aria-hidden="true">' + (IC[n] || "") + "</svg>"; }
  var IC = {
    home: '<path d="M3 11.5 12 4l9 7.5M5.5 10v9.5h4.5v-5.5h4v5.5h4.5V10"/>',
    meals: '<path d="M7 3v8a2.5 2.5 0 0 0 2.5 2.5M12 3v8M9.5 13.5V21M17 21V3c-2.2 1.2-3.5 4-3.5 7.5V14H17"/>',
    bazar: '<path d="M3.5 10h17l-1.8 9.2a1.5 1.5 0 0 1-1.5 1.2H6.8a1.5 1.5 0 0 1-1.5-1.2zM8 10l3-6M16 10l-3-6"/>',
    money: '<path d="M4 7.5A2.5 2.5 0 0 1 6.5 5H18v3M4 7.5V18a2 2 0 0 0 2 2h12.5a1.5 1.5 0 0 0 1.5-1.5v-9A1.5 1.5 0 0 0 18.5 8H6.5A2.5 2.5 0 0 1 4 7.5zM16 14h2"/>',
    more: '<path d="M6 12h.01M12 12h.01M18 12h.01" stroke-width="3.2"/>',
    vert: '<path d="M12 6h.01M12 12h.01M12 18h.01" stroke-width="3.2"/>',
    left: '<path d="m15 6-6 6 6 6"/>', right: '<path d="m9 6 6 6-6 6"/>',
    plus: '<path d="M12 5v14M5 12h14"/>', minus: '<path d="M5 12h14"/>',
    back: '<path d="M19 12H5m6-6-6 6 6 6"/>',
    send: '<path d="M3.5 11 20.5 3.5 13 20.5l-2.3-7.2zM10.7 13.3 20.5 3.5"/>',
    check: '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
    bell: '<path d="M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15zM10 21h4"/>',
    search: '<circle cx="11" cy="11" r="6.5"/><path d="m20 20-4.2-4.2"/>',
    all: '<path d="m2 13 4 4L15 8M10 15l2 2L22 8"/>',
    hist: '<path d="M4 12a8 8 0 1 0 2.5-5.8M4 4v4.5h4.5M12 8v4.5l3 1.8"/>',
    camp: '<path d="M4 10v4h3l7 4V6l-7 4zM17.5 9a4 4 0 0 1 0 6"/>',
    pin: '<path d="M9 4h6l-1 6 3 3H7l3-3zM12 13v7"/>',
    cloudoff: '<path d="M4 4 20 20M7.5 18A4 4 0 0 1 6 10.5 6 6 0 0 1 10 6.3M17.5 18H8M18.3 10A4.2 4.2 0 0 1 20 17"/>',
    drop: '<path d="M7 10l5 5 5-5z" fill="currentColor" stroke="none"/>',
    edit: '<path d="M4 20h4L19 9l-4-4L4 16zM13.5 6.5l4 4"/>',
    cal: '<rect x="4" y="5" width="16" height="15" rx="2.5"/><path d="M4 10h16M8 3v4M16 3v4M8 14h4"/>',
    list: '<path d="M4 7h10M4 12h10M4 17h6M17 14v6M14 17h6"/>',
    expand: '<path d="m6 9 6 6 6-6"/>',
    bolt: '<path d="M13 3 5 13h6l-1 8 8-10h-6z"/>', wifi: '<path d="M3 9a14 14 0 0 1 18 0M6 12.5a9 9 0 0 1 12 0M9 16a4.5 4.5 0 0 1 6 0M12 19.5h.01"/>',
    user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    dl: '<path d="M12 4v11M7 11l5 5 5-5M5 20h14"/>'
  };
  var MEMBERS = [["Rakib", "রাকিব"], ["Tanvir", "তানভীর"], ["Sabbir", "সাব্বির"], ["Sumon", "সুমন"]];
  function nm(i) { return L(MEMBERS[i][1], MEMBERS[i][0]); }
  function av(i, strong, big) { return '<span class="av' + (big ? " l" : "") + '"' + (strong ? ' style="background:#141413;color:#FAFAF9"' : "") + ">" + nm(i).charAt(0).toUpperCase() + "</span>"; }
  // one consistent mess: rate 4,820 / 100 meals = 48.20; shared costs 2,600 / 4 = 650
  var RATE = 48.2, EXTRA = 650;
  var MEAL = [41, 28, 19, 12], CREDIT = [2300, 2500, 1500, 1000];
  function closing(i, credit) { return (credit === undefined ? CREDIT[i] : credit) - MEAL[i] * RATE - EXTRA; }
  var DAY = function () { return dg(12) + " " + L("অক্টোবর", "October") + " " + dg(2026); };
  var TYPES = function () { return [L("সকাল", "Breakfast"), L("দুপুর", "Lunch"), L("রাত", "Dinner")]; };

  function tween(o, k, to, ms, cb) {
    if (RM || !ms) { o[k] = to; cb(); return; }
    var from = o[k], t0 = null;
    requestAnimationFrame(function f(t) {
      if (t0 === null) t0 = t;
      var p = Math.min(1, (t - t0) / ms);
      o[k] = from + (to - from) * (1 - Math.pow(1 - p, 3));
      cb();
      if (p < 1) requestAnimationFrame(f);
    });
  }

  // ---------- tiny DOM morph: patch nodes in place so CSS transitions run and taps are never lost ----------
  function morph(host, html) {
    var t = document.createElement("template"); t.innerHTML = html;
    kids(host, t.content);
  }
  function kids(a, b) {
    var ac = a.childNodes, bc = b.childNodes, i;
    for (i = 0; i < bc.length; i++) {
      var x = ac[i], y = bc[i];
      if (!x) { a.appendChild(y.cloneNode(true)); continue; }
      if (x.nodeType !== y.nodeType || x.nodeName !== y.nodeName) { a.replaceChild(y.cloneNode(true), x); continue; }
      if (x.nodeType === 3) { if (x.nodeValue !== y.nodeValue) x.nodeValue = y.nodeValue; continue; }
      if (x.nodeType !== 1) continue;
      attrs(x, y); kids(x, y);
    }
    while (ac.length > bc.length) a.removeChild(a.lastChild);
  }
  function attrs(x, y) {
    var i, n;
    for (i = 0; i < y.attributes.length; i++) { n = y.attributes[i]; if (x.getAttribute(n.name) !== n.value) x.setAttribute(n.name, n.value); }
    for (i = x.attributes.length - 1; i >= 0; i--) { n = x.attributes[i].name; if (!y.hasAttribute(n)) x.removeAttribute(n); }
  }

  // ---------- shared app chrome (dp units) ----------
  var NAV = [["home", "Home", "হোম"], ["meals", "Meals", "মিল"], ["bazar", "Bazar", "বাজার"], ["money", "Money", "হিসাব"], ["more", "More", "আরও"]];
  function nav(active) {
    var idx = 0;
    var items = NAV.map(function (n, i) {
      var on = n[0] === active; if (on) idx = i;
      return '<div class="ni' + (on ? " on" : "") + '"><span class="np">' + ic(n[0], on && n[0] !== "meals" && n[0] !== "more" ? "f" : "") + "</span><span>" + L(n[2], n[1]) + "</span></div>";
    }).join("");
    return '<div class="nvb">' + items + '<i class="dot" style="left:calc(' + (idx * 20) + '% + 10% - 2px)"></i></div>';
  }
  function appbar(title, o) {
    o = o || {};
    return '<div class="ap' + (o.back ? " bk" : "") + '">' + (o.back ? '<button type="button" class="a ib" data-a="back" data-k="back" aria-label="' + L("পেছনে", "Back") + '">' + ic("back") + "</button>" : "") +
      '<span class="ttl t-tm">' + title + "</span>" + (o.actions || "") + "</div>";
  }
  function stripHTML(s) {
    return '<div class="sstrip' + (s.off ? " show" : "") + '">' + ic("cloudoff") + "<span>" + L("অফলাইন · " + dg(s.q) + "টি পরিবর্তন এই ফোনে সেভ আছে, নেট ফিরলে পাঠানো হবে", "Offline · " + s.q + " changes saved on this phone, sent when you are back online") + "</span><b>" + L("আবার চেষ্টা", "Retry") + "</b></div>";
  }

  var S = {};

  // ---------- MEALS (meals_screen.dart + meal_grid.dart) ----------
  S.meals = {
    nav: "meals",
    init: function () { return { v: [[1, 1, 1], [1, 1, 1], [0, 1, 1], [1, 1, 1]], last: "", off: 0, q: 0 }; },
    body: function (s) {
      var T = TYPES();
      var h = '<div class="bd" data-sc="1"><div class="mhd"><div><div class="t-tl">' + L("গ্রিন হাউস", "Green House") + '</div><div class="ov">' + L("ম্যানেজার: রাকিব", "Manager: Rakib") + '</div></div>' +
        '<div class="mpill"><span class="ib">' + ic("left") + '</span><span class="x">' + L("অক্টোবর", "October") + " " + dg(2026) + '</span><span class="ib" style="opacity:.38">' + ic("right") + "</span></div></div>" +
        '<div class="dsw"><span class="rn">' + ic("left") + '</span><div class="c"><span class="t-tm">' + DAY() + '</span><span class="todayp"><i></i>' + L("আজ", "Today") + '</span></div><span class="rn">' + ic("right") + "</span></div>" +
        '<div class="bulk"><span class="bpill">' + ic("all") + L("সবাই ১", "Everyone 1") + '</span><span class="bpill">' + ic("hist") + L("গতকালের মতো", "Same as yesterday") + "</span></div>";
      var col = [0, 0, 0], names = "", cells = "", tot = "";
      s.v.forEach(function (row, r) {
        names += '<div class="gnc">' + av(r) + "<span>" + nm(r) + "</span></div>";
        cells += '<div class="gr">' + row.map(function (v, c) {
          col[c] += v;
          var k = r + "," + c;
          return '<div class="gc"><button type="button" class="a sbtn' + (v <= 0 ? " dis" : "") + '" data-a="d" data-v="' + k + '" data-k="d' + r + c + '" aria-label="' + L("কমান: ", "Decrease: ") + nm(r) + " " + T[c] + '"><i>' + ic("minus") + '</i></button><button type="button" class="a gv' + (v <= 0 ? " z" : "") + (s.last === k ? " pop" : "") + '" data-a="c" data-v="' + k + '" data-k="c' + r + c + '" aria-label="' + nm(r) + " " + T[c] + ": " + ml(v) + '">' + ml(v) + '</button><button type="button" class="a sbtn' + (v >= 5 ? " dis" : "") + '" data-a="i" data-v="' + k + '" data-k="i' + r + c + '" aria-label="' + L("বাড়ান: ", "Increase: ") + nm(r) + " " + T[c] + '"><i>' + ic("plus") + "</i></button></div>";
        }).join("") + "</div>";
      });
      var day = col[0] + col[1] + col[2];
      tot = col.map(function (c) { return '<div class="gc t-tm" style="width:112px">' + ml(c) + "</div>"; }).join("");
      h += '<div class="cd gridc"><div class="gn"><div class="gnc h"><span class="ov">' + L("সদস্য", "Member") + "</span></div>" + names + '<div class="gnc l"><span class="ov">' + L("মোট মিল", "Total meals") + '</span></div></div><div class="gs"><div style="width:336px"><div class="gr gh">' +
        T.map(function (t) { return '<div class="gc"><span class="ov" style="color:#141413">' + t + "</span></div>"; }).join("") + "</div>" + cells + '<div class="gr gl" style="height:56px">' + tot + "</div></div></div></div>" +
        '<p class="t-bs" style="margin:8px 16px 0;color:#6F6E6A">' + L("সংখ্যায় ট্যাপ করলে ০, ০.৫, ১, ১.৫, ২ ঘুরে আসবে", "Tap a number to cycle 0, 0.5, 1, 1.5, 2") + "</p>" +
        '<div class="syl">' + (s.off ? "<i></i>" + L("অফলাইনে সেভ হয়েছে", "Saved offline") : "") + "</div>" +
        '<div style="padding:12px 16px 0"><div class="inkc" style="padding:24px"><div class="ov">' + L("এই দিনের মোট মিল", "Total meals this day") + '</div><div class="t-dl" style="margin-top:4px">' + ml(day) + '</div><div class="t-bm" style="margin-top:4px">' +
        T.map(function (t, i) { return t + " " + ml(col[i]); }).join("&nbsp;&nbsp;·&nbsp;&nbsp;") + "</div></div></div></div>" +
        stripHTML(s) + '<div class="fab" aria-hidden="true">' + ic("plus") + "</div>" + nav("meals");
      return h;
    },
    act: function (s, a, v) {
      var p = v.split(","), r = +p[0], c = +p[1], cur = s.v[r][c];
      if (a === "c") s.v[r][c] = [0, 0.5, 1, 1.5, 2].indexOf(cur) < 0 || cur >= 2 ? 0 : cur + 0.5;
      else if (a === "i") { if (cur >= 5) return false; s.v[r][c] = cur + 0.5; } else { if (cur <= 0) return false; s.v[r][c] = cur - 0.5; }
      s.last = v; if (s.off) s.q++; return true;
    },
    play: function (i) {
      [["i", "3,0"], ["i", "3,0"], ["c", "2,0"], ["i", "1,2"]].forEach(function (a, n) {
        later(i, function () { S.meals.act(i.st, a[0], a[1]); render(i); }, 900 + n * 750);
      });
    }
  };

  // ---------- HOME (today_screen.dart) ----------
  S.home = {
    nav: "home",
    init: function () { return { page: 0 }; },
    body: function (s) {
      var T = TYPES();
      return '<div class="ap"><span class="ttl t-tm">' + L("গ্রিন হাউস", "Green House") + '</span><span class="mchip" style="margin-right:4px">' + L("অক্টোবর · বন্ধ করুন", "October · Close") + '</span><span class="ib">' + ic("bell") + "</span></div>" +
        '<div class="bd" data-sc="1"><div style="padding:12px 16px 16px"><div class="inkc" style="padding:12px 8px 24px 24px">' +
        '<div style="display:flex;align-items:center"><div style="flex:1;padding:4px 0"><div class="t-tm">' + DAY() + '</div><div style="display:flex;align-items:center;gap:8px"><i style="width:8px;height:8px;border-radius:50%;background:#E8B33A"></i><span class="t-ls acc" style="color:#E8B33A">' + L("আজ", "Today") + " · " + L("গ্রিন হাউস", "Green House") + '</span></div></div><span class="ib">' + ic("left") + '</span><span class="ib">' + ic("right") + "</span></div>" +
        '<div style="padding-right:16px;margin-top:16px"><div class="ov">' + L("আজ মোট মিল", "Meals today") + '</div><div class="t-dl" style="margin-top:4px">' + ml(11) + '</div><div class="t-bm" style="margin-top:4px">' + T.map(function (t, i) { return t + " " + ml([3, 4, 4][i]); }).join(" · ") + "</div>" +
        '<div style="padding:16px 0"><hr></div><div class="ov">' + L("এই মাসের মিল রেট", "Meal rate this month") + '</div><div class="t-ds" style="margin-top:4px">' + mo(RATE) + '</div><div class="t-bm" style="margin-top:4px">' + L(mo(4820) + " ÷ " + dg(100) + " মিল", mo(4820) + " ÷ 100 meals") + "</div>" +
        '<div style="margin-top:24px"><span class="btn2" style="width:100%">' + ic("meals") + L("মিল বসান", "Enter meals") + "</span></div></div></div></div>" +
        '<div style="padding:0 0 0"><div class="car" data-sc="1">' + [["সাব্বির কাল বাজার করবেন", "Sabbir does the bazar tomorrow", "ম্যানেজার", "Rakib"], ["শুক্রবার গ্যাস সিলিন্ডার আসবে", "The gas cylinder arrives on Friday", "ম্যানেজার", "Rakib"], ["ভাড়া ৫ তারিখের মধ্যে", "Rent is due by the 5th", "ম্যানেজার", "Rakib"]].map(function (n, i) {
          return '<div class="nc"><div class="cd"><span class="nic">' + ic(i === 0 ? "pin" : "camp") + '</span><div style="min-width:0;flex:1"><div class="nm1">' + L(n[0], n[1]) + '</div><div class="nm2">' + L("ম্যানেজার রাকিব", "From Rakib, manager") + '</div><div class="t-ls" style="color:#6F6E6A">' + L(dg(12) + " অক্টোবর", dg(12) + " October") + '</div></div><span style="color:#6F6E6A">' + ic("right") + "</span></div></div>";
        }).join("") + '</div><div class="dots">' + [0, 1, 2].map(function (i) { return '<i class="' + (s.page === i ? "on" : "") + '"></i>'; }).join("") + "</div></div>" +
        '<div style="padding:16px"><div class="cd" style="padding:12px;display:flex;align-items:center;gap:12px"><span class="nic" style="background:#F0EFEC;width:40px;height:40px">' + ic("bazar") + '</span><div><div class="t-ts">' + L("কাল বাজার করবেন সাব্বির", "Sabbir does the bazar tomorrow") + '</div><div class="t-bm">' + L("পরশু বাজার করবেন সুমন", "Sumon does the bazar the day after") + "</div></div></div></div></div>" +
        '<div class="fab" aria-hidden="true">' + ic("plus") + "</div>" + nav("home");
    },
    act: function () { return false; },
    play: function (i) {
      var iv = setInterval(function () {
        var c = $(".car", i.el); if (!c || !document.body.contains(c)) return clearInterval(iv);
        var w = c.firstElementChild.offsetWidth, n = Math.round(c.scrollLeft / w);
        c.scrollTo({ left: ((n + 1) % 3) * w, behavior: "smooth" });
      }, 4200);
      i.timers.push(iv);
    }
  };

  // ---------- BAZAR LIST (shopping_screens.dart) ----------
  var BZ = [[["আলু", "Potato"], "2", ["কেজি", "kg"], 110], [["পেঁয়াজ", "Onion"], "1", ["কেজি", "kg"], 85], [["রুই মাছ", "Rui fish"], "1", ["কেজি", "kg"], 320]];
  S.bazar = {
    nav: "bazar",
    init: function () { return { on: [0, 0, 0], sent: 0, shown: 0, press: 0, open: 0, snack: 0 }; },
    total: function (s) { return BZ.reduce(function (t, b, i) { return t + (s.on[i] ? b[3] : 0); }, 0); },
    body: function (s) {
      var n = s.on.reduce(function (a, b) { return a + b; }, 0), editable = !s.sent;
      var chips = [["আলু", "Potato", 1], ["পেঁয়াজ", "Onion", 1], ["রুই মাছ", "Rui fish", 1], ["মুরগি", "Chicken", 0], ["লবণ", "Salt", 0], ["আটা", "Flour", 0]];
      var h = appbar(dg(12) + " " + L("অক্টোবর", "October"), { back: 1, actions: '<span class="ib">' + ic("vert") + "</span>" }) +
        '<div class="bd" data-sc="1"><div class="tags"><span class="tag">' + dg(12) + " " + L("অক্টোবর", "October") + '</span><span class="tag">' + L("তানভীর-এর জন্য", "For Tanvir") + '</span><span class="tag">' + (s.sent ? L("অপেক্ষায়", "Waiting") : L("বাকি", "To do")) + "</span></div>" +
        (s.sent ? '<p class="t-bm" style="padding:0 16px 16px">' + L("পাঠানো হয়েছে। ম্যানেজারের অনুমোদনের অপেক্ষায়।", "Sent. Waiting for the manager to approve it.") + "</p>" : "") +
        (editable ? '<div class="cd plain pk' + (s.open ? " open" : "") + '"><button type="button" class="a pkh" data-a="open" data-k="open">' + ic("list") + "<span>" + L("তালিকা থেকে বাছুন", "Pick from the list") + '</span><span class="ex">' + ic("expand") + '</span></button><div class="pkb"><div><div class="in"><div class="fld">' + ic("search") + "<span>" + L("খুঁজুন বা নতুন নাম লিখুন", "Search or type a new item") + '</span></div><div class="tabs"><span class="on">' + L("বেশি কেনা হয়", "Bought often") + "<i></i></span><span>" + L("চাল-ডাল-তেল", "Rice, lentils, oil") + "<i></i></span><span>" + L("সবজি", "Vegetables") + '<i></i></span></div><div class="chs">' +
          chips.map(function (c) { return '<span class="chip2' + (c[2] ? " on" : "") + '">' + (c[2] ? ic("check") : "") + L(c[0], c[1]) + "</span>"; }).join("") + "</div></div></div></div></div>" : "") +
        '<div style="padding:0 16px"><div class="cd plain rg">' + BZ.map(function (b, i) {
          return '<div class="it' + (s.on[i] ? " on" : "") + '"' + (editable ? ' data-a="t" data-v="' + i + '"' : "") + '><button type="button" class="a cb" role="checkbox" aria-checked="' + !!s.on[i] + '" aria-label="' + L(b[0][0] + " কেনা হয়েছে", "Bought: " + b[0][1]) + '" data-a="t" data-v="' + i + '" data-k="t' + i + '"><i>' + ic("check") + '</i></button><div class="nm"><span class="n1">' + L(b[0][0], b[0][1]) + '</span><span class="qty"><b>' + dg(b[1]) + "</b><span>" + L(b[2][0], b[2][1]) + ic("drop") + '</span></span></div><span class="pr' + (s.on[i] ? "" : " ph2") + '">' + (s.on[i] ? "<em>৳</em>" + dg(b[3]) : "<em>৳</em>" + L("দাম", "Price")) + "</span></div>";
        }).join("") + "</div>" + (editable ? '<div style="margin-top:12px"><span class="btn2 sec" style="width:100%">' + ic("plus") + L("নিজের আইটেম লিখুন", "Write your own item") + "</span></div>" : "") + "</div></div>" +
        '<div class="snack' + (s.snack ? " show" : "") + '">' + L("অন্তত একটি আইটেমে টিক দিন আর দাম লিখুন", "Tick at least one item and write its price") + "</div>" +
        (editable ? '<div class="sbar"><div class="trk"><i style="transform:scaleX(' + (n / 3) + ')"></i></div><div class="r"><div class="l"><div class="tt">' + mo(Math.round(s.shown)) + "</div><small>" + L(dg(3) + "টির মধ্যে " + dg(n) + "টি কেনা হয়েছে", n + " of 3 bought") + '</small></div><button type="button" class="a btn2' + (s.press ? " press" : "") + '" data-a="send" data-k="send">' + ic("send") + L("বাজার হিসেবে পাঠান", "Send as bazar") + "</button></div></div>" : "") +
        nav("bazar");
      return h;
    },
    act: function (s, a, v, i) {
      if (a === "back") { s.on = [0, 0, 0]; s.sent = 0; s.shown = 0; s.open = 0; return true; }
      if (a === "open") { s.open = s.open ? 0 : 1; return true; }
      if (a === "t") { s.on[v] = s.on[v] ? 0 : 1; tween(s, "shown", S.bazar.total(s), 450, function () { render(i); }); return true; }
      if (a === "send") {
        if (!S.bazar.total(s)) { s.snack = 1; later(i, function () { s.snack = 0; render(i); }, 2400); return true; }
        s.sent = 1; return true;
      }
    },
    play: function (i) {
      var s = i.st;
      [0, 1, 2].forEach(function (k) { later(i, function () { s.on[k] = 1; tween(s, "shown", S.bazar.total(s), 500, function () { render(i); }); render(i); }, 800 + k * 800); });
      later(i, function () { s.press = 1; render(i); }, 3500);
      later(i, function () { s.press = 0; s.sent = 1; render(i); }, 3800);
    }
  };

  // ---------- MONEY (money_screen.dart) + bill sheet ----------
  S.money = {
    nav: "money",
    init: function () { return { tab: 0, ver: 0, press: 0, shown: 7300, sheet: -1, stamp: 0, due: 0 }; },
    body: function (s) {
      var order = [0, 3, 2, 1]; // dues first
      function row(i) {
        var c = closing(i, i === 3 && s.ver ? 2000 : undefined);
        return '<button type="button" class="a row" style="width:100%;' + (i === 0 ? "background:#F0EFEC" : "") + '" data-a="bill" data-v="' + i + '" data-k="b' + i + '">' + av(i, i === 0, true) + '<div class="mid"><div class="t-ts" style="display:flex;gap:8px;align-items:center">' + nm(i) + (i === 0 ? '<span class="tag" style="background:#141413;color:#FAFAF9">' + L("আপনি", "You") + "</span>" : "") + "</div><small>" + L(dg(MEAL[i]) + " মিল", MEAL[i] + " meals") + '</small></div><div class="r"><div class="t-ts">' + (c < 0 ? "−" : "+") + mo(Math.abs(c)) + '</div><div class="t-ls" style="color:#5C5B57">' + (c < 0 ? L("বাকি", "Due") : L("অগ্রিম", "Advance")) + "</div></div></button>";
      }
      function drow(name, who, sub, amt, method, extra) {
        return '<div class="row">' + av(who, 0, true) + '<div class="mid"><div class="t-ts">' + name + "</div><small>" + sub + '</small></div><div class="r"><div class="t-ts">' + mo(amt) + '</div><span class="tag">' + method + "</span></div>" + (extra || "") + "</div>";
      }
      var cash = L("ক্যাশ", "Cash"), bk = L("বিকাশ", "bKash"), ng = L("নগদ", "Nagad");
      var D = function (d) { return dg(d) + " " + L("অক্টোবর", "October"); };
      var list;
      if (s.tab === 0) list = '<div style="padding:0 16px"><div class="cd rg">' + order.map(row).join("") + "</div></div>";
      else if (s.tab === 1) list = '<div style="padding:0 16px"><div class="cd rg">' + [["বিদ্যুৎ", "Electricity", "bolt", 1100], ["ওয়াইফাই", "Wi-Fi", "wifi", 700], ["বুয়া", "Cleaner", "user", 800]].map(function (e) {
        return '<div class="row"><span class="av l" style="border-radius:12px;color:#141413">' + ic(e[2], "") + '</span><div class="mid"><div class="t-ts">' + L(e[0], e[1]) + "</div><small>" + D(5) + " · " + L("সমান ভাগে", "Split equally") + '</small></div><div class="t-ts">' + mo(e[3]) + "</div></div>";
      }).join("") + "</div></div>";
      else {
        list = '<div style="display:flex;gap:8px;padding:0 16px 16px"><button type="button" class="a btn2" style="flex:1;padding:0 8px">' + ic("plus") + L("জমা যোগ করুন", "Add deposit") + '</button><span class="btn2 sec" style="flex:1;padding:0 8px">' + ic("minus") + L("ফেরত দিন", "Pay back") + "</span></div>" +
          (s.ver ? "" : '<div class="rs"><div class="hd">' + L("যাচাই বাকি", "TO REVIEW") + '<span class="cnt">1</span></div><div class="cd rv"><div style="display:flex;align-items:center;gap:8px">' + av(3) + '<span class="t-ts" style="flex:1">' + nm(3) + '</span><span class="t-ls" style="color:#5C5B57">' + bk + '</span></div><div class="t-hs">' + mo(1000) + '</div><div class="t-bs" style="color:#6F6E6A">' + D(11) + " · TrxID 8N7A4K2L</div>" +
            '<div class="btns"><span class="btn2 sec" style="flex:2">' + L("বাতিল করুন", "Reject") + '</span><button type="button" class="a btn2 acc' + (s.press ? " press" : "") + '" style="flex:3" data-a="ver" data-k="ver">' + L("যাচাই করুন", "Verify") + "</button></div></div></div>") +
          '<div style="padding:0 16px"><div class="cd rg">' + (s.ver ? drow(nm(3), 3, D(11) + " · TrxID 8N7A4K2L", 1000, bk) : "") + drow(nm(0), 0, D(10) + " · TrxID 3F9K2M", 800, bk) + drow(nm(1), 1, D(9), 2500, cash) + drow(nm(2), 2, D(8) + " · TrxID 5C1D9X", 1500, ng) + drow(nm(0), 0, D(5), 1500, cash) + "</div></div>";
      }
      var sh = s.sheet >= 0 ? s.sheet : 0, c2 = closing(sh, sh === 3 && s.ver ? 2000 : undefined), cr = sh === 3 && s.ver ? 2000 : CREDIT[sh];
      function rl(a, b) { return '<div class="rl"><span class="n t-bm">' + a + '</span><span class="t-bl">' + b + "</span></div>"; }
      return '<div class="ap"><span class="ttl t-tm">' + L("গ্রিন হাউস", "Green House") + '</span><span class="ib">' + ic("cal") + '</span><span class="ib">' + ic("vert") + "</span></div>" +
        '<div class="bd" data-sc="1"><div style="padding:8px 16px 0;display:flex;flex-direction:column;gap:12px"><div class="inkc" style="padding:24px"><div class="ov">' + L("মিল রেট", "Meal rate") + '</div><div class="t-dl" style="margin-top:4px">' + mo(RATE) + '</div><div class="t-bm" style="margin-top:4px">' + mo(4820) + " ÷ " + L(dg(100) + " মিল", "100 meals") + '</div><div style="height:16px"></div><hr><div style="height:12px"></div><div class="ov">' + L("খাবার খরচ", "Food cost") + '</div><div class="t-tl">' + mo(4820) + '</div><div class="t-bs" style="color:#A9A7A2">' + L("বাজার আর মিলে ভাগ হওয়া খরচ মিলিয়ে", "Bazar plus expenses split by meal") + "</div></div>" +
        '<div class="stats"><div class="cd"><div class="ov" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' + L("অন্যান্য খরচ", "Other expenses") + '</div><div class="t-tl" style="margin-top:4px">' + mo(2600) + '</div><div class="t-bs" style="color:#6F6E6A;margin-top:4px">' + L("সবার মধ্যে সমান ভাগে", "Split equally among members") + '</div></div><div class="cd"><div class="ov" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' + L("মোট জমা (ফেরত বাদে)", "Deposits (net of paybacks)") + '</div><div class="t-tl" style="margin-top:4px">' + mo(Math.round(s.shown)) + '</div><div class="t-bs" style="color:#6F6E6A;margin-top:4px">' + L("যাচাই হওয়া জমা মিলিয়ে", "Verified deposits only") + "</div></div></div></div>" +
        '<div style="padding:24px 16px 12px"><div class="seg" id="seg"><i class="th" style="transform:translateX(' + s.tab * 100 + '%)"></i>' + [L("সদস্য", "Members"), L("খরচ", "Expenses"), L("জমা", "Deposits")].map(function (t, i) { return '<button type="button" class="a' + (s.tab === i ? " on" : "") + '" data-a="tab" data-v="' + i + '" data-k="tab' + i + '">' + t + "</button>"; }).join("") + "</div></div>" + list + '<div style="height:24px"></div></div>' +
        nav("money") + '<div class="scrim' + (s.sheet >= 0 ? " show" : "") + '" data-a="close" data-k="scrim"></div>' +
        '<div class="sheet' + (s.sheet >= 0 ? " show" : "") + '"><div class="grab"></div><div class="t-tm" style="margin-bottom:12px">' + L(nm(sh) + "-এর হিসাব", nm(sh) + "'s bill") + '</div><div class="rc">' +
        rl(L("আগের মাস থেকে", "From last month"), "+ " + mo(0)) + rl(L("জমা আর নিজের পকেট থেকে খরচ", "Deposits and own-pocket spending"), "+ " + mo(cr)) + rl(L("খাবার খরচ (" + dg(MEAL[sh]) + " মিল × " + mo(RATE) + ")", "Food (" + MEAL[sh] + " meals × " + mo(RATE) + ")"), "− " + mo(MEAL[sh] * RATE)) + rl(L("অন্যান্য খরচের ভাগ", "Share of other expenses"), "− " + mo(EXTRA)) +
        '<div class="dash"></div><div class="rl"><span class="n t-ts">' + L("এখনকার হিসাব", "Balance now") + " · " + (c2 < 0 ? L("বাকি", "Due") : L("অগ্রিম", "Advance")) + '</span><span class="t-tl" style="color:' + (c2 < 0 ? "#B42318" : "#067647") + '">' + (c2 < 0 ? "−" : "+") + mo(Math.abs(c2)) + '</span></div><span class="stamp' + (s.sheet >= 0 ? " show" : "") + '" style="' + (c2 < 0 ? "" : "color:#067647;border-color:#067647") + '">' + (c2 < 0 ? L("বাকি", "Due") : L("পরিশোধিত", "Paid")) + "</span></div></div>";
    },
    act: function (s, a, v, i) {
      if (a === "tab") { s.tab = +v; var bd = $(".bd", i.el); if (bd && !RM) bd.scrollTo({ top: s.tab === 2 ? 296 : 0, behavior: "smooth" }); else if (bd) bd.scrollTop = s.tab === 2 ? 296 : 0; return true; }
      if (a === "ver") { s.ver = 1; tween(s, "shown", 8300, 700, function () { render(i); }); return true; }
      if (a === "bill") { s.sheet = +v; return true; }
      if (a === "close") { s.sheet = -1; return true; }
    },
    play: function (i) {
      var s = i.st, bd = $(".bd", i.el);
      later(i, function () { s.tab = 2; if (bd) bd.scrollTo({ top: 296, behavior: "smooth" }); render(i); }, 900);
      later(i, function () { s.press = 1; render(i); }, 2300);
      later(i, function () { s.press = 0; S.money.act(s, "ver", 0, i); render(i); }, 2550);
    }
  };

  // bill = the same Money screen with Rakib's bill sheet open
  S.bill = {
    nav: "money",
    init: function () { var s = S.money.init(); return s; },
    body: function (s) { return S.money.body(s); },
    act: function (s, a, v, i) { return S.money.act(s, a, v, i); },
    play: function (i) {
      var s = i.st; s.sheet = 0; render(i);
    }
  };

  // ---------- engine ----------
  function later(i, fn, ms) { i.timers.push(setTimeout(fn, ms)); }
  function render(i) {
    morph(i.dp, i.def.body(i.st));
    if (i.def === S.home) {
      var car = $(".car", i.dp);
      if (car && !car._b) { car._b = 1; car.addEventListener("scroll", function () { var w = car.firstElementChild.offsetWidth, p = Math.min(2, Math.round(car.scrollLeft / w)); if (p !== i.st.page) { i.st.page = p; render(i); } }, { passive: true }); }
    }
  }
  function mountLayer(el, kind) {
    var i = { el: el, def: S[kind], st: S[kind].init(), timers: [], touched: 0, played: 0, kind: kind };
    el.innerHTML = '<div class="sb"><span>9:41</span><i class="notch"></i><svg viewBox="0 0 16 11" aria-hidden="true"><path d="M0 8h2v3H0zM4 6h2v5H4zM8 3h2v8H8zM12 0h2v11h-2z"/></svg></div><div class="dp"></div>';
    i.dp = $(".dp", el);
    render(i);
    el.addEventListener("click", function (e) {
      var t = e.target.closest("[data-a]"); if (!t || !el.contains(t)) return;
      i.touched = 1; i.timers.forEach(function (x) { clearTimeout(x); clearInterval(x); }); i.timers = [];
      if (i.def.act(i.st, t.dataset.a, t.dataset.v, i) !== false) render(i);
    });
    i.play = function () { if (i.played || i.touched || RM) return; i.played = 1; i.def.play(i); };
    all.push(i);
    return i;
  }
  function mountPhone(host) {
    var kinds = host.dataset.phone.split(","), multi = kinds.length > 1;
    var ph = document.createElement("div");
    ph.className = "ph" + (multi ? " multi" : "");
    ph.setAttribute("role", "group");
    ph.setAttribute("aria-label", "Meal Bazar app preview with example data");
    var layers = kinds.map(function (k, n) {
      var l = document.createElement("div"); l.className = "scr" + (n === 0 ? " on" : ""); if (multi && n > 0) l.setAttribute("inert", ""); ph.appendChild(l); return mountLayer(l, k);
    });
    host.appendChild(ph);
    var o = { host: host, layers: layers, active: 0 };
    phones.push(o);
    return o;
  }
  $$("[data-phone]").forEach(mountPhone);

  // crops for the "day in your mess" cards: real components, scaled
  var CROPS = {
    meals: function () { var T = TYPES(); return '<div class="cd" style="padding:12px"><div class="gr" style="border:0;height:56px"><div class="gc" style="width:112px"><button class="a sbtn" tabindex="-1"><i>' + ic("minus") + '</i></button><span class="gv">1</span><button class="a sbtn" tabindex="-1"><i>' + ic("plus") + '</i></button></div><div style="flex:1"><div class="ov">' + nm(0) + '</div><div class="t-bs" style="color:#6F6E6A">' + T[1] + "</div></div></div></div>"; },
    bazar: function () { return '<div class="cd plain rg">' + BZ.slice(0, 2).map(function (b) { return '<div class="it"><span class="cb"><i>' + ic("check") + '</i></span><div class="nm"><span class="n1">' + L(b[0][0], b[0][1]) + '</span><span class="qty"><b>' + dg(b[1]) + "</b><span>" + L(b[2][0], b[2][1]) + ic("drop") + '</span></span></div><span class="pr ph2"><em>৳</em>' + L("দাম", "Price") + "</span></div>"; }).join("") + "</div>"; },
    review: function () { return '<div class="cd" style="padding:12px"><div style="display:flex;align-items:center;gap:8px">' + av(3) + '<span class="t-ts" style="flex:1">' + nm(3) + '</span><span class="t-ls">' + L("বিকাশ", "bKash") + '</span></div><div class="t-hs">' + mo(1000) + '</div><div class="t-bs" style="color:#6F6E6A">TrxID 8N7A4K2L</div><div style="display:flex;gap:8px;margin-top:8px"><span class="btn2 sec" style="flex:2;padding:0">' + L("বাতিল করুন", "Reject") + '</span><span class="btn2 acc" style="flex:3;padding:0">' + L("যাচাই করুন", "Verify") + "</span></div></div>"; },
    notice: function () { return '<div class="cd" style="padding:12px;display:flex;gap:12px;align-items:center;margin-bottom:12px"><span class="nic">' + ic("camp") + '</span><div><div class="nm1">' + L("শুক্রবার গ্যাস সিলিন্ডার আসবে", "The gas cylinder arrives on Friday") + '</div><div class="nm2">' + L("ম্যানেজার রাকিব", "From Rakib, manager") + '</div></div></div><div class="cd" style="padding:12px;display:flex;gap:12px;align-items:center"><span class="nic" style="background:#F0EFEC">' + ic("bazar") + '</span><div class="t-ts">' + L("কাল বাজার করবেন সাব্বির", "Sabbir does the bazar tomorrow") + "</div></div>"; }
  };
  function drawCrops() { $$("[data-crop]").forEach(function (el) { el.innerHTML = '<div class="dp">' + CROPS[el.dataset.crop]() + "</div>"; }); }

  // ---------- language ----------
  var page = document.body;
  $$("[data-bn]").forEach(function (el) { el.dataset.en = el.innerHTML; });
  $$("[data-bn-label]").forEach(function (el) { el.dataset.enLabel = el.getAttribute("aria-label"); });
  $$("[data-bn-alt]").forEach(function (el) { el.dataset.enAlt = el.getAttribute("alt"); });
  var META = { en: ["Meal Bazar: run your whole mess from your phone", "Meals, bazar, deposits and the month-end bill in one shared ledger. Works offline, in Bangla and English. Free Android APK."], bn: ["Meal Bazar: পুরো মেসের হিসাব ফোনেই", "মিল, বাজার, জমা আর মাস শেষের বিল, সব এক খাতায়। নেট ছাড়াও চলে, বাংলা ও ইংরেজিতে। অ্যান্ড্রয়েডের জন্য বিনামূল্যে APK।"] };
  function split(el) {
    var n = 0;
    (function walk(p) {
      Array.prototype.slice.call(p.childNodes).forEach(function (c) {
        if (c.nodeType === 3) {
          var f = document.createDocumentFragment();
          c.textContent.split(/(\s+)/).forEach(function (t) {
            if (!t) return;
            if (/^\s+$/.test(t)) f.appendChild(document.createTextNode(t));
            else { var w = document.createElement("span"), s = document.createElement("span"); w.className = "w"; s.textContent = t; s.style.animationDelay = (0.1 + n++ * 0.07) + "s"; w.appendChild(s); f.appendChild(w); }
          });
          p.replaceChild(f, c);
        } else if (c.nodeType === 1) walk(c);
      });
    })(el);
  }
  function apply(l) {
    lang = l;
    document.documentElement.lang = l;
    $$("[data-bn]").forEach(function (el) { el.innerHTML = l === "bn" ? el.getAttribute("data-bn") : el.dataset.en; });
    $$("[data-bn-label]").forEach(function (el) { el.setAttribute("aria-label", l === "bn" ? el.getAttribute("data-bn-label") : el.dataset.enLabel); });
    $$("[data-bn-alt]").forEach(function (el) { el.setAttribute("alt", l === "bn" ? el.getAttribute("data-bn-alt") : el.dataset.enAlt); });
    $$("[data-lang]").forEach(function (b) { b.setAttribute("aria-pressed", String(b.dataset.lang === l)); });
    if (document.body.dataset.legal) document.title = l === "bn" ? document.body.dataset.titleBn : document.body.dataset.titleEn;
    else {
      document.title = META[l][0];
      [['meta[name="description"]', 1], ['meta[property="og:title"]', 0], ['meta[property="og:description"]', 1]].forEach(function (m) { var el = $(m[0]); if (el) el.content = META[l][m[1]]; });
    }
    all.forEach(render);
    drawCrops();
    drawSw();
    var h1 = $("#h1"); if (h1 && !RM) { h1.classList.remove("rise"); split(h1); void h1.offsetWidth; h1.classList.add("rise"); }
    var ol = $("#tickol"); if (ol) { $$("[data-clone]", ol).forEach(function (x) { x.remove(); }); Array.prototype.slice.call(ol.children).forEach(function (li) { var c = li.cloneNode(true); c.setAttribute("data-clone", ""); c.setAttribute("aria-hidden", "true"); ol.appendChild(c); }); }
    document.documentElement.classList.add("ready");
  }
  function setLang(l, first) {
    if (!first && l === lang) return;
    if (first || RM) apply(l);
    else { page.classList.add("fade"); setTimeout(function () { apply(l); page.classList.remove("fade"); }, 170); }
  }
  $$("[data-lang]").forEach(function (b) {
    b.addEventListener("click", function () { setLang(b.dataset.lang); try { localStorage.setItem("mb-lang", b.dataset.lang); } catch (e) {} });
  });
  var start = window.__mbLang || "en";

  // ---------- offline switch (drives the Meals phone in the offline section) ----------
  var off = phones.filter(function (p) { return p.host.id === "offPh"; })[0], sw = $("#sw"), offline = 0;
  function drawSw() { if (!sw) return; sw.setAttribute("aria-checked", String(!!offline)); $("#sw-l").textContent = offline ? L("নেটওয়ার্ক বন্ধ", "Network off") : L("নেটওয়ার্ক চালু", "Network on"); }
  if (sw) sw.addEventListener("click", function () {
    var i = off.layers[0], s = i.st; offline = offline ? 0 : 1; i.touched = 1;
    s.off = offline; if (offline) s.q = 0; render(i); drawSw();
  });

  // ---------- scroll: reveals, plays, story, parallax ----------
  var obs = "IntersectionObserver" in window;
  if (!RM && obs) {
    var io = new IntersectionObserver(function (es) { es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.remove("pre"); io.unobserve(e.target); } }); }, { threshold: 0.12 });
    $$("[data-rv]").forEach(function (el) {
      if (el.getBoundingClientRect().top > innerHeight * 0.9) { el.classList.add("pre"); io.observe(el); }
      if (el.classList.contains("stag")) Array.prototype.forEach.call(el.children, function (c, n) { c.style.setProperty("--i", n); });
    });
  }
  var stage = phones.filter(function (p) { return p.host.hasAttribute("data-stage"); })[0];
  function setActive(n) {
    if (!stage || (stage.active === n && stage.layers[n].played)) return;
    stage.active = n;
    stage.layers.forEach(function (l, k) { l.el.classList.toggle("on", k === n); if (k === n) l.el.removeAttribute("inert"); else l.el.setAttribute("inert", ""); });
    $$(".step").forEach(function (s, k) { s.classList.toggle("on", k === n); });
    if (stage.host.offsetParent) stage.layers[n].play();
  }
  if (obs) {
    var sio = new IntersectionObserver(function (es) { es.forEach(function (e) { if (e.isIntersecting) setActive(+e.target.dataset.step); }); }, { rootMargin: "-45% 0px -45% 0px" });
    $$(".step").forEach(function (s) { sio.observe(s); });
    var pio = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { phones.forEach(function (p) { if (p.host === e.target && p.host.offsetParent) p.layers[0].play(); }); pio.unobserve(e.target); } });
    }, { threshold: 0.55 });
    phones.forEach(function (p) { if (p.host.dataset.play === "view") pio.observe(p.host); });
  }
  phones.forEach(function (p) { if (p.host.dataset.play === "load") setTimeout(function () { p.layers[0].play(); }, 1500); });

  var hero = $("#hero"), tick = 0;
  if (!RM && hero) {
    addEventListener("scroll", function () {
      if (tick) return; tick = 1;
      requestAnimationFrame(function () { tick = 0; var y = scrollY; if (y < hero.offsetHeight * 1.3) hero.style.setProperty("--sy", y); });
    }, { passive: true });
  }

  setLang(start, true);
})();
