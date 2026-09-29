# Gabarito da aula 18:

## Conteúdo acumulado (aulas 10 a 17):
- **Consultas básicas:** `SELECT`, `FROM`, `DISTINCT`, `LIMIT`, `ORDER BY`
- **Filtros e operadores:** `WHERE` com aritméticos (`+`, `-`, `*`, `/`), comparação (`>`, `<`, `>=`, `<=`, `=`, `<>`) e lógicos (`AND`, `OR`, `NOT`)
- **Condicionais:** `IF`, `CASE`, `COALESCE`
- **Funções de data:** `EXTRACT`, `DATE_TRUNC`, `DATE_DIFF`/`DATETIME_DIFF`, `DATE_ADD`/`DATE_SUB`, `FORMAT_DATE`/`PARSE_DATE`, `CURRENT_DATE`
- **Funções de texto:** `UPPER`/`LOWER`/`INITCAP`, `TRIM`/`LTRIM`/`RTRIM`, `LENGTH`, `SUBSTR`/`STRPOS`/`SPLIT`, `REPLACE`/`REGEXP_REPLACE`


### EXERCÍCIOS:


* **Exercício 01** *(fácil)*: O time de BI quer analisar quais clientes foram cadastrados em **2023**. Traga `cliente_id`, `nome`, `data_cadastro` e uma coluna `ano_cadastro`. Filtre apenas o ano de 2023. Ordene pela data de cadastro **crescente** e limite a **15 linhas**.

```sql
SELECT 
    cliente_id,
    nome,
    data_cadastro,
    EXTRACT(YEAR FROM data_cadastro) AS ano_cadastro
FROM `unipds-503513.entregaja.clientes`
WHERE EXTRACT(YEAR FROM data_cadastro) = 2023
ORDER BY data_cadastro ASC
LIMIT 15;
```

> 💡 O `EXTRACT` pode aparecer **no `SELECT`** (para exibir a parte da data) **e no `WHERE`** (para filtrar por essa parte) na mesma query. Ordenamos pela `data_cadastro` completa — se ordenássemos pelo `ano_cadastro`, todos empatariam em 2023.

---
* **Exercício 02** *(fácil)*: A equipe de Marketing recebeu os nomes com **caixa inconsistente** de uma planilha externa. Traga `cliente_id`, `nome` e três colunas mostrando o mesmo nome padronizado de três formas diferentes: `nome_upper` (tudo maiúsculo), `nome_lower` (tudo minúsculo) e `nome_initcap` (primeira letra de cada palavra em maiúscula). Limite a **15 linhas**.

```sql
SELECT 
    cliente_id,
    nome,
    UPPER(nome) AS nome_upper,
    LOWER(nome) AS nome_lower,
    INITCAP(nome) AS nome_initcap
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

> 💡 As três funções não mudam o dado original — só criam colunas novas. `INITCAP` é a mais usada em **relatórios apresentáveis** (nomes próprios, cidades); `UPPER` e `LOWER` são mais úteis para **comparações** (padronizar antes de comparar com `=`).

---
* **Exercício 03** *(fácil)*: O time de Suporte quer analisar o **tamanho dos comentários** das avaliações para identificar feedback muito curto. Traga `avaliacao_id`, `nota`, `comentario` e uma coluna `tamanho_comentario`. Ordene pelo tamanho **decrescente** e limite a **15 linhas**.

```sql
SELECT 
    avaliacao_id,
    nota,
    comentario,
    LENGTH(comentario) AS tamanho_comentario
