# Aula 29: Window Functions — Funções de Agregação

**Objetivo:** usar as **funções de agregação clássicas** (`SUM`, `AVG`, `COUNT`, `MIN`, `MAX`) como **window functions** — ou seja, calculando sobre "um conjunto de linhas relacionadas" **sem colapsar** as linhas individuais. É o que permite fazer **totais acumulados**, **médias móveis** e **comparações de cada linha com o grupo dela**.

> 💡 **Pré-requisito:** você já viu a estrutura `funcao() OVER (PARTITION BY ... ORDER BY ...)` na aula 26. Nesta aula o esqueleto continua igual — o que muda é **usar as agregações que você já conhece** (`SUM`, `AVG`, `COUNT`, ...) dentro do `OVER`, e entender o efeito do `ORDER BY` sobre elas.

---

## 🎯 Modelo mental

Uma agregação comum (`SUM`, `AVG`, ...) responde a: **"qual é o total/média deste grupo?"** — e devolve **uma linha por grupo**.

A mesma agregação com `OVER` responde a: **"qual é o total/média do grupo desta linha, ao lado dela?"** — devolve **todas as linhas**, cada uma com o valor do seu grupo ao lado.

E se você adicionar `ORDER BY` dentro do `OVER`, ela passa a responder: **"qual é o total/média acumulado(a) até esta linha, dentro do grupo?"** — a famosa **soma acumulada** (running total).

| Estrutura | Pergunta que responde | Efeito |
|-----------|-----------------------|--------|
| `SUM(x) OVER ()` | "total geral" ao lado de cada linha | mesmo valor em todas |
| `SUM(x) OVER (PARTITION BY g)` | "total do grupo `g`" ao lado de cada linha | mesmo valor dentro do grupo |
| `SUM(x) OVER (ORDER BY t)` | "total acumulado até esta linha" (global) | valor cresce linha a linha |
| `SUM(x) OVER (PARTITION BY g ORDER BY t)` | "total acumulado até esta linha, dentro do grupo" | reinicia a cada grupo, cresce dentro dele |

> 🧭 **Regra de bolso:** `ORDER BY` **dentro** do `OVER` transforma a agregação de "total do grupo" em **"acumulado até esta linha"**. Sem `ORDER BY`, é o total. Com `ORDER BY`, é o acumulado.

---

# 📘 Exemplo 1 — `SUM() OVER (PARTITION BY ...)`: total do grupo ao lado da linha

**Cenário:** para cada item vendido, mostrar seu subtotal e, ao lado, o **total do pedido inteiro** — para comparar o peso de cada item no valor final do pedido.

```sql
SELECT
    pedido_id,
    pedido_item_id,
    quantidade,
    preco_unitario,
    quantidade * preco_unitario AS subtotal_item,
    SUM(quantidade * preco_unitario) OVER (PARTITION BY pedido_id) AS total_pedido
FROM `unipds-503513.entregaja.pedido_itens`
ORDER BY pedido_id, pedido_item_id
LIMIT 20;
```

**Como ler:**

- `PARTITION BY pedido_id` — divide os itens em **grupos por pedido**.
- `SUM(quantidade * preco_unitario)` — soma o subtotal dentro de cada grupo.
- Resultado: cada item continua na saída (nenhuma linha some), e ao lado aparece o **total do pedido inteiro**. Dois itens do mesmo pedido veem o **mesmo** total.

**Comparação com `GROUP BY`:**
- `GROUP BY pedido_id` + `SUM(quantidade * preco_unitario)` → **1 linha por pedido** (colapsa).
- `SUM(quantidade * preco_unitario) OVER (PARTITION BY pedido_id)` → **1 linha por item**, cada uma com o total do pedido ao lado.

Isso é ótimo quando você quer calcular **percentuais** — `subtotal_item / total_pedido` te dá o peso de cada item no valor total daquele pedido.

---

# 📗 Exemplo 2 — `SUM() OVER (ORDER BY ...)`: running total (soma acumulada)

**Cenário:** listar as avaliações em ordem cronológica e mostrar, ao lado de cada uma, o **total de pontos de nota acumulados pela plataforma até aquele momento** — quantos "pontos de estrela" a base de clientes já tinha atribuído no total.

```sql
SELECT
    avaliacao_id,
    data_avaliacao,
    nota,
    SUM(nota) OVER (ORDER BY data_avaliacao) AS notas_acumuladas
FROM `unipds-503513.entregaja.avaliacoes`
ORDER BY data_avaliacao
LIMIT 15;
```

**Como ler:**

- `SUM(nota) OVER (ORDER BY data_avaliacao)` — a soma inclui **todas as linhas da janela até a linha atual**, na ordem definida.
- Resultado: a coluna `notas_acumuladas` **cresce a cada linha** — na primeira linha vale a nota daquela avaliação, na segunda vale a soma das duas, e assim por diante.

**O detalhe crucial — a diferença entre com e sem `ORDER BY`:**

