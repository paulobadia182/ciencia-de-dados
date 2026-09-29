# Aula 23: Subqueries e CTEs

**Objetivo:** aprender a **usar uma consulta dentro de outra** — seja aninhando (subquery) ou dando um nome ao resultado intermediário (CTE).

> 💡 **Diferença chave:** até agora, cada `SELECT` era autossuficiente. Agora, um `SELECT` pode **usar o resultado de outro `SELECT`** — como um filtro dinâmico, uma tabela intermediária, ou um valor auxiliar. Existem duas formas de escrever isso: **subquery** (aninhada) e **CTE** (nomeada com `WITH`).

---

## 🎯 Modelo mental

Toda vez que você precisa que uma consulta **use o resultado de outra**, existem dois caminhos:

| Forma | Como se escreve | Quando prefere |
|-------|----------------|----------------|
| **Subquery** | Consulta entre parênteses **dentro** de outra | Filtros pontuais, valores escalares, um único uso |
| **CTE** (`WITH`) | Consulta nomeada **antes** da query principal | Quando o resultado é reusado, ou a lógica ficaria muito aninhada |

As duas fazem a mesma coisa em muitos casos — a escolha é por **legibilidade**.

---

# 📘 Parte 1 — Subqueries

Uma **subquery** (também chamada de *consulta aninhada*) é uma query **dentro de parênteses**, colocada dentro de outra query. Ela roda **primeiro**, e o resultado dela é usado pela query **externa**.

Existem **três lugares principais** onde uma subquery pode aparecer:

| Onde | Para quê | Exemplo típico |
|------|----------|---------------|
| **`WHERE`** | Filtrar linhas com base em um cálculo ou lista dinâmica | "clientes com idade acima da média" |
| **`FROM`** | Usar o resultado como uma **tabela derivada** | "média dos totais de pedidos por cliente" |
| **`SELECT`** | Trazer um **valor auxiliar** ao lado de cada linha | "cada pedido + a média geral ao lado, para comparar" |

---

## 🔎 1.1 — Subquery no WHERE

O uso mais comum. Você filtra a query externa com base em um valor (ou lista) calculado pela subquery.

### Exemplo 1: Subquery com operador de comparação (`>`, `<`, `=`)

**Cenário:** clientes com idade **acima da média geral**.

```sql
SELECT 
    cliente_id,
    nome,
    idade,
    cidade
FROM `unipds-503513.entregaja.clientes`
WHERE idade > (
    SELECT AVG(idade) 
    FROM `unipds-503513.entregaja.clientes`
)
ORDER BY idade DESC
LIMIT 15;
```

**Explicação:** A subquery entre parênteses **roda primeiro** e devolve **um único valor** (a média de idade — ex.: `38.5`). Depois, a query externa filtra apenas clientes cuja `idade` é maior que esse valor.

Uma subquery usada com operador de comparação precisa retornar **exatamente uma linha e uma coluna** (um "escalar"). Se retornasse mais linhas, daria erro.

---

### Exemplo 2: Subquery com `IN` — filtrar por uma lista dinâmica

**Cenário:** todos os pedidos feitos por clientes do plano **Premium**.

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
    WHERE plano = 'Premium'
)
ORDER BY data_hora_pedido DESC
LIMIT 15;
```

**Explicação:** Aqui a subquery devolve **uma lista** de IDs (todos os cliente_ids Premium). O `IN` filtra a tabela de pedidos, mantendo apenas linhas cujo `cliente_id` está nessa lista.

Muitas vezes esse mesmo resultado pode ser obtido com um `INNER JOIN` — a escolha entre subquery e JOIN é mais uma questão de **legibilidade**: se você só quer filtrar (sem trazer colunas da outra tabela), a subquery costuma deixar a intenção mais clara.

---

### Exemplo 3: Subquery com `NOT IN` — o padrão "anti-join"

**Cenário:** clientes que **nunca fizeram um pedido** (para uma campanha de reativação).

```sql
SELECT 
    cliente_id,
    nome,
    cidade,
    data_cadastro
