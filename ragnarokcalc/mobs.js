// Base de mobs e seus drops — Ragnarok Landverse America.
// Taxa em %. Quando o mob droppa o mesmo item em slots separados
// (ex: Harpy/Yellow Herb 7.50% + 4.00%), o total foi somado.
// Fonte: Ragnarok Analytics (ragnarokanalytics.com).

window.MOBS = [
  {
    id: "harpy",
    pt: "Harpia",
    en: "Harpy",
    drops: [
      { itemId: 7115, rate: 16.98 }, // Pena de Harpia / Harpy Feather
      { itemId: 7116, rate: 8.75 }, // Garra de Harpia / Harpy Talon
      { itemId: 508, rate: 11.5 }, // Erva Amarela / Yellow Herb
      { itemId: 709, rate: 0.1 }, // Izidor / Izidor
      { itemId: 1820, rate: 0.1 }, // Punho Voltaico / Electric Fist
      { itemId: 4325, rate: 0.01, isCard: true }, // Carta Harpia / Harpy Card
    ],
  },
  {
    id: "arclouze",
    pt: "Arclouse",
    en: "Arclouze",
    drops: [
      { itemId: 1096, rate: 17.5 }, // Casca Arredondada / Round Shell
      { itemId: 938, rate: 15.0 }, // Muco Pegajoso / Sticky Mucus
      { itemId: 943, rate: 12.0 }, // Casca Rija / Solid Shell
      { itemId: 912, rate: 23.75 }, // Zargônio / Zargon
      { itemId: 716, rate: 1.5 }, // Gema Vermelha / Red Gemstone
      { itemId: 997, rate: 0.1 }, // Natureza Grandiosa / Great Nature
      { itemId: 4240, rate: 0.01, isCard: true }, // Carta Arclouse / Arclouse Card
    ],
  },
  {
    id: "sting",
    pt: "Sting",
    en: "Sting",
    drops: [
      { itemId: 7004, rate: 24.25 }, // Monte de Lama / Mud Lump
      { itemId: 90001, rate: 0.2 }, // Colar de Grama Fresca / Fresh Grass Necklace
      { itemId: 2604, rate: 0.01 }, // Luvas / Glove
      { itemId: 1003, rate: 0.65 }, // Carvão / Coal
      { itemId: 997, rate: 0.13 }, // Natureza Grandiosa / Great Nature
      { itemId: 10007, rate: 0.05 }, // Laço de Seda / Silk Ribbon
      { itemId: 6213, rate: 12.0 }, // Pó Explosivo / Explosive Powder
      { itemId: 4226, rate: 0.01, isCard: true }, // Carta Sting / Sting Card
    ],
  },
  {
    id: "sleeper",
    pt: "Rochoso",
    en: "Sleeper",
    drops: [
      { itemId: 7124, rate: 17.0 }, // Areia Molhada / Sand Clump
      { itemId: 1056, rate: 18.6 }, // Torrão de Areia / Grit
      { itemId: 997, rate: 2.5 }, // Natureza Grandiosa / Great Nature
      { itemId: 1621, rate: 0.03 }, // Cajado do Hipnotizador / Hypnotist's Staff
      { itemId: 7043, rate: 6.0 }, // Areia Fina / Fine Sand
      { itemId: 4228, rate: 0.01, isCard: true }, // Carta Rochoso / Sleeper Card
    ],
  },
  {
    id: "goat",
    pt: "Bode",
    en: "Goat",
    drops: [
      { itemId: 7106, rate: 22.8 }, // Chifre de Bode / Antelope Horn
      { itemId: 7107, rate: 12.5 }, // Pele de Bode / Antelope Skin
      { itemId: 507, rate: 2.5 }, // Erva Vermelha / Red Herb
      { itemId: 510, rate: 2.5 }, // Erva Azul / Blue Herb
      { itemId: 508, rate: 12.5 }, // Erva Amarela / Yellow Herb
      { itemId: 511, rate: 27.5 }, // Erva Verde / Green Herb
      { itemId: 4150, rate: 0.01, isCard: true }, // Carta Bode / Goat Card
    ],
  },
];
