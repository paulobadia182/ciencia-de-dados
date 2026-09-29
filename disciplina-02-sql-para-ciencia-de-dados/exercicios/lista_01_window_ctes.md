# Lista de exercícios 01 — Window functions, CTEs e queries avançadas

**Escopo:** consolidar as aulas **26** (estrutura de window function), **27** (ranking), **28** (deslocamento) e **29** (agregações como window). Os exercícios estão em ordem **crescente de dificuldade** — os primeiros exigem uma window function isolada; os últimos combinam CTEs encadeadas, ranking e agregação numa mesma query.

**Dataset:** `unipds-503513.entregaja.*` no BigQuery — as tabelas em uso são `clientes`, `entregadores`, `pedidos`, `pedido_itens`, `itens`, `restaurantes` e `avaliacoes`.

**Como usar:**

1. Tente resolver **antes** de abrir o gabarito.
2. Rode a sua versão no BigQuery.
3. Só então abra o `<details>` do gabarito e compare — se o resultado bater, ótimo; se não, use a **explicação** pra entender **por que** a versão do gabarito funciona.

> 🧭 **Nomenclatura:** todos os exemplos usam nomes de coluna descritivos (`total_pedido`, `posicao_no_ranking`) — não use `p1`, `p2`, `x`. Nomear bem é metade da leitura da query.

---

## 🟢 Parte 1 — Window functions básicas

### Exercício 1 — `OVER ()` vazio

**Cenário:** o time comercial quer, para cada restaurante, ver a **taxa de entrega** dele e ao lado a **taxa de entrega média de toda a plataforma** — pra saber quem cobra acima ou abaixo da média geral.

**Tarefa:** liste `nome`, `categoria`, `taxa_entrega` e uma coluna `taxa_media_plataforma` (arredondada em 2 casas), ordenado por `taxa_entrega` decrescente. Limite a 15 linhas.

<details>
<summary>✅ Gabarito</summary>

```sql
SELECT
    nome,
    categoria,
    taxa_entrega,
    ROUND(AVG(taxa_entrega) OVER (), 2) AS taxa_media_plataforma
FROM `unipds-503513.entregaja.restaurantes`
ORDER BY taxa_entrega DESC
LIMIT 15;
```

**Explicação:**

- `OVER ()` sem nada dentro significa **"a janela é a tabela inteira"** — a média é calculada sobre **todas as linhas** e o mesmo valor aparece ao lado de cada uma.
- Não precisa de `GROUP BY`: o `OVER` **libera** a mistura entre coluna individual (`nome`, `categoria`) e função de agregação (`AVG`) — coisa que numa query com `GROUP BY` daria erro.
- É o menor `OVER` possível. Serve pra fixar o esqueleto antes de adicionar `PARTITION BY` e `ORDER BY`.

</details>

---

### Exercício 2 — `PARTITION BY`

**Cenário:** para cada cliente, mostre a **idade dele** e ao lado a **idade média dos clientes do mesmo plano** (Free, Premium, ...) — pra ver se ele é mais velho ou mais novo que o segmento a que pertence.

**Tarefa:** liste `nome`, `plano`, `idade` e `idade_media_plano` (arredondada em 1 casa). Ordene por `plano` e, dentro do plano, por idade decrescente. Limite a 20 linhas.

<details>
<summary>✅ Gabarito</summary>

```sql
SELECT
    nome,
    plano,
    idade,
    ROUND(AVG(idade) OVER (PARTITION BY plano), 1) AS idade_media_plano
FROM `unipds-503513.entregaja.clientes`
ORDER BY plano, idade DESC
LIMIT 20;
```

**Explicação:**

- `PARTITION BY plano` divide as linhas em **grupos por plano** — a média é recalculada para cada grupo, mas **sem colapsar**: cada cliente continua aparecendo.
- Todos os clientes do mesmo plano veem o **mesmo** valor de `idade_media_plano`.
- É o "GROUP BY do OVER" — mas ele **não some as linhas**, só define grupos internos pro cálculo da janela.