FROM `unipds-503513.entregaja.clientes`
WHERE cliente_id NOT IN (
    SELECT DISTINCT cliente_id 
    FROM `unipds-503513.entregaja.pedidos`
)
ORDER BY data_cadastro DESC
LIMIT 15;
```

**Explicação:** O `NOT IN` retorna clientes cujo `cliente_id` **não aparece** na lista da subquery — ou seja, clientes que nunca fizeram pedido. É o mesmo resultado que um `LEFT JOIN ... WHERE pedidos.pedido_id IS NULL`, só que via subquery.

⚠️ **Cuidado com `NOT IN` e valores nulos:** se a subquery interna retornar **algum valor `NULL`**, o `NOT IN` acaba retornando **zero linhas** (comportamento traiçoeiro do SQL). Por isso é comum ver `WHERE cliente_id IS NOT NULL` dentro da subquery — aqui não precisamos porque `cliente_id` em `pedidos` nunca é nulo.

---

## 📦 1.2 — Subquery no FROM (tabela derivada)

Quando você quer aplicar **outra consulta em cima do resultado** de uma consulta anterior, coloca a subquery no `FROM`. O resultado vira uma "tabela virtual".

### Exemplo 4: Agregação sobre agregação

**Cenário:** qual a **média, o mínimo e o máximo** de pedidos que cada cliente faz?

```sql
SELECT 
    ROUND(AVG(qtd_pedidos), 2) AS media_pedidos_por_cliente,
    MIN(qtd_pedidos) AS min_pedidos,
    MAX(qtd_pedidos) AS max_pedidos
FROM (
    SELECT 
        cliente_id,
        COUNT(*) AS qtd_pedidos
    FROM `unipds-503513.entregaja.pedidos`
    GROUP BY cliente_id
) AS pedidos_por_cliente;
```

**Explicação:** A subquery interna (`SELECT ... GROUP BY cliente_id`) devolve uma tabela com **uma linha por cliente**, contendo quantos pedidos ele fez. A query externa trata esse resultado como se fosse uma tabela normal (`pedidos_por_cliente`) e aplica **agregações em cima**: a média de pedidos por cliente, o mínimo e o máximo.

Não daria para fazer isso em uma query só, porque não dá para colocar `AVG(COUNT(*))` — precisaríamos "agregar duas vezes", e o SQL não permite. A subquery no `FROM` resolve esse tipo de problema.

**Nota:** subqueries no `FROM` **precisam de um alias** (aqui, `AS pedidos_por_cliente`). O SQL exige um nome para referenciar essa tabela derivada.

---

## 🏷️ 1.3 — Subquery no SELECT (escalar)

Quando você quer trazer **um valor auxiliar** ao lado de cada linha — normalmente um total geral, uma média global, um "benchmark" para comparação.

### Exemplo 5: Cada pedido + a média geral ao lado

**Cenário:** para cada pedido concluído, mostrar o tempo de entrega **junto com a média geral** — para saber quão longe está da média.

```sql
SELECT 
    pedido_id,
    tempo_entrega_min,
    (
        SELECT ROUND(AVG(tempo_entrega_min), 2) 
        FROM `unipds-503513.entregaja.pedidos` 
        WHERE status = 'Concluído'
    ) AS tempo_medio_geral,
    tempo_entrega_min - (
        SELECT AVG(tempo_entrega_min) 
        FROM `unipds-503513.entregaja.pedidos` 
        WHERE status = 'Concluído'
    ) AS diferenca_da_media
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído'
ORDER BY diferenca_da_media DESC
LIMIT 15;
```

**Explicação:** Uma subquery no `SELECT` precisa retornar **um único valor** (uma linha, uma coluna). Aqui, calculamos o tempo médio geral uma vez, e ele aparece em **todas as linhas** do resultado — permitindo comparar cada pedido com o benchmark.

Como a subquery não depende da linha atual, o BigQuery só executa ela **uma vez** (não repete o cálculo linha a linha).

Repare que o **mesmo cálculo aparece duas vezes** no `SELECT` (uma para mostrar o valor, outra para calcular a diferença). É exatamente esse tipo de repetição que uma **CTE** resolve elegantemente — como veremos a seguir.

---

# 📗 Parte 2 — CTEs (`WITH`)

Uma **CTE** (*Common Table Expression*) é uma **consulta nomeada** que você declara **antes** da query principal, usando a cláusula `WITH`. Depois, você referencia essa CTE pelo nome, como se fosse uma tabela.

**Sintaxe geral:**

```sql
WITH nome_da_cte AS (
    SELECT ...
    FROM ...
)
SELECT ...
FROM nome_da_cte;
```

Você pode declarar **várias CTEs** separadas por vírgula:

```sql
WITH 
    cte_a AS ( SELECT ... ),
    cte_b AS ( SELECT ... )
