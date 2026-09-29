# Aula 21: Agregação, GROUP BY e HAVING

**Objetivo:** Aprender a **resumir dados** — em vez de mostrar cada linha, calcular **totais, médias e contagens** sobre conjuntos de linhas.

> 💡 **Diferença chave:** até agora, cada linha do resultado representava **uma linha** da tabela. Com agregação, uma linha do resultado representa **um resumo** de várias linhas.

---

## 🎯 Modelo mental

Pense em três estágios que acontecem em ordem:

1. **Linhas individuais** → o SQL parte da tabela original (ex.: 10 mil pedidos).
2. **Grupos** → `GROUP BY` **agrupa** linhas que compartilham o mesmo valor (ex.: agrupar por `status`).
3. **Resumo** → uma **função de agregação** (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`) devolve **um único valor por grupo**.

Depois, o `HAVING` pode filtrar **os grupos resumidos** (diferente do `WHERE`, que filtra linhas individuais antes do agrupamento).

---

## 🔢 Parte 1 — Funções de Agregação

As funções de agregação **colapsam várias linhas em um único valor**. Podem ser usadas **sozinhas** (resumindo a tabela inteira) ou **com `GROUP BY`** (resumindo por grupo).

### Exemplo 1: `COUNT` — contar linhas

```sql
SELECT 
    COUNT(*) AS total_pedidos,
    COUNT(entregador_id) AS pedidos_com_entregador,
    COUNT(DISTINCT cliente_id) AS clientes_unicos
FROM `unipds-503513.entregaja.pedidos`;
```

**Explicação:** As três variações do `COUNT`:
- `COUNT(*)` — conta **todas as linhas** (inclusive as com valores nulos).
- `COUNT(coluna)` — conta **linhas onde `coluna` NÃO é nula**. No exemplo, isso mostra quantos pedidos têm entregador (pedidos cancelados ficam de fora, porque `entregador_id` é nulo).
- `COUNT(DISTINCT coluna)` — conta **valores únicos**. Útil para saber "quantos clientes diferentes fizeram pedido", em vez de "quantos pedidos existem".

---

### Exemplo 2: `SUM` — somar valores

```sql
SELECT 
    SUM(quantidade) AS total_itens
FROM `unipds-503513.entregaja.pedido_itens`;
```

**Explicação:** `SUM` soma todos os valores **não-nulos** da coluna. Só funciona com colunas **numéricas** — se tentar somar texto ou data, dá erro. Valores `NULL` são **ignorados** (não contam como zero).

---

### Exemplo 3: `AVG` — média

```sql
SELECT 
    ROUND(AVG(tempo_entrega_min), 2) AS tempo_medio_entrega,
    ROUND(AVG(taxa_entrega), 2) AS taxa_media
FROM `unipds-503513.entregaja.pedido`;
```

**Explicação:** `AVG` calcula a **média aritmética** dos valores não-nulos. Costuma dar um número com muitas casas decimais — por isso combinamos com `ROUND(valor, 2)` para arredondar para 2 casas. Assim como `SUM`, os nulos são **ignorados** (não entram no denominador).

---

### Exemplo 4: `MIN` e `MAX` — mínimo e máximo

```sql
SELECT 
    MIN(data_hora_pedido) AS primeiro_pedido,
    MAX(data_hora_pedido) AS ultimo_pedido,
    MIN(tempo_entrega_min) AS entrega_mais_rapida,
    MAX(tempo_entrega_min) AS entrega_mais_lenta
FROM `unipds-503513.entregaja.pedidos`;
```

**Explicação:** `MIN` devolve o **menor** valor da coluna; `MAX`, o **maior**. Funcionam com **números, datas e textos** (para texto, seguem ordem alfabética). Aqui usamos os dois para saber o intervalo de datas dos pedidos e o intervalo de tempos de entrega.

---

## 📦 Parte 2 — GROUP BY

Sozinhas, as funções de agregação resumem a **tabela inteira** numa única linha. Com `GROUP BY`, elas resumem **por grupo** — devolvendo uma linha para cada valor único da coluna agrupadora.

### Exemplo 5: `GROUP BY` por uma coluna — quantos pedidos por status?

```sql
SELECT 
    status,
    COUNT(*) AS qtd_pedidos
FROM `unipds-503513.entregaja.pedidos`
GROUP BY status
ORDER BY qtd_pedidos DESC;
```

**Explicação:** O `GROUP BY status` diz "**junte todas as linhas que têm o mesmo `status`**". Para cada grupo (`Concluído`, `Cancelado`, etc.), o `COUNT(*)` devolve quantas linhas caíram ali.

⚠️ **Regra de ouro:** toda coluna do `SELECT` que **não é uma agregação** precisa aparecer no `GROUP BY`. Se tentar `SELECT status, forma_pagamento, COUNT(*)` sem colocar `forma_pagamento` no `GROUP BY`, o SQL dá erro.

---

### Exemplo 6: `GROUP BY` por várias colunas + várias agregações + JOIN

```sql
SELECT 
    c.regiao,
    p.forma_pagamento,
    COUNT(*) AS qtd_pedidos,
    ROUND(AVG(p.taxa_entrega), 2) AS taxa_media,
    SUM(p.taxa_entrega) AS total_taxas
FROM `unipds-503513.entregaja.pedidos` AS p
INNER JOIN `unipds-503513.entregaja.clientes` AS c
    ON p.cliente_id = c.cliente_id
GROUP BY c.regiao, p.forma_pagamento
ORDER BY c.regiao, qtd_pedidos DESC;
```

**Explicação:** Quando o `GROUP BY` tem **várias colunas**, o SQL agrupa pela **combinação** delas. Aqui, cada linha do resultado é uma combinação `(região, forma_pagamento)` — ex.: `("Sudeste", "PIX")`. Para cada combinação, calculamos três agregações (contagem, média e soma).

O `JOIN` acontece **antes** do agrupamento: o SQL primeiro combina as tabelas, depois agrupa o resultado.

---

## 🚦 Parte 3 — HAVING

O `HAVING` filtra **os grupos resumidos** — igual ao `WHERE`, mas depois do `GROUP BY`. Usar um ou outro depende de **quando** você quer filtrar.

### Exemplo 7: `HAVING` — só cidades com mais de 15 clientes

```sql
SELECT 
    cidade,
    COUNT(*) AS qtd_clientes
FROM `unipds-503513.entregaja.clientes`
GROUP BY cidade
HAVING COUNT(*) > 15
ORDER BY qtd_clientes DESC;
```

**Explicação:** O `HAVING COUNT(*) > 15` acontece **depois** do agrupamento. Cada linha do resultado (uma por cidade) é testada, e só as cidades com mais de 15 clientes sobrevivem.

**Não daria para usar `WHERE COUNT(*) > 15`** — o `COUNT(*)` só existe **depois** do agrupamento, e o `WHERE` roda **antes**.

---

### Exemplo 8: `WHERE` **e** `HAVING` juntos — filtro antes E depois do agrupamento

```sql
SELECT 
    c.regiao,
    c.plano,
    COUNT(*) AS qtd_clientes,
    ROUND(AVG(c.idade), 1) AS idade_media
FROM `unipds-503513.entregaja.clientes` AS c
WHERE c.idade >= 18                    -- 1º: filtra linhas ANTES de agrupar
GROUP BY c.regiao, c.plano             -- 2º: agrupa as linhas restantes
HAVING COUNT(*) > 10                   -- 3º: filtra grupos DEPOIS de agrupar
ORDER BY c.regiao, qtd_clientes DESC;
```

**Explicação:** A diferença fica clara nos papéis:
- **`WHERE c.idade >= 18`** — descarta linhas (clientes menores de idade) **antes** do agrupamento.
- **`HAVING COUNT(*) > 10`** — descarta grupos (combinações região+plano com poucos clientes) **depois** do agrupamento.

**Regra prática:**
- Se o filtro compara **uma coluna** (`idade`, `regiao`, `status`), use `WHERE`.
- Se o filtro compara o **resultado de uma agregação** (`COUNT(*)`, `SUM(...)`, `AVG(...)`), use `HAVING`.

---

## 📝 Resumo

### Funções de Agregação

| Função | Serve para | Ignora `NULL`? |
|--------|------------|:-:|
| `COUNT(*)` | Contar linhas (inclusive nulas) | ❌ |
| `COUNT(coluna)` | Contar linhas onde `coluna` não é nula | ✅ |
| `COUNT(DISTINCT coluna)` | Contar valores únicos | ✅ |
| `SUM(coluna)` | Somar valores | ✅ |
| `AVG(coluna)` | Média aritmética | ✅ |
| `MIN(coluna)` | Menor valor | ✅ |
| `MAX(coluna)` | Maior valor | ✅ |

### Cláusulas

| Cláusula | Função | Quando roda |
|----------|--------|-------------|
| `WHERE` | Filtra **linhas** | **Antes** do agrupamento |
| `GROUP BY` | **Agrupa** linhas com valores iguais | Cria os grupos |
| `HAVING` | Filtra **grupos** | **Depois** do agrupamento |

---

## 📌 Ordem completa das cláusulas

```sql
SELECT [DISTINCT] colunas + agregações  -- 1º: o que mostrar
FROM tabela                             -- 2º: de onde vem
[JOIN ...]                              -- 3º: combinar com outra tabela
WHERE condição                          -- 4º: filtra LINHAS
GROUP BY colunas                        -- 5º: agrupa
HAVING condição_de_agregação            -- 6º: filtra GRUPOS
ORDER BY coluna [ASC|DESC]              -- 7º: ordena o resultado
LIMIT n;                                -- 8º: corta as primeiras n linhas
```

---

## ⚠️ Cuidados importantes

1. **Toda coluna não-agregada no `SELECT` precisa estar no `GROUP BY`.** Se tem `SELECT regiao, plano, COUNT(*)`, o `GROUP BY` precisa ter `regiao, plano`.
2. **`WHERE` **≠** `HAVING`**: `WHERE` filtra **linhas** (antes do agrupamento); `HAVING` filtra **grupos** (depois). Não são intercambiáveis.
3. **`COUNT(*)` **≠** `COUNT(coluna)`**: `COUNT(*)` conta linhas; `COUNT(coluna)` conta linhas onde a coluna não é nula. Se a coluna nunca é nula, os dois dão o mesmo resultado.
4. **`SUM`, `AVG`, `MIN`, `MAX` ignoram `NULL`** — não contam como zero. `AVG` também ignora nulos no denominador (não é `SUM/COUNT(*)`, é `SUM/COUNT(coluna_não_nula)`).
5. **Cuidado com `AVG` de números com muitas casas decimais.** Combine com `ROUND(valor, n)` para relatórios legíveis.
6. **Aliases criados no `SELECT` não valem no `WHERE` nem no `GROUP BY`** — mas valem no `HAVING` e no `ORDER BY` (no BigQuery).

---