FROM `unipds-503513.entregaja.avaliacoes`
ORDER BY tamanho_comentario DESC
LIMIT 15;
```

> 💡 `LENGTH` conta o número de **caracteres**, incluindo espaços. Comentários `NULL` retornam `LENGTH` `NULL` — e no BigQuery, valores nulos ficam **no fim** quando ordenados por `DESC`.

---
* **Exercício 04** *(fácil)*: O time de CRM quer saber **há quantos dias** cada cliente está cadastrado. Traga `cliente_id`, `nome`, `data_cadastro` e uma coluna `dias_como_cliente`. Ordene do cliente mais antigo para o mais recente e limite a **20 linhas**.

```sql
SELECT 
    cliente_id,
    nome,
    data_cadastro,
    DATE_DIFF(CURRENT_DATE(), data_cadastro, DAY) AS dias_como_cliente
FROM `unipds-503513.entregaja.clientes`
ORDER BY dias_como_cliente DESC
LIMIT 20;
```

> 💡 Ordem dos argumentos do `DATE_DIFF`: **(final, inicial, unidade)**. Como quem tem **mais dias de cadastro** é o **mais antigo**, ordenamos `dias_como_cliente DESC`.

---
* **Exercício 05** *(médio)*: O time Financeiro quer os pedidos com uma coluna adicional `inicio_mes` (o primeiro dia do mês do pedido) para agrupar visualmente por mês depois. Use `DATE_TRUNC`. Traga `pedido_id`, `data_hora_pedido`, `inicio_mes` e `taxa_entrega`. Ordene por `inicio_mes` e limite a **20 linhas**.

```sql
SELECT 
    pedido_id,
    data_hora_pedido,
    DATE_TRUNC(DATE(data_hora_pedido), MONTH) AS inicio_mes,
    taxa_entrega
FROM `unipds-503513.entregaja.pedidos`
ORDER BY inicio_mes
LIMIT 20;
```

> 💡 `DATE_TRUNC` **mantém o formato de data** (diferente do `EXTRACT`, que devolve um número). Assim, todos os pedidos de janeiro ficam com `inicio_mes = 2023-01-01`, todos de fevereiro com `2023-02-01`, etc. — perfeito para agrupamento. Convertemos `data_hora_pedido` (que é `DATETIME`) para `DATE`.

---
* **Exercício 06** *(médio)*: O time de CRM quer disparar uma campanha de aniversário de **1 ano de cadastro**. Traga `cliente_id`, `nome`, `data_cadastro` e uma coluna `aniversario_1_ano` (data em que o cliente completa 1 ano). Ordene por `aniversario_1_ano` crescente e limite a **15 linhas**.

```sql
SELECT 
    cliente_id,
    nome,
    data_cadastro,
    DATE_ADD(data_cadastro, INTERVAL 1 YEAR) AS aniversario_1_ano
FROM `unipds-503513.entregaja.clientes`
ORDER BY aniversario_1_ano ASC
LIMIT 15;
```

> 💡 A sintaxe do intervalo é sempre `INTERVAL n <unidade>` (`DAY`, `MONTH`, `YEAR`…). Para "6 meses depois", seria `INTERVAL 6 MONTH`. Para "30 dias antes", usaríamos `DATE_SUB(..., INTERVAL 30 DAY)`.

---
* **Exercício 07** *(médio)*: O time de BI quer segmentar clientes pelo **provedor de email**. Traga `cliente_id`, `email` e uma coluna `dominio` extraída com `SUBSTR` + `STRPOS` (o que vem depois do `@`). Ordene por `dominio` e limite a **15 linhas**.

```sql
SELECT 
    cliente_id,
    email,
    SUBSTR(email, STRPOS(email, '@') + 1) AS dominio
FROM `unipds-503513.entregaja.clientes`
ORDER BY dominio
LIMIT 15;
```

> 💡 `STRPOS(email, '@')` devolve a **posição do `@`** (por exemplo, 15). Somamos 1 para começar **depois** do `@`, e `SUBSTR` sem o terceiro argumento vai **até o fim** do texto. A mesma coisa poderia ser feita com `SPLIT(email, '@')[OFFSET(1)]` — mais legível quando há separador claro.

---
* **Exercício 08** *(médio)*: A empresa está migrando o domínio dos emails de `@exemplo.com` para `@entregaja.com.br`. Traga `cliente_id`, `email` (o original) e `email_novo` já com a substituição feita. Limite a **15 linhas**.

```sql
SELECT 
    cliente_id,
    email,
    REPLACE(email, '@exemplo.com', '@entregaja.com.br') AS email_novo
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