SELECT ... FROM cte_a JOIN cte_b ...
```

> 💡 **Modelo mental:** a CTE é como criar uma "tabela temporária" que só existe dentro daquela query. Ela tem um **nome**, o que deixa o código muito mais legível quando o resultado intermediário é complexo ou reusado.

---

## 🔁 2.1 — CTE simples (equivalente a subquery no FROM)

### Exemplo 6: Reescrevendo o Exemplo 4 com CTE

Vamos pegar o mesmo cenário do Exemplo 4 — **média, mínimo e máximo** de pedidos que cada cliente faz — e reescrever usando `WITH`:

```sql
WITH pedidos_por_cliente AS (
    SELECT 
        cliente_id,
        COUNT(*) AS qtd_pedidos
    FROM `unipds-503513.entregaja.pedidos`
    GROUP BY cliente_id
)
SELECT 
    ROUND(AVG(qtd_pedidos), 2) AS media_pedidos_por_cliente,
    MIN(qtd_pedidos) AS min_pedidos,
    MAX(qtd_pedidos) AS max_pedidos
FROM pedidos_por_cliente;
```

**Explicação:** O resultado é **idêntico** ao Exemplo 4. A diferença é apenas **estilística**:

- Na versão com subquery, o cálculo intermediário fica **aninhado** dentro do `FROM`.
- Na versão com CTE, o cálculo intermediário fica **acima**, com um nome (`pedidos_por_cliente`), e a query principal fica **limpa**.

Para um único uso, tanto faz. Mas assim que a lógica cresce, a versão com CTE lê muito melhor — você vê primeiro o que está sendo calculado, depois como está sendo usado.

---

## 🔂 2.2 — CTE reusada várias vezes (o caso onde CTE ganha claramente)

Este é o **caso mais forte** para preferir CTE sobre subquery: quando o **mesmo resultado intermediário** é usado **mais de uma vez** na query principal.

### Exemplo 7: Clientes com número de pedidos acima da média

**Cenário:** o time de CRM quer identificar clientes cujo **número de pedidos está acima da média** de pedidos por cliente. Ou seja, precisamos:

1. Calcular quantos pedidos cada cliente fez (tabela intermediária).
2. Calcular a **média** desse número (usa o resultado de 1).
3. Filtrar os clientes cujo `qtd_pedidos` supera essa média (usa o resultado de 1 **de novo**).

O passo 1 é usado **duas vezes**. Com subquery, teríamos que **repetir** o `GROUP BY` inteiro. Com CTE, calculamos uma vez e referenciamos duas.

```sql
WITH pedidos_por_cliente AS (
    SELECT 
        cliente_id,
        COUNT(*) AS qtd_pedidos
    FROM `unipds-503513.entregaja.pedidos`
    GROUP BY cliente_id
)
SELECT 
    ppc.cliente_id,
    c.nome,
    ppc.qtd_pedidos,
    (SELECT ROUND(AVG(qtd_pedidos), 2) FROM pedidos_por_cliente) AS media_geral