</details>

---

### Exercício 3 — `PARTITION BY` + comparação linha vs. grupo

**Cenário:** pra cada item de cardápio, mostre seu `preco` e ao lado a **diferença entre o preço dele e a média da categoria** — positivo indica item acima da média, negativo indica item abaixo.

**Tarefa:** liste `nome_item`, `categoria_item`, `preco`, `preco_medio_categoria` e `diferenca_para_media` (as duas últimas arredondadas em 2 casas). Ordene por `categoria_item` e `diferenca_para_media` decrescente. Limite a 20 linhas.

<details>
<summary>✅ Gabarito</summary>

```sql
SELECT
    nome_item,
    categoria_item,
    preco,
    ROUND(AVG(preco) OVER (PARTITION BY categoria_item), 2) AS preco_medio_categoria,
    ROUND(preco - AVG(preco) OVER (PARTITION BY categoria_item), 2) AS diferenca_para_media
FROM `unipds-503513.entregaja.itens`
ORDER BY categoria_item, diferenca_para_media DESC
LIMIT 20;
```

**Explicação:**

- O padrão **"linha vs. grupo"** — calcula o agregado do grupo com `OVER` e **subtrai** da linha atual.
- Repare que a mesma expressão `AVG(preco) OVER (PARTITION BY categoria_item)` aparece **duas vezes**. O BigQuery é esperto o suficiente para calcular uma vez só e reusar — não é ineficiente.
- Sempre que você quiser saber "**quanto esta linha desvia do grupo dela**", esse é o esqueleto.

</details>

---

## 🟡 Parte 2 — Ranking

### Exercício 4 — `ROW_NUMBER()` + CTE: pedido mais recente de cada cliente

**Cenário:** o time de CS quer, pra cada cliente, saber **qual foi o pedido mais recente dele** e o status daquele pedido — uma linha por cliente.

**Tarefa:** usando uma CTE, numere os pedidos de cada cliente por data decrescente e traga só o mais recente. Devolva `cliente_id`, `pedido_id`, `data_hora_pedido` e `status`. Ordene pelos pedidos mais recentes primeiro. Limite a 15 linhas.

<details>
<summary>✅ Gabarito</summary>

```sql
WITH pedidos_numerados AS (
    SELECT
        cliente_id,
        pedido_id,
        data_hora_pedido,
        status,
        ROW_NUMBER() OVER (
            PARTITION BY cliente_id
            ORDER BY data_hora_pedido DESC
        ) AS ordem_do_cliente
    FROM `unipds-503513.entregaja.pedidos`
)
SELECT
    cliente_id,
    pedido_id,
    data_hora_pedido,
    status
FROM pedidos_numerados
WHERE ordem_do_cliente = 1
ORDER BY data_hora_pedido DESC
LIMIT 15;
```

**Explicação:**

- Não dá pra filtrar por window function no `WHERE` (janela roda **depois** do `WHERE`) — daí a **CTE**: primeiro numera, depois filtra na query externa.
- **Por que `ROW_NUMBER` e não `RANK`?** Se dois pedidos empatarem na data, `RANK` daria posição 1 pros dois e você teria 2 pedidos daquele cliente. `ROW_NUMBER` escolhe **um só**, garantindo uma linha por cliente.
- Padrão canônico "**a linha mais X de cada Y**" → `ROW_NUMBER() OVER (PARTITION BY Y ORDER BY X DESC)` + `WHERE ordem = 1`.

</details>

---

### Exercício 5 — `RANK()` com `PARTITION BY`: top 3 por grupo

**Cenário:** o time de marketing quer os **3 restaurantes mais bem avaliados de cada categoria** (Pizzaria, Japonesa, Hambúrguer, ...) — para destacar num banner regional.

**Tarefa:** considere só pedidos com status `'Concluído'` que têm avaliação. Calcule a nota média de cada restaurante e, dentro de cada categoria, ranqueie por nota média decrescente. Devolva `categoria`, `nome`, `nota_media` (2 casas), `qtd_avaliacoes` e `posicao_na_categoria` — apenas as posições 1 a 3. Ordene por categoria e posição.

