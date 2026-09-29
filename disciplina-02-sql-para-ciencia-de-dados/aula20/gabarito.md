# Gabarito da aula 20:

## Conteúdo acumulado (aulas 10 a 19):
- **Consultas básicas:** `SELECT`, `FROM`, `DISTINCT`, `LIMIT`, `ORDER BY`
- **Filtros e operadores:** `WHERE` com aritméticos (`+`, `-`, `*`, `/`), comparação (`>`, `<`, `>=`, `<=`, `=`, `<>`) e lógicos (`AND`, `OR`, `NOT`)
- **Condicionais:** `IF`, `CASE`, `COALESCE`
- **Funções de data:** `EXTRACT`, `DATE_TRUNC`, `DATE_DIFF`/`DATETIME_DIFF`, `DATE_ADD`/`DATE_SUB`, `FORMAT_DATE`/`PARSE_DATE`, `CURRENT_DATE`
- **Funções de texto:** `UPPER`/`LOWER`/`INITCAP`, `TRIM`/`LTRIM`/`RTRIM`, `LENGTH`, `SUBSTR`/`STRPOS`/`SPLIT`, `REPLACE`/`REGEXP_REPLACE`
- **JOINs:** `INNER`, `LEFT`, `RIGHT`, `FULL`


### EXERCÍCIOS:


* **Exercício 01** *(fácil)*: O time de CRM quer um relatório dos pedidos com o nome do cliente em **MAIÚSCULAS** (padrão da agência). Traga `pedido_id`, `nome_cliente` em maiúsculas e `status`. Filtre apenas pedidos com status `'Concluído'`. Ordene por `pedido_id` e limite a **15 linhas**.

```sql
SELECT 
    p.pedido_id,
    UPPER(c.nome) AS nome_cliente,
    p.status
FROM `unipds-503513.entregaja.pedidos` AS p
INNER JOIN `unipds-503513.entregaja.clientes` AS c
    ON p.cliente_id = c.cliente_id
WHERE p.status = 'Concluído'
ORDER BY p.pedido_id
LIMIT 15;
```

> 💡 Como todo pedido tem um `cliente_id` válido, o `INNER JOIN` é seguro. `UPPER` transforma só a coluna exibida — o dado original em `clientes` continua igual.

---
* **Exercício 02** *(fácil)*: O time de Operações quer um relatório com **todos os pedidos** e o nome do entregador. Quando o pedido não tem entregador (cancelado), mostre `'Sem entregador'`. Traga `pedido_id`, `status` e `entregador`. Ordene por `pedido_id` e limite a **15 linhas**.

```sql
SELECT 
    p.pedido_id,
    p.status,
    COALESCE(e.nome, 'Sem entregador') AS entregador
FROM `unipds-503513.entregaja.pedidos` AS p
LEFT JOIN `unipds-503513.entregaja.entregadores` AS e
    ON p.entregador_id = e.entregador_id
ORDER BY p.pedido_id
LIMIT 15;
```

> 💡 Precisamos de **todos** os pedidos (inclusive cancelados sem entregador) — por isso `LEFT JOIN`. Onde não há par em `entregadores`, o `nome` volta como `NULL` e o `COALESCE` substitui pelo texto padrão.

---
* **Exercício 03** *(fácil)*: O time Financeiro quer os pedidos com **entrega grátis** (`taxa_entrega = 0`) com a data em formato brasileiro. Traga `pedido_id`, o `nome` do restaurante e a `data_pedido_br` (formato `dd/mm/aaaa`). Ordene pela data mais recente e limite a **15 linhas**.

```sql
SELECT 
    p.pedido_id,
    r.nome AS nome_restaurante,
    FORMAT_DATE('%d/%m/%Y', DATE(p.data_hora_pedido)) AS data_pedido_br
FROM `unipds-503513.entregaja.pedidos` AS p
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON p.restaurante_id = r.restaurante_id
WHERE p.taxa_entrega = 0
ORDER BY p.data_hora_pedido DESC
LIMIT 15;
```

> 💡 Como `data_hora_pedido` é `DATETIME` (tem hora), envolvemos com `DATE(...)` antes de passar para `FORMAT_DATE`. Ordenamos pela coluna **original** `data_hora_pedido` — se ordenássemos pela coluna formatada (que virou texto), a ordem seria alfabética, não cronológica.

---
* **Exercício 04** *(médio)*: O time de CRM quer entender **há quantos dias** cada cliente já estava cadastrado quando fez cada pedido. Traga `pedido_id`, `nome` do cliente, `data_cadastro`, `data_hora_pedido` e uma coluna `dias_de_relacionamento` (diferença em dias entre o cadastro e o pedido). Ordene por `dias_de_relacionamento` **decrescente** e limite a **15 linhas**.

```sql
SELECT 
    p.pedido_id,
    c.nome,
    c.data_cadastro,
    p.data_hora_pedido,
    DATE_DIFF(DATE(p.data_hora_pedido), c.data_cadastro, DAY) AS dias_de_relacionamento
FROM `unipds-503513.entregaja.pedidos` AS p
INNER JOIN `unipds-503513.entregaja.clientes` AS c
    ON p.cliente_id = c.cliente_id
ORDER BY dias_de_relacionamento DESC
LIMIT 15;
```

