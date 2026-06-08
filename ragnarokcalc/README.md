# Calculadora Ragnarok Landverse

Calculadora simples de zeny/hora para farm no **Ragnarok Landverse America**.

- 882 itens pré-renewal com nomes em PT e EN (toggle no topo)
- Preços já com **Super Faturar Lv10 (+24%)** aplicado
- Tempo: por horário (início → fim) ou em horas direto
- Botão **Copiar resumo** que joga o resultado formatado pra colar no Discord
- Funciona offline (HTML/CSS/JS puro, sem backend, sem build)
- Estado salvo no `localStorage` — não perde nada ao recarregar
- Layout responsivo, otimizado pra celular (que é como a maioria abre links do Discord)

## Como usar

1. Abra o `index.html` no navegador (ou hospede no GitHub Pages, ver abaixo).
2. Toggle PT/EN no canto superior — só muda o nome dos itens.
3. Digite o nome do item (autocomplete) e a quantidade.
4. Adicione quantos itens precisar com **+ Adicionar item**.
5. Informe o tempo de duas formas:
   - **Horário início → fim** (ex.: 14:30 → 16:00). Se o fim for menor que o início, assume que passou da meia-noite.
   - **Horas direto** (ex.: 2.5).
6. Veja o **Zeny por hora** no card de resultado.
7. Clique **Copiar resumo para Discord** e cole no canal/fórum.

## Publicar (GitHub Pages, grátis)

1. Coloque a pasta `ragnarokcalc/` na raiz de um repo público no GitHub.
2. **Settings → Pages → Source: `main` branch / folder: `/ragnarokcalc`** (ou mova os arquivos pra raiz se preferir `/`).
3. A página fica em `https://<seu-usuario>.github.io/<repo>/`.
4. Cole esse link no fórum do Discord. O preview aparece automaticamente (via `<meta og:*>`).

> Alternativas de hospedagem: Vercel, Netlify, Cloudflare Pages — todas grátis e funcionam só fazendo deploy desta pasta.

## Editar itens / preços

Tudo em `items.js`:

```js
{ id: 909, pt: "Geleia", en: "Jellopy", price: 3 },
```

- `price` é o **preço base de venda ao NPC** (sem Super Faturar). A multiplicação por 1.24 é feita no `app.js`.
- Se Landverse modificou o preço de algum item em relação ao pre-renewal padrão, edite o `price` aqui.
- Para mudar a tradução PT, edite o campo `pt`.
- Para mudar a constante de Overcharge, edite `OVERCHARGE_MULT` no topo de `app.js`.

## Fontes dos dados

- **Preços e nomes EN**: [rAthena `db/pre-re/item_db_etc.yml`](https://github.com/rathena/rathena/blob/master/db/pre-re/item_db_etc.yml) (GPL-3).
- **Nomes PT**: [CronusDATA — Pré-Renewal / Português](https://github.com/Cronus-Emulator/CronusDATA/blob/master/Pre-Renewal/Portugu%C3%AAs/data/idnum2itemdisplaynametable.txt) (sob a licença do projeto).
- Itens sem tradução PT na CronusDATA aparecem com o nome em inglês no campo PT — pode editar à vontade.
- O preço de venda ao NPC é calculado como `floor(Buy / 2) * 1.24` por item, somado pela quantidade.

## Limitações conhecidas

- Não tem login, não tem histórico, não tem multi-personagem. Tudo fica no navegador via `localStorage`.
- Os preços vêm do pre-renewal rAthena: se Landverse alterou algum preço específico, ajuste no `items.js`.
- O Discord **não renderiza HTML interativo** em mensagens — o link abre no navegador in-app. Pra rodar a calculadora *dentro* do canal seria preciso virar uma **Discord Activity** ou um **bot com modal**, que requerem app registrado no Developer Portal.