<details>
<summary>✅ Gabarito</summary>

```sql
WITH ranking_por_categoria AS (
    SELECT
        r.categoria,
        r.nome,
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
    GROUP BY r.categoria, r.nome
)
SELECT *
FROM ranking_por_categoria
WHERE posicao_na_categoria <= 3
ORDER BY categoria, posicao_na_categoria;
```

**Explicação:**

- **`GROUP BY` + window function na mesma query:** primeiro o `GROUP BY r.categoria, r.nome` colapsa em uma linha por restaurante; depois o `RANK() OVER (...)` ranqueia esse resultado agregado.
- Dentro do `OVER`, usamos `AVG(a.nota)` (não `nota_media`, o alias) — na maioria dos dialetos você **não pode** usar aliases do `SELECT` dentro do `OVER` na mesma query. Solução: repetir a expressão.
- **Por que `RANK` e não `ROW_NUMBER`?** Se dois restaurantes empatarem na nota média, `RANK` mantém os dois em 2º (ranking justo). `ROW_NUMBER` escolheria arbitrariamente qual fica em 2º e qual em 3º.
- Filtrar `posicao_na_categoria <= 3` só é possível **na query externa** — daí a CTE.

</details>

---

## 🟠 Parte 3 — Running totals e médias móveis

### Exercício 6 — Running total: pedidos acumulados por dia

**Cenário:** o time financeiro quer, por dia, ver **quantos pedidos concluídos aconteceram** e **quantos já foram acumulados no total** desde o começo — uma curva de crescimento acumulado.

**Tarefa:** agregue os pedidos concluídos por dia numa CTE. Depois, devolva `dia`, `qtd_pedidos_dia` e `qtd_pedidos_acumulada`. Ordene por dia crescente. Limite a 30 linhas.

<details>
<summary>✅ Gabarito</summary>

```sql
WITH pedidos_por_dia AS (
    SELECT
        DATE(data_hora_pedido) AS dia,
        COUNT(*) AS qtd_pedidos_dia
    FROM `unipds-503513.entregaja.pedidos`
    WHERE status = 'Concluído'
    GROUP BY dia
)
SELECT
    dia,
    qtd_pedidos_dia,
    SUM(qtd_pedidos_dia) OVER (ORDER BY dia) AS qtd_pedidos_acumulada
FROM pedidos_por_dia
ORDER BY dia
LIMIT 30;
```

**Explicação:**

- `SUM(qtd_pedidos_dia) OVER (ORDER BY dia)` **sem** `PARTITION BY` — a janela é a tabela inteira, ordenada por dia.
- **Sem `ROWS BETWEEN`**, o frame default é `UNBOUNDED PRECEDING AND CURRENT ROW` → "do início até a linha atual". Ou seja, running total clássico.
- Compare mentalmente:
  - `SUM(x) OVER ()` → total geral (mesmo valor em todas as linhas).
  - `SUM(x) OVER (ORDER BY dia)` → total **até este dia** (cresce a cada linha).
- Adicionar `ORDER BY` dentro do `OVER` **muda o significado da agregação**, não é só ordenação.

</details>

---

### Exercício 7 — Média móvel de 7 dias

**Cenário:** a área de qualidade quer suavizar as flutuações diárias da satisfação — calcular, pra cada dia, a **média das notas dos últimos 7 dias** (o dia atual + os 6 anteriores).

**Tarefa:** agregue a nota média por dia numa CTE, e depois devolva `dia`, `nota_media_dia` (2 casas) e `media_movel_7d` (2 casas). Ordene por dia crescente. Limite a 30 linhas.

<details>
<summary>✅ Gabarito</summary>

