# Aula 27: Window Functions — Ranking

**Objetivo:** aprender as **funções de ranking** — as que atribuem uma **posição** (1º, 2º, 3º, ...) para cada linha dentro de uma janela. São as window functions mais usadas no dia a dia: "top 3 por categoria", "posição do cliente no mês", "melhor pedido de cada restaurante".

> 💡 **Pré-requisito:** você já viu a **estrutura** `funcao() OVER (PARTITION BY ... ORDER BY ...)` na aula 27. Nesta aula, o **esqueleto não muda** — o que muda é **qual função** você coloca na frente do `OVER`.

---

## 🎯 Modelo mental

Toda função de ranking responde à pergunta: **"em que posição essa linha está, dentro da ordem que eu defini?"**

Para responder isso, a função precisa de duas coisas:

1. **Uma ordem** — o `ORDER BY` dentro do `OVER` diz quem vem primeiro, segundo, etc.
2. **(Opcional) Uma partição** — o `PARTITION BY` diz "reinicie a contagem a cada grupo" (ex.: ranking **por categoria**, e não global).

O que **muda** entre as funções de ranking é **como elas lidam com empates** — linhas que têm o mesmo valor no `ORDER BY`.

| Função | Empate → | Pula posições? | Quando usar |
|--------|----------|----------------|-------------|
| **`ROW_NUMBER()`** | Números **diferentes** (desempate arbitrário) | — | Quando você quer uma numeração **única** (1, 2, 3, ...), sem empate |
| **`RANK()`** | Mesma posição, **pula** as próximas | ✅ Sim (1, 2, 2, 4) | Ranking "esportivo" — dois em segundo, próximo é quarto |
| **`DENSE_RANK()`** | Mesma posição, **não pula** | ❌ Não (1, 2, 2, 3) | Ranking "compacto" — dois em segundo, próximo é terceiro |
| **`NTILE(n)`** | Divide as linhas em **n grupos** de tamanho igual | — | Quartis, decis, percentis (ex.: top 25% de clientes) |

---

# 📘 Exemplo 1 — `ROW_NUMBER()`: numeração única

**Cenário:** listar os **10 clientes mais velhos** com uma coluna que numera cada um por ordem de idade (1 = mais velho).

```sql
SELECT 
    ROW_NUMBER() OVER (ORDER BY idade DESC) AS posicao,
    cliente_id,
    nome,
    idade,
    cidade
FROM `unipds-503513.entregaja.clientes`
ORDER BY posicao
LIMIT 10;
```

**Como ler:**

- `ROW_NUMBER()` — atribui um número **sequencial e único** para cada linha.
- `OVER (ORDER BY idade DESC)` — a janela é a tabela inteira, ordenada por idade decrescente.
- Resultado: 1 para o mais velho, 2 para o segundo, 3 para o terceiro... **sem empates**, mesmo que dois clientes tenham a mesma idade (o SQL desempata "como quiser" — na prática, imprevisível).

**Detalhe importante:** se dois clientes têm exatamente **75 anos**, um vai receber posição 5 e o outro 6 — mas **qual deles fica em 5** é arbitrário. Se você precisa de um desempate previsível, adicione critérios no `ORDER BY`:

```sql
ROW_NUMBER() OVER (ORDER BY idade DESC, cliente_id ASC)
```

---

# 📗 Exemplo 2 — `RANK()`: empates ganham a mesma posição (e pulam as próximas)

**Cenário:** ranking dos restaurantes por **nota média** — se dois restaurantes têm a mesma média, ficam **empatados na mesma posição**, e o próximo pula.

```sql
SELECT 
    RANK() OVER (ORDER BY ROUND(AVG(a.nota), 2) DESC) AS posicao,
    r.nome,
    r.categoria,
    ROUND(AVG(a.nota), 2) AS nota_media,
    COUNT(*) AS qtd_avaliacoes
FROM `unipds-503513.entregaja.avaliacoes` AS a
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON a.pedido_id = p.pedido_id
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON p.restaurante_id = r.restaurante_id
WHERE p.status = 'Concluído'
GROUP BY r.nome, r.categoria
ORDER BY posicao
LIMIT 15;
```

**Como ler:**

- `RANK()` atribui a **mesma posição** para linhas empatadas.
- Se dois restaurantes têm nota `4.85`, ambos ficam em **2º lugar**, e o próximo vai direto pro **4º** (pulou o 3º).
- Resultado possível: `1, 2, 2, 4, 5, 6, 6, 6, 9, ...`

