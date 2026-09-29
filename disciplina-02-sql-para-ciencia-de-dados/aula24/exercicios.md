# Exercícios da aula 24:

## Conteúdo acumulado (aulas 10 a 23):
- **Consultas básicas:** `SELECT`, `FROM`, `DISTINCT`, `LIMIT`, `ORDER BY`
- **Filtros e operadores:** `WHERE` com aritméticos (`+`, `-`, `*`, `/`), comparação (`>`, `<`, `>=`, `<=`, `=`, `<>`) e lógicos (`AND`, `OR`, `NOT`)
- **Condicionais:** `IF`, `CASE`, `COALESCE`
- **Funções de data:** `EXTRACT`, `DATE_TRUNC`, `DATE_DIFF`/`DATETIME_DIFF`, `DATE_ADD`/`DATE_SUB`, `FORMAT_DATE`/`PARSE_DATE`, `CURRENT_DATE`
- **Funções de texto:** `UPPER`/`LOWER`/`INITCAP`, `TRIM`/`LTRIM`/`RTRIM`, `LENGTH`, `SUBSTR`/`STRPOS`/`SPLIT`, `REPLACE`/`REGEXP_REPLACE`
- **JOINs:** `INNER`, `LEFT`, `RIGHT`, `FULL`
- **Agregação e agrupamento:** `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, `HAVING`
- **Subqueries e CTEs:** subquery no `WHERE` (`=`/`>`/`<`, `IN`, `NOT IN`), subquery no `FROM` (tabela derivada), subquery no `SELECT` (escalar), `WITH` (CTEs simples, reusadas e encadeadas)

> 🎯 **Progressão:** os primeiros exercícios usam **subqueries simples no WHERE**; os do meio introduzem **subqueries no FROM e no SELECT**; os últimos exigem **CTEs** — inclusive múltiplas CTEs encadeadas combinadas com `JOIN`, `GROUP BY` e `HAVING`.


### EXERCÍCIOS:


* **Exercício 01** *(fácil)*: O time de BI quer ver os pedidos com **taxa de entrega acima da média geral** (de todos os pedidos). Traga `pedido_id`, `forma_pagamento` e `taxa_entrega`. Ordene por `taxa_entrega` decrescente e limite a **15 linhas**.

---
* **Exercício 02** *(fácil)*: A equipe de Operações quer todos os pedidos feitos por clientes da **região Sul**. Use uma **subquery com `IN`** (não use `JOIN`). Traga `pedido_id`, `cliente_id`, `status` e `data_hora_pedido`. Ordene por `data_hora_pedido` decrescente e limite a **15 linhas**.

---
* **Exercício 03** *(fácil)*: O time de Parcerias quer identificar **restaurantes que nunca receberam pedidos** (para reavaliar o cadastro). Use `NOT IN`. Traga `restaurante_id`, `nome` e `categoria`. Ordene por `nome` e limite a **15 linhas**.

---
* **Exercício 04** *(médio)*: O time de Operações quer investigar pedidos com **tempo de entrega maior que o dobro da média** dos pedidos concluídos. Traga `pedido_id`, `tempo_entrega_min` e `status`. Ordene por `tempo_entrega_min` decrescente e limite a **15 linhas**.

---
* **Exercício 05** *(médio)*: O time Executivo quer saber, **em média, quantos pedidos cada restaurante recebeu**, além do mínimo e do máximo. Use **subquery no `FROM`**. Retorne `media_pedidos_por_restaurante` (arredondada em 2 casas), `min_pedidos` e `max_pedidos`.

---
* **Exercício 06** *(médio)*: O time de Customer Success quer, para cada avaliação, comparar a nota com a **média geral de todas as avaliações**. Use **subquery no `SELECT`**. Traga `avaliacao_id`, `nota`, `nota_media_geral` (arredondada em 2 casas) e `diferenca_da_media` (nota − média). Ordene por `diferenca_da_media` decrescente e limite a **15 linhas**.

---
* **Exercício 07** *(médio-difícil)*: **Reescreva o Exercício 05 usando CTE** (com `WITH`). O resultado deve ser idêntico: `media_pedidos_por_restaurante` (arredondada em 2 casas), `min_pedidos` e `max_pedidos`.

---
* **Exercício 08** *(médio-difícil)*: O time de Parcerias quer os **restaurantes cujo número de pedidos recebidos está acima da média** de pedidos por restaurante. Use **uma CTE** para calcular a quantidade de pedidos por restaurante (para não repetir o `GROUP BY` na subquery de comparação). Traga `nome`, `categoria` e `qtd_pedidos`. Ordene por `qtd_pedidos` decrescente e limite a **15 linhas**.

---
* **Exercício 09** *(difícil)*: O time Financeiro quer identificar **clientes cujo gasto total em taxa de entrega (só pedidos concluídos) está acima da média** de gasto por cliente. Use **CTE**. Traga `cliente_id`, `nome` do cliente, `gasto_total` (arredondado em 2 casas) e `gasto_medio_geral` (arredondado em 2 casas, o mesmo valor em todas as linhas). Ordene por `gasto_total` decrescente e limite a **15 linhas**.

---
* **Exercício 10** *(difícil)*: O time Executivo quer um relatório de **restaurantes de destaque**: aqueles cuja **nota média está acima da média geral de notas médias** dos restaurantes e que têm **pelo menos 5 avaliações** — considerando **apenas pedidos concluídos**. Use **duas CTEs encadeadas**: a primeira calcula `qtd_avaliacoes` e `nota_media` por restaurante; a segunda calcula a média geral dessas notas médias. Traga `nome`, `categoria`, `qtd_avaliacoes`, `nota_media` (arredondada em 2 casas) e `nota_media_global` (arredondada em 2 casas). Ordene por `nota_media` decrescente e limite a **15 linhas**.
