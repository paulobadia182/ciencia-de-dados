# Gabarito da aula 24:

## Conteúdo acumulado (aulas 10 a 23):
- **Consultas básicas:** `SELECT`, `FROM`, `DISTINCT`, `LIMIT`, `ORDER BY`
- **Filtros e operadores:** `WHERE` com aritméticos (`+`, `-`, `*`, `/`), comparação (`>`, `<`, `>=`, `<=`, `=`, `<>`) e lógicos (`AND`, `OR`, `NOT`)
- **Condicionais:** `IF`, `CASE`, `COALESCE`
- **Funções de data:** `EXTRACT`, `DATE_TRUNC`, `DATE_DIFF`/`DATETIME_DIFF`, `DATE_ADD`/`DATE_SUB`, `FORMAT_DATE`/`PARSE_DATE`, `CURRENT_DATE`
- **Funções de texto:** `UPPER`/`LOWER`/`INITCAP`, `TRIM`/`LTRIM`/`RTRIM`, `LENGTH`, `SUBSTR`/`STRPOS`/`SPLIT`, `REPLACE`/`REGEXP_REPLACE`
- **JOINs:** `INNER`, `LEFT`, `RIGHT`, `FULL`
- **Agregação e agrupamento:** `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, `HAVING`
- **Subqueries e CTEs:** subquery no `WHERE` (`=`/`>`/`<`, `IN`, `NOT IN`), subquery no `FROM` (tabela derivada), subquery no `SELECT` (escalar), `WITH` (CTEs simples, reusadas e encadeadas)


### EXERCÍCIOS:


* **Exercício 01** *(fácil)*: O time de BI quer ver os pedidos com **taxa de entrega acima da média geral** (de todos os pedidos). Traga `pedido_id`, `forma_pagamento` e `taxa_entrega`. Ordene por `taxa_entrega` decrescente e limite a **15 linhas**.

```sql
SELECT 
    pedido_id,
    forma_pagamento,
    taxa_entrega
FROM `unipds-503513.entregaja.pedidos`
WHERE taxa_entrega > (
    SELECT AVG(taxa_entrega) 
    FROM `unipds-503513.entregaja.pedidos`
)
ORDER BY taxa_entrega DESC
LIMIT 15;
```

> 💡 Caso clássico de **subquery escalar no `WHERE`**: a subquery devolve **um único valor** (a média de todas as taxas) e o operador `>` compara cada linha contra esse valor. Como a subquery não depende da linha atual, o BigQuery a executa **uma única vez**.

---
* **Exercício 02** *(fácil)*: A equipe de Operações quer todos os pedidos feitos por clientes da **região Sul**. Use uma **subquery com `IN`** (não use `JOIN`). Traga `pedido_id`, `cliente_id`, `status` e `data_hora_pedido`. Ordene por `data_hora_pedido` decrescente e limite a **15 linhas**.

```sql
SELECT 
    pedido_id,
    cliente_id,
    status,
    data_hora_pedido
FROM `unipds-503513.entregaja.pedidos`
WHERE cliente_id IN (
    SELECT cliente_id 
    FROM `unipds-503513.entregaja.clientes` 
    WHERE regiao = 'Sul'
)
ORDER BY data_hora_pedido DESC
LIMIT 15;
```

> 💡 A subquery devolve uma **lista** de `cliente_id`s da região Sul; o `IN` filtra os pedidos mantendo só os que estão nessa lista. Poderia ser feito com `INNER JOIN`, mas como não precisamos de nenhuma coluna da tabela `clientes` no resultado, a subquery deixa a intenção ("só quero filtrar") mais clara.

---
* **Exercício 03** *(fácil)*: O time de Parcerias quer identificar **restaurantes que nunca receberam pedidos** (para reavaliar o cadastro). Use `NOT IN`. Traga `restaurante_id`, `nome` e `categoria`. Ordene por `nome` e limite a **15 linhas**.

```sql
SELECT 
    restaurante_id,
    nome,
    categoria
