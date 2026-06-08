// Base de itens da calculadora — Ragnarok Landverse America.
// `price` é o preço base de venda ao NPC (sem Super Faturar).
// Itens listados em mobs.js usam preços oficiais do Ragnarok Analytics;
// demais itens usam aproximação rAthena pre-renewal.
// O Overcharge / Super Faturar Lv10 é aplicado em app.js (Math.round(price * 1.24)).

window.ITEMS = [
  { id: 7043, pt: "Areia Fina", en: "Fine Sand", price: 17 },
  { id: 7124, pt: "Areia Molhada", en: "Sand Clump", price: 118 },
  { id: 1621, pt: "Cajado do Hipnotizador", en: "Hypnotist's Staff", price: 3 },
  { id: 4240, pt: "Carta Arclouse", en: "Arclouse Card", price: 3 },
  { id: 4150, pt: "Carta Bode", en: "Goat Card", price: 3 },
  { id: 4325, pt: "Carta Harpia", en: "Harpy Card", price: 3 },
  { id: 4228, pt: "Carta Rochoso", en: "Sleeper Card", price: 3 },
  { id: 4226, pt: "Carta Sting", en: "Sting Card", price: 3 },
  { id: 1003, pt: "Carvão", en: "Coal", price: 83 },
  { id: 1096, pt: "Casca Arredondada", en: "Round Shell", price: 130 },
  { id: 943, pt: "Casca Rija", en: "Solid Shell", price: 75 },
  { id: 7106, pt: "Chifre de Bode", en: "Antelope Horn", price: 112 },
  { id: 90001, pt: "Colar de Grama Fresca", en: "Fresh Grass Necklace", price: 3 },
  { id: 508, pt: "Erva Amarela", en: "Yellow Herb", price: 7 },
  { id: 510, pt: "Erva Azul", en: "Blue Herb", price: 10 },
  { id: 511, pt: "Erva Verde", en: "Green Herb", price: 2 },
  { id: 507, pt: "Erva Vermelha", en: "Red Herb", price: 3 },
  { id: 7116, pt: "Garra de Harpia", en: "Harpy Talon", price: 202 },
  { id: 716, pt: "Gema Vermelha", en: "Red Gemstone", price: 75 },
  { id: 709, pt: "Izidor", en: "Izidor", price: 83 },
  { id: 10007, pt: "Laço de Seda", en: "Silk Ribbon", price: 3 },
  { id: 2604, pt: "Luvas", en: "Glove", price: 10000 },
  { id: 7004, pt: "Monte de Lama", en: "Mud Lump", price: 146 },
  { id: 938, pt: "Muco Pegajoso", en: "Sticky Mucus", price: 12 },
  { id: 997, pt: "Natureza Grandiosa", en: "Great Nature", price: 300 },
  { id: 7107, pt: "Pele de Bode", en: "Antelope Skin", price: 126 },
  { id: 7115, pt: "Pena de Harpia", en: "Harpy Feather", price: 190 },
  { id: 1820, pt: "Punho Voltaico", en: "Electric Fist", price: 3 },
  { id: 6213, pt: "Pó Explosivo", en: "Explosive Powder", price: 83 },
  { id: 1056, pt: "Torrão de Areia", en: "Grit", price: 51 },
  { id: 912, pt: "Zargônio", en: "Zargon", price: 80 },
];
