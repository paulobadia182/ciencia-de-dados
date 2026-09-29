# Aula 26: Window Functions — a estrutura

**Objetivo:** entender a **estrutura básica** de uma *window function* — como se escreve, o que cada pedaço significa e como o SQL "vê" o cálculo. Nesta aula o foco é **absorver a forma**. As funções específicas (`RANK`, `ROW_NUMBER`, `LAG`, `LEAD`, running totals, médias móveis) você vai estudar nas próximas aulas.

> 💡 **Diferença chave:** até agora, tudo que "olhava várias linhas juntas" (`SUM`, `AVG`, `COUNT`) precisava de `GROUP BY` — e o `GROUP BY` **colapsa** várias linhas em uma. A window function faz um cálculo sobre "várias linhas relacionadas", mas **sem colapsar**: cada linha original continua no resultado, e o valor calculado aparece **ao lado** dela.

---

## 🎯 Modelo mental

Pense em três formas de "olhar várias linhas juntas":

| Forma | O que faz com as linhas | Exemplo |
|-------|-------------------------|---------|
| **`GROUP BY` + agregação** | **Colapsa** várias linhas em uma | "média de idade **por região**" (1 linha por região) |
| **Subquery/CTE escalar no `SELECT`** | Traz **um único valor** ao lado de todas as linhas | "cada pedido + a **média geral** ao lado" |
| **Window function** | Traz um valor calculado sobre um **conjunto de linhas relacionadas** ao lado de **cada linha** | "cada pedido + a **média da região daquele cliente** ao lado" |

A window function é a evolução natural da subquery escalar: em vez de um único valor "global" ao lado de todas as linhas, o valor é **específico do grupo de cada linha** — mas **sem** perder as linhas individuais no processo.

---

## 🧩 A estrutura básica

Toda window function segue este esqueleto:

```sql
funcao() OVER (
    [PARTITION BY coluna(s)]
    [ORDER BY coluna(s)]
)
```

Três partes, nessa ordem:

| Parte | Papel | Obrigatório? |
|-------|-------|--------------|
| **`funcao()`** | O cálculo — `AVG`, `SUM`, `COUNT`, `ROW_NUMBER`, `RANK`, `LAG`, ... | ✅ Sim |
| **`OVER ( ... )`** | A "janela" — **quais linhas** entram no cálculo | ✅ Sim (mesmo vazio: `OVER ()`) |
| **`PARTITION BY`** | Divide as linhas em **grupos** — o cálculo se reinicia a cada grupo | Opcional |
| **`ORDER BY`** | Ordena as linhas **dentro** de cada grupo — importante para funções sequenciais (`ROW_NUMBER`, `RANK`, running totals) | Opcional |

> 🧭 **Regra do `OVER`:** é ele que **transforma** uma função comum em window function. `AVG(idade)` sozinho precisa de `GROUP BY`. `AVG(idade) OVER (...)` é uma window function — não colapsa linhas.

---

# 📘 Exemplo 1 — `OVER ()` vazio (a mais simples possível)

**Cenário:** para cada cliente, mostrar o nome, a idade e ao lado a **idade média geral** — para comparar cada cliente com a média.

```sql
SELECT 
    nome,
    idade,
    AVG(idade) OVER () AS idade_media_geral
FROM `unipds-503513.entregaja.clientes`
ORDER BY idade DESC
LIMIT 15;
```

**Como ler:**

- `AVG(idade)` é a função de agregação.
- `OVER ()` — a janela **está vazia**, ou seja, "considere **todas as linhas** da tabela como uma única janela".
- Resultado: a mesma média aparece **em todas as linhas** (idêntico a uma subquery escalar no `SELECT`).

**Por que começar por aqui?** Este é o menor `OVER` possível — apenas os parênteses. Serve para você **fixar o esqueleto** antes de adicionar peças. Note que **não usamos `GROUP BY`** — e mesmo assim, cada cliente aparece no resultado, com a média ao lado.

> ⚠️ Repare: `SELECT nome, idade, AVG(idade) FROM clientes` (sem `OVER`) daria **erro**, porque `nome` e `idade` não estão em `GROUP BY`. É o `OVER` que "libera" o mix entre coluna individual e função de agregação.

---

# 📗 Exemplo 2 — `PARTITION BY` (média por grupo, ao lado da linha)

**Cenário:** para cada cliente, mostrar o nome, a região e a idade — junto com a **idade média da região dele**.

```sql
SELECT 
    nome,
    regiao,
    idade,
    AVG(idade) OVER (PARTITION BY regiao) AS idade_media_regiao
FROM `unipds-503513.entregaja.clientes`
ORDER BY regiao, idade DESC
LIMIT 20;
```

**Como ler:**

- `PARTITION BY regiao` divide as linhas em **grupos por região** (Sul, Sudeste, ...).
- `AVG(idade)` é calculado **dentro de cada grupo**.
- Resultado: dois clientes da mesma região veem a **mesma** média ao lado; clientes de regiões diferentes veem médias **diferentes**.

**Comparação mental:**

- `GROUP BY regiao` + `AVG(idade)` → **1 linha por região** (colapsa).
- `AVG(idade) OVER (PARTITION BY regiao)` → **1 linha por cliente**, cada um com a média da sua região ao lado (**não colapsa**).

> 🧭 **Analogia:** `PARTITION BY` é o "GROUP BY do OVER". A diferença é que ele **não some** as linhas — só define grupos internos para o cálculo da janela.

---