| Estrutura | O que soma |
|-----------|------------|
| `SUM(x) OVER ()` | **Todas** as linhas — mesmo valor em todas |
| `SUM(x) OVER (ORDER BY t)` | Apenas as linhas **até a atual**, na ordem `t` — valor cresce |

Adicionar `ORDER BY` **muda o comportamento da agregação**: ela deixa de olhar "todas as linhas do grupo" e passa a olhar "as linhas até esta, em ordem". Esse é o padrão do **running total**.

---


# 📕 Exemplo 3 — `COUNT() OVER (PARTITION BY ... ORDER BY ...)`: contagem acumulada

**Cenário:** para cada entregador, mostrar **quantos entregadores a cidade já tinha contratado até a data dele** — uma contagem acumulada por data dentro de cada cidade — usando `COUNT` como window function.

```sql
SELECT
    cidade,
    entregador_id,
    nome,
    data_inicio,
    COUNT(*) OVER (
        PARTITION BY cidade
        ORDER BY data_inicio
    ) AS contratados_ate_a_data,
    COUNT(*) OVER (PARTITION BY cidade) AS total_entregadores_cidade
FROM `unipds-503513.entregaja.entregadores`
ORDER BY cidade, data_inicio
LIMIT 20;
```

**Como ler:**

- `COUNT(*) OVER (PARTITION BY cidade ORDER BY data_inicio)` → conta as linhas **até a data atual** dentro do grupo. Se dois entregadores foram contratados no mesmo dia, os dois recebem o mesmo valor — "até essa data, a cidade tinha N contratados no total".
- `COUNT(*) OVER (PARTITION BY cidade)` → conta **todas as linhas** do grupo (sem `ORDER BY`). Resultado: o total de entregadores daquela cidade, igual em todas as linhas dela.

**Sacada:** as duas colunas juntas te dizem "quando este entregador entrou, a cidade já tinha 3 contratados de um total atual de 12". Ótimo pra ver a evolução da frota local ao longo do tempo.

> 🧭 **`COUNT(*) OVER (PARTITION BY x ORDER BY y)` parece um `ROW_NUMBER`, mas não é.** O `COUNT` usa o frame padrão `RANGE UNBOUNDED PRECEDING AND CURRENT ROW`, que trata linhas empatadas em `y` como "a mesma posição" — todas recebem o mesmo valor. Se você precisa de numeração sequencial única (1, 2, 3, 4...), use `ROW_NUMBER() OVER (PARTITION BY x ORDER BY y)` em vez disso.

---

# 📓 Exemplo 4 — `AVG() OVER (PARTITION BY ...)`: comparar cada linha com a média do grupo

**Cenário:** para cada cliente, mostrar sua idade e ao lado a **idade média do plano dele** — para saber se ele está acima ou abaixo da média daquele segmento de clientes.

```sql
SELECT
    nome,
    plano,
    idade,
    ROUND(AVG(idade) OVER (PARTITION BY plano), 2) AS idade_media_plano,
    ROUND(idade - AVG(idade) OVER (PARTITION BY plano), 2) AS diferenca_para_media
FROM `unipds-503513.entregaja.clientes`
ORDER BY plano, idade DESC
LIMIT 25;
```

**Como ler:**

1. `AVG(idade) OVER (PARTITION BY plano)` calcula a **idade média dentro do plano** — sem colapsar: cada cliente continua na saída.
2. `idade - AVG(...) OVER (...)` dá a **diferença** de cada cliente para a média do plano dele. Positivo = mais velho que a média do segmento; negativo = mais jovem.
3. Diferente dos exemplos anteriores, aqui **não precisamos de CTE**: a coluna `idade` já vem pronta na tabela `clientes`, então dá pra calcular o agregado direto na query final.

**Padrão útil:** "linha vs. grupo". Sempre que você quiser saber "quanto esta linha desvia do grupo dela", este é o esqueleto — calcule o agregado do grupo com `OVER` e subtraia da linha.

---

# 📔 Exemplo 5 — `AVG() OVER (... ROWS BETWEEN ...)`: média móvel

**Cenário:** para cada dia, mostrar a **nota média das avaliações do dia** e a **média móvel dos últimos 7 dias** — o clássico "média dos últimos 7 dias" que suaviza flutuações diárias e mostra a tendência de satisfação.

```sql
WITH avaliacoes_por_dia AS (
    SELECT
        DATE(data_avaliacao) AS dia,
        ROUND(AVG(nota), 2) AS nota_media_dia
    FROM `unipds-503513.entregaja.avaliacoes`
    GROUP BY dia
)
SELECT
    dia,
    nota_media_dia,
    ROUND(
        AVG(nota_media_dia) OVER (
            ORDER BY dia
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS media_movel_7d
FROM avaliacoes_por_dia
ORDER BY dia
LIMIT 30;
```

**Como ler:**

- A CTE agrega as avaliações **por dia** (uma linha por dia, com a nota média daquele dia).
- Na query externa, `AVG(nota_media_dia) OVER (ORDER BY dia ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` calcula a média das **últimas 7 linhas** (a atual + as 6 anteriores).
- Resultado: uma coluna de média móvel que suaviza os picos diários e evidencia a tendência da satisfação ao longo do tempo.

