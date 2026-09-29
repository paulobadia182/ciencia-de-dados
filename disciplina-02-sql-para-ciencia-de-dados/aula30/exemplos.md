# Aula 30: Composição analítica com CTEs encadeadas

**Objetivo:** aprender a **decompor uma pergunta analítica complexa em CTEs pequenas e independentes**, cada uma respondendo a uma sub-pergunta, e depois **juntá-las** na query final. É o padrão de trabalho que aparece em quase todo relatório real: nenhum agregado sai direto da tabela — passa por camadas.

> 💡 **Pré-requisito:** você já viu CTEs (`WITH`) na aula 23 e agregações com `GROUP BY` na aula 21. Aqui não há sintaxe nova — o que muda é a **estratégia**: em vez de uma CTE grande fazendo tudo, várias CTEs pequenas encadeadas.

---

## 🎯 Modelo mental

Toda pergunta analítica complexa pode ser lida como uma **cadeia de agregações em níveis diferentes**. Por exemplo:

> "Quais os 5 restaurantes com maior faturamento em pedidos concluídos, e qual a nota média que eles receberam?"

Se você tentar responder em uma query só, precisa de vários `JOIN`s aninhados e um `GROUP BY` fazendo malabarismo com colunas de tabelas diferentes. O código fica difícil de ler e mais difícil ainda de depurar.

Com CTEs encadeadas, você quebra a pergunta em três sub-perguntas independentes:

1. **Qual o valor de cada pedido?** (agregação no nível do pedido, a partir dos itens)
2. **Qual o faturamento total de cada restaurante?** (agregação no nível do restaurante, a partir dos pedidos)
3. **Qual a nota média de cada restaurante?** (agregação independente da anterior, mas no mesmo nível)

E na query final você **junta** as respostas e ordena.

| Camada | Nível de granularidade | Fonte |
|--------|------------------------|-------|
| CTE 1: `faturamento_por_pedido` | 1 linha por pedido | `pedido_itens` |
| CTE 2: `faturamento_por_restaurante` | 1 linha por restaurante | CTE 1 + `pedidos` |
| CTE 3: `nota_por_restaurante` | 1 linha por restaurante | `avaliacoes` + `pedidos` |
| Query final | 1 linha por restaurante (top 5) | CTE 2 + CTE 3 + `restaurantes` |

> 🧭 **Regra de bolso:** cada CTE deve responder a **uma pergunta clara** e ter um nome que descreva essa pergunta. Se você não consegue nomear a CTE em duas ou três palavras, provavelmente ela está fazendo coisa demais e vale quebrá-la em duas.

---

# 📘 Exemplo — Top 5 restaurantes por faturamento (com nota média)

**Cenário:** o time comercial da EntregaJá quer saber quais são os **5 restaurantes que mais faturaram** em pedidos concluídos, e — para dar contexto — **que nota média** esses restaurantes receberam. Faturamento diz "quem vende", nota média diz "quem vende bem". Juntos, é o começo de uma conversa sobre parcerias premium.

```sql
-- Ranking dos 5 restaurantes com maior faturamento em pedidos concluídos,
-- junto com a nota média que eles receberam.

WITH faturamento_por_pedido AS (
    SELECT
        pedido_id,
        SUM(quantidade * preco_unitario) AS valor_pedido
    FROM `unipds-503513.entregaja.pedido_itens`
    GROUP BY pedido_id
),
faturamento_por_restaurante AS (
    SELECT
        p.restaurante_id,
        SUM(fp.valor_pedido) AS faturamento_total,
        COUNT(*) AS qtd_pedidos
    FROM faturamento_por_pedido AS fp
    INNER JOIN `unipds-503513.entregaja.pedidos` AS p
        ON fp.pedido_id = p.pedido_id
    WHERE p.status = 'Concluído'
    GROUP BY p.restaurante_id
),
nota_por_restaurante AS (
    SELECT
        p.restaurante_id,
        ROUND(AVG(a.nota), 2) AS nota_media
    FROM `unipds-503513.entregaja.avaliacoes` AS a
    INNER JOIN `unipds-503513.entregaja.pedidos` AS p
        ON a.pedido_id = p.pedido_id
    WHERE p.status = 'Concluído'
    GROUP BY p.restaurante_id
)
SELECT
    r.nome,
    r.categoria,
    r.cidade,
    ROUND(fr.faturamento_total, 2) AS faturamento_total,
    fr.qtd_pedidos,
    nr.nota_media
FROM faturamento_por_restaurante AS fr
INNER JOIN nota_por_restaurante AS nr
    ON fr.restaurante_id = nr.restaurante_id
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON fr.restaurante_id = r.restaurante_id
ORDER BY fr.faturamento_total DESC
LIMIT 5;
```

