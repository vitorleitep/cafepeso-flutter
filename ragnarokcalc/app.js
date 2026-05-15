"use strict";

// Overcharge / Super Faturar Lv10 = +24% no preço base de venda ao NPC.
const OVERCHARGE_MULT = 1.24;

const STORAGE_KEY = "rolg.calc.state.v1";

// ITEMS comes from items.js (window.ITEMS).
const ITEMS = window.ITEMS || [];

// Index by id and by lowercased localized name (rebuilt when language flips).
const byId = new Map(ITEMS.map((it) => [it.id, it]));
let nameIndex = new Map();

const state = {
  lang: "pt",
  rows: [{ id: cryptoId(), itemId: null, qty: 1 }],
  timeMode: "range",
  timeStart: "",
  timeEnd: "",
  timeHours: "",
};

// ---------- Persistence ----------

function save() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch (_) {}
}

function load() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === "object") {
      Object.assign(state, parsed);
      if (!Array.isArray(state.rows) || state.rows.length === 0) {
        state.rows = [{ id: cryptoId(), itemId: null, qty: 1 }];
      }
    }
  } catch (_) {}
}

function cryptoId() {
  return "r" + Math.random().toString(36).slice(2, 10);
}

// ---------- Formatting ----------

const nfZeny = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 });

function fmtZeny(n) {
  if (!isFinite(n) || n <= 0) return "0 z";
  return nfZeny.format(Math.round(n)) + " z";
}

function fmtDuration(hours) {
  if (!isFinite(hours) || hours <= 0) return "—";
  const totalMin = Math.round(hours * 60);
  const h = Math.floor(totalMin / 60);
  const m = totalMin % 60;
  if (h === 0) return `${m} min`;
  if (m === 0) return `${h} h`;
  return `${h} h ${m} min`;
}

// ---------- Calculation ----------

function lineTotal(itemId, qty) {
  const it = byId.get(itemId);
  if (!it || !qty || qty <= 0) return 0;
  return Math.floor(it.price * OVERCHARGE_MULT) * qty;
}

function grandTotal() {
  return state.rows.reduce((acc, r) => acc + lineTotal(r.itemId, r.qty), 0);
}

function computeHours() {
  if (state.timeMode === "direct") {
    const h = parseFloat((state.timeHours || "").toString().replace(",", "."));
    return isFinite(h) && h > 0 ? h : 0;
  }
  // range
  const s = parseTime(state.timeStart);
  const e = parseTime(state.timeEnd);
  if (s == null || e == null) return 0;
  let diff = e - s;
  if (diff <= 0) diff += 24 * 60; // wraps past midnight
  return diff / 60;
}

function parseTime(str) {
  if (!str || typeof str !== "string") return null;
  const m = /^(\d{1,2}):(\d{2})$/.exec(str);
  if (!m) return null;
  const h = parseInt(m[1], 10);
  const min = parseInt(m[2], 10);
  if (h < 0 || h > 23 || min < 0 || min > 59) return null;
  return h * 60 + min;
}

// ---------- Item resolution ----------

function rebuildNameIndex() {
  nameIndex = new Map();
  for (const it of ITEMS) {
    const key = (state.lang === "en" ? it.en : it.pt).toLowerCase();
    if (!nameIndex.has(key)) nameIndex.set(key, it);
  }
}

function resolveByName(typed) {
  if (!typed) return null;
  return nameIndex.get(typed.trim().toLowerCase()) || null;
}

function displayName(itemId) {
  const it = byId.get(itemId);
  if (!it) return "";
  return state.lang === "en" ? it.en : it.pt;
}

// ---------- Render ----------

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

function renderDatalist() {
  const list = $("#itemList");
  // Build once per language flip — 882 entries.
  const seen = new Set();
  const opts = [];
  for (const it of ITEMS) {
    const name = state.lang === "en" ? it.en : it.pt;
    if (seen.has(name)) continue;
    seen.add(name);
    const npcPrice = Math.floor(it.price * OVERCHARGE_MULT);
    const opt = document.createElement("option");
    opt.value = name;
    opt.label = `${npcPrice} z`;
    opts.push(opt);
  }
  list.replaceChildren(...opts);
}

function renderRows() {
  const ul = $("#rows");
  ul.replaceChildren();
  for (const row of state.rows) {
    ul.appendChild(rowEl(row));
  }
}

function rowEl(row) {
  const li = document.createElement("li");
  li.className = "row";
  li.dataset.rowId = row.id;

  const itemInput = document.createElement("input");
  itemInput.type = "text";
  itemInput.className = "item-input";
  itemInput.setAttribute("list", "itemList");
  itemInput.setAttribute("autocomplete", "off");
  itemInput.setAttribute("autocapitalize", "off");
  itemInput.setAttribute("spellcheck", "false");
  itemInput.placeholder = state.lang === "en" ? "Item name" : "Nome do item";
  itemInput.value = displayName(row.itemId);
  itemInput.addEventListener("input", () => {
    const it = resolveByName(itemInput.value);
    row.itemId = it ? it.id : null;
    updateRowTotal(li, row);
    updateResults();
    save();
  });
  itemInput.addEventListener("blur", () => {
    // Snap to canonical case when matched
    if (row.itemId) itemInput.value = displayName(row.itemId);
  });

  const qtyInput = document.createElement("input");
  qtyInput.type = "number";
  qtyInput.className = "qty-input";
  qtyInput.min = "0";
  qtyInput.step = "1";
  qtyInput.inputMode = "numeric";
  qtyInput.placeholder = "qtd";
  qtyInput.value = row.qty || "";
  qtyInput.addEventListener("input", () => {
    const n = parseInt(qtyInput.value, 10);
    row.qty = isFinite(n) && n > 0 ? n : 0;
    updateRowTotal(li, row);
    updateResults();
    save();
  });

  const removeBtn = document.createElement("button");
  removeBtn.type = "button";
  removeBtn.className = "row-remove";
  removeBtn.setAttribute("aria-label", "Remover item");
  removeBtn.textContent = "×";
  removeBtn.addEventListener("click", () => {
    state.rows = state.rows.filter((r) => r.id !== row.id);
    if (state.rows.length === 0) state.rows.push({ id: cryptoId(), itemId: null, qty: 1 });
    renderRows();
    updateResults();
    save();
  });

  const total = document.createElement("div");
  total.className = "row-total";

  li.append(itemInput, qtyInput, removeBtn, total);
  updateRowTotal(li, row);
  return li;
}

