# Exercícios da aula 22:

## Conteúdo acumulado (aulas 10 a 21):
- **Consultas básicas:** `SELECT`, `FROM`, `DISTINCT`, `LIMIT`, `ORDER BY`
- **Filtros e operadores:** `WHERE` com aritméticos (`+`, `-`, `*`, `/`), comparação (`>`, `<`, `>=`, `<=`, `=`, `<>`) e lógicos (`AND`, `OR`, `NOT`)
- **Condicionais:** `IF`, `CASE`, `COALESCE`
- **Funções de data:** `EXTRACT`, `DATE_TRUNC`, `DATE_DIFF`/`DATETIME_DIFF`, `DATE_ADD`/`DATE_SUB`, `FORMAT_DATE`/`PARSE_DATE`, `CURRENT_DATE`
- **Funções de texto:** `UPPER`/`LOWER`/`INITCAP`, `TRIM`/`LTRIM`/`RTRIM`, `LENGTH`, `SUBSTR`/`STRPOS`/`SPLIT`, `REPLACE`/`REGEXP_REPLACE`
- **JOINs:** `INNER`, `LEFT`, `RIGHT`, `FULL`
- **Agregação e agrupamento:** `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, `HAVING`

> 🎯 **Progressão:** os primeiros exercícios usam **uma agregação** sobre a tabela inteira; os do meio introduzem `GROUP BY`; os últimos combinam `WHERE` + `GROUP BY` + `HAVING` + `JOIN`.


### EXERCÍCIOS:


* **Exercício 01** *(fácil)*: O time Executivo quer saber **quantos clientes diferentes** já fizeram pelo menos um pedido. Retorne uma única coluna `clientes_ativos`.

---
* **Exercício 02** *(fácil)*: A equipe de Operações precisa das datas do **primeiro** e do **último** pedido **concluído** da plataforma. Retorne duas colunas: `primeiro_pedido` e `ultimo_pedido`.

---
* **Exercício 03** *(fácil)*: O time de BI quer o **tempo médio de entrega** dos pedidos **concluídos**, arredondado em **2 casas decimais**. Retorne uma única coluna `tempo_medio_entrega`.

---
* **Exercício 04** *(fácil)*: A equipe de Parcerias quer saber **quantos restaurantes existem em cada categoria**. Retorne `categoria` e `qtd_restaurantes`. Ordene do maior para o menor e limite a **10 linhas**.

---
* **Exercício 05** *(médio)*: O time Financeiro quer o **total arrecadado em taxa de entrega** por **forma de pagamento**, considerando **apenas pedidos concluídos**. Traga `forma_pagamento` e `total_taxas` (arredondado em 2 casas). Ordene do maior para o menor.

---
* **Exercício 06** *(médio)*: O time de BI quer o **tempo médio de entrega por região do cliente**, considerando **apenas pedidos concluídos**. Traga `regiao`, `qtd_pedidos` e `tempo_medio` (arredondado em 2 casas). Ordene por `tempo_medio` **crescente**.

---
* **Exercício 07** *(médio-difícil)*: O time de Customer Success quer um ranking dos **top 10 restaurantes com maior nota média**. Traga `nome` do restaurante, `qtd_avaliacoes` e `nota_media` (arredondada em 2 casas). Ordene por `nota_media` decrescente.

---
* **Exercício 08** *(médio-difícil)*: O time de Marketing quer identificar **categorias de restaurante com mais de 3 unidades cadastradas** (para focar campanhas nas categorias mais representativas). Traga `categoria` e `qtd_restaurantes`. Ordene do maior para o menor.

---
* **Exercício 09** *(difícil)*: O time Financeiro quer as **formas de pagamento cujo total arrecadado em taxa de entrega passou de R$ 5.000** — considerando **apenas pedidos concluídos**. Traga `forma_pagamento`, `qtd_pedidos` e `total_arrecadado` (arredondado em 2 casas). Ordene por `total_arrecadado` decrescente.

---
* **Exercício 10** *(difícil)*: O time Executivo quer um ranking de **restaurantes de excelência**: aqueles que têm **média de nota maior ou igual a 4** e **mais de 10 avaliações** — considerando **apenas pedidos concluídos**. Traga `nome` do restaurante, `categoria`, `qtd_avaliacoes` e `nota_media` (arredondada em 2 casas). Ordene por `nota_media` decrescente e limite a **15 linhas**.