## Como ler, CTE por CTE

### CTE 1 — `faturamento_por_pedido`: subir do item para o pedido

```sql
SELECT
    pedido_id,
    SUM(quantidade * preco_unitario) AS valor_pedido
FROM `unipds-503513.entregaja.pedido_itens`
GROUP BY pedido_id
```

- A tabela `pedido_itens` tem **uma linha por item de pedido** — um pedido com 3 itens vira 3 linhas.
- `SUM(quantidade * preco_unitario)` calcula o **valor total de cada pedido**, somando o subtotal de cada item.
- `GROUP BY pedido_id` colapsa os itens em **uma linha por pedido**.
- **Saída:** `(pedido_id, valor_pedido)` — pronta para ser somada por restaurante na próxima camada.

> 🧭 **Por que não juntar isso direto com `pedidos`?** Porque misturar `GROUP BY pedido_id` com um `JOIN` em `pedidos` (que já é 1 linha por pedido) funciona, mas torna a query final mais difícil de ler. Isolar a agregação em uma CTE deixa cada nível com um propósito claro.

### CTE 2 — `faturamento_por_restaurante`: subir do pedido para o restaurante

```sql
SELECT
    p.restaurante_id,
    SUM(fp.valor_pedido) AS faturamento_total,
    COUNT(*) AS qtd_pedidos
FROM faturamento_por_pedido AS fp
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON fp.pedido_id = p.pedido_id
WHERE p.status = 'Concluído'
GROUP BY p.restaurante_id
```

- Junta o **valor de cada pedido** (CTE 1) com a tabela `pedidos` para descobrir **a qual restaurante** cada pedido pertence.
- `WHERE p.status = 'Concluído'` — descarta pedidos cancelados ou em andamento. Faturamento real só considera o que fechou.
- `SUM(fp.valor_pedido)` — soma o valor de todos os pedidos daquele restaurante.
- `COUNT(*)` — quantos pedidos concluídos ele teve (bônus útil para contexto: um restaurante pode ter faturamento alto por poucos pedidos caros, ou por muitos pedidos baratos).
- **Saída:** `(restaurante_id, faturamento_total, qtd_pedidos)` — 1 linha por restaurante que teve ao menos um pedido concluído.

### CTE 3 — `nota_por_restaurante`: nota média (paralela à CTE 2)

```sql
SELECT
    p.restaurante_id,
    ROUND(AVG(a.nota), 2) AS nota_media
FROM `unipds-503513.entregaja.avaliacoes` AS a
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON a.pedido_id = p.pedido_id
WHERE p.status = 'Concluído'
GROUP BY p.restaurante_id
```

- Junta `avaliacoes` com `pedidos` para saber **qual restaurante** foi avaliado em cada nota.
- `WHERE p.status = 'Concluído'` — coerente com a CTE 2: só consideramos avaliações de pedidos concluídos.
- `AVG(a.nota)` — média das notas do restaurante; `ROUND(..., 2)` arredonda para duas casas.
- **Saída:** `(restaurante_id, nota_media)` — 1 linha por restaurante que recebeu ao menos uma avaliação.

> 🧭 **Esta CTE é independente da CTE 2** — nenhuma depende do resultado da outra. Elas só compartilham a mesma **granularidade** (restaurante), o que permite juntá-las depois. Dá para trocar a ordem no `WITH` sem afetar o resultado.

### Query final — juntar as respostas e rankear

```sql
SELECT
    r.nome,
    r.categoria,
    r.cidade,
    ROUND(fr.faturamento_total, 2) AS faturamento_total,
    fr.qtd_pedidos,
    nr.nota_media
FROM faturamento_por_restaurante AS fr
INNER JOIN nota_por_restaurante AS nr
    ON fr.restaurante_id = nr.restaurante_id
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON fr.restaurante_id = r.restaurante_id
ORDER BY fr.faturamento_total DESC
LIMIT 5;
```

