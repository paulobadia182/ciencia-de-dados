# Gabarito da aula 22:

## Conteúdo acumulado (aulas 10 a 21):
- **Consultas básicas:** `SELECT`, `FROM`, `DISTINCT`, `LIMIT`, `ORDER BY`
- **Filtros e operadores:** `WHERE` com aritméticos (`+`, `-`, `*`, `/`), comparação (`>`, `<`, `>=`, `<=`, `=`, `<>`) e lógicos (`AND`, `OR`, `NOT`)
- **Condicionais:** `IF`, `CASE`, `COALESCE`
- **Funções de data:** `EXTRACT`, `DATE_TRUNC`, `DATE_DIFF`/`DATETIME_DIFF`, `DATE_ADD`/`DATE_SUB`, `FORMAT_DATE`/`PARSE_DATE`, `CURRENT_DATE`
- **Funções de texto:** `UPPER`/`LOWER`/`INITCAP`, `TRIM`/`LTRIM`/`RTRIM`, `LENGTH`, `SUBSTR`/`STRPOS`/`SPLIT`, `REPLACE`/`REGEXP_REPLACE`
- **JOINs:** `INNER`, `LEFT`, `RIGHT`, `FULL`
- **Agregação e agrupamento:** `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, `HAVING`


### EXERCÍCIOS:


* **Exercício 01** *(fácil)*: O time Executivo quer saber **quantos clientes diferentes** já fizeram pelo menos um pedido. Retorne uma única coluna `clientes_ativos`.

```sql
SELECT 
    COUNT(DISTINCT cliente_id) AS clientes_ativos
FROM `unipds-503513.entregaja.pedidos`;
```

> 💡 A tabela `pedidos` tem uma linha por **pedido** — como um cliente pode ter feito vários, `COUNT(cliente_id)` daria o total de pedidos com cliente. Precisamos do `DISTINCT` para contar cada cliente **uma única vez**.

---
* **Exercício 02** *(fácil)*: A equipe de Operações precisa das datas do **primeiro** e do **último** pedido **concluído** da plataforma. Retorne duas colunas: `primeiro_pedido` e `ultimo_pedido`.

```sql
SELECT 
    MIN(data_hora_pedido) AS primeiro_pedido,
    MAX(data_hora_pedido) AS ultimo_pedido
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído';
```

> 💡 `MIN` e `MAX` funcionam direto com colunas de data — não precisa converter para `DATE` ou aplicar `EXTRACT`. O `WHERE` filtra as linhas **antes** da agregação, então só pedidos concluídos entram no cálculo.

---
* **Exercício 03** *(fácil)*: O time de BI quer o **tempo médio de entrega** dos pedidos **concluídos**, arredondado em **2 casas decimais**. Retorne uma única coluna `tempo_medio_entrega`.

```sql
SELECT 
    ROUND(AVG(tempo_entrega_min), 2) AS tempo_medio_entrega
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído';
```

> 💡 Combinação clássica: `AVG` + `ROUND(..., 2)` para relatórios legíveis. `AVG` sozinho costuma dar números com muitas casas decimais. Os pedidos cancelados (com `tempo_entrega_min` nulo) seriam ignorados pelo `AVG` de qualquer forma, mas o `WHERE` deixa a intenção explícita.

---
* **Exercício 04** *(fácil)*: A equipe de Parcerias quer saber **quantos restaurantes existem em cada categoria**. Retorne `categoria` e `qtd_restaurantes`. Ordene do maior para o menor e limite a **10 linhas**.

```sql
SELECT 
    categoria,
    COUNT(*) AS qtd_restaurantes
FROM `unipds-503513.entregaja.restaurantes`
GROUP BY categoria
ORDER BY qtd_restaurantes DESC
LIMIT 10;
```

> 💡 Primeiro exercício com `GROUP BY`: agrupamos por `categoria` e contamos quantas linhas caem em cada grupo. Como `categoria` aparece no `SELECT` sem agregação, ela **precisa** estar no `GROUP BY`.

---
* **Exercício 05** *(médio)*: O time Financeiro quer o **total arrecadado em taxa de entrega** por **forma de pagamento**, considerando **apenas pedidos concluídos**. Traga `forma_pagamento` e `total_taxas` (arredondado em 2 casas). Ordene do maior para o menor.

```sql
SELECT 
    forma_pagamento,
    ROUND(SUM(taxa_entrega), 2) AS total_taxas
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído'
GROUP BY forma_pagamento
ORDER BY total_taxas DESC;
```

> 💡 A ordem das cláusulas é importante: `WHERE` filtra **antes** do `GROUP BY`. Assim, pedidos cancelados **não entram** no `SUM(taxa_entrega)` de nenhuma forma de pagamento.

---
* **Exercício 06** *(médio)*: O time de BI quer o **tempo médio de entrega por região do cliente**, considerando **apenas pedidos concluídos**. Traga `regiao`, `qtd_pedidos` e `tempo_medio` (arredondado em 2 casas). Ordene por `tempo_medio` **crescente**.

```sql
SELECT 
    c.regiao,
    COUNT(*) AS qtd_pedidos,
    ROUND(AVG(p.tempo_entrega_min), 2) AS tempo_medio
FROM `unipds-503513.entregaja.pedidos` AS p
INNER JOIN `unipds-503513.entregaja.clientes` AS c
    ON p.cliente_id = c.cliente_id
