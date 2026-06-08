"use strict";

// Overcharge Lv10 = +24%. RA rounds (not floor).
const OVERCHARGE_MULT = 1.24;
const STORAGE_KEY = "rolg.calc.state.v3";

const ITEMS = window.ITEMS || [];
const MOBS = window.MOBS || [];

const itemById = new Map(ITEMS.map((it) => [it.id, it]));
const mobById = new Map(MOBS.map((m) => [m.id, m]));

// ---------- State ----------

const state = {
  buffs: { vip: false, kafra: false, premium: false, catfruit: false },
  gum: 0,            // % drop bonus
  stamina: 1,        // 1.0 or 0.3
  mobs: [],          // [{ uid, mobId, kpm, drops: { itemId: { checked, realQty } } }]
  timeMode: "range",
  timeStart: "",
  timeEnd: "",
  timeHours: "",
};

const BUFF_PCT = { vip: 15, kafra: 50, premium: 20, catfruit: 15 };

function save() {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch (_) {}
}
function load() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    const p = JSON.parse(raw);
    if (p && typeof p === "object") Object.assign(state, p);
  } catch (_) {}
}
function uid() { return "m" + Math.random().toString(36).slice(2, 10); }

// ---------- Format ----------

const nfZ = new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 });
const nfDec = new Intl.NumberFormat("en-US", { maximumFractionDigits: 1 });
const nfDec2 = new Intl.NumberFormat("en-US", { maximumFractionDigits: 2 });

function fmtZeny(n) {
  if (!isFinite(n) || n <= 0) return "0 z";
  return nfZ.format(Math.round(n)) + " z";
}
function fmtPct(n) { return nfDec.format(n) + "%"; }
function fmtDuration(hours) {
  if (!isFinite(hours) || hours <= 0) return "—";
  const totalMin = Math.round(hours * 60);
  const h = Math.floor(totalMin / 60);
  const m = totalMin % 60;
  if (h === 0) return `${m} min`;
  if (m === 0) return `${h} h`;
  return `${h} h ${m} min`;
}

// ---------- Calc ----------

function priceOC(itemId) {
  const it = itemById.get(itemId);
  if (!it) return 0;
  return Math.round(it.price * OVERCHARGE_MULT);
}

function buffsTotalPct() {
  let s = 0;
  for (const k of Object.keys(BUFF_PCT)) if (state.buffs[k]) s += BUFF_PCT[k];
  s += Number(state.gum) || 0;
  return s;
}
function dropMultiplier() {
  return (1 + buffsTotalPct() / 100) * (Number(state.stamina) || 1);
}

function computeHours() {
  if (state.timeMode === "direct") {
    const h = parseFloat((state.timeHours || "").toString().replace(",", "."));
    return isFinite(h) && h > 0 ? h : 0;
  }
  const s = parseTime(state.timeStart);
  const e = parseTime(state.timeEnd);
  if (s == null || e == null) return 0;
  let diff = e - s;
  if (diff <= 0) diff += 24 * 60;
  return diff / 60;
}
function parseTime(str) {
  if (!str || typeof str !== "string") return null;
  const m = /^(\d{1,2}):(\d{2})$/.exec(str);
  if (!m) return null;
  const h = +m[1], min = +m[2];
  if (h < 0 || h > 23 || min < 0 || min > 59) return null;
  return h * 60 + min;
}

function totalsForMob(mobEntry) {
  const mob = mobById.get(mobEntry.mobId);
  if (!mob) return { expected: 0, realized: 0, kills: 0 };
  const hours = computeHours();
  const minutes = hours * 60;
  const kpm = Number(mobEntry.kpm) || 0;
  const kills = kpm * minutes;
  const mult = dropMultiplier();
  let expected = 0, realized = 0;
  for (const drop of mob.drops) {
    const entry = mobEntry.drops[drop.itemId] || { checked: !drop.isCard, realQty: 0 };
    if (!entry.checked) continue;
    const p = priceOC(drop.itemId);
    const expQty = kills * (drop.rate / 100) * mult;
    expected += expQty * p;
    const rq = Number(entry.realQty) || 0;
    if (rq > 0) realized += rq * p;
  }
  return { expected, realized, kills };
}
function grandTotals() {
  let exp = 0, real = 0;
  for (const me of state.mobs) {
    const t = totalsForMob(me);
    exp += t.expected;
    real += t.realized;
  }
  return { exp, real };
}

// ---------- Render ----------

const $ = (s) => document.querySelector(s);
const $$ = (s) => document.querySelectorAll(s);

function mobName(mob) { return mob.en; }
function itemName(it) { return it.en; }