> 💡 O `DATE_DIFF` só funciona entre datas do **mesmo tipo** — por isso usamos `DATE(p.data_hora_pedido)` para converter o `DATETIME` em `DATE`, igualando com `data_cadastro`. A ordem `(final, inicial, DAY)` importa: invertida, o resultado seria negativo.

---
* **Exercício 05** *(médio)*: O time de Customer Success quer classificar as **avaliações** por sentimento — mas só das avaliações de pedidos **concluídos**. Traga `avaliacao_id`, `nota`, `status` do pedido e uma coluna `sentimento`:
  - Nota igual a 5 → `'Muito satisfeito'`
  - Nota entre 3 e 4 → `'Neutro'`
  - Nota abaixo de 3 → `'Insatisfeito'`

Ordene pela nota **crescente** e limite a **15 linhas**.

```sql
SELECT 
    a.avaliacao_id,
    a.nota,
    p.status,
    CASE 
        WHEN a.nota = 5 THEN 'Muito satisfeito'
        WHEN a.nota BETWEEN 3 AND 4 THEN 'Neutro'
        ELSE 'Insatisfeito'
    END AS sentimento
FROM `unipds-503513.entregaja.avaliacoes` AS a
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON a.pedido_id = p.pedido_id
WHERE p.status = 'Concluído'
ORDER BY a.nota ASC
LIMIT 15;
```

> 💡 Como partimos de `avaliacoes` e fazemos `INNER JOIN` com `pedidos`, o resultado só traz **linhas com par nos dois lados** — o `WHERE p.status = 'Concluído'` fica correto porque não há pedidos com status nulo dentro do resultado do join.

---
* **Exercício 06** *(médio)*: O time de Customer Success quer identificar **pedidos concluídos que ainda não foram avaliados** — para pedir feedback. Traga `pedido_id`, `status` e a `data_pedido_br` (formato brasileiro). Ordene pela data mais recente e limite a **15 linhas**.

```sql
SELECT 
    p.pedido_id,
    p.status,
    FORMAT_DATE('%d/%m/%Y', DATE(p.data_hora_pedido)) AS data_pedido_br
FROM `unipds-503513.entregaja.pedidos` AS p
LEFT JOIN `unipds-503513.entregaja.avaliacoes` AS a
    ON p.pedido_id = a.pedido_id
WHERE a.avaliacao_id IS NULL 
    AND p.status = 'Concluído'
ORDER BY p.data_hora_pedido DESC
LIMIT 15;
```

> 💡 Padrão **"anti-join"**: `LEFT JOIN` traz todos os pedidos + a avaliação (se existir); depois o `WHERE a.avaliacao_id IS NULL` mantém **só os pedidos que não tinham par** em `avaliacoes` — ou seja, os não avaliados.

---
* **Exercício 07** *(médio-difícil)*: O time Financeiro quer analisar pedidos agrupados pelo **início do mês** (para dashboards de sazonalidade). Traga `pedido_id`, `nome` do cliente, `nome` do restaurante, uma coluna `inicio_mes` (com `DATE_TRUNC` no primeiro dia do mês do pedido) e a `taxa_entrega`. Ordene por `inicio_mes` **decrescente** e limite a **15 linhas**.

```sql
SELECT 
    p.pedido_id,
    c.nome AS nome_cliente,
    r.nome AS nome_restaurante,
    DATE_TRUNC(DATE(p.data_hora_pedido), MONTH) AS inicio_mes,
    p.taxa_entrega
FROM `unipds-503513.entregaja.pedidos` AS p
INNER JOIN `unipds-503513.entregaja.clientes` AS c
    ON p.cliente_id = c.cliente_id
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON p.restaurante_id = r.restaurante_id
ORDER BY inicio_mes DESC
LIMIT 15;
```

> 💡 Como `clientes` e `restaurantes` têm colunas com o **mesmo nome** (`nome`), o alias vira obrigatório (`c.nome`, `r.nome`) para o SQL não ficar ambíguo. `DATE_TRUNC` **preserva o formato de data** (diferente do `EXTRACT`, que devolve um número) — todos os pedidos do mesmo mês ficam com a mesma data (dia 01), o que é ideal para agrupamento.

---
* **Exercício 08** *(difícil)*: O time Financeiro quer auditar pedidos **concluídos** feitos em **dezembro** (de qualquer ano) com **taxa de entrega maior que zero**. Traga `pedido_id`, `nome` do cliente, `nome` do restaurante, `data_br` (formato `dd/mm/aaaa`) e `taxa_entrega`. Ordene pela `taxa_entrega` **decrescente** e limite a **15 linhas**.