FROM `unipds-503513.entregaja.restaurantes`
WHERE restaurante_id NOT IN (
    SELECT DISTINCT restaurante_id 
    FROM `unipds-503513.entregaja.pedidos`
)
ORDER BY nome
LIMIT 15;
```

> 💡 Padrão **anti-join** com `NOT IN`: retorna os restaurantes cujo `restaurante_id` **não aparece** na lista da subquery. Lembre-se do cuidado com `NULL`: se `restaurante_id` em `pedidos` pudesse ser nulo, o `NOT IN` retornaria zero linhas — nesse dataset a coluna não é nula, então funciona.

---
* **Exercício 04** *(médio)*: O time de Operações quer investigar pedidos com **tempo de entrega maior que o 50% da média** dos pedidos concluídos. Traga `pedido_id`, `tempo_entrega_min` e `status`. Ordene por `tempo_entrega_min` decrescente e limite a **15 linhas**.

```sql
SELECT 
    pedido_id,
    tempo_entrega_min,
    status
FROM `unipds-503513.entregaja.pedidos`
WHERE tempo_entrega_min > 0.5 * (
    SELECT AVG(tempo_entrega_min) 
    FROM `unipds-503513.entregaja.pedidos`
    WHERE status = 'Concluído'
)
ORDER BY tempo_entrega_min DESC
LIMIT 15;
```

> 💡 Nada impede aplicar **operações aritméticas** ao resultado da subquery — aqui multiplicamos por 2. O `WHERE` **dentro** da subquery filtra os pedidos concluídos antes do `AVG`, deixando o benchmark mais preciso. O `WHERE` **de fora** não precisa filtrar por status: se o time quer investigar qualquer pedido lento, deixa passar todos.

---
* **Exercício 05** *(médio)*: O time Executivo quer saber, **em média, quantos pedidos cada restaurante recebeu**, além do mínimo e do máximo. Use **subquery no `FROM`**. Retorne `media_pedidos_por_restaurante` (arredondada em 2 casas), `min_pedidos` e `max_pedidos`.

```sql
SELECT 
    ROUND(AVG(qtd_pedidos), 2) AS media_pedidos_por_restaurante,
    MIN(qtd_pedidos) AS min_pedidos,
    MAX(qtd_pedidos) AS max_pedidos
FROM (
    SELECT 
        restaurante_id,
        COUNT(*) AS qtd_pedidos
    FROM `unipds-503513.entregaja.pedidos`
    GROUP BY restaurante_id
) AS pedidos_por_restaurante;
```

> 💡 Clássica **agregação sobre agregação**: primeiro contamos quantos pedidos cada restaurante recebeu (uma linha por restaurante), depois agregamos essa tabela derivada para obter média, mínimo e máximo. Não daria para escrever `AVG(COUNT(*))` numa query só. Lembre-se: subquery no `FROM` **exige alias** (aqui, `pedidos_por_restaurante`).

---
* **Exercício 06** *(médio)*: O time de Customer Success quer, para cada avaliação, comparar a nota com a **média geral de todas as avaliações**. Use **subquery no `SELECT`**. Traga `avaliacao_id`, `nota`, `nota_media_geral` (arredondada em 2 casas) e `diferenca_da_media` (nota − média). Ordene por `diferenca_da_media` decrescente e limite a **15 linhas**.

```sql
SELECT 
    avaliacao_id,
    nota,
    (
        SELECT ROUND(AVG(nota), 2) 
        FROM `unipds-503513.entregaja.avaliacoes`
    ) AS nota_media_geral,
    nota - (
        SELECT AVG(nota) 
        FROM `unipds-503513.entregaja.avaliacoes`
    ) AS diferenca_da_media
FROM `unipds-503513.entregaja.avaliacoes`
ORDER BY diferenca_da_media DESC
LIMIT 15;
```

> 💡 **Subquery no `SELECT`** (escalar) traz um valor auxiliar ao lado de cada linha. Como o cálculo não depende da linha atual, o BigQuery executa a subquery **uma vez** e reaproveita o resultado em todas as linhas. Repare que o **mesmo cálculo aparece duas vezes** (uma pra mostrar, outra pra subtrair) — é exatamente o desconforto que a **CTE** vai resolver nos próximos exercícios.

---
* **Exercício 07** *(médio-difícil)*: **Reescreva o Exercício 05 usando CTE** (com `WITH`). O resultado deve ser idêntico: `media_pedidos_por_restaurante` (arredondada em 2 casas), `min_pedidos` e `max_pedidos`.

```sql
WITH pedidos_por_restaurante AS (
    SELECT 
        restaurante_id,
        COUNT(*) AS qtd_pedidos
    FROM `unipds-503513.entregaja.pedidos`
    GROUP BY restaurante_id
)
SELECT 
    ROUND(AVG(qtd_pedidos), 2) AS media_pedidos_por_restaurante,
    MIN(qtd_pedidos) AS min_pedidos,
    MAX(qtd_pedidos) AS max_pedidos