- `INNER JOIN nr` — traz a nota média ao lado do faturamento. Usar `INNER` aqui significa que **restaurantes sem nenhuma avaliação são descartados**. Se quisesse manter esses (mostrando `NULL` na nota), trocaria por `LEFT JOIN`.
- `INNER JOIN restaurantes` — traz `nome`, `categoria` e `cidade` — as CTEs 2 e 3 só carregavam o `restaurante_id`.
- `ORDER BY fr.faturamento_total DESC` + `LIMIT 5` — o clássico "top 5".

**Saída esperada:** 5 linhas, uma por restaurante, ordenadas do maior para o menor faturamento, com o contexto de quantos pedidos geraram esse faturamento e como o cliente avaliou a experiência.

---

## 🧭 Por que essa decomposição funciona

**1. Cada CTE tem uma granularidade clara.** CTE 1 é "por pedido". CTEs 2 e 3 são "por restaurante". A query final é "por restaurante (top 5)". Você nunca fica em dúvida sobre "o que uma linha representa aqui".

**2. Você pode testar cada CTE isoladamente.** Enquanto está construindo, substitua a query final por `SELECT * FROM faturamento_por_pedido LIMIT 20;` e valide se o valor por pedido está batendo. Depois faça o mesmo com a CTE 2. Isso encurta MUITO o ciclo de depuração.

**3. Faturamento e nota são cálculos independentes.** Se amanhã o time pedir "e agora coloca também o tempo médio de entrega", basta adicionar uma quarta CTE `tempo_por_restaurante` e mais um `JOIN` na query final — sem tocar nas outras.

**4. `WHERE status = 'Concluído'` aparece nos dois lugares em que faz sentido.** Não é redundância: cada CTE filtra os pedidos que **ela** usa. Se você filtrasse só no final, a CTE 1 calcularia valor até de pedidos cancelados (desperdício), e a média poderia incluir avaliações de pedidos que depois foram descartados.

---

# 📗 Exemplo 2 — Persistindo as CTEs como `VIEW`s reutilizáveis

**Cenário:** o Exemplo 1 responde à pergunta do time comercial, mas amanhã o time de marketing vai pedir outro relatório que também precisa de "faturamento por pedido" e "nota média por restaurante". Se cada analista reescrever essas CTEs do zero na sua query, a lógica **duplica** — e quando alguém decidir mudar o filtro (por exemplo, considerar também `'Entregue'` como concluído), vai ter que caçar cada cópia. A solução é **transformar as CTEs em `VIEW`s**: blocos nomeados, persistidos no dataset, que qualquer query pode consultar como se fossem tabelas.

> 💡 **O que é uma `VIEW`:** uma consulta SQL **salva com nome**. Ela não guarda dados — guarda a **definição da query**. Toda vez que você faz `SELECT * FROM view_x`, o BigQuery executa a query da view por baixo dos panos e devolve o resultado atualizado.

## Modelo mental — CTE vs. VIEW

| Aspecto | CTE (`WITH ... AS`) | `VIEW` |
|---------|---------------------|--------|
| Escopo | Vive **só na query** onde foi declarada | Vive no **dataset**, disponível para qualquer query |
| Reuso | Precisa ser reescrita em cada query | Consulta com `SELECT * FROM ...` |
| Persistência | Nenhuma — some no fim da execução | Definição fica salva; some se você `DROP` |
| Armazenamento | Não ocupa espaço | Não ocupa espaço (a query é reexecutada) |
| Quando usar | Lógica **específica de uma análise** | Lógica **reutilizável** por várias análises |

> 🧭 **Regra de bolso:** se a mesma CTE está aparecendo em três queries diferentes, promova-a a `VIEW`. Se aparece em uma só, deixa como CTE mesmo — não polua o dataset.

## Criando as três VIEWs

