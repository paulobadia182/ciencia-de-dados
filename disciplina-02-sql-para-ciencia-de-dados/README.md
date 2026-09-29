# SQL para Ciência de Dados

Este diretório reúne o material completo do módulo de SQL — do `SELECT` básico até window functions e otimização física no BigQuery, com um projeto aplicado no final. O conteúdo foi construído em ordem crescente de dificuldade: cada aula assume o que veio antes.

Todas as queries usam o dataset **`unipds-503513.entregaja.*`** no **BigQuery** (delivery fictício "EntregaJá"), com sete tabelas: `clientes`, `restaurantes`, `entregadores`, `itens`, `pedidos`, `pedido_itens` e `avaliacoes`. Os CSVs originais estão em [`aula09_datasets/`](aula09_datasets/) — dá pra recriar o dataset localmente (DuckDB, SQLite, Postgres) se você não quiser usar o BigQuery.

---

## Como usar este material

O fluxo recomendado por aula é:

1. **Leia o `exemplos.md`** da aula — cada tópico traz um modelo mental e queries comentadas.
2. **Rode os exemplos** no BigQuery (ou no seu SGBD) contra o dataset EntregaJá.
3. Quando a aula tiver uma **lista de exercícios** correspondente (padrão: a aula seguinte é de exercícios), tente resolver **antes** de abrir o gabarito.
4. **Compare com o gabarito** — se o resultado bater, ótimo; se não, use a explicação pra entender **por quê** a versão do gabarito funciona.

> Regra de ouro: escreva a query você mesma primeiro. Copiar gabarito não fixa nada.

---

## Estrutura das aulas

### Fundamentos e modelagem

| Pasta | Conteúdo |
|-------|----------|
| [`aula08_resolucao/`](aula08_resolucao/) | Modelagem ER e star schema do EntregaJá (diagramas em Mermaid) |
| [`aula09_datasets/`](aula09_datasets/) | CSVs das sete tabelas do dataset — fonte de dados de todas as aulas |

### Consultas básicas

| Pasta | Tópico |
|-------|--------|
| [`aula10/`](aula10/) | `SELECT` e `FROM` — a consulta mais simples |
| [`aula11/`](aula11/) | `LIMIT`, `DISTINCT` e `ORDER BY` |
| [`aula12/`](aula12/) | Exercícios (aulas 10–11) + gabarito |

### Filtros, operadores e condicionais

| Pasta | Tópico |
|-------|--------|
| [`aula14/`](aula14/) | Operadores aritméticos, de comparação e lógicos |
| [`aula15/`](aula15/) | `WHERE`, `IF`, `CASE` e `COALESCE` |
| [`aula16/`](aula16/) | Exercícios (aulas 10–15) + gabarito |

### Funções e JOINs

| Pasta | Tópico |
|-------|--------|
| [`aula18/`](aula18/) | Funções de data (`EXTRACT`, `DATE_TRUNC`, `DATE_DIFF`, ...) e de texto (`UPPER`, `TRIM`, `SUBSTR`, ...) — inclui exercícios e gabarito |
| [`aula19/`](aula19/) | `JOIN`s: `INNER`, `LEFT`, `RIGHT`, `FULL` |
| [`aula20/`](aula20/) | Exercícios (aulas 10–19) + gabarito |

### Agregação e subqueries

| Pasta | Tópico |
|-------|--------|
| [`aula21/`](aula21/) | Agregações (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`), `GROUP BY` e `HAVING` |
| [`aula22/`](aula22/) | Exercícios (aulas 10–21) + gabarito |
| [`aula23/`](aula23/) | Subqueries e CTEs (`WITH`) |
| [`aula24/`](aula24/) | Exercícios (aulas 10–23) + gabarito |

### BigQuery na prática

| Pasta | Tópico |
|-------|--------|
| [`aula25/`](aula25/) | Plano de execução e bytes processados — como escrever SQL eficiente e barato no BigQuery |

### Window functions

| Pasta | Tópico |
|-------|--------|
| [`aula26/`](aula26/) | Estrutura básica: `funcao() OVER (PARTITION BY ... ORDER BY ...)` |
| [`aula27/`](aula27/) | Ranking: `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `NTILE` |
| [`aula28/`](aula28/) | Deslocamento: `LAG`, `LEAD`, `FIRST_VALUE`, `LAST_VALUE` |
| [`aula29/`](aula29/) | Agregações como window (`SUM OVER`, `AVG OVER`, running totals, médias móveis) |

### Persistência e otimização no BigQuery

| Pasta | Tópico |
|-------|--------|
| [`aula30/`](aula30/) | Composição analítica com CTEs encadeadas e promoção para `VIEW` reutilizável |
| [`aula31/`](aula31/) | `MATERIALIZED VIEW` — cache gerenciado, restrições incrementais e `APPROX_COUNT_DISTINCT` vs. `allow_non_incremental_definition` |
| [`aula32/`](aula32/) | Otimização física: `PARTITION BY` e `CLUSTER BY` (com as pegadinhas do sandbox) |

---

## Listas de exercícios consolidadas

A pasta [`exercicios/`](exercicios/) reúne listas que atravessam várias aulas e cobram a combinação dos tópicos:

- [`lista_01_window_ctes.md`](exercicios/lista_01_window_ctes.md) — consolidação das aulas 26 a 29 (window functions + CTEs).

Cada exercício tem gabarito escondido em bloco `<details>` — resolva primeiro, expanda depois.

---

## Projeto final

A pasta [`projeto-sql-fraude/`](projeto-sql-fraude/) contém um projeto aplicado de detecção de fraude em transações, com:

- [`orientacao_e_gabarito/`](projeto-sql-fraude/orientacao_e_gabarito/) — enunciado do case e orientações originais da atividade (`orientacoes_do_case.docx`). Comece por aqui antes de olhar as queries.
- [`sql/`](projeto-sql-fraude/sql/) — script de construção da tabela unificada (`abt_fraude`) e queries analíticas.
- [`relatorios/`](projeto-sql-fraude/relatorios/) — relatório final em Markdown e PDF, com achados, recomendações e a leitura de negócio.
- [`apresentacao/`](projeto-sql-fraude/apresentacao/) — deck com os insights principais.
- [`assets/`](projeto-sql-fraude/assets/) — gráficos e capturas usados no relatório.

É o exercício de fechamento do módulo: aplica JOINs, CTEs, agregações e window functions numa análise real, com entrega em formato de produto (relatório + apresentação).

---

## Dicas de estudo

- **Pule aulas com cuidado.** Cada exercício acumula o conteúdo das anteriores — se a aula 22 estiver difícil, é sinal de que vale revisar 21 (GROUP BY) ou 19 (JOINs), não seguir em frente.
- **Nomeie bem as colunas.** Todos os gabaritos usam nomes descritivos (`taxa_media_plataforma`, `posicao_no_ranking`) em vez de `x`, `p1`, `t2`. Nome bom é metade da legibilidade.
- **Rode as queries de verdade.** Ler SQL sem executar não fixa — abra o BigQuery e cole cada exemplo.
- **No BigQuery, olhe o "medidor de bytes"** (canto inferior esquerdo) antes de rodar. A aula 25 explica por que isso importa — e as aulas 30 a 32 mostram como reduzir esse número com `VIEW`, `MATERIALIZED VIEW` e particionamento.