```sql
WITH avaliacoes_por_dia AS (
    SELECT
        DATE(data_avaliacao) AS dia,
        ROUND(AVG(nota), 2) AS nota_media_dia
    FROM `unipds-503513.entregaja.avaliacoes`
    GROUP BY dia
)
SELECT
    dia,
    nota_media_dia,
    ROUND(
        AVG(nota_media_dia) OVER (
            ORDER BY dia
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS media_movel_7d
FROM avaliacoes_por_dia
ORDER BY dia
LIMIT 30;
```

**Explicação:**

- `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` = 7 linhas (a atual + as 6 anteriores). Sem esse frame explícito, o SQL assumiria `UNBOUNDED PRECEDING AND CURRENT ROW`, o que daria uma **média acumulada** (do início até agora), não uma média móvel.
- **Regra sutil:** `ROWS BETWEEN` só faz sentido com `ORDER BY` — frames operam sobre linhas em ordem.
- Nos **primeiros 6 dias** da série, a média móvel considera menos de 7 linhas (só as que existem). Se você quiser ignorar os primeiros dias incompletos, adicione um `WHERE` no fim ou use `ROW_NUMBER() >= 7` numa CTE extra.

</details>

---

## 🔵 Parte 4 — Deslocamento (`LAG`, `LEAD`, `FIRST_VALUE`)

### Exercício 8 — `LAG()` para variação percentual

**Cenário:** o time financeiro quer o **crescimento day-over-day** — pra cada dia, quantos pedidos aconteceram, quantos tinham no dia anterior e a **variação percentual**.

**Tarefa:** parta da CTE de pedidos por dia (só concluídos). Devolva `dia`, `qtd_pedidos_dia`, `qtd_dia_anterior` e `variacao_percentual` (2 casas). Ordene por dia. Limite a 30 linhas.

<details>
<summary>✅ Gabarito</summary>

```sql
WITH pedidos_por_dia AS (
    SELECT
        DATE(data_hora_pedido) AS dia,
        COUNT(*) AS qtd_pedidos_dia
    FROM `unipds-503513.entregaja.pedidos`
    WHERE status = 'Concluído'
    GROUP BY dia
)
SELECT
    dia,
    qtd_pedidos_dia,
    LAG(qtd_pedidos_dia) OVER (ORDER BY dia) AS qtd_dia_anterior,
    ROUND(
        (qtd_pedidos_dia - LAG(qtd_pedidos_dia) OVER (ORDER BY dia))
        / LAG(qtd_pedidos_dia) OVER (ORDER BY dia) * 100,
        2
    ) AS variacao_percentual
FROM pedidos_por_dia
ORDER BY dia
LIMIT 30;
```

**Explicação:**

- `LAG(qtd_pedidos_dia) OVER (ORDER BY dia)` traz o valor do dia **imediatamente anterior**. Na primeira linha, retorna `NULL` (não há anterior).
- A fórmula é o **day-over-day clássico**: `(atual - anterior) / anterior * 100`.
- Repetir `LAG(...) OVER (...)` três vezes na mesma query **não é ineficiente**: o BigQuery deduplica internamente.
- **Cuidado com `NULL`:** qualquer conta com `NULL` vira `NULL`. Se você quiser um default (ex.: zero), use `LAG(qtd_pedidos_dia, 1, 0)`.

</details>

---

### Exercício 9 — `LAG()` + `PARTITION BY`: intervalo entre pedidos do mesmo cliente

**Cenário:** a equipe de retenção quer entender **a frequência de compra de cada cliente** — pra cada pedido, quantos dias se passaram desde o pedido anterior daquele mesmo cliente.

**Tarefa:** considere apenas pedidos concluídos. Devolva `cliente_id`, `pedido_id`, `data_hora_pedido` e `dias_desde_pedido_anterior`. Ordene por `cliente_id` e `data_hora_pedido`. Limite a 25 linhas.

<details>
<summary>✅ Gabarito</summary>

