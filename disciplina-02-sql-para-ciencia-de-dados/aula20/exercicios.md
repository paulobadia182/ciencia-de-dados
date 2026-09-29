# Exercícios da aula 20:

## Conteúdo acumulado (aulas 10 a 19):
- **Consultas básicas:** `SELECT`, `FROM`, `DISTINCT`, `LIMIT`, `ORDER BY`
- **Filtros e operadores:** `WHERE` com aritméticos (`+`, `-`, `*`, `/`), comparação (`>`, `<`, `>=`, `<=`, `=`, `<>`) e lógicos (`AND`, `OR`, `NOT`)
- **Condicionais:** `IF`, `CASE`, `COALESCE`
- **Funções de data:** `EXTRACT`, `DATE_TRUNC`, `DATE_DIFF`/`DATETIME_DIFF`, `DATE_ADD`/`DATE_SUB`, `FORMAT_DATE`/`PARSE_DATE`, `CURRENT_DATE`
- **Funções de texto:** `UPPER`/`LOWER`/`INITCAP`, `TRIM`/`LTRIM`/`RTRIM`, `LENGTH`, `SUBSTR`/`STRPOS`/`SPLIT`, `REPLACE`/`REGEXP_REPLACE`
- **JOINs:** `INNER`, `LEFT`, `RIGHT`, `FULL`

> 🎯 **Progressão:** os exercícios vão do mais simples ao mais completo — os primeiros combinam **um JOIN + uma função**; os últimos misturam **JOINs múltiplos + várias funções + CASE**.


### EXERCÍCIOS:


* **Exercício 01** *(fácil)*: O time de CRM quer um relatório dos pedidos com o nome do cliente em **MAIÚSCULAS** (padrão da agência). Traga `pedido_id`, `nome_cliente` em maiúsculas e `status`. Filtre apenas pedidos com status `'Concluído'`. Ordene por `pedido_id` e limite a **15 linhas**.

---
* **Exercício 02** *(fácil)*: O time de Operações quer um relatório com **todos os pedidos** e o nome do entregador. Quando o pedido não tem entregador (cancelado), mostre `'Sem entregador'`. Traga `pedido_id`, `status` e `entregador`. Ordene por `pedido_id` e limite a **15 linhas**.

---
* **Exercício 03** *(fácil)*: O time Financeiro quer os pedidos com **entrega grátis** (`taxa_entrega = 0`) com a data em formato brasileiro. Traga `pedido_id`, o `nome` do restaurante e a `data_pedido_br` (formato `dd/mm/aaaa`). Ordene pela data mais recente e limite a **15 linhas**.

---
* **Exercício 04** *(médio)*: O time de CRM quer entender **há quantos dias** cada cliente já estava cadastrado quando fez cada pedido. Traga `pedido_id`, `nome` do cliente, `data_cadastro`, `data_hora_pedido` e uma coluna `dias_de_relacionamento` (diferença em dias entre o cadastro e o pedido). Ordene por `dias_de_relacionamento` **decrescente** e limite a **15 linhas**.

---
* **Exercício 05** *(médio)*: O time de Customer Success quer classificar as **avaliações** por sentimento — mas só das avaliações de pedidos **concluídos**. Traga `avaliacao_id`, `nota`, `status` do pedido e uma coluna `sentimento`:
  - Nota igual a 5 → `'Muito satisfeito'`
  - Nota entre 3 e 4 → `'Neutro'`
  - Nota abaixo de 3 → `'Insatisfeito'`

Ordene pela nota **crescente** e limite a **15 linhas**.

---
* **Exercício 06** *(médio)*: O time de Customer Success quer identificar **pedidos concluídos que ainda não foram avaliados** — para pedir feedback. Traga `pedido_id`, `status` e a `data_pedido_br` (formato brasileiro). Ordene pela data mais recente e limite a **15 linhas**.

---
* **Exercício 07** *(médio-difícil)*: O time Financeiro quer analisar pedidos agrupados pelo **início do mês** (para dashboards de sazonalidade). Traga `pedido_id`, `nome` do cliente, `nome` do restaurante, uma coluna `inicio_mes` (com `DATE_TRUNC` no primeiro dia do mês do pedido) e a `taxa_entrega`. Ordene por `inicio_mes` **decrescente** e limite a **15 linhas**.

---
* **Exercício 08** *(difícil)*: O time Financeiro quer auditar pedidos **concluídos** feitos em **dezembro** (de qualquer ano) com **taxa de entrega maior que zero**. Traga `pedido_id`, `nome` do cliente, `nome` do restaurante, `data_br` (formato `dd/mm/aaaa`) e `taxa_entrega`. Ordene pela `taxa_entrega` **decrescente** e limite a **15 linhas**.

---
* **Exercício 09** *(difícil)*: O time de Customer Success quer priorizar contatos: para cada pedido **concluído**, mostre a nota da avaliação (tratando NULL como 0) e uma coluna `acao` com `IF`:
  - Se a nota tratada for **menor que 3** → `'Contatar cliente'`
  - Caso contrário → `'OK'`

Traga `pedido_id`, `status`, `nota` (já tratada) e `acao`. Ordene pela `nota` **crescente** e limite a **20 linhas**.

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