function renderMobPicker() {
  const sel = $("#mobPicker");
  sel.replaceChildren();
  for (const m of MOBS) {
    const opt = document.createElement("option");
    opt.value = m.id;
    opt.textContent = mobName(m);
    sel.appendChild(opt);
  }
}

function renderMobs() {
  const ul = $("#mobs");
  ul.replaceChildren();
  if (state.mobs.length === 0) {
    const li = document.createElement("li");
    li.className = "mob-empty";
    li.textContent = "No mobs added yet.";
    ul.appendChild(li);
    return;
  }
  for (const me of state.mobs) {
    ul.appendChild(mobEl(me));
  }
}

function mobEl(me) {
  const mob = mobById.get(me.mobId);
  const li = document.createElement("li");
  li.className = "mob";
  if (!mob) {
    li.textContent = `(unknown mob: ${me.mobId})`;
    return li;
  }

  const head = document.createElement("div");
  head.className = "mob-head";

  const title = document.createElement("h3");
  title.textContent = mobName(mob);

  const kpmWrap = document.createElement("label");
  kpmWrap.className = "kpm";
  const kpmLabel = document.createElement("span");
  kpmLabel.textContent = "Kills/min";
  const kpmInput = document.createElement("input");
  kpmInput.type = "number";
  kpmInput.min = "0";
  kpmInput.step = "0.1";
  kpmInput.inputMode = "decimal";
  kpmInput.placeholder = "0";
  kpmInput.value = me.kpm || "";
  kpmInput.addEventListener("input", () => {
    me.kpm = parseFloat(kpmInput.value.replace(",", ".")) || 0;
    updateMobBody(li, me);
    updateResults();
    save();
  });
  kpmWrap.append(kpmLabel, kpmInput);

  const removeBtn = document.createElement("button");
  removeBtn.type = "button";
  removeBtn.className = "icon-btn";
  removeBtn.setAttribute("aria-label", "Remove mob");
  removeBtn.textContent = "×";
  removeBtn.addEventListener("click", () => {
    state.mobs = state.mobs.filter((m) => m.uid !== me.uid);
    renderMobs();
    tagMobLis();
    updateResults();
    save();
  });

  head.append(title, kpmWrap, removeBtn);
  li.appendChild(head);

  const killsInfo = document.createElement("div");
  killsInfo.className = "mob-kills";
  li.appendChild(killsInfo);

  const dropsEl = document.createElement("div");
  dropsEl.className = "drops";
  li.appendChild(dropsEl);

  for (const drop of mob.drops) {
    dropsEl.appendChild(dropEl(me, drop));
  }

  updateMobBody(li, me);
  return li;
}

function dropEl(me, drop) {
  const it = itemById.get(drop.itemId);
  const entry = me.drops[drop.itemId] || (me.drops[drop.itemId] = { checked: !drop.isCard, realQty: 0 });

  const row = document.createElement("div");
  row.className = "drop";
  if (drop.isCard) row.classList.add("drop-card");

  const top = document.createElement("label");
  top.className = "drop-top";
  const cb = document.createElement("input");
  cb.type = "checkbox";
  cb.checked = !!entry.checked;
  cb.addEventListener("change", () => {
    entry.checked = cb.checked;
    row.classList.toggle("is-off", !entry.checked);
    updateDropBody(row, me, drop);
    updateMobBody(row.closest(".mob"), me);
    updateResults();
    save();
  });
  const name = document.createElement("span");
  name.className = "drop-name";
  name.textContent = it ? itemName(it) : `id ${drop.itemId}`;
  const rate = document.createElement("span");
  rate.className = "drop-rate";
  rate.textContent = fmtPct(drop.rate);
  top.append(cb, name, rate);

  const body = document.createElement("div");
  body.className = "drop-body";

  const expLine = document.createElement("div");
  expLine.className = "drop-line";
  const expLab = document.createElement("span"); expLab.textContent = "Exp:";
  const expVal = document.createElement("span"); expVal.className = "drop-val";
  expLine.append(expLab, expVal);

  const realLine = document.createElement("div");
  realLine.className = "drop-line";
  const realLab = document.createElement("span"); realLab.textContent = "Real:";
  const realInput = document.createElement("input");
  realInput.type = "number";
  realInput.min = "0";
  realInput.step = "1";
  realInput.inputMode = "numeric";
  realInput.className = "real-qty";
  realInput.placeholder = "qty";
  realInput.value = entry.realQty || "";
  realInput.addEventListener("input", () => {
    entry.realQty = parseInt(realInput.value, 10) || 0;
    updateDropBody(row, me, drop);
    updateMobBody(row.closest(".mob"), me);
    updateResults();
    save();
  });
  const realVal = document.createElement("span"); realVal.className = "drop-val";
  realLine.append(realLab, realInput, realVal);

  body.append(expLine, realLine);
  row.append(top, body);

  if (!entry.checked) row.classList.add("is-off");
  updateDropBody(row, me, drop);
  return row;
}