```sql
SELECT
    cliente_id,
    pedido_id,
    data_hora_pedido,
    DATE_DIFF(
        DATE(data_hora_pedido),
        DATE(LAG(data_hora_pedido) OVER (
            PARTITION BY cliente_id
            ORDER BY data_hora_pedido
        )),
        DAY
    ) AS dias_desde_pedido_anterior
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído'
ORDER BY cliente_id, data_hora_pedido
LIMIT 25;
```

**Explicação:**

- `PARTITION BY cliente_id` — sem isso, `LAG` compararia com o pedido anterior **global** (qualquer cliente). Com isso, compara com o pedido anterior **do mesmo cliente**.
- No **primeiro pedido de cada cliente**, `LAG` retorna `NULL` → `DATE_DIFF` também dá `NULL`. Está correto: aquele cliente não tinha pedido anterior.
- É a base do cálculo de **recência** e **retenção** — "clientes com intervalo médio > 30 dias", "gap máximo entre compras", etc.

</details>

---

### Exercício 10 — `FIRST_VALUE()`: evolução em relação ao primeiro

**Cenário:** para cada avaliação recebida por um restaurante, mostrar a nota atual e a **primeira nota que ele já recebeu** — pra ver se a percepção melhorou ou piorou desde o começo.

**Tarefa:** considere só pedidos concluídos com avaliação. Devolva `restaurante_id`, `data_hora_pedido`, `nota`, `primeira_nota` e `diferenca_para_primeira`. Ordene por `restaurante_id` e `data_hora_pedido`. Limite a 25 linhas.

<details>
<summary>✅ Gabarito</summary>

```sql
SELECT
    p.restaurante_id,
    p.data_hora_pedido,
    a.nota,
    FIRST_VALUE(a.nota) OVER (
        PARTITION BY p.restaurante_id
        ORDER BY p.data_hora_pedido
    ) AS primeira_nota,
    a.nota - FIRST_VALUE(a.nota) OVER (
        PARTITION BY p.restaurante_id
        ORDER BY p.data_hora_pedido
    ) AS diferenca_para_primeira
FROM `unipds-503513.entregaja.avaliacoes` AS a
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON a.pedido_id = p.pedido_id
WHERE p.status = 'Concluído'
ORDER BY p.restaurante_id, p.data_hora_pedido
LIMIT 25;
```

**Explicação:**

- `FIRST_VALUE(a.nota) OVER (PARTITION BY p.restaurante_id ORDER BY p.data_hora_pedido)` pega a **primeira nota** de cada restaurante, na ordem cronológica.
- Todas as linhas do mesmo restaurante veem a **mesma** primeira nota — dá pra subtrair diretamente.
- **Por que não `LAST_VALUE`?** Porque com o frame default (`UNBOUNDED PRECEDING AND CURRENT ROW`), o "último" acaba sendo **a linha atual**. Se você quiser a **última** nota de verdade, precisaria de `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` — ou usar `FIRST_VALUE(...) OVER (... ORDER BY ... DESC)`, que é mais seguro.

</details>

---

## 🔴 Parte 5 — Queries combinadas (CTEs encadeadas + múltiplas windows)

### Exercício 11 — Percentual do total: contribuição de cada categoria no faturamento

**Cenário:** o time de estratégia quer, por categoria de restaurante, saber **o faturamento total** dela e **quanto essa categoria representa do faturamento da plataforma** — em % e com ranking.

**Tarefa:** encadeie CTEs. Primeiro calcule o faturamento de cada pedido (soma de `quantidade * preco_unitario` em `pedido_itens`). Depois some por categoria de restaurante. Na query final, mostre `categoria`, `faturamento_categoria` (2 casas), `percentual_do_total` (2 casas) e `posicao_no_ranking` — ordenado por faturamento decrescente. Considere apenas pedidos concluídos.

<details>
<summary>✅ Gabarito</summary>

