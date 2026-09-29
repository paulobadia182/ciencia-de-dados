# Aula 28: Window Functions — Deslocamento

**Objetivo:** aprender as **funções de deslocamento** — as que "olham" para uma **outra linha** da janela (a anterior, a próxima, a primeira, a última) e trazem um valor **para o lado** da linha atual. São elas que permitem calcular **variações**, **diferenças em relação ao anterior**, **tempo entre eventos** e **comparações com o primeiro/último** dentro de um grupo.

> 💡 **Pré-requisito:** você já viu a estrutura `funcao() OVER (PARTITION BY ... ORDER BY ...)` na aula 26 e viu ranking na aula 27. O esqueleto continua o mesmo — o que muda é **qual função** vai antes do `OVER` e o **papel do `ORDER BY`**: aqui ele é essencial, porque "linha anterior" só faz sentido se existe uma **ordem** definida.

---

## 🎯 Modelo mental

Toda função de deslocamento responde à pergunta: **"qual é o valor de uma outra linha da janela, ao lado desta?"**

Diferente das agregações (que resumem várias linhas em um valor) e do ranking (que numera a posição), as funções de deslocamento **copiam o valor de outra linha** pra ficar ao lado da linha atual.

| Função | Traz o valor de qual linha? | Uso típico |
|--------|-----------------------------|------------|
| **`LAG(col, n)`** | A linha **`n` posições anteriores** (default `n = 1`) | Comparar valor atual com o anterior |
| **`LEAD(col, n)`** | A linha **`n` posições posteriores** (default `n = 1`) | Comparar valor atual com o próximo |
| **`FIRST_VALUE(col)`** | A **primeira linha** da janela ordenada | Comparar cada linha com o "primeiro" do grupo |
| **`LAST_VALUE(col)`** | A **última linha** da janela ordenada | Comparar cada linha com o "último" (com cuidado no frame) |

> 🧭 **Por que `ORDER BY` é obrigatório aqui:** "linha anterior" só existe se você definiu uma ordem. Sem `ORDER BY`, não há passado nem futuro — só um monte de linhas soltas.

---

# 📘 Exemplo 1 — `LAG()`: valor da linha anterior

**Cenário:** listar os pedidos concluídos em ordem cronológica e mostrar, ao lado de cada um, a **data do pedido imediatamente anterior**.

```sql
SELECT
    pedido_id,
    data_hora_pedido,
    LAG(data_hora_pedido) OVER (ORDER BY data_hora_pedido) AS data_pedido_anterior
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído'
ORDER BY data_hora_pedido
LIMIT 15;
```

**Como ler:**

- `LAG(data_hora_pedido)` — traz o valor de `data_hora_pedido` **da linha anterior**, considerando a ordem definida no `OVER`.
- `OVER (ORDER BY data_hora_pedido)` — a ordem é por data crescente, então "anterior" = "pedido feito antes".
- Resultado: na primeira linha, `data_pedido_anterior` fica **`NULL`** (não existe linha anterior). Nas demais, aparece a data do pedido imediatamente anterior.

**Detalhe importante:** `LAG` **não faz cálculo** — ele só **copia** o valor de outra linha. O cálculo (subtração, comparação) você faz depois, no `SELECT`.

---

# 📗 Exemplo 2 — `LAG()` para calcular variação entre dias

**Cenário:** para cada dia, mostrar o número de pedidos concluídos e **quanto variou** em relação ao dia anterior.

```sql
WITH pedidos_por_dia AS (
    SELECT
        DATE(data_hora_pedido) AS dia,
        COUNT(*) AS qtd_pedidos
    FROM `unipds-503513.entregaja.pedidos`
    WHERE status = 'Concluído'
    GROUP BY dia
)
SELECT
    dia,
    qtd_pedidos,
    LAG(qtd_pedidos) OVER (ORDER BY dia) AS qtd_dia_anterior,
    qtd_pedidos - LAG(qtd_pedidos) OVER (ORDER BY dia) AS variacao_absoluta,
    ROUND(
        (qtd_pedidos - LAG(qtd_pedidos) OVER (ORDER BY dia))
        / LAG(qtd_pedidos) OVER (ORDER BY dia) * 100,
        2
    ) AS variacao_percentual
FROM pedidos_por_dia
ORDER BY dia
LIMIT 30;
```

**Como ler:**

1. A CTE agrega os pedidos **por dia** (uma linha por dia).
2. `LAG(qtd_pedidos) OVER (ORDER BY dia)` traz a quantidade do dia anterior.
3. Subtrair `qtd_pedidos - LAG(...)` dá a **variação absoluta**.
4. Dividir pela quantidade anterior e multiplicar por 100 dá a **variação percentual**.

**O padrão "day-over-day":** este é **o** uso mais clássico de `LAG` — mostrar quanto cada dia (ou mês, ou semana) variou em relação ao anterior. Você repete a mesma expressão `LAG(...) OVER (...)` três vezes na query — o BigQuery é esperto o suficiente para calcular uma vez só.