function updateDropBody(row, me, drop) {
  const p = priceOC(drop.itemId);
  const entry = me.drops[drop.itemId] || { checked: !drop.isCard, realQty: 0 };
  const hours = computeHours();
  const kpm = Number(me.kpm) || 0;
  const kills = kpm * hours * 60;
  const mult = dropMultiplier();

  const expQty = entry.checked ? kills * (drop.rate / 100) * mult : 0;
  const expZ = expQty * p;
  const realQty = entry.checked ? (Number(entry.realQty) || 0) : 0;
  const realZ = realQty * p;

  const lines = row.querySelectorAll(".drop-val");
  lines[0].textContent = expQty > 0
    ? `${nfDec.format(expQty)} × ${fmtZeny(p)} = ${fmtZeny(expZ)}`
    : `0 × ${fmtZeny(p)}`;
  lines[1].textContent = realQty > 0
    ? `× ${fmtZeny(p)} = ${fmtZeny(realZ)}`
    : `× ${fmtZeny(p)}`;
}

function updateMobBody(li, me) {
  if (!li) return;
  const info = li.querySelector(".mob-kills");
  if (!info) return;
  const hours = computeHours();
  const kpm = Number(me.kpm) || 0;
  const kills = kpm * hours * 60;
  const t = totalsForMob(me);
  if (hours > 0 && kpm > 0) {
    info.innerHTML = `${nfZ.format(Math.round(kills))} kills · expected <b>${fmtZeny(t.expected)}</b> · realized <b>${fmtZeny(t.realized)}</b>`;
  } else {
    info.innerHTML = `<span class="dim">Set time and KPM to see kills/expected.</span>`;
  }
  const mob = mobById.get(me.mobId);
  if (mob) {
    const rows = li.querySelectorAll(".drop");
    mob.drops.forEach((drop, idx) => {
      if (rows[idx]) updateDropBody(rows[idx], me, drop);
    });
  }
}

function updateResults() {
  const hours = computeHours();
  const { exp, real } = grandTotals();
  $("#rTime").textContent = fmtDuration(hours);
  $("#rExpTotal").textContent = fmtZeny(exp);
  $("#rRealTotal").textContent = fmtZeny(real);
  $("#rExpPerHour").textContent = hours > 0 && exp > 0 ? fmtZeny(exp / hours) + "/h" : "—";
  $("#rRealPerHour").textContent = hours > 0 && real > 0 ? fmtZeny(real / hours) + "/h" : "—";
  for (const li of $$(".mob")) {
    const uidKey = li.dataset.uid;
    const me = state.mobs.find((m) => m.uid === uidKey);
    if (me) updateMobBody(li, me);
  }
  $("#cfgSum").textContent = `Effective multiplier: ×${nfDec2.format(dropMultiplier())} (buffs +${buffsTotalPct()}%)`;
}

// ---------- Time / Config UI ----------

function syncTimeUI() {
  $("#timeRange").classList.toggle("is-hidden", state.timeMode !== "range");
  $("#timeDirect").classList.toggle("is-hidden", state.timeMode !== "direct");
  $("#timeStart").value = state.timeStart || "";
  $("#timeEnd").value = state.timeEnd || "";
  $("#timeHours").value = state.timeHours || "";
  for (const r of $$('input[name="timeMode"]')) r.checked = r.value === state.timeMode;
}
function syncConfigUI() {
  for (const cb of $$('.buffs input[type="checkbox"]')) {
    cb.checked = !!state.buffs[cb.dataset.buff];
  }
  $("#gum").value = String(state.gum);
  $("#stamina").value = String(state.stamina);
}

// ---------- Copy summary ----------