# 📙 Exemplo 3 — `ORDER BY` dentro do `OVER` (numerar linhas)

**Cenário:** listar os 10 pedidos mais recentes, com uma coluna que **numera** cada pedido por ordem de chegada (1 = mais recente).

```sql
SELECT 
    ROW_NUMBER() OVER (ORDER BY data_hora_pedido DESC) AS posicao,
    pedido_id,
    cliente_id,
    data_hora_pedido
FROM `unipds-503513.entregaja.pedidos`
ORDER BY posicao
LIMIT 10;
```

**Como ler:**

- `ROW_NUMBER()` é uma window function que atribui **um número sequencial** para cada linha da janela.
- `OVER (ORDER BY data_hora_pedido DESC)` — dentro da janela (aqui, a tabela inteira), as linhas são ordenadas por data decrescente. O `ROW_NUMBER` respeita essa ordem: 1 pro mais recente, 2 pro segundo mais recente, e assim por diante.
- **Não tem `PARTITION BY`** — a janela é a tabela toda.

**Detalhe importante:** o `ORDER BY` **dentro** do `OVER` é diferente do `ORDER BY` do **fim** da query.
- O `ORDER BY` dentro do `OVER` diz **como a window function conta** (define quem é "o 1º", "o 2º", etc.).
- O `ORDER BY` no fim diz **como o resultado final é exibido** na tela.

Nesta aula é comum os dois serem iguais — mas eles têm papéis diferentes.

---

# 📕 Exemplo 4 — `PARTITION BY` + `ORDER BY` juntos (o formato completo)

**Cenário:** numerar os pedidos de **cada cliente** por ordem cronológica — para saber se cada pedido é o 1º, 2º, 3º daquele cliente.

```sql
SELECT 
    cliente_id,
    pedido_id,
    data_hora_pedido,
    ROW_NUMBER() OVER (
        PARTITION BY cliente_id 
        ORDER BY data_hora_pedido ASC
    ) AS numero_pedido_do_cliente
FROM `unipds-503513.entregaja.pedidos`
ORDER BY cliente_id, numero_pedido_do_cliente
LIMIT 20;
```

**Como ler, peça por peça:**

1. `PARTITION BY cliente_id` → divide as linhas em **grupos por cliente**.
2. `ORDER BY data_hora_pedido ASC` → dentro de cada grupo, ordena do pedido mais antigo pro mais novo.
3. `ROW_NUMBER()` → dá um número sequencial começando em **1** para cada grupo — ou seja, **reinicia a cada cliente**.

**Resultado:** para o cliente A, os pedidos ganham 1, 2, 3, 4... na ordem cronológica. Para o cliente B, também começa em 1, 2, 3... É como se o `ROW_NUMBER` "zerasse o contador" a cada novo cliente.

Este é o formato **mais completo** e o mais comum no dia a dia: `PARTITION BY` para dizer "por qual coluna agrupar" + `ORDER BY` para dizer "em qual ordem contar dentro do grupo".

---

## 📝 Resumo — os 4 formatos que você vai ver

| Estrutura | O que faz | Exemplo típico |
|-----------|-----------|---------------|
| `funcao() OVER ()` | Aplica a função sobre **todas as linhas** — mesmo valor em todas | Média geral ao lado de cada linha |
| `funcao() OVER (PARTITION BY x)` | Aplica a função **por grupo** — mesmo valor dentro do grupo | Média da região ao lado de cada cliente |
| `funcao() OVER (ORDER BY x)` | Aplica a função **em ordem** — valor muda linha a linha | Ranking global, running total |
| `funcao() OVER (PARTITION BY x ORDER BY y)` | Aplica a função **em ordem, dentro de cada grupo** | "É o 1º/2º/3º pedido daquele cliente" |

---

## ⚠️ Cuidados importantes

1. **Window functions não usam `GROUP BY`.** O agrupamento é feito **dentro** do `OVER`, com `PARTITION BY`. Misturar os dois na mesma query é raro e costuma indicar confusão de intenção.

2. **O resultado sempre tem o mesmo número de linhas que a tabela original.** Ao contrário do `GROUP BY`, a window function **não colapsa** — se você começou com 10 mil pedidos, termina com 10 mil linhas (mais uma coluna nova).

3. **`OVER` é obrigatório** — mesmo vazio. `AVG(idade) OVER ()` funciona; `AVG(idade)` sozinho, sem `GROUP BY`, dá erro.

4. **`ORDER BY` dentro do `OVER` ≠ `ORDER BY` no fim da query.** O primeiro define **como a janela conta**; o segundo define **como o resultado é exibido**. Podem ser iguais ou totalmente diferentes.

5. **Window functions rodam depois do `WHERE`.** Se você filtrar `WHERE status = 'Concluído'`, a janela só enxerga as linhas concluídas — os cancelados nem entram no cálculo.

6. **Não dá para usar window function no `WHERE`.** Elas são calculadas **depois** do `WHERE`. Para filtrar por resultado de window function, use uma CTE ou subquery no `FROM`.

---

> 🧭 **O que vem depois:** nas próximas aulas você vai explorar **quais funções** cabem nesse esqueleto — `RANK`, `DENSE_RANK`, `ROW_NUMBER`, `LAG`, `LEAD`, `SUM` como running total, `AVG` como média móvel, entre outras. A boa notícia: a **estrutura** que você viu aqui **não muda**. É sempre `funcao() OVER (PARTITION BY ... ORDER BY ...)` — o que varia é a função e o que você coloca em cada uma das duas partes de dentro do `OVER`.