function updateRowTotal(li, row) {
  const total = li.querySelector(".row-total");
  const v = lineTotal(row.itemId, row.qty);
  total.innerHTML = v > 0 ? `Subtotal <b>${fmtZeny(v)}</b>` : "";
}

function updateResults() {
  const total = grandTotal();
  const hours = computeHours();
  $("#rTotal").textContent = fmtZeny(total);
  $("#rTime").textContent = fmtDuration(hours);
  $("#rPerHour").textContent = hours > 0 && total > 0 ? fmtZeny(total / hours) + "/h" : "—";
}

// ---------- Time UI ----------

function syncTimeUI() {
  const range = $("#timeRange");
  const direct = $("#timeDirect");
  range.classList.toggle("is-hidden", state.timeMode !== "range");
  direct.classList.toggle("is-hidden", state.timeMode !== "direct");
  $("#timeStart").value = state.timeStart || "";
  $("#timeEnd").value = state.timeEnd || "";
  $("#timeHours").value = state.timeHours || "";
  for (const r of $$('input[name="timeMode"]')) {
    r.checked = r.value === state.timeMode;
  }
}

function syncLangUI() {
  for (const b of $$(".lang-btn")) {
    const active = b.dataset.lang === state.lang;
    b.classList.toggle("is-active", active);
    b.setAttribute("aria-pressed", active ? "true" : "false");
  }
}

// ---------- Copy summary ----------

function buildSummary() {
  const lines = [];
  let total = 0;
  for (const row of state.rows) {
    const it = byId.get(row.itemId);
    if (!it || !row.qty) continue;
    const lt = lineTotal(row.itemId, row.qty);
    total += lt;
    const name = state.lang === "en" ? it.en : it.pt;
    lines.push(`${row.qty}x ${name} → ${fmtZeny(lt)}`);
  }
  if (lines.length === 0) return null;

  const hours = computeHours();
  const out = [];
  out.push("Calculadora Landverse (Super Faturar Lv10)");
  out.push("─".repeat(36));
  out.push(...lines);
  out.push("─".repeat(36));
  out.push(`Total:    ${fmtZeny(total)}`);
  if (hours > 0) {
    out.push(`Tempo:    ${fmtDuration(hours)}`);
    out.push(`Por hora: ${fmtZeny(total / hours)}/h`);
  }
  return "```\n" + out.join("\n") + "\n```";
}

async function copySummary() {
  const text = buildSummary();
  const status = $("#copyStatus");
  if (!text) {
    status.style.color = "var(--danger)";
    status.textContent = "Adicione pelo menos um item válido.";
    setTimeout(() => (status.textContent = ""), 2500);
    return;
  }
  try {
    await navigator.clipboard.writeText(text);
    status.style.color = "var(--success)";
    status.textContent = "Resumo copiado! Cole no Discord.";
  } catch (_) {
    // Fallback: select-and-copy via textarea
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand("copy"); } catch (_) {}
    document.body.removeChild(ta);
    status.style.color = "var(--success)";
    status.textContent = "Resumo copiado! Cole no Discord.";
  }
  setTimeout(() => (status.textContent = ""), 2500);
}

// ---------- Wire-up ----------

function bind() {
  $("#addRow").addEventListener("click", () => {
    state.rows.push({ id: cryptoId(), itemId: null, qty: 1 });
    renderRows();
    updateResults();
    save();
    // Focus the newly added item input
    const inputs = $$(".row .item-input");
    if (inputs.length) inputs[inputs.length - 1].focus();
  });

  $("#btnCopy").addEventListener("click", copySummary);

  $("#btnReset").addEventListener("click", () => {
    if (!confirm("Limpar todos os itens e tempos?")) return;
    state.rows = [{ id: cryptoId(), itemId: null, qty: 1 }];
    state.timeStart = "";
    state.timeEnd = "";
    state.timeHours = "";
    renderRows();
    syncTimeUI();
    updateResults();
    save();
  });

  for (const b of $$(".lang-btn")) {
    b.addEventListener("click", () => {
      state.lang = b.dataset.lang;
      rebuildNameIndex();
      renderDatalist();
      renderRows();
      syncLangUI();
      save();
    });
  }

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
}

// ---------- Init ----------

load();
rebuildNameIndex();
renderDatalist();
renderRows();
syncLangUI();
syncTimeUI();
updateResults();
bind();