**A parte nova — `ROWS BETWEEN ... AND ...`:** é o **frame** da janela. Ele diz **exatamente quais linhas** entram no cálculo dentro da janela ordenada. Alguns frames comuns:

| Frame | Significado |
|-------|-------------|
| `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` | 7 linhas — as 6 anteriores + a atual (janela móvel) |
| `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | Desde o início até a atual — é o **default quando há `ORDER BY`** (o running total do Exemplo 2 usa este implicitamente) |
| `ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING` | Da atual até o fim (raramente usado) |
| `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` | Todas as linhas — anula o efeito do `ORDER BY` |

> 🧭 **Regra sutil:** com `ORDER BY` e **sem** `ROWS BETWEEN`, o SQL assume `UNBOUNDED PRECEDING AND CURRENT ROW` (do início até agora — o running total). Se você quer uma **janela móvel** de N linhas, precisa escrever o `ROWS BETWEEN` explicitamente.

---

# 📒 Exemplo 6 — `MAX()` e `MIN()` OVER: comparar cada linha com o extremo do grupo

**Cenário:** para cada item de cardápio, mostrar seu preço e ao lado o **maior preço** e o **menor preço** dentro da mesma categoria de item — para identificar itens fora do padrão de preço na categoria (muito caros ou muito baratos).

```sql
SELECT
    categoria_item,
    item_id,
    nome_item,
    preco,
    MAX(preco) OVER (PARTITION BY categoria_item) AS maior_preco_categoria,
    MIN(preco) OVER (PARTITION BY categoria_item) AS menor_preco_categoria
FROM `unipds-503513.entregaja.itens`
ORDER BY categoria_item, preco DESC
LIMIT 25;
```

**Como ler:**

- `MAX(preco) OVER (PARTITION BY categoria_item)` — o maior preço **dentro da categoria**.
- `MIN(...) OVER (...)` — o menor preço, mesma lógica.
- Cada linha ganha os dois extremos da categoria ao lado, e continua listada individualmente.

**Uso típico:** filtrar depois "onde `preco = maior_preco_categoria`" pra encontrar o **item mais caro de cada categoria**. Padrão parecido com o `ROW_NUMBER + WHERE ordem = 1` da aula 27, mas usando `MAX` como comparação direta.

---

## 📝 Resumo geral

| Função como window | Sem `ORDER BY` (dentro do OVER) | Com `ORDER BY` (dentro do OVER) |
|--------------------|-----------------------------|-----------------------------|
| `SUM(x)` | Total do grupo ao lado de cada linha | Soma acumulada até a linha atual |
| `AVG(x)` | Média do grupo ao lado de cada linha | Média acumulada (ou móvel, com `ROWS BETWEEN`) |
| `COUNT(*)` | Total de linhas do grupo | Contagem acumulada até a linha atual |
| `MIN(x)` / `MAX(x)` | Extremo do grupo ao lado de cada linha | Mínimo/máximo até a linha atual |

**Estrutura padrão:**

```sql
funcao_agregacao(coluna) OVER (
    [PARTITION BY grupo]                              -- opcional
    [ORDER BY ordem]                                  -- opcional; muda o significado
    [ROWS BETWEEN N PRECEDING AND CURRENT ROW]        -- opcional; define o frame
)
```

---

## ⚠️ Cuidados importantes

1. **`ORDER BY` dentro do `OVER` muda o significado da agregação.** Sem ele, é "total/média do grupo inteiro". Com ele, é "acumulado até esta linha". Não é apenas uma questão de ordenação — é uma mudança de **cálculo**.

2. **`ROWS BETWEEN` só faz sentido com `ORDER BY`.** Frames operam sobre linhas em ordem — sem `ORDER BY`, não há "linhas anteriores" definidas.

3. **Frame default: `UNBOUNDED PRECEDING AND CURRENT ROW`.** Quando você escreve `SUM(x) OVER (ORDER BY t)` sem `ROWS BETWEEN`, o SQL soma **do começo até agora** — daí o running total. Para média móvel, você precisa **explicitar** o frame.

4. **Window function + `GROUP BY` na mesma query é comum.** Primeiro o `GROUP BY` agrupa (colapsa), depois o `OVER` opera sobre o resultado agregado. Foi o padrão do Exemplo 5 (nota média por restaurante → média das categorias).

5. **Cuidado com performance em janelas grandes.** Um `SUM(x) OVER (ORDER BY t)` sem `PARTITION BY` sobre milhões de linhas força o BigQuery a ordenar tudo numa janela só. Sempre que possível, particione por algo que faça sentido (cliente, região, mês).

6. **Não dá para filtrar por resultado de window function no `WHERE`.** Igual à aula 27: use CTE + filtro na query externa (ex.: "só pedidos onde `taxa_entrega = maior_taxa_cliente`" precisa de CTE).
