# Exercícios da aula 18:

## Conteúdo acumulado (aulas 10 a 17):
- **Consultas básicas:** `SELECT`, `FROM`, `DISTINCT`, `LIMIT`, `ORDER BY`
- **Filtros e operadores:** `WHERE` com aritméticos (`+`, `-`, `*`, `/`), comparação (`>`, `<`, `>=`, `<=`, `=`, `<>`) e lógicos (`AND`, `OR`, `NOT`)
- **Condicionais:** `IF`, `CASE`, `COALESCE`
- **Funções de data:** `EXTRACT`, `DATE_TRUNC`, `DATE_DIFF`/`DATETIME_DIFF`, `DATE_ADD`/`DATE_SUB`, `FORMAT_DATE`/`PARSE_DATE`, `CURRENT_DATE`
- **Funções de texto:** `UPPER`/`LOWER`/`INITCAP`, `TRIM`/`LTRIM`/`RTRIM`, `LENGTH`, `SUBSTR`/`STRPOS`/`SPLIT`, `REPLACE`/`REGEXP_REPLACE`


### EXERCÍCIOS:


* **Exercício 01** *(fácil)*: O time de BI quer analisar quais clientes foram cadastrados em **2023**. Traga `cliente_id`, `nome`, `data_cadastro` e uma coluna `ano_cadastro`. Filtre apenas o ano de 2023. Ordene pela data de cadastro **crescente** e limite a **15 linhas**.

---
* **Exercício 02** *(fácil)*: A equipe de Marketing recebeu os nomes com **caixa inconsistente** de uma planilha externa. Traga `cliente_id`, `nome` e três colunas mostrando o mesmo nome padronizado de três formas diferentes: `nome_upper` (tudo maiúsculo), `nome_lower` (tudo minúsculo) e `nome_initcap` (primeira letra de cada palavra em maiúscula). Limite a **15 linhas**.

---
* **Exercício 03** *(fácil)*: O time de Suporte quer analisar o **tamanho dos comentários** das avaliações para identificar feedback muito curto. Traga `avaliacao_id`, `nota`, `comentario` e uma coluna `tamanho_comentario`. Ordene pelo tamanho **decrescente** e limite a **15 linhas**.

---
* **Exercício 04** *(fácil)*: O time de CRM quer saber **há quantos dias** cada cliente está cadastrado. Traga `cliente_id`, `nome`, `data_cadastro` e uma coluna `dias_como_cliente`. Ordene do cliente mais antigo para o mais recente e limite a **20 linhas**.

---
* **Exercício 05** *(médio)*: O time Financeiro quer os pedidos com uma coluna adicional `inicio_mes` (o primeiro dia do mês do pedido) para agrupar visualmente por mês depois. Use `DATE_TRUNC`. Traga `pedido_id`, `data_hora_pedido`, `inicio_mes` e `taxa_entrega`. Ordene por `inicio_mes` e limite a **20 linhas**.

---
* **Exercício 06** *(médio)*: O time de CRM quer disparar uma campanha de aniversário de **1 ano de cadastro**. Traga `cliente_id`, `nome`, `data_cadastro` e uma coluna `aniversario_1_ano` (data em que o cliente completa 1 ano). Ordene por `aniversario_1_ano` crescente e limite a **15 linhas**.

---
* **Exercício 07** *(médio)*: O time de BI quer segmentar clientes pelo **provedor de email**. Traga `cliente_id`, `email` e uma coluna `dominio` extraída com `SUBSTR` + `STRPOS` (o que vem depois do `@`). Ordene por `dominio` e limite a **15 linhas**.

---
* **Exercício 08** *(médio)*: A empresa está migrando o domínio dos emails de `@exemplo.com` para `@entregaja.com.br`. Traga `cliente_id`, `email` (o original) e `email_novo` já com a substituição feita. Limite a **15 linhas**.

---
* **Exercício 09** *(difícil)*: O time Financeiro quer um relatório dos pedidos feitos em **dezembro** (de qualquer ano), com a data em **formato brasileiro** (`dd/mm/aaaa`) e o **dia da semana** em texto. Traga `pedido_id`, `data_br`, `dia_semana` e `taxa_entrega`. Ordene pela data mais recente e limite a **15 linhas**.

---
* **Exercício 10** *(difícil)*: O time de CRM quer extrair o **primeiro nome** de cada cliente para personalizar mensagens. Traga `cliente_id`, `nome` completo, uma coluna `primeiro_nome` (extraída com `SPLIT`) e uma coluna `tamanho_primeiro_nome` com o `LENGTH` do primeiro nome. Ordene pelo `tamanho_primeiro_nome` **decrescente** e limite a **15 linhas**.