function buildSummary() {
  if (state.mobs.length === 0) return null;
  const hours = computeHours();
  const mult = dropMultiplier();
  const buffPct = buffsTotalPct();

  const lines = [];
  lines.push("Landverse Farming Calc — Overcharge Lv10");
  if (buffPct > 0 || state.stamina !== 1) {
    const parts = [];
    if (buffPct > 0) parts.push(`buffs +${buffPct}%`);
    if (Number(state.stamina) === 0.3) parts.push("no stamina");
    lines.push(`Modifier: ×${nfDec2.format(mult)} (${parts.join(", ")})`);
  }
  lines.push("─".repeat(38));

  let totExp = 0, totReal = 0;
  for (const me of state.mobs) {
    const mob = mobById.get(me.mobId);
    if (!mob) continue;
    const t = totalsForMob(me);
    const kpm = Number(me.kpm) || 0;
    const kills = kpm * hours * 60;
    totExp += t.expected;
    totReal += t.realized;
    lines.push(`${mobName(mob)} · ${kpm}/min · ${nfZ.format(Math.round(kills))} kills`);
    for (const drop of mob.drops) {
      const e = me.drops[drop.itemId];
      if (!e || !e.checked) continue;
      const it = itemById.get(drop.itemId);
      const p = priceOC(drop.itemId);
      const expQty = kills * (drop.rate / 100) * mult;
      const real = Number(e.realQty) || 0;
      const name = it ? itemName(it) : `#${drop.itemId}`;
      lines.push(`  ${name} ${fmtPct(drop.rate)} · exp ${nfDec.format(expQty)} (${fmtZeny(expQty * p)}) · real ${real} (${fmtZeny(real * p)})`);
    }
    lines.push(`  ↳ Subtotal: exp ${fmtZeny(t.expected)} · real ${fmtZeny(t.realized)}`);
  }
  lines.push("─".repeat(38));
  lines.push(`Time:     ${fmtDuration(hours)}`);
  lines.push(`Expected: ${fmtZeny(totExp)}${hours > 0 ? ` (${fmtZeny(totExp / hours)}/h)` : ""}`);
  lines.push(`Realized: ${fmtZeny(totReal)}${hours > 0 ? ` (${fmtZeny(totReal / hours)}/h)` : ""}`);

  return "```\n" + lines.join("\n") + "\n```";
}

async function copySummary() {
  const text = buildSummary();
  const status = $("#copyStatus");
  if (!text) {
    status.style.color = "var(--danger)";
    status.textContent = "Add at least one mob.";
    setTimeout(() => (status.textContent = ""), 2500);
    return;
  }
  try {
    await navigator.clipboard.writeText(text);
  } catch (_) {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand("copy"); } catch (_) {}
    document.body.removeChild(ta);
  }
  status.style.color = "var(--success)";
  status.textContent = "Summary copied! Paste in Discord.";
  setTimeout(() => (status.textContent = ""), 2500);
}

// ---------- Wire-up ----------

function addMob(mobId) {
  const mob = mobById.get(mobId);
  if (!mob) return;
  const drops = {};
  for (const d of mob.drops) drops[d.itemId] = { checked: !d.isCard, realQty: 0 };
  state.mobs.push({ uid: uid(), mobId, kpm: 0, drops });
  renderMobs();
  tagMobLis();
  updateResults();
  save();
}

function tagMobLis() {
  const lis = $$(".mob");
  for (let i = 0; i < lis.length; i++) {
    if (state.mobs[i]) lis[i].dataset.uid = state.mobs[i].uid;
  }
}

function bind() {
  $("#addMob").addEventListener("click", () => {
    addMob($("#mobPicker").value);
  });

  for (const cb of $$('.buffs input[type="checkbox"]')) {
    cb.addEventListener("change", () => {
      state.buffs[cb.dataset.buff] = cb.checked;
      updateResults();
      save();
    });
  }
  $("#gum").addEventListener("change", (e) => {
    state.gum = parseInt(e.target.value, 10) || 0;
    updateResults();
    save();
  });
  $("#stamina").addEventListener("change", (e) => {
    state.stamina = parseFloat(e.target.value) || 1;
    updateResults();
    save();
  });

  for (const r of $$('input[name="timeMode"]')) {
    r.addEventListener("change", () => {
      state.timeMode = r.value;
      syncTimeUI();
      updateResults();
      save();
    });
  }
  $("#timeStart").addEventListener("input", (e) => { state.timeStart = e.target.value; updateResults(); save(); });
  $("#timeEnd").addEventListener("input", (e) => { state.timeEnd = e.target.value; updateResults(); save(); });
  $("#timeHours").addEventListener("input", (e) => { state.timeHours = e.target.value; updateResults(); save(); });

  $("#btnCopy").addEventListener("click", copySummary);
  $("#btnReset").addEventListener("click", () => {
    if (!confirm("Clear all mobs and times?")) return;
    state.mobs = [];
    state.timeStart = ""; state.timeEnd = ""; state.timeHours = "";
    renderMobs();
    syncTimeUI();
    updateResults();
    save();
  });
}

// ---------- Init ----------

load();
renderMobPicker();
renderMobs();
tagMobLis();
syncConfigUI();
syncTimeUI();
updateResults();
bind();