> ⚠️ **Cuidado com `NULL`:** na primeira linha, `LAG` retorna `NULL`, e qualquer conta com `NULL` vira `NULL`. Se você quiser tratar isso, pode usar `LAG(qtd_pedidos, 1, 0)` — o terceiro argumento é o **default**.

---

# 📙 Exemplo 3 — `LAG()` com `PARTITION BY`: tempo entre pedidos do mesmo cliente

**Cenário:** para cada pedido, calcular **quantos dias se passaram desde o pedido anterior daquele mesmo cliente** — ótimo para entender a frequência de compra de cada um.

```sql
SELECT
    cliente_id,
    pedido_id,
    data_hora_pedido,
    LAG(data_hora_pedido) OVER (
        PARTITION BY cliente_id
        ORDER BY data_hora_pedido
    ) AS pedido_anterior_do_cliente,
    DATE_DIFF(
        DATE(data_hora_pedido),
        DATE(LAG(data_hora_pedido) OVER (
            PARTITION BY cliente_id
            ORDER BY data_hora_pedido
        )),
        DAY
    ) AS dias_desde_ultimo_pedido
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído'
ORDER BY cliente_id, data_hora_pedido
LIMIT 25;
```

**Como ler, peça por peça:**

1. `PARTITION BY cliente_id` → a janela é **por cliente**, então "anterior" significa "pedido anterior **daquele cliente**", não pedido anterior global.
2. `ORDER BY data_hora_pedido` → dentro de cada cliente, ordena pelo tempo.
3. `LAG(data_hora_pedido)` → pega a data do pedido anterior **daquele cliente**.
4. `DATE_DIFF(atual, anterior, DAY)` → calcula quantos dias se passaram.

**Resultado:** no primeiro pedido de cada cliente, `dias_desde_ultimo_pedido` é `NULL` (não há pedido anterior). Nos demais, você vê o intervalo entre pedidos consecutivos do mesmo cliente.

**Uso analítico:** esse padrão é a base do cálculo de **recência** e **retenção** — "clientes com mais de 30 dias sem pedir", "intervalo médio entre pedidos por região", etc.

---

# 📕 Exemplo 4 — `LEAD()`: olhar para a próxima linha

**Cenário:** para cada pedido de um cliente, mostrar **quando ele vai fazer o próximo** — útil pra saber se um pedido teve uma "sequência rápida" depois dele ou se foi seguido por um longo intervalo.

```sql
SELECT
    cliente_id,
    pedido_id,
    data_hora_pedido,
    LEAD(data_hora_pedido) OVER (
        PARTITION BY cliente_id
        ORDER BY data_hora_pedido
    ) AS proximo_pedido_do_cliente,
    DATE_DIFF(
        DATE(LEAD(data_hora_pedido) OVER (
            PARTITION BY cliente_id
            ORDER BY data_hora_pedido
        )),
        DATE(data_hora_pedido),
        DAY
    ) AS dias_ate_proximo_pedido
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído'
ORDER BY cliente_id, data_hora_pedido
LIMIT 25;
```

**Como ler:**

- `LEAD` é o **espelho** de `LAG`: olha para a **próxima linha** em vez da anterior.
- No **último pedido** de cada cliente, `LEAD` retorna `NULL` (não existe próximo).

**Quando usar `LAG` vs. `LEAD`:**

| Pergunta | Função |
|----------|--------|
| "Quanto **variou** desde o último?" | `LAG` |
| "Quanto **falta** até o próximo?" | `LEAD` |
| "Este cliente **voltou** a comprar depois?" | `LEAD` (se `NULL`, não voltou) |
| "Este é o **primeiro** pedido dele?" | `LAG` (se `NULL`, é o primeiro) |

Na prática, `LAG` é bem mais comum — mas `LEAD` é a ferramenta certa quando você quer olhar "para frente".

---

# 📓 Exemplo 5 — `FIRST_VALUE()`: comparar cada linha com o "primeiro" do grupo

**Cenário:** para cada avaliação de um restaurante, mostrar a nota atual e a **primeira nota que aquele restaurante recebeu** — para ver como as avaliações evoluíram em relação ao início.

```sql
SELECT
    p.restaurante_id,
    a.pedido_id,
    p.data_hora_pedido,
    a.nota,
    FIRST_VALUE(a.nota) OVER (
        PARTITION BY p.restaurante_id
        ORDER BY p.data_hora_pedido
    ) AS primeira_nota_do_restaurante,
    a.nota - FIRST_VALUE(a.nota) OVER (
        PARTITION BY p.restaurante_id
        ORDER BY p.data_hora_pedido
    ) AS diferenca_para_primeira_nota
FROM `unipds-503513.entregaja.avaliacoes` AS a
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON a.pedido_id = p.pedido_id
WHERE p.status = 'Concluído'
ORDER BY p.restaurante_id, p.data_hora_pedido
LIMIT 30;
```

**Como ler:**