**Nota importante — window function + `GROUP BY`:** aqui usamos os dois na mesma query. É válido: primeiro o SQL agrupa por restaurante (colapsando), depois aplica o `RANK()` sobre esse resultado agrupado. Repare que dentro do `OVER`, usamos `ROUND(AVG(a.nota), 2)` — a **mesma expressão** do `SELECT`, porque o `RANK` precisa saber por qual valor ordenar.

---

# 📙 Exemplo 3 — `DENSE_RANK()`: empates sem pular posições

**Cenário:** mesmo ranking do Exemplo 2, mas queremos que as posições sejam **consecutivas** — dois em 2º, o próximo é 3º (não 4º).

```sql
SELECT 
    DENSE_RANK() OVER (ORDER BY ROUND(AVG(a.nota), 2) DESC) AS posicao,
    r.nome,
    r.categoria,
    ROUND(AVG(a.nota), 2) AS nota_media,
    COUNT(*) AS qtd_avaliacoes
FROM `unipds-503513.entregaja.avaliacoes` AS a
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON a.pedido_id = p.pedido_id
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON p.restaurante_id = r.restaurante_id
WHERE p.status = 'Concluído'
GROUP BY r.nome, r.categoria
ORDER BY posicao
LIMIT 15;
```

**Diferença para `RANK()`:**

| Nota média | `RANK()` | `DENSE_RANK()` |
|-----------|----------|----------------|
| 4.95 | 1 | 1 |
| 4.85 | 2 | 2 |
| 4.85 | 2 | 2 |
| 4.72 | **4** ← pulou 3 | **3** ← não pulou |
| 4.50 | 5 | 4 |

**Quando escolher qual:**
- **`RANK()`** — ranking "esportivo", onde a posição reflete quantas linhas estão **acima** (dois em 2º ⇒ o próximo está em 4º porque há 3 linhas empatadas ou melhores).
- **`DENSE_RANK()`** — ranking "compacto", onde a posição reflete quantos **níveis distintos** existem acima. Ótimo para "níveis de qualidade" ou "faixas".

---

# 📕 Exemplo 4 — `PARTITION BY`: ranking **dentro de cada grupo**

**Cenário:** top 3 restaurantes **de cada categoria** por nota média — ou seja, um ranking que **reinicia** a cada categoria.

```sql
WITH ranking_por_categoria AS (
    SELECT 
        r.nome,
        r.categoria,
        ROUND(AVG(a.nota), 2) AS nota_media,
        COUNT(*) AS qtd_avaliacoes,
        RANK() OVER (
            PARTITION BY r.categoria 
            ORDER BY AVG(a.nota) DESC
        ) AS posicao_na_categoria
    FROM `unipds-503513.entregaja.avaliacoes` AS a
    INNER JOIN `unipds-503513.entregaja.pedidos` AS p
        ON a.pedido_id = p.pedido_id
    INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
        ON p.restaurante_id = r.restaurante_id
    WHERE p.status = 'Concluído'
    GROUP BY r.nome, r.categoria
)
SELECT *
FROM ranking_por_categoria
WHERE posicao_na_categoria <= 3
ORDER BY categoria, posicao_na_categoria;
```

**Como ler, peça por peça:**

1. `PARTITION BY r.categoria` → divide os restaurantes em **grupos por categoria** (Pizzaria, Japonesa, Hamburgueria, ...).
2. `ORDER BY AVG(a.nota) DESC` → dentro de cada grupo, ordena pela nota média decrescente.
3. `RANK()` → dá a posição **dentro da categoria** — reinicia em 1 a cada nova categoria.

**Por que a CTE?** Não dá para usar window function no `WHERE` (elas rodam **depois** do `WHERE`). Então: primeiro calculamos o ranking numa CTE, depois filtramos `posicao_na_categoria <= 3` na query externa. Esse padrão — **CTE + filtro por resultado de window function** — é o jeito canônico de fazer "top N por grupo".

---

# 📓 Exemplo 5 — `NTILE(n)`: dividir em faixas iguais

**Cenário:** classificar os clientes em **4 grupos** (quartis) por idade — do mais jovem (quartil 1) ao mais velho (quartil 4). Útil para segmentação.

```sql
SELECT 
    cliente_id,
    nome,
    idade,
    NTILE(4) OVER (ORDER BY idade ASC) AS quartil_idade
FROM `unipds-503513.entregaja.clientes`
ORDER BY idade ASC
LIMIT 20;
```

**Como ler:**