FROM pedidos_por_cliente AS ppc
JOIN `unipds-503513.entregaja.clientes` AS c
    ON c.cliente_id = ppc.cliente_id
WHERE ppc.qtd_pedidos > (
    SELECT AVG(qtd_pedidos) FROM pedidos_por_cliente
)
ORDER BY ppc.qtd_pedidos DESC
LIMIT 15;
```

**Explicação:**

- A CTE `pedidos_por_cliente` é declarada **uma única vez**.
- Depois, ela é referenciada **três vezes**: no `FROM`, no `SELECT` (para trazer a média junto) e no `WHERE` (para filtrar acima da média).
- Se tivéssemos feito isso com subquery, o mesmo `SELECT cliente_id, COUNT(*) ... GROUP BY cliente_id` apareceria **três vezes** no código — difícil de manter, propenso a erros (se muda uma, esquece de mudar as outras).

**Nota:** o BigQuery é livre para **materializar** a CTE (calcular uma vez e reaproveitar) ou **reexecutar** a cada referência — na prática, para consultas simples, isso raramente é um gargalo. A vantagem principal aqui é **de legibilidade e manutenção**, não de performance.

---

# 📕 Parte 3 — Quando usar cada uma

As duas formas produzem os mesmos resultados na maioria dos casos. A escolha é sobre **clareza**:

| Situação | Prefira |
|----------|---------|
| Filtro simples com `IN` / `NOT IN` | Subquery no `WHERE` |
| Comparação com um valor escalar (`> AVG(...)`) | Subquery no `WHERE` |
| Trazer um benchmark único ao lado das linhas | Subquery no `SELECT` |
| Tabela derivada usada **uma única vez** | Subquery no `FROM` ou CTE — tanto faz |
| Tabela derivada usada **duas ou mais vezes** | **CTE** (sem repetir código) |
| Lógica com **múltiplos passos** encadeados | **CTE** (uma por passo, nomeada) |
| Query começando a ficar difícil de ler aninhada | **CTE** (achata a hierarquia) |

> 🧭 **Regra prática:** comece com subquery se for algo pontual. Se você se pegar **repetindo** o mesmo bloco, ou **aninhando três níveis** de subqueries, é sinal de que uma CTE deixaria tudo mais claro.

---

## 📝 Resumo geral

| Construção | Retorna | Serve para |
|-----------|---------|------------|
| **`WHERE ... operador (subquery)`** | 1 valor | Comparar contra um número calculado |
| **`WHERE ... IN (subquery)`** | Lista | Filtrar por lista dinâmica |
| **`WHERE ... NOT IN (subquery)`** | Lista | Excluir (anti-join) |
| **`FROM (subquery) AS alias`** | Tabela | Tabela derivada aninhada |
| **`SELECT (subquery) AS coluna`** | 1 valor | Valor auxiliar em cada linha |
| **`WITH nome AS (...) SELECT ...`** | Tabela nomeada | Resultado intermediário reusável e legível |

---

## ⚠️ Cuidados importantes

1. **Sempre entre parênteses.** Toda subquery precisa vir entre `( )`. CTEs também usam parênteses após o `AS`.
2. **Subqueries no `FROM` precisam de alias** (`AS nome`). CTEs já têm nome próprio.
3. **Escalar = 1 linha, 1 coluna.** Subquery usada com `=`, `>`, `<` ou no `SELECT` só pode retornar **um valor**. Se retornar mais, dá erro.
4. **`NOT IN` + `NULL` = armadilha.** Se a subquery interna tem algum valor nulo, o `NOT IN` retorna zero linhas. Filtre nulos na subquery quando necessário.
5. **`WITH` vem antes do `SELECT` principal**, e você pode ter **várias CTEs** separadas por vírgula.
6. **Uma CTE só existe dentro da query onde foi declarada** — não persiste, não é uma tabela real.
7. **Toda subquery/CTE roda antes da query externa.** Mentalmente: resolva o "de dentro" primeiro, veja o que devolve, depois aplique o "de fora".