- `FIRST_VALUE(a.nota)` — pega a **primeira nota** de acordo com a ordem definida no `OVER`.
- `PARTITION BY p.restaurante_id` → o "primeiro" é **por restaurante** (o primeiro de cada, não o global).
- Resultado: todas as linhas de um mesmo restaurante veem a **mesma** primeira nota ao lado.

**Uso típico:** comparar valores atuais com o "estado inicial" — a primeira compra do cliente, a primeira avaliação do produto, o preço original antes de descontos, etc.

---

# 📔 Exemplo 6 — `LAST_VALUE()`: o cuidado com o frame default

**Cenário:** para cada avaliação, mostrar a **última nota que aquele restaurante recebeu** — parece simétrico ao Exemplo 5, mas tem uma pegadinha.

```sql
SELECT
    p.restaurante_id,
    a.pedido_id,
    p.data_hora_pedido,
    a.nota,
    LAST_VALUE(a.nota) OVER (
        PARTITION BY p.restaurante_id
        ORDER BY p.data_hora_pedido
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS ultima_nota_do_restaurante
FROM `unipds-503513.entregaja.avaliacoes` AS a
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON a.pedido_id = p.pedido_id
WHERE p.status = 'Concluído'
ORDER BY p.restaurante_id, p.data_hora_pedido
LIMIT 30;
```

**A pegadinha do `LAST_VALUE`:**

Quando você usa `OVER (ORDER BY ...)` **sem** especificar `ROWS BETWEEN`, o SQL assume o frame **`UNBOUNDED PRECEDING AND CURRENT ROW`** — ou seja, "do início até a linha atual". Isso funciona bem para `SUM` acumulado, mas com `LAST_VALUE` gera um resultado **surpreendente**: o "último" acaba sendo a **linha atual**, porque o frame não inclui as linhas seguintes.

**Solução:** para pegar de verdade o último valor do grupo, sempre escreva explicitamente:

```sql
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
```

Isso força o frame a incluir **todas** as linhas da partição — do começo ao fim.

> 🧭 **Regra prática:** `FIRST_VALUE` funciona bem com o frame default (o primeiro sempre está incluído). `LAST_VALUE` **quase sempre** precisa de `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` para dar o resultado que você espera. Se esquecer, o "último" vira "atual" e a query fica errada silenciosamente.

---

## 📝 Resumo geral

| Função | O que faz | Frame default resolve? |
|--------|-----------|:----------------------:|
| `LAG(col, n, default)` | Valor de N linhas antes | ✅ Sim |
| `LEAD(col, n, default)` | Valor de N linhas depois | ⚠️ **Não** — precisa considerar o frame |
| `FIRST_VALUE(col)` | Primeiro valor da janela | ✅ Sim |
| `LAST_VALUE(col)` | Último valor da janela | ❌ **Não** — sempre use `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` |

**Padrões clássicos:**

```sql
-- Variação em relação ao anterior
valor - LAG(valor) OVER (ORDER BY tempo)

-- Variação percentual
(valor - LAG(valor) OVER (ORDER BY tempo))
  / LAG(valor) OVER (ORDER BY tempo) * 100

-- Tempo entre eventos consecutivos (por grupo)
DATE_DIFF(
    DATE(tempo),
    DATE(LAG(tempo) OVER (PARTITION BY grupo ORDER BY tempo)),
    DAY
)

-- Diferença para o primeiro do grupo
valor - FIRST_VALUE(valor) OVER (PARTITION BY grupo ORDER BY tempo)
```

---

## ⚠️ Cuidados importantes

1. **`ORDER BY` é essencial.** Sem uma ordem definida, "linha anterior" e "linha próxima" não existem — a query pode até rodar, mas o resultado será imprevisível (ou dará erro, dependendo do dialeto).

2. **`LAG` e `LEAD` retornam `NULL` nas bordas.** Na primeira linha, não há anterior — `LAG` volta `NULL`. Na última linha, não há próximo — `LEAD` volta `NULL`. Use o **terceiro argumento** para definir um default: `LAG(col, 1, 0)`.

3. **`LAST_VALUE` sem frame explícito quase sempre dá o resultado errado.** Sempre escreva `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` quando usar `LAST_VALUE` — ou considere usar `FIRST_VALUE` com `ORDER BY ... DESC` como alternativa (é mais seguro).

4. **`LAG(col, n)` — o segundo argumento é o "quantas linhas atrás".** `LAG(nota, 1)` é a linha imediatamente anterior; `LAG(nota, 3)` é a de 3 posições atrás. Default = 1.

5. **`PARTITION BY` reinicia o deslocamento a cada grupo.** Sem ele, `LAG` compara com a linha global anterior. Com ele, compara só com a anterior **dentro do mesmo grupo** — que quase sempre é o que você quer para análise por cliente/produto/região.

6. **Cálculos com `LAG/LEAD` propagam `NULL`.** Se a linha anterior deu `NULL` (por ser a primeira, ou porque a coluna original era `NULL`), qualquer subtração/divisão resulta em `NULL`. Trate isso quando o relatório final precisar de zero em vez de vazio.