WHERE p.status = 'Concluído'
GROUP BY c.regiao
ORDER BY tempo_medio ASC;
```

> 💡 `JOIN` acontece **antes** do `GROUP BY`: primeiro combinamos as duas tabelas, depois o SQL agrupa o resultado. Como `regiao` vem de `clientes`, precisamos qualificar com o alias (`c.regiao`) tanto no `SELECT` quanto no `GROUP BY`.

---
* **Exercício 07** *(médio-difícil)*: O time de Customer Success quer um ranking dos **top 10 restaurantes com maior nota média**. Traga `nome` do restaurante, `qtd_avaliacoes` e `nota_media` (arredondada em 2 casas). Ordene por `nota_media` decrescente.

```sql
SELECT 
    r.nome,
    COUNT(*) AS qtd_avaliacoes,
    ROUND(AVG(a.nota), 2) AS nota_media
FROM `unipds-503513.entregaja.avaliacoes` AS a
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON a.pedido_id = p.pedido_id
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON p.restaurante_id = r.restaurante_id
GROUP BY r.nome
ORDER BY nota_media DESC
LIMIT 10;
```

> 💡 Como a avaliação é feita **do pedido** (não diretamente do restaurante), precisamos de **dois JOINs** para chegar em `restaurantes`: primeiro `avaliacoes → pedidos`, depois `pedidos → restaurantes`. O `GROUP BY r.nome` junta todas as avaliações de cada restaurante numa única linha.

---
* **Exercício 08** *(médio-difícil)*: O time de Marketing quer identificar **categorias de restaurante com mais de 3 unidades cadastradas** (para focar campanhas nas categorias mais representativas). Traga `categoria` e `qtd_restaurantes`. Ordene do maior para o menor.

```sql
SELECT 
    categoria,
    COUNT(*) AS qtd_restaurantes
FROM `unipds-503513.entregaja.restaurantes`
GROUP BY categoria
HAVING COUNT(*) > 3
ORDER BY qtd_restaurantes DESC;
```

> 💡 Primeiro `HAVING`: o filtro `COUNT(*) > 3` **não pode** entrar no `WHERE` porque o `COUNT(*)` só existe **depois** do `GROUP BY`. Regra prática: se o filtro compara uma **agregação**, ele vai no `HAVING`.

---
* **Exercício 09** *(difícil)*: O time Financeiro quer as **formas de pagamento cujo total arrecadado em taxa de entrega passou de R$ 5.000** — considerando **apenas pedidos concluídos**. Traga `forma_pagamento`, `qtd_pedidos` e `total_arrecadado` (arredondado em 2 casas). Ordene por `total_arrecadado` decrescente.

```sql
SELECT 
    forma_pagamento,
    COUNT(*) AS qtd_pedidos,
    ROUND(SUM(taxa_entrega), 2) AS total_arrecadado
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído'
GROUP BY forma_pagamento
HAVING SUM(taxa_entrega) > 5000
ORDER BY total_arrecadado DESC;
```

> 💡 `WHERE` e `HAVING` na **mesma query**, cada um com seu papel:
> - `WHERE status = 'Concluído'` — filtra **linhas** antes do agrupamento (descarta pedidos cancelados).
> - `HAVING SUM(taxa_entrega) > 5000` — filtra **grupos** depois do agrupamento (descarta formas de pagamento com faturamento baixo).
>
> No `HAVING`, usamos `SUM(taxa_entrega)` diretamente — não podemos usar o alias `total_arrecadado` porque o `ROUND` só é aplicado no `SELECT`, que roda depois.

---
* **Exercício 10** *(difícil)*: O time Executivo quer um ranking de **restaurantes de excelência**: aqueles que têm **média de nota maior ou igual a 4** e **mais de 10 avaliações** — considerando **apenas pedidos concluídos**. Traga `nome` do restaurante, `categoria`, `qtd_avaliacoes` e `nota_media` (arredondada em 2 casas). Ordene por `nota_media` decrescente e limite a **15 linhas**.

```sql
SELECT 
    r.nome,
    r.categoria,
    COUNT(*) AS qtd_avaliacoes,
    ROUND(AVG(a.nota), 2) AS nota_media
FROM `unipds-503513.entregaja.avaliacoes` AS a
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON a.pedido_id = p.pedido_id
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON p.restaurante_id = r.restaurante_id
WHERE p.status = 'Concluído'
GROUP BY r.nome, r.categoria
HAVING AVG(a.nota) >= 4 AND COUNT(*) > 10
ORDER BY nota_media DESC
LIMIT 15;
```

> 💡 Exercício que **junta tudo**: dois `JOIN`s (avaliações → pedidos → restaurantes), `WHERE` para filtrar linhas (só concluídos), `GROUP BY` por **duas colunas** (`r.nome` e `r.categoria`, ambas aparecem no `SELECT`), e `HAVING` com **duas condições** de agregação combinadas com `AND` (nota média alta **E** volume relevante de avaliações).

---

## 📌 Ordem completa das cláusulas

```sql
SELECT [DISTINCT] colunas + agregações  -- 1º: o que mostrar
FROM tabela                             -- 2º: de onde vem
[JOIN ...]                              -- 3º: combinar com outra tabela
WHERE condição                          -- 4º: filtra LINHAS (antes do agrupamento)
GROUP BY colunas                        -- 5º: agrupa
HAVING condição_de_agregação            -- 6º: filtra GRUPOS (depois do agrupamento)
ORDER BY coluna [ASC|DESC]              -- 7º: ordena
LIMIT n;                                -- 8º: corta as primeiras n linhas
```