```sql
WITH faturamento_por_pedido AS (
    SELECT
        pi.pedido_id,
        SUM(pi.quantidade * pi.preco_unitario) AS valor_pedido
    FROM `unipds-503513.entregaja.pedido_itens` AS pi
    GROUP BY pi.pedido_id
),
faturamento_por_categoria AS (
    SELECT
        r.categoria,
        SUM(fp.valor_pedido) AS faturamento_categoria
    FROM faturamento_por_pedido AS fp
    INNER JOIN `unipds-503513.entregaja.pedidos` AS p
        ON fp.pedido_id = p.pedido_id
    INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
        ON p.restaurante_id = r.restaurante_id
    WHERE p.status = 'Concluído'
    GROUP BY r.categoria
)
SELECT
    categoria,
    ROUND(faturamento_categoria, 2) AS faturamento_categoria,
    ROUND(
        faturamento_categoria / SUM(faturamento_categoria) OVER () * 100,
        2
    ) AS percentual_do_total,
    RANK() OVER (ORDER BY faturamento_categoria DESC) AS posicao_no_ranking
FROM faturamento_por_categoria
ORDER BY faturamento_categoria DESC;
```

**Explicação:**

- **Duas CTEs encadeadas:** a primeira calcula o valor de cada pedido (some os itens); a segunda soma por categoria (com join no pedido pra filtrar concluídos e no restaurante pra pegar a categoria).
- **`SUM(...) OVER ()` como total geral:** ao dividir `faturamento_categoria / SUM(faturamento_categoria) OVER ()`, você tem o percentual de cada categoria sobre o total. Padrão clássico de "**% do total**".
- **`RANK` ao lado da % do total:** duas window functions **na mesma query**, cada uma respondendo uma pergunta diferente — participação e posição.
- Ordenar por `faturamento_categoria DESC` no fim faz o ranking casar visualmente com a ordem exibida.

</details>

---

### Exercício 12 — Cliente mais valioso de cada cidade

**Cenário:** o time comercial quer descobrir, **em cada cidade**, quem é o **cliente que mais gastou** — nome, valor total gasto e a cidade.

**Tarefa:** encadeie CTEs. Primeiro calcule o valor de cada pedido; depois some por cliente; depois traga a cidade do cliente e ranqueie **dentro da cidade**. Devolva só o top 1 de cada cidade. Considere apenas pedidos concluídos.

<details>
<summary>✅ Gabarito</summary>

```sql
WITH faturamento_por_pedido AS (
    SELECT
        pi.pedido_id,
        SUM(pi.quantidade * pi.preco_unitario) AS valor_pedido
    FROM `unipds-503513.entregaja.pedido_itens` AS pi
    GROUP BY pi.pedido_id
),
gasto_por_cliente AS (
    SELECT
        p.cliente_id,
        SUM(fp.valor_pedido) AS gasto_total
    FROM faturamento_por_pedido AS fp
    INNER JOIN `unipds-503513.entregaja.pedidos` AS p
        ON fp.pedido_id = p.pedido_id
    WHERE p.status = 'Concluído'
    GROUP BY p.cliente_id
),
ranking_por_cidade AS (
    SELECT
        c.cidade,
        c.nome,
        gc.gasto_total,
        ROW_NUMBER() OVER (
            PARTITION BY c.cidade
            ORDER BY gc.gasto_total DESC
        ) AS posicao_na_cidade
    FROM gasto_por_cliente AS gc
    INNER JOIN `unipds-503513.entregaja.clientes` AS c
        ON gc.cliente_id = c.cliente_id
)
SELECT
    cidade,
    nome,
    ROUND(gasto_total, 2) AS gasto_total
FROM ranking_por_cidade
WHERE posicao_na_cidade = 1
ORDER BY gasto_total DESC;
```

**Explicação:**

- **Três CTEs em cascata**, cada uma com uma responsabilidade clara:
  1. `faturamento_por_pedido` → valor de cada pedido.
  2. `gasto_por_cliente` → soma do gasto por cliente (filtrando concluídos).
  3. `ranking_por_cidade` → junta com `clientes` pra ter a cidade e ranqueia dentro dela.