FROM pedidos_por_restaurante;
```

> 💡 Resultado **idêntico** ao Exercício 05 — a diferença é puramente estilística. A CTE dá **um nome** (`pedidos_por_restaurante`) ao cálculo intermediário, o que deixa a query principal mais limpa: primeiro você vê o que está sendo calculado, depois como está sendo usado. Para um único uso, tanto faz. Vai ficar muito melhor no próximo exercício, quando o resultado intermediário for referenciado **mais de uma vez**.

---
* **Exercício 08** *(médio-difícil)*: O time de Parcerias quer os **restaurantes cujo número de pedidos recebidos está acima da média** de pedidos por restaurante. Use **uma CTE** para calcular a quantidade de pedidos por restaurante (para não repetir o `GROUP BY` na subquery de comparação). Traga `nome`, `categoria` e `qtd_pedidos`. Ordene por `qtd_pedidos` decrescente e limite a **15 linhas**.

```sql
WITH pedidos_por_restaurante AS (
    SELECT 
        restaurante_id,
        COUNT(*) AS qtd_pedidos
    FROM `unipds-503513.entregaja.pedidos`
    GROUP BY restaurante_id
)
SELECT 
    r.nome,
    r.categoria,
    ppr.qtd_pedidos
FROM pedidos_por_restaurante AS ppr
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON r.restaurante_id = ppr.restaurante_id
WHERE ppr.qtd_pedidos > (
    SELECT AVG(qtd_pedidos) FROM pedidos_por_restaurante
)
ORDER BY ppr.qtd_pedidos DESC
LIMIT 15;
```

> 💡 Este é o **caso onde a CTE ganha claramente**: a mesma tabela intermediária (`pedidos_por_restaurante`) é referenciada **duas vezes** — no `FROM` (para trazer o número de pedidos de cada restaurante) e no `WHERE` (para comparar com a média desse mesmo número). Sem CTE, teríamos que repetir o `SELECT restaurante_id, COUNT(*) ... GROUP BY restaurante_id` duas vezes. Se um dia mudarmos o critério (ex.: filtrar só pedidos concluídos), com CTE alteramos **em um lugar só**.

---
* **Exercício 09** *(difícil)*: O time Financeiro quer identificar **clientes cujo gasto total em taxa de entrega (só pedidos concluídos) está acima da média** de gasto por cliente. Use **CTE**. Traga `cliente_id`, `nome` do cliente, `gasto_total` (arredondado em 2 casas) e `gasto_medio_geral` (arredondado em 2 casas, o mesmo valor em todas as linhas). Ordene por `gasto_total` decrescente e limite a **15 linhas**.

```sql
WITH gasto_por_cliente AS (
    SELECT 
        cliente_id,
        SUM(taxa_entrega) AS gasto_total
    FROM `unipds-503513.entregaja.pedidos`
    WHERE status = 'Concluído'
    GROUP BY cliente_id
)
SELECT 
    gpc.cliente_id,
    c.nome,
    ROUND(gpc.gasto_total, 2) AS gasto_total,
    (SELECT ROUND(AVG(gasto_total), 2) FROM gasto_por_cliente) AS gasto_medio_geral
FROM gasto_por_cliente AS gpc
INNER JOIN `unipds-503513.entregaja.clientes` AS c
    ON c.cliente_id = gpc.cliente_id