> 💡 `REPLACE(texto, procurar, substituir)` faz busca **literal exata**. Como `@exemplo.com` só aparece uma vez em cada email, a troca é direta. Se tivéssemos um padrão que varia (ex.: qualquer domínio), aí `REGEXP_REPLACE` com regex seria melhor.

---
* **Exercício 09** *(difícil)*: O time Financeiro quer um relatório dos pedidos feitos em **dezembro** (de qualquer ano), com a data em **formato brasileiro** (`dd/mm/aaaa`) e o **dia da semana** em texto. Traga `pedido_id`, `data_br`, `dia_semana` e `taxa_entrega`. Ordene pela data mais recente e limite a **15 linhas**.

```sql
SELECT 
    pedido_id,
    FORMAT_DATE('%d/%m/%Y', DATE(data_hora_pedido)) AS data_br,
    FORMAT_DATE('%A', DATE(data_hora_pedido)) AS dia_semana,
    taxa_entrega
FROM `unipds-503513.entregaja.pedidos`
WHERE EXTRACT(MONTH FROM data_hora_pedido) = 12
ORDER BY data_hora_pedido DESC
LIMIT 15;
```

> 💡 Exercício que combina três funções: `EXTRACT` no `WHERE` (para filtrar o mês 12), `FORMAT_DATE` no `SELECT` (para gerar a coluna formatada), e outro `FORMAT_DATE` com o padrão `%A` para o nome do dia da semana. Ordenamos pela `data_hora_pedido` **original** — se ordenássemos pela `data_br` (texto), a ordem seria alfabética.

---
* **Exercício 10** *(difícil)*: O time de CRM quer extrair o **primeiro nome** de cada cliente para personalizar mensagens. Traga `cliente_id`, `nome` completo, uma coluna `primeiro_nome` (extraída com `SPLIT`) e uma coluna `tamanho_primeiro_nome` com o `LENGTH` do primeiro nome. Ordene pelo `tamanho_primeiro_nome` **decrescente** e limite a **15 linhas**.

```sql
SELECT 
    cliente_id,
    nome,
    SPLIT(nome, ' ')[OFFSET(0)] AS primeiro_nome,
    LENGTH(SPLIT(nome, ' ')[OFFSET(0)]) AS tamanho_primeiro_nome
FROM `unipds-503513.entregaja.clientes`
ORDER BY tamanho_primeiro_nome DESC
LIMIT 15;
```

> 💡 `SPLIT(nome, ' ')` quebra o nome em um **array** pelos espaços. `[OFFSET(0)]` pega o **primeiro pedaço** (arrays no BigQuery começam em 0 com `OFFSET`, e em 1 com `ORDINAL`). Cuidado: aplicamos `SPLIT` **duas vezes** — não dá para reusar o alias `primeiro_nome` dentro do próprio `SELECT`.

---

## 📌 Onde cada função entra na query

```sql
SELECT [DISTINCT] colunas       -- EXTRACT, DATE_TRUNC, DATE_DIFF, DATE_ADD/SUB,
                                -- FORMAT_DATE, UPPER/LOWER/INITCAP, TRIM,
                                -- LENGTH, SUBSTR, STRPOS, SPLIT, REPLACE
                                -- criam ou transformam colunas aqui.
FROM tabela                     
WHERE condição                  -- Todas essas funções também podem entrar aqui,
                                -- ex.: WHERE EXTRACT(MONTH FROM d) = 12
                                --      WHERE LENGTH(comentario) < 15
ORDER BY coluna [ASC|DESC]      -- Pode usar aliases criados no SELECT
LIMIT n;                        -- Quantas linhas trazer
```