```sql
SELECT 
    p.pedido_id,
    c.nome AS nome_cliente,
    r.nome AS nome_restaurante,
    FORMAT_DATE('%d/%m/%Y', DATE(p.data_hora_pedido)) AS data_br,
    p.taxa_entrega
FROM `unipds-503513.entregaja.pedidos` AS p
INNER JOIN `unipds-503513.entregaja.clientes` AS c
    ON p.cliente_id = c.cliente_id
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON p.restaurante_id = r.restaurante_id
WHERE p.status = 'Concluído'
    AND EXTRACT(MONTH FROM p.data_hora_pedido) = 12
    AND p.taxa_entrega > 0
ORDER BY p.taxa_entrega DESC
LIMIT 15;
```

> 💡 O `EXTRACT` também funciona **dentro do `WHERE`** — sem precisar comparar strings de data ou intervalos manualmente. As três condições unidas com `AND` filtram pedidos concluídos, no mês 12, com taxa positiva.

---
* **Exercício 09** *(difícil)*: O time de Customer Success quer priorizar contatos: para cada pedido **concluído**, mostre a nota da avaliação (tratando NULL como 0) e uma coluna `acao` com `IF`:
  - Se a nota tratada for **menor que 3** → `'Contatar cliente'`
  - Caso contrário → `'OK'`

Traga `pedido_id`, `status`, `nota` (já tratada) e `acao`. Ordene pela `nota` **crescente** e limite a **20 linhas**.

```sql
SELECT 
    p.pedido_id,
    p.status,
    COALESCE(a.nota, 0) AS nota,
    IF(COALESCE(a.nota, 0) < 3, 'Contatar cliente', 'OK') AS acao
FROM `unipds-503513.entregaja.pedidos` AS p
LEFT JOIN `unipds-503513.entregaja.avaliacoes` AS a
    ON p.pedido_id = a.pedido_id
WHERE p.status = 'Concluído'
ORDER BY nota ASC
LIMIT 20;
```

> 💡 Repare que o `COALESCE(a.nota, 0)` precisa aparecer **duas vezes**: uma no `SELECT` (para exibir a nota tratada) e outra dentro do `IF` (para o teste lógico). Não podemos usar o alias `nota` dentro do próprio `SELECT` — ele só existe depois que a linha é montada. Como pedido sem avaliação vira nota = 0, ele automaticamente cai no ramo `'Contatar cliente'`.

---
* **Exercício 10** *(muito difícil)*: O time Executivo quer um **relatório consolidado** dos pedidos **concluídos** feitos por clientes do plano **Premium**. Traga:
  - `pedido_id`
  - `nome_cliente` (nome do cliente **em MAIÚSCULAS**)
  - `primeiro_nome_cliente` (só o primeiro nome, extraído com `SPLIT`)
  - `nome_restaurante`
  - `ano_pedido` (só o ano da data do pedido)
  - `tempo_entrega` (com `COALESCE` tratando NULL como 0)
  - `classificacao_entrega` (com `CASE`):
    - Tempo ≤ 30 → `'Rápida'`
    - Tempo entre 31 e 60 → `'Normal'`
    - Tempo > 60 → `'Lenta'`

Ordene por `tempo_entrega` **crescente** e limite a **15 linhas**.

```sql
SELECT 
    p.pedido_id,
    UPPER(c.nome) AS nome_cliente,
    SPLIT(c.nome, ' ')[OFFSET(0)] AS primeiro_nome_cliente,
    r.nome AS nome_restaurante,
    EXTRACT(YEAR FROM p.data_hora_pedido) AS ano_pedido,
    COALESCE(p.tempo_entrega_min, 0) AS tempo_entrega,
    CASE 
        WHEN COALESCE(p.tempo_entrega_min, 0) <= 30 THEN 'Rápida'
        WHEN COALESCE(p.tempo_entrega_min, 0) BETWEEN 31 AND 60 THEN 'Normal'
        ELSE 'Lenta'
    END AS classificacao_entrega
FROM `unipds-503513.entregaja.pedidos` AS p
INNER JOIN `unipds-503513.entregaja.clientes` AS c
    ON p.cliente_id = c.cliente_id
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON p.restaurante_id = r.restaurante_id
WHERE p.status = 'Concluído' AND c.plano = 'Premium'
ORDER BY tempo_entrega ASC
LIMIT 15;
```

> 💡 Exercício que **junta tudo**: `INNER JOIN` duplo, `UPPER` para padronizar o nome, `SPLIT` + `[OFFSET(0)]` para extrair só o primeiro nome, `EXTRACT` para o ano, `COALESCE` (repetido no `SELECT` e no `CASE`, pela mesma razão do exercício 09) e `CASE` para classificar. Como o filtro exige `status = 'Concluído'`, na prática `tempo_entrega_min` raramente virá nulo — mas mantemos o `COALESCE` por segurança.

---

## 📌 Estrutura completa de uma query com JOIN

```sql
SELECT [DISTINCT] colunas       -- IF, CASE, COALESCE, funções de data/texto aqui
FROM tabela_esquerda AS a       -- tabela base
[INNER|LEFT|RIGHT|FULL] JOIN
    tabela_direita AS b         -- tabela a combinar
    ON a.chave = b.chave        -- condição de junção
WHERE condição                  -- pode usar colunas de qualquer tabela do join
ORDER BY coluna [ASC|DESC]      -- pode usar aliases criados no SELECT
LIMIT n;                        -- corta as primeiras n linhas
```
