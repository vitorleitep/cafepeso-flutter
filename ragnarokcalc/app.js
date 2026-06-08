"use strict";

// Overcharge Lv10 = +24%. RA rounds (not floor).
const OVERCHARGE_MULT = 1.24;
const STORAGE_KEY = "rolg.calc.state.v3";
const SESSIONS_KEY = "rolg.calc.sessions.v1";

const ITEMS = window.ITEMS || [];
const MOBS = window.MOBS || [];

const itemById = new Map(ITEMS.map((it) => [it.id, it]));
const mobById = new Map(MOBS.map((m) => [m.id, m]));

// ---------- State ----------

const state = {
  playerNick: "",
  playerClass: "",
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

// ---------- Sessions (histórico) ----------

let sessions = [];

function loadSessions() {
  try {
    const raw = localStorage.getItem(SESSIONS_KEY);
    if (!raw) return;
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed?.sessions)) sessions = parsed.sessions;
  } catch (_) {}
}
function saveSessions() {
  try { localStorage.setItem(SESSIONS_KEY, JSON.stringify({ sessions })); } catch (_) {}
}

// ---------- Format ----------

const nfZ = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 });
const nfDec = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 1 });
const nfDec2 = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 2 });
const nfPct = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 2 });

function fmtZeny(n) {
  if (!isFinite(n) || n <= 0) return "0 z";
  return nfZ.format(Math.round(n)) + " z";
}
function fmtPct(n) { return nfPct.format(n) + "%"; }
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
    li.textContent = "Nenhum mob adicionado ainda.";
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
    li.textContent = `(mob desconhecido: ${me.mobId})`;
    return li;
  }

  const head = document.createElement("div");
  head.className = "mob-head";

  const title = document.createElement("h3");
  title.textContent = mobName(mob);

  const kpmWrap = document.createElement("label");
  kpmWrap.className = "kpm";
  const kpmLabel = document.createElement("span");
  kpmLabel.textContent = "Mortes/min";
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
  removeBtn.setAttribute("aria-label", "Remover mob");
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
  const expLab = document.createElement("span"); expLab.textContent = "Esp:";
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
  realInput.placeholder = "qtd";
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
    info.innerHTML = `${nfZ.format(Math.round(kills))} mortes · esperado <b>${fmtZeny(t.expected)}</b> · realizado <b>${fmtZeny(t.realized)}</b>`;
  } else {
    info.innerHTML = `<span class="dim">Defina o tempo e a taxa pra ver mortes/esperado.</span>`;
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
  $("#cfgSum").textContent = `Multiplicador efetivo: ×${nfDec2.format(dropMultiplier())} (buffs +${buffsTotalPct()}%)`;
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
function syncPlayerUI() {
  $("#playerNick").value = state.playerNick || "";
  $("#playerClass").value = state.playerClass || "";
}

// ---------- Copy summary ----------

function buildSummary() {
  if (state.mobs.length === 0) return null;
  const hours = computeHours();
  const mult = dropMultiplier();
  const buffPct = buffsTotalPct();

  const lines = [];
  lines.push("Calculadora Landverse — Super Faturar Lv10");
  const nick = (state.playerNick || "").trim();
  const cls = (state.playerClass || "").trim();
  if (nick || cls) {
    lines.push(`Jogador: ${nick || "?"}${cls ? ` (${cls})` : ""}`);
  }
  if (buffPct > 0 || state.stamina !== 1) {
    const parts = [];
    if (buffPct > 0) parts.push(`buffs +${buffPct}%`);
    if (Number(state.stamina) === 0.3) parts.push("sem stamina");
    lines.push(`Modificador: ×${nfDec2.format(mult)} (${parts.join(", ")})`);
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
    lines.push(`${mobName(mob)} · ${nfDec.format(kpm)}/min · ${nfZ.format(Math.round(kills))} mortes`);
    for (const drop of mob.drops) {
      const e = me.drops[drop.itemId];
      if (!e || !e.checked) continue;
      const it = itemById.get(drop.itemId);
      const p = priceOC(drop.itemId);
      const expQty = kills * (drop.rate / 100) * mult;
      const real = Number(e.realQty) || 0;
      const name = it ? itemName(it) : `#${drop.itemId}`;
      lines.push(`  ${name} ${fmtPct(drop.rate)} · esp ${nfDec.format(expQty)} (${fmtZeny(expQty * p)}) · real ${real} (${fmtZeny(real * p)})`);
    }
    lines.push(`  ↳ Subtotal: esp ${fmtZeny(t.expected)} · real ${fmtZeny(t.realized)}`);
  }
  lines.push("─".repeat(38));
  lines.push(`Tempo:     ${fmtDuration(hours)}`);
  lines.push(`Esperado:  ${fmtZeny(totExp)}${hours > 0 ? ` (${fmtZeny(totExp / hours)}/h)` : ""}`);
  lines.push(`Realizado: ${fmtZeny(totReal)}${hours > 0 ? ` (${fmtZeny(totReal / hours)}/h)` : ""}`);

  return "```\n" + lines.join("\n") + "\n```";
}

async function copySummary() {
  const text = buildSummary();
  const status = $("#copyStatus");
  if (!text) {
    status.style.color = "var(--danger)";
    status.textContent = "Adicione pelo menos um mob.";
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
  status.textContent = "Resumo copiado! Cole no Discord.";
  setTimeout(() => (status.textContent = ""), 2500);
}

// ---------- Sessions API ----------

function snapshotSession() {
  const hours = computeHours();
  const minutes = Math.round(hours * 60);
  if (state.mobs.length === 0) return null;
  if (minutes <= 0) return null;
  // Calcula totais e contagens
  let totalExpected = 0;
  let totalRealized = 0;
  let totalKills = 0;
  const mobsSnap = [];
  for (const me of state.mobs) {
    const mob = mobById.get(me.mobId);
    if (!mob) continue;
    const t = totalsForMob(me);
    const kpm = Number(me.kpm) || 0;
    const kills = kpm * hours * 60;
    totalExpected += t.expected;
    totalRealized += t.realized;
    totalKills += kills;
    // Salva drops com qty real (esp recalculado depois se necessário)
    const dropsSnap = {};
    for (const drop of mob.drops) {
      const e = me.drops[drop.itemId];
      if (!e) continue;
      dropsSnap[drop.itemId] = {
        checked: !!e.checked,
        realQty: Number(e.realQty) || 0,
        rate: drop.rate,
      };
    }
    mobsSnap.push({
      mobId: me.mobId,
      mobEn: mob.en,
      kpm,
      kills,
      drops: dropsSnap,
      expected: t.expected,
      realized: t.realized,
    });
  }
  return {
    id: "s_" + Math.random().toString(36).slice(2, 10),
    savedAt: Date.now(),
    playerNick: (state.playerNick || "").trim(),
    playerClass: (state.playerClass || "").trim(),
    durationMinutes: minutes,
    buffs: { ...state.buffs },
    gum: Number(state.gum) || 0,
    stamina: Number(state.stamina) || 1,
    multiplier: dropMultiplier(),
    buffsPct: buffsTotalPct(),
    mobs: mobsSnap,
    totalExpected,
    totalRealized,
    totalKills,
  };
}

function addSession() {
  const snap = snapshotSession();
  if (!snap) return null;
  sessions.unshift(snap); // mais recente primeiro
  saveSessions();
  renderHistory();
  return snap;
}

function deleteSession(id) {
  sessions = sessions.filter((s) => s.id !== id);
  saveSessions();
  renderHistory();
}

function clearAllSessions() {
  sessions = [];
  saveSessions();
  renderHistory();
}

// ---------- History render ----------

function fmtDateBR(epochMs) {
  const d = new Date(epochMs);
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const yy = String(d.getFullYear()).slice(-2);
  const hh = String(d.getHours()).padStart(2, "0");
  const mi = String(d.getMinutes()).padStart(2, "0");
  return `${dd}/${mm}/${yy} ${hh}:${mi}`;
}

function renderHistory() {
  const list = $("#historyList");
  list.replaceChildren();

  $("#histCount").textContent = sessions.length === 1 ? "1 sessão" : `${sessions.length} sessões`;

  let totZeny = 0, totMin = 0, totKills = 0;
  for (const s of sessions) {
    totZeny += s.totalRealized || 0;
    totMin += s.durationMinutes || 0;
    totKills += s.totalKills || 0;
  }
  const totH = totMin / 60;
  $("#htZeny").textContent = fmtZeny(totZeny);
  $("#htHours").textContent = totH > 0 ? fmtDuration(totH) : "—";
  $("#htKills").textContent = nfZ.format(Math.round(totKills));
  $("#htAvg").textContent = totH > 0 && totZeny > 0 ? fmtZeny(totZeny / totH) + "/h" : "—";

  if (sessions.length === 0) {
    const li = document.createElement("li");
    li.className = "hist-empty";
    li.textContent = "Nenhuma sessão salva ainda.";
    list.appendChild(li);
    return;
  }

  for (const s of sessions) {
    list.appendChild(historyItemEl(s));
  }
}

function historyItemEl(s) {
  const li = document.createElement("li");
  li.className = "hist-item";

  const details = document.createElement("details");
  const summary = document.createElement("summary");

  const date = document.createElement("span");
  date.className = "hist-date";
  date.textContent = fmtDateBR(s.savedAt);

  const player = (s.playerNick || s.playerClass)
    ? `${s.playerNick || "?"}${s.playerClass ? ` (${s.playerClass})` : ""} · `
    : "";
  const mobs = document.createElement("span");
  mobs.className = "hist-mobs";
  mobs.textContent = player + s.mobs.map((m) => m.mobEn).join(", ");

  const zeny = document.createElement("span");
  zeny.className = "hist-zeny";
  const hrs = (s.durationMinutes || 0) / 60;
  const zh = hrs > 0 ? fmtZeny(s.totalRealized / hrs) + "/h" : "";
  zeny.innerHTML = `<b>${fmtZeny(s.totalRealized)}</b>${zh ? ` <span class="dim">(${zh})</span>` : ""}`;

  summary.append(date, mobs, zeny);
  details.appendChild(summary);

  const body = document.createElement("div");
  body.className = "hist-body";

  // resumo de buffs
  const meta = document.createElement("div");
  meta.className = "hist-meta";
  const buffStr = s.buffsPct > 0 ? `buffs +${s.buffsPct}%` : "sem buffs";
  const stam = s.stamina === 0.3 ? ", sem stamina" : "";
  meta.textContent = `${fmtDuration(hrs)} · mult ×${nfDec2.format(s.multiplier)} (${buffStr}${stam}) · ${nfZ.format(Math.round(s.totalKills))} mortes · esperado ${fmtZeny(s.totalExpected)}`;
  body.appendChild(meta);

  // detalhes por mob
  for (const m of s.mobs) {
    const mobBlock = document.createElement("div");
    mobBlock.className = "hist-mob";
    const h = document.createElement("h4");
    const mobObj = mobById.get(m.mobId);
    const mobLabel = mobObj ? mobObj.en : m.mobEn;
    const hrsM = (s.durationMinutes || 0) / 60;
    const zhM = hrsM > 0 ? fmtZeny(m.realized / hrsM) + "/h" : "";
    h.innerHTML = `${mobLabel} · ${nfDec.format(m.kpm)}/min · ${nfZ.format(Math.round(m.kills))} mortes <span class="dim">— real ${fmtZeny(m.realized)}${zhM ? ` (${zhM})` : ""}</span>`;
    mobBlock.appendChild(h);

    for (const itemId in m.drops) {
      const d = m.drops[itemId];
      if (!d.checked || !d.realQty) continue;
      const it = itemById.get(Number(itemId));
      const name = it ? it.en : `#${itemId}`;
      const p = priceOC(Number(itemId));
      const line = document.createElement("div");
      line.className = "hist-drop";
      line.textContent = `${d.realQty}× ${name} · ${fmtZeny(d.realQty * p)}`;
      mobBlock.appendChild(line);
    }
    body.appendChild(mobBlock);
  }

  const actions = document.createElement("div");
  actions.className = "hist-item-actions";
  const del = document.createElement("button");
  del.type = "button";
  del.className = "btn btn-ghost btn-small btn-danger";
  del.textContent = "Apagar";
  del.addEventListener("click", () => {
    if (confirm("Apagar essa sessão do histórico?")) deleteSession(s.id);
  });
  actions.appendChild(del);
  body.appendChild(actions);

  details.appendChild(body);
  li.appendChild(details);
  return li;
}

function setHistStatus(msg, isError) {
  const el = $("#histStatus");
  el.style.color = isError ? "var(--danger)" : "var(--success)";
  el.textContent = msg || "";
  if (msg) setTimeout(() => { if (el.textContent === msg) el.textContent = ""; }, 3000);
}

// ---------- Export / Import ----------

function exportJSON() {
  const data = {
    exportedAt: new Date().toISOString(),
    sessions,
  };
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  const stamp = new Date().toISOString().slice(0, 19).replace(/[T:]/g, "-");
  a.href = url;
  a.download = `landverse-calc-${stamp}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  setHistStatus(`Exportado: ${sessions.length} sessão${sessions.length === 1 ? "" : "es"}.`);
}

async function importJSON(file) {
  try {
    const text = await file.text();
    const data = JSON.parse(text);
    if (!Array.isArray(data?.sessions)) {
      setHistStatus("Arquivo inválido: faltou campo 'sessions'.", true);
      return;
    }
    // Pergunta: substituir ou somar
    const merge = sessions.length === 0
      ? true
      : confirm(`Você já tem ${sessions.length} sessão(ões).\n\nOK = somar (mantém as atuais e adiciona as do arquivo)\nCancelar = substituir (apaga as atuais)`);
    const incoming = data.sessions.filter((s) => s && s.id && Array.isArray(s.mobs));
    if (merge) {
      const existingIds = new Set(sessions.map((s) => s.id));
      const fresh = incoming.filter((s) => !existingIds.has(s.id));
      sessions = [...fresh, ...sessions];
    } else {
      sessions = incoming;
    }
    sessions.sort((a, b) => (b.savedAt || 0) - (a.savedAt || 0));
    saveSessions();
    renderHistory();
    setHistStatus(`Importado: ${incoming.length} sessão${incoming.length === 1 ? "" : "es"}.`);
  } catch (e) {
    setHistStatus("Erro lendo o arquivo: " + e.message, true);
  }
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

  $("#playerNick").addEventListener("input", (e) => { state.playerNick = e.target.value; save(); });
  $("#playerClass").addEventListener("input", (e) => { state.playerClass = e.target.value; save(); });

  $("#btnSave").addEventListener("click", () => {
    const snap = addSession();
    const status = $("#copyStatus");
    if (!snap) {
      status.style.color = "var(--danger)";
      status.textContent = "Adicione mob, KPM e tempo antes de salvar.";
    } else {
      status.style.color = "var(--success)";
      status.textContent = `Sessão salva! Histórico: ${sessions.length}.`;
    }
    setTimeout(() => (status.textContent = ""), 3000);
  });

  $("#btnExport").addEventListener("click", () => {
    if (sessions.length === 0) {
      setHistStatus("Nada pra exportar.", true);
      return;
    }
    exportJSON();
  });
  $("#fileImport").addEventListener("change", (e) => {
    const f = e.target.files?.[0];
    if (f) importJSON(f);
    e.target.value = "";
  });
  $("#btnClearHist").addEventListener("click", () => {
    if (sessions.length === 0) return;
    if (confirm(`Apagar TODAS as ${sessions.length} sessões do histórico? Essa ação não tem volta (faça export antes).`)) {
      clearAllSessions();
      setHistStatus("Histórico apagado.");
    }
  });

  $("#btnCopy").addEventListener("click", copySummary);
  $("#btnReset").addEventListener("click", () => {
    if (!confirm("Limpar todos os mobs e tempos?")) return;
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
loadSessions();
renderMobPicker();
renderMobs();
tagMobLis();
syncConfigUI();
syncPlayerUI();
syncTimeUI();
updateResults();
renderHistory();
bind();