- **`ROW_NUMBER` (não `RANK`) porque queremos exatamente 1 cliente por cidade.** Se dois empatarem no gasto, `RANK` traria os dois e a saída teria mais linhas que cidades.
- **Filtro `WHERE posicao_na_cidade = 1`** só é possível na query externa — window function não roda no `WHERE` da mesma seleção que a criou.
- Padrão: "**o top 1 de cada Y**" → CTE com `ROW_NUMBER() OVER (PARTITION BY Y ORDER BY X DESC)` + `WHERE ordem = 1`.

</details>

---

### Exercício 13 — Mês a mês: novos clientes vs. crescimento acumulado

**Cenário:** a diretoria quer, por mês, ver **quantos clientes novos entraram** e o **total acumulado** de clientes na base até aquele mês — pra visualizar a curva de crescimento da plataforma.

**Tarefa:** agregue os cadastros por mês numa CTE (use `DATE_TRUNC(data_cadastro, MONTH)`). Depois devolva `mes`, `clientes_novos_no_mes`, `clientes_acumulados` e `variacao_percentual_mes_anterior` (2 casas). Ordene por mês crescente.

<details>
<summary>✅ Gabarito</summary>

```sql
WITH cadastros_por_mes AS (
    SELECT
        DATE_TRUNC(DATE(data_cadastro), MONTH) AS mes,
        COUNT(*) AS clientes_novos_no_mes
    FROM `unipds-503513.entregaja.clientes`
    GROUP BY mes
)
SELECT
    mes,
    clientes_novos_no_mes,
    SUM(clientes_novos_no_mes) OVER (ORDER BY mes) AS clientes_acumulados,
    ROUND(
        (clientes_novos_no_mes - LAG(clientes_novos_no_mes) OVER (ORDER BY mes))
        / LAG(clientes_novos_no_mes) OVER (ORDER BY mes) * 100,
        2
    ) AS variacao_percentual_mes_anterior
FROM cadastros_por_mes
ORDER BY mes;
```

**Explicação:**

- **Três windows na mesma query, cada uma com um papel:**
  1. Nenhuma (`clientes_novos_no_mes`) → veio da CTE via `GROUP BY`.
  2. `SUM(...) OVER (ORDER BY mes)` → running total mês a mês.
  3. `LAG(...) OVER (ORDER BY mes)` → variação em relação ao mês anterior.
- Elas convivem sem interferir uma na outra — o SQL calcula cada `OVER` de forma independente.
- **Primeira linha:** `LAG` retorna `NULL` → variação percentual fica `NULL`. Correto: não há mês anterior pra comparar.
- **`DATE_TRUNC(..., MONTH)`** joga qualquer data pro primeiro dia do mês — todos os cadastros de outubro/2023 viram `2023-10-01`, o que permite agrupar por mês.

</details>

---

### Exercício 14 — Restaurantes acima da média da própria categoria

**Cenário:** achar os restaurantes que estão **acima da média de nota da sua categoria** — os "destaques" de cada segmento.

**Tarefa:** calcule a nota média de cada restaurante (só pedidos concluídos com avaliação). Depois compare com a média da categoria dele. Devolva `categoria`, `nome`, `nota_media_restaurante` (2 casas), `nota_media_categoria` (2 casas) e `diferenca_para_categoria` (2 casas) — apenas os que estão **acima** da média da categoria. Ordene por categoria e diferença decrescente.

<details>
<summary>✅ Gabarito</summary>