- `NTILE(4)` divide as linhas em **4 grupos aproximadamente iguais**, na ordem definida pelo `ORDER BY`.
- 25% mais jovens → quartil `1`; próximos 25% → quartil `2`; e assim até o quartil `4` (25% mais velhos).
- Se o total não divide certinho por 4, os primeiros grupos recebem **1 linha a mais**.

**Variações comuns:**
- `NTILE(4)` → **quartis**
- `NTILE(5)` → **quintis**
- `NTILE(10)` → **decis**
- `NTILE(100)` → **percentis**

Muito usado em análise de clientes: "top 10% dos compradores", "clientes na faixa mediana de gasto", etc.

---

# 📔 Exemplo 6 — Combinando: "o pedido mais recente de cada cliente"

**Cenário:** para cada cliente, trazer **apenas o pedido mais recente** — descartando os demais. Padrão muito comum em relatórios ("último status de cada").

```sql
WITH pedidos_numerados AS (
    SELECT 
        cliente_id,
        pedido_id,
        status,
        data_hora_pedido,
        ROW_NUMBER() OVER (
            PARTITION BY cliente_id 
            ORDER BY data_hora_pedido DESC
        ) AS ordem
    FROM `unipds-503513.entregaja.pedidos`
)
SELECT 
    cliente_id,
    pedido_id,
    status,
    data_hora_pedido
FROM pedidos_numerados
WHERE ordem = 1
ORDER BY data_hora_pedido DESC
LIMIT 15;
```

**Como ler:**

1. A CTE numera os pedidos de cada cliente por data decrescente — o mais recente ganha `ordem = 1`.
2. A query externa filtra apenas `ordem = 1`, ficando com **um pedido por cliente** (o último de cada).

**Por que `ROW_NUMBER()` e não `RANK()`?** Se dois pedidos tivessem exatamente o mesmo `data_hora_pedido`, o `RANK()` daria posição 1 pros dois — e você acabaria com **dois pedidos** para aquele cliente. O `ROW_NUMBER()` **sempre** escolhe apenas um (mesmo que arbitrariamente), o que garante uma linha por cliente.

> 🧭 **Padrão para lembrar:** "**a linha mais X de cada Y**" → `ROW_NUMBER() OVER (PARTITION BY Y ORDER BY X ...)` + `WHERE ordem = 1`.

---

## 📝 Resumo geral

| Função | Trata empates como | Sequência típica | Uso mais comum |
|--------|--------------------|--------------------|----------------|
| `ROW_NUMBER()` | Desempate arbitrário | 1, 2, 3, 4, 5 | "1 linha por grupo" (top 1 de cada) |
| `RANK()` | Mesma posição, pula próximas | 1, 2, 2, 4, 5 | Ranking esportivo/competitivo |
| `DENSE_RANK()` | Mesma posição, sem pular | 1, 2, 2, 3, 4 | Ranking compacto por níveis |
| `NTILE(n)` | Distribui em `n` grupos | 1, 1, 2, 2, 3 | Quartis, decis, segmentação |

**Estrutura padrão que vale para todas:**

```sql
funcao_de_ranking() OVER (
    [PARTITION BY coluna(s)]   -- opcional: reinicia a contagem a cada grupo
    ORDER BY coluna(s)         -- obrigatório: define a ordem do ranking
)
```

---

## ⚠️ Cuidados importantes

1. **Ranking sem `ORDER BY` não faz sentido.** As três funções (`ROW_NUMBER`, `RANK`, `DENSE_RANK`) exigem um `ORDER BY` dentro do `OVER` — sem ele, não há como decidir quem é o 1º.

2. **Não dá para filtrar por ranking no `WHERE`.** Como toda window function, o ranking é calculado **depois** do `WHERE`. Para filtrar por posição (`posicao <= 3`), use uma **CTE ou subquery no `FROM`** e filtre na query externa.

3. **`ROW_NUMBER` vs `RANK` importa quando pode haver empate.** Se você quer garantir uma linha por grupo, use `ROW_NUMBER`. Se você quer respeitar empates, use `RANK` ou `DENSE_RANK`.

4. **Desempates arbitrários são traiçoeiros.** Se dois pedidos têm a mesma data, o `ROW_NUMBER` escolhe "algum" — mas qual pode variar entre execuções. Adicione critérios extras no `ORDER BY` (`ORDER BY data DESC, pedido_id DESC`) quando o desempate importa.

5. **Combinar `GROUP BY` com window function é comum.** Primeiro o `GROUP BY` agrega, depois o `OVER` ranqueia o resultado agregado (como no Exemplo 2). O `OVER` **não substitui** o `GROUP BY` — eles resolvem problemas diferentes.