```sql
-- View 1: faturamento por pedido
CREATE OR REPLACE VIEW `unipds-503513.entregaja.vw_faturamento_por_pedido` AS
    SELECT
        pedido_id,
        SUM(quantidade * preco_unitario) AS valor_pedido
    FROM `unipds-503513.entregaja.pedido_itens`
    GROUP BY pedido_id;


-- View 2: faturamento por restaurante (usa a view 1)
CREATE OR REPLACE VIEW `unipds-503513.entregaja.vw_faturamento_por_restaurante` AS
    SELECT
        p.restaurante_id,
        SUM(fp.valor_pedido) AS faturamento_total,
        COUNT(*) AS qtd_pedidos
    FROM `unipds-503513.entregaja.vw_faturamento_por_pedido` AS fp
    INNER JOIN `unipds-503513.entregaja.pedidos` AS p
        ON fp.pedido_id = p.pedido_id
    WHERE p.status = 'Concluído'
    GROUP BY p.restaurante_id;


-- View 3: nota média por restaurante
CREATE OR REPLACE VIEW `unipds-503513.entregaja.vw_nota_por_restaurante` AS
    SELECT
        p.restaurante_id,
        ROUND(AVG(a.nota), 2) AS nota_media
    FROM `unipds-503513.entregaja.avaliacoes` AS a
    INNER JOIN `unipds-503513.entregaja.pedidos` AS p
        ON a.pedido_id = p.pedido_id
    WHERE p.status = 'Concluído'
    GROUP BY p.restaurante_id;
```

**Como ler:**

- `CREATE OR REPLACE VIEW` — cria a view; se já existir com esse nome, **substitui** a definição. Ideal para iterar (mudou a lógica, roda de novo e a view fica atualizada).
- **Nomenclatura `vw_...`** — prefixo comum para deixar claro no autocomplete do BigQuery que aquilo é uma view, não uma tabela. Ajuda a evitar confusão em datasets grandes.
- **`vw_faturamento_por_restaurante` referencia `vw_faturamento_por_pedido`** — views podem se compor umas nas outras, exatamente como as CTEs faziam. O BigQuery resolve a cadeia de views na hora do `SELECT` final.
- **Cada view tem uma responsabilidade única** — a mesma disciplina de granularidade das CTEs (1 linha por pedido / 1 linha por restaurante) se mantém.

## Query final com as VIEWs

Depois das views criadas, a query do Exemplo 1 fica **drasticamente mais curta** — o bloco `WITH` desaparece por completo:

```sql
SELECT
    r.nome,
    r.categoria,
    r.cidade,
    ROUND(fr.faturamento_total, 2) AS faturamento_total,
    fr.qtd_pedidos,
    nr.nota_media
FROM `unipds-503513.entregaja.vw_faturamento_por_restaurante` AS fr
INNER JOIN `unipds-503513.entregaja.vw_nota_por_restaurante` AS nr
    ON fr.restaurante_id = nr.restaurante_id
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON fr.restaurante_id = r.restaurante_id
ORDER BY fr.faturamento_total DESC
LIMIT 5;
```

O resultado é **idêntico** ao do Exemplo 1 — a única diferença é onde a lógica mora. Antes vivia dentro da query; agora vive no dataset, e a query final virou uma composição de blocos.

## Quando o ganho aparece de verdade

Imagine que amanhã o time de marketing pede: **"quais restaurantes tiveram faturamento acima de 10 mil e nota média abaixo de 4?"** — para ligar para eles e entender o que está errado.

Sem as views, a analista de marketing teria que copiar as três CTEs do Exemplo 1 e adicionar um `WHERE` no final. Com as views:

```sql
SELECT r.nome, fr.faturamento_total, nr.nota_media
FROM `unipds-503513.entregaja.vw_faturamento_por_restaurante` AS fr
INNER JOIN `unipds-503513.entregaja.vw_nota_por_restaurante` AS nr USING (restaurante_id)
INNER JOIN `unipds-503513.entregaja.restaurantes` AS r USING (restaurante_id)
WHERE fr.faturamento_total > 10000 AND nr.nota_media < 4;
```

Cinco linhas de SQL. Toda a lógica de agregação e filtro por `status = 'Concluído'` fica **encapsulada** — a analista nem precisa saber que existe uma tabela `pedido_itens`.

## Cuidados específicos de VIEWs

1. **View não guarda dados — reexecuta a query.** Se a query da view custa 500 GB de bytes processados, cada `SELECT * FROM view` custa os mesmos 500 GB. Para lógica pesada e estável, considere **`MATERIALIZED VIEW`** (view com resultado armazenado e atualizado incrementalmente) ou uma **tabela intermediária** com `CREATE TABLE AS SELECT`.