```sql
WITH nota_por_restaurante AS (
    SELECT
        r.categoria,
        r.nome,
        AVG(a.nota) AS nota_media_restaurante
    FROM `unipds-503513.entregaja.avaliacoes` AS a
    INNER JOIN `unipds-503513.entregaja.pedidos` AS p
        ON a.pedido_id = p.pedido_id
    INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
        ON p.restaurante_id = r.restaurante_id
    WHERE p.status = 'Concluído'
    GROUP BY r.categoria, r.nome
),
comparacao_com_categoria AS (
    SELECT
        categoria,
        nome,
        nota_media_restaurante,
        AVG(nota_media_restaurante) OVER (PARTITION BY categoria) AS nota_media_categoria
    FROM nota_por_restaurante
)
SELECT
    categoria,
    nome,
    ROUND(nota_media_restaurante, 2) AS nota_media_restaurante,
    ROUND(nota_media_categoria, 2) AS nota_media_categoria,
    ROUND(nota_media_restaurante - nota_media_categoria, 2) AS diferenca_para_categoria
FROM comparacao_com_categoria
WHERE nota_media_restaurante > nota_media_categoria
ORDER BY categoria, diferenca_para_categoria DESC;
```

**Explicação:**

- **Duas CTEs:**
  1. `nota_por_restaurante` → agrega por restaurante (colapsa via `GROUP BY`).
  2. `comparacao_com_categoria` → aplica `AVG(...) OVER (PARTITION BY categoria)` pra ter a média da categoria ao lado.
- **Por que precisa da segunda CTE?** Porque o `WHERE nota_media_restaurante > nota_media_categoria` compara com o resultado da window function — e window function não roda no mesmo `WHERE`. Solução: calcular na CTE, filtrar na query externa.
- **Cuidado com `GROUP BY` + `OVER` na mesma query:** aqui separamos em duas CTEs pra ficar mais legível. Dava pra fazer numa CTE só (com `GROUP BY` e `AVG(AVG(...)) OVER (PARTITION BY categoria)`), mas fica confuso — CTEs em cascata deixam cada etapa explícita.

</details>

---

## 📝 Resumo dos padrões usados

| Padrão | Exercícios | Estrutura |
|--------|-----------|-----------|
| `OVER ()` — valor global ao lado da linha | 1 | `funcao(x) OVER ()` |
| `PARTITION BY` — agregado por grupo ao lado | 2, 3 | `funcao(x) OVER (PARTITION BY g)` |
| "Top 1 de cada grupo" | 4, 12 | CTE + `ROW_NUMBER() OVER (PARTITION BY g ORDER BY x DESC)` + `WHERE ordem = 1` |
| "Top N de cada grupo" | 5 | CTE + `RANK() OVER (PARTITION BY g ORDER BY x DESC)` + `WHERE posicao <= N` |
| Running total | 6, 13 | `SUM(x) OVER (ORDER BY t)` |
| Média móvel | 7 | `AVG(x) OVER (ORDER BY t ROWS BETWEEN N PRECEDING AND CURRENT ROW)` |
| Variação com anterior | 8, 13 | `LAG(x) OVER (ORDER BY t)` |
| Intervalo entre eventos do mesmo grupo | 9 | `DATE_DIFF(atual, LAG(atual) OVER (PARTITION BY g ORDER BY t), DAY)` |
| Comparar com o primeiro do grupo | 10 | `FIRST_VALUE(x) OVER (PARTITION BY g ORDER BY t)` |
| % do total | 11 | `x / SUM(x) OVER () * 100` |
| Comparar linha com média do grupo | 3, 14 | `x - AVG(x) OVER (PARTITION BY g)` |

---

## ⚠️ Cuidados que reaparecem em todo exercício

1. **Window function não roda no `WHERE`** — pra filtrar por resultado dela, sempre use **CTE + filtro na query externa**.
2. **`ORDER BY` dentro do `OVER` muda o significado** da agregação: sem ele, é "total do grupo"; com ele, vira **acumulado**.
3. **`ROWS BETWEEN` só faz sentido com `ORDER BY`** — sem ordem, não há "linhas anteriores".
4. **`LAG`/`LEAD` retornam `NULL` nas bordas** — a primeira linha não tem anterior, a última não tem próxima. Trate com o terceiro argumento (`LAG(x, 1, 0)`) se precisar.
5. **Alias do `SELECT` não funciona dentro do `OVER`** na mesma query — repita a expressão.
6. **Duas windows na mesma query são comuns e OK** — cada `OVER (...)` é calculado independentemente.