WHERE gpc.gasto_total > (
    SELECT AVG(gasto_total) FROM gasto_por_cliente
)
ORDER BY gasto_total DESC
LIMIT 15;
```

> 💡 A CTE `gasto_por_cliente` é referenciada **três vezes**: no `FROM` da query principal, no `SELECT` (para trazer o benchmark ao lado) e no `WHERE` (para o filtro "acima da média"). O `WHERE status = 'Concluído'` está **dentro da CTE**, porque queremos que o cálculo intermediário só considere pedidos concluídos — se estivesse na query externa, o `AVG` teria sido calculado sobre todos os gastos e o filtro só se aplicaria no fim.

---
* **Exercício 10** *(difícil)*: O time Executivo quer um relatório de **restaurantes de destaque**: aqueles cuja **nota média está acima da média geral de notas médias** dos restaurantes e que têm **pelo menos 5 avaliações** — considerando **apenas pedidos concluídos**. Use **duas CTEs encadeadas**: a primeira calcula `qtd_avaliacoes` e `nota_media` por restaurante; a segunda calcula a média geral dessas notas médias. Traga `nome`, `categoria`, `qtd_avaliacoes`, `nota_media` (arredondada em 2 casas) e `nota_media_global` (arredondada em 2 casas). Ordene por `nota_media` decrescente e limite a **15 linhas**.

```sql
WITH 
    notas_por_restaurante AS (
        SELECT 
            r.restaurante_id,
            r.nome,
            r.categoria,
            COUNT(*) AS qtd_avaliacoes,
            AVG(a.nota) AS nota_media
        FROM `unipds-503513.entregaja.avaliacoes` AS a
        INNER JOIN `unipds-503513.entregaja.pedidos` AS p
            ON a.pedido_id = p.pedido_id
        INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
            ON p.restaurante_id = r.restaurante_id
        WHERE p.status = 'Concluído'
        GROUP BY r.restaurante_id, r.nome, r.categoria
    ),
    media_global AS (
        SELECT AVG(nota_media) AS nota_media_global
        FROM notas_por_restaurante
    )
SELECT 
    npr.nome,
    npr.categoria,
    npr.qtd_avaliacoes,
    ROUND(npr.nota_media, 2) AS nota_media,
    ROUND(mg.nota_media_global, 2) AS nota_media_global
FROM notas_por_restaurante AS npr
CROSS JOIN media_global AS mg
WHERE npr.nota_media > mg.nota_media_global
  AND npr.qtd_avaliacoes >= 5
ORDER BY nota_media DESC
LIMIT 15;
```

> 💡 Exercício que **junta tudo**:
> - **Duas CTEs encadeadas**, separadas por vírgula. A segunda (`media_global`) usa o resultado da primeira (`notas_por_restaurante`) — exatamente o padrão "múltiplos passos nomeados" que a CTE torna legível.
> - **`CROSS JOIN` com a CTE de valor único**: como `media_global` retorna uma **única linha** com o benchmark, o `CROSS JOIN` "cola" essa linha em cada restaurante — assim conseguimos usar `mg.nota_media_global` tanto no `WHERE` quanto no `SELECT` sem repetir a subquery. Alternativa equivalente: usar a subquery escalar `(SELECT nota_media_global FROM media_global)` no `SELECT` e no `WHERE`.
> - **Dois `JOIN`s** dentro da primeira CTE (avaliações → pedidos → restaurantes) porque a avaliação é feita **do pedido**, não diretamente do restaurante.
> - **Duas condições no filtro** combinadas com `AND`: nota acima da média global **E** volume mínimo de 5 avaliações (a segunda condição evita restaurantes com uma única avaliação nota 5 dominando o ranking).

---

## 📌 Guia rápido — subquery vs. CTE

| Situação | Prefira |
|----------|---------|
| Filtro simples com `IN` / `NOT IN` | Subquery no `WHERE` |
| Comparação com um valor escalar (`> AVG(...)`) | Subquery no `WHERE` |
| Trazer um benchmark único ao lado das linhas | Subquery no `SELECT` |
| Tabela derivada usada **uma única vez** | Subquery no `FROM` ou CTE |
| Tabela derivada usada **duas ou mais vezes** | **CTE** (sem repetir código) |
| Lógica com **múltiplos passos** encadeados | **CTE** (uma por passo, nomeada) |