2. **Mudar uma tabela subjacente pode quebrar a view.** Se você renomear ou remover a coluna `preco_unitario` de `pedido_itens`, a `vw_faturamento_por_pedido` passa a dar erro. O BigQuery **não** avisa na hora do `DROP` da coluna — só descobre quando alguém consulta a view. Antes de mudar tabela, pesquise as views que dependem dela.

3. **Cascade de views tem custo cognitivo.** `vw_faturamento_por_restaurante` depende de `vw_faturamento_por_pedido`. Para alguém entender o resultado, precisa abrir **as duas** definições. Não crie cascades de 5 níveis "porque parece elegante" — 2 ou 3 níveis é o razoável.

4. **`CREATE OR REPLACE VIEW` não valida contra queries existentes.** Se você mudar a coluna `valor_pedido` para `valor_total_pedido` na view, todas as queries que consultavam `valor_pedido` vão quebrar silenciosamente na próxima execução. Trate view como **contrato público** do dataset: renomear coluna é breaking change, avisa o time.

5. **Views não aceitam parâmetros.** Se você precisa de "faturamento por restaurante **em um período específico**", uma view não resolve — o filtro por data ficaria fixo na definição. Nesse caso use **`TABLE FUNCTION`** (função de tabela parametrizada) ou deixe o filtro na query que consulta a view.

---

## 📝 Resumo geral — receita para decompor uma pergunta em CTEs

1. **Escreva a pergunta em português** e identifique o **nível final** da resposta ("uma linha por restaurante", "uma linha por dia", etc.).
2. **Liste os agregados** que aparecem na pergunta (faturamento, nota média, tempo de entrega, ...). Cada um vira uma CTE — a menos que estejam na mesma granularidade e venham da mesma tabela, aí podem ficar juntos.
3. **Identifique as "subidas de nível"**: se o agregado final é por restaurante mas o dado bruto está no item, você precisa de uma CTE intermediária por pedido.
4. **Nomeie cada CTE pela pergunta que ela responde** (`faturamento_por_pedido`, `nota_por_restaurante`), não pelo passo técnico (`cte1`, `agregacao_final`).
5. **Filtre em cada CTE, não só no final** — reduz o volume que passa para a próxima camada e deixa cada bloco autoexplicativo.
6. **Query final é só `JOIN` + `SELECT` + `ORDER BY` + `LIMIT`**. Se você está fazendo agregação na query final, provavelmente falta uma CTE.

---

## ⚠️ Cuidados importantes

1. **Cuidado com granularidade ao fazer `JOIN` entre CTEs.** Se você junta duas CTEs que estão em níveis diferentes (`por pedido` × `por restaurante`), pode **multiplicar linhas** sem perceber, e agregados posteriores ficam errados. Antes de dar `JOIN`, confirme mentalmente: "as duas estão na mesma granularidade?".

2. **`INNER JOIN` na query final descarta silenciosamente.** Se um restaurante tem faturamento mas nunca foi avaliado, o `INNER JOIN nota_por_restaurante` o remove do resultado. Se você quer **manter** todos os que faturaram (mostrando `NULL` na nota), use `LEFT JOIN`. É uma decisão de produto — decida conscientemente.

3. **CTEs não são "cache" no BigQuery.** Se você referencia a mesma CTE duas vezes na query final, o BigQuery pode reexecutá-la. Não é problema em queries pequenas; em queries pesadas, considere materializar em tabela temporária ou reestruturar.

4. **Ordem das CTEs no `WITH` importa apenas por dependência.** Uma CTE pode referenciar outra que aparece **antes** dela no `WITH`, nunca depois. Se a CTE B usa a CTE A, então A vem primeiro no `WITH`.

5. **Filtre por `status` sempre que o negócio pedir "pedidos válidos".** Um erro comum é esquecer o `WHERE status = 'Concluído'` em alguma CTE — o resultado passa a incluir pedidos cancelados e o faturamento "explode" sem motivo aparente. Quando o número parecer estranho, essa é uma das primeiras coisas a conferir.

6. **`COUNT(*)` na CTE 2 conta linhas da CTE 1 após o `JOIN`.** Como a CTE 1 já é uma linha por pedido, `COUNT(*)` aqui é literalmente "quantidade de pedidos". Se a CTE fonte fosse `pedido_itens` direto (sem agregação prévia), `COUNT(*)` viraria "quantidade de itens" — um bug clássico.
