# Aula 31: `MATERIALIZED VIEW` — quando a `VIEW` precisa de resultado pré-calculado

**Objetivo:** aprender quando uma `VIEW` comum não basta e como usar `MATERIALIZED VIEW` (MV) — uma view cujo **resultado fica armazenado** e é atualizado automaticamente pelo BigQuery à medida que a tabela base muda. É o próximo passo natural depois da aula 30: a mesma lógica de composição, mas com **cache gerenciado**. Também vamos ver duas restrições importantes que "pegam de surpresa" quem chega das VIEWs comuns.

> 💡 **Pré-requisito:** você viu `VIEW` na [aula 30](../aula30/exemplos.md). Aqui a diferença é que a MV **materializa** (persiste) o resultado, então há regras específicas sobre o que pode aparecer na definição.

---

## 🎯 Modelo mental — `VIEW` vs. `MATERIALIZED VIEW`

Uma `VIEW` comum é **só uma query salva** — cada `SELECT * FROM view` reexecuta a lógica por baixo dos panos. Se a query original custa 500 GB de bytes processados, cada leitura da view custa os mesmos 500 GB.

Uma `MATERIALIZED VIEW` é **query salva + resultado guardado**. O BigQuery:

1. **Executa a query uma vez** e persiste o resultado como uma "tabela invisível" atrás da MV.
2. **Rastreia mudanças** na(s) tabela(s) base — quando novas linhas chegam, ele atualiza a MV **de forma incremental** (só o delta), sem reprocessar tudo.
3. Consultas que baterem na MV pagam apenas pelos bytes **do resultado materializado**, muito menor que a fonte.
4. Bônus: se você fizer um `SELECT` na **tabela original** com um agregado que a MV já responde, o BigQuery pode **reroute** automaticamente sua query para a MV — sem você pedir. É o chamado **smart tuning**.

| Aspecto | `VIEW` | `MATERIALIZED VIEW` |
|---------|--------|---------------------|
| Guarda dados? | ❌ Não — só a definição | ✅ Sim — resultado persistido |
| Custo por leitura | Reexecuta a query completa | Lê o resultado pré-calculado |
| Atualização | "Sempre fresca" (é reexecutada) | Incremental automática pelo BigQuery |
| Restrições na definição | Praticamente nenhuma | **Várias** (ver seções abaixo) |
| Pode referenciar outra view? | ✅ Sim | ❌ **Não** — só tabelas base |
| Quando usar | Encapsular lógica de leitura barata/média | Encapsular agregações caras e frequentes |

> 🧭 **Regra de bolso:** só promova uma `VIEW` para `MATERIALIZED VIEW` se ela **(a)** for consultada com frequência e **(b)** for cara de recalcular. Para lógica leve, a view comum é mais simples e mais flexível.

---

# 📘 Exemplo 1 — MV simples: faturamento por pedido

**Cenário:** o `vw_faturamento_por_pedido` da aula 30 é consultado por vários dashboards ao longo do dia. Cada consulta reexecuta a agregação `SUM(quantidade * preco_unitario) GROUP BY pedido_id` — desperdício, porque o resultado quase não muda entre uma consulta e outra. Vamos materializá-la.

```sql
-- Materialized View: faturamento por pedido
CREATE OR REPLACE MATERIALIZED VIEW `unipds-503513.entregaja.mvw_faturamento_por_pedido` AS
    SELECT
        pedido_id,
        SUM(quantidade * preco_unitario) AS valor_pedido
    FROM `unipds-503513.entregaja.pedido_itens`
    GROUP BY pedido_id;
```

**Como ler:**

- `CREATE OR REPLACE MATERIALIZED VIEW` — a única diferença sintática em relação a uma view comum é a palavra `MATERIALIZED`.
- **Prefixo `mvw_`** — convenção para deixar claro no autocomplete que aquilo é uma materialized view, distinguindo das `vw_` da aula 30.
- **A definição é idêntica** à `vw_faturamento_por_pedido`. Tudo o que muda é o **comportamento por trás**: agora existe uma tabela invisível guardando o resultado, e o BigQuery a mantém atualizada à medida que `pedido_itens` recebe novas linhas.
- **Custo da primeira execução**: o BigQuery roda a query inteira uma vez para popular a MV. Custo das próximas: só o incremental.

---

# 📕 Exemplo 2 — A tentativa que falha: MV composta em cima de uma VIEW

Seguindo a mesma lógica da aula 30, o instinto é criar `mvw_faturamento_por_restaurante` composta em cima da view do exemplo anterior:

```sql
-- ⚠️ NÃO FUNCIONA — MV não pode depender de uma VIEW
CREATE OR REPLACE MATERIALIZED VIEW `unipds-503513.entregaja.mvw_faturamento_por_restaurante` AS
    SELECT
        p.restaurante_id,
        SUM(fp.valor_pedido) AS faturamento_total,
        COUNT(*) AS qtd_pedidos
    FROM `unipds-503513.entregaja.vw_faturamento_por_pedido` AS fp     -- 👈 referência a uma VIEW
    INNER JOIN `unipds-503513.entregaja.pedidos` AS p
        ON fp.pedido_id = p.pedido_id
    WHERE p.status = 'Concluído'
    GROUP BY p.restaurante_id;
```

O BigQuery devolve algo como:

> `Materialized view cannot reference view unipds-503513.entregaja.vw_faturamento_por_pedido. Materialized views can only reference tables.`

## Por que essa restrição existe

Para manter a MV atualizada de forma **incremental**, o BigQuery precisa saber exatamente **quais linhas** da fonte mudaram — e propagar só o delta. Views comuns são queries dinâmicas: seu conteúdo depende do estado atual das tabelas subjacentes no momento da leitura. Rastrear "o que mudou dentro da view" seria caríssimo. Então a regra é dura: **MV só pode referenciar tabelas base** (ou outras MVs, com limites).

## Solução: **inline** da lógica da view

Como não podemos compor MV em cima de view, temos que **repetir a lógica** da view diretamente na definição da MV — juntando `pedido_itens` e `pedidos` num único bloco:

```sql
-- Versão "inline" — dá adeus ao reuso da view, mas a MV agora se sustenta em tabelas base
CREATE OR REPLACE MATERIALIZED VIEW `unipds-503513.entregaja.mvw_faturamento_por_restaurante` AS
SELECT
    p.restaurante_id,
    SUM(it.quantidade * it.preco_unitario) AS faturamento_total,
    COUNT(DISTINCT p.pedido_id) AS qtd_pedidos                     -- 👈 agora precisamos de DISTINCT
FROM `unipds-503513.entregaja.pedido_itens` AS it
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON it.pedido_id = p.pedido_id
WHERE p.status = 'Concluído'
GROUP BY p.restaurante_id;
```

**Detalhe importante que mudou:** na versão original com a view, `COUNT(*)` funcionava porque a view já entregava **1 linha por pedido**. Ao fazer inline, agora estamos joinando com `pedido_itens` — que tem **1 linha por item** — então `COUNT(*)` passaria a contar itens, não pedidos. Por isso precisamos de `COUNT(DISTINCT p.pedido_id)`.

**Só que agora batemos numa segunda restrição** ⤵

---

# 📗 Exemplo 3 — A segunda restrição: `COUNT(DISTINCT)` não é incremental

Ao rodar a versão inline acima, o BigQuery reclama:

> `COUNT DISTINCT is not supported in materialized view definitions.`

## Por que `COUNT(DISTINCT)` não funciona

Para manter um `COUNT(DISTINCT x)` incrementalmente correto quando chega uma linha nova, o BigQuery precisaria saber se aquele valor de `x` **já existia** no conjunto atual — ou seja, teria que manter o **conjunto inteiro de valores distintos** em memória. É caro e não escala. Por isso o BigQuery restringe as agregações permitidas em MVs a **funções "incrementáveis"**: `SUM`, `COUNT(*)`, `MIN`, `MAX`, `AVG` — e algumas variantes aproximadas.

## Opção 1 — trocar por `APPROX_COUNT_DISTINCT` (aproximação incremental)

```sql
-- Opção 1: aproximar a contagem distinta usando APPROX_COUNT_DISTINCT
CREATE OR REPLACE MATERIALIZED VIEW `unipds-503513.entregaja.mvw_faturamento_por_restaurante` AS
SELECT
    p.restaurante_id,
    SUM(it.quantidade * it.preco_unitario) AS faturamento_total,
    -- Substituição para respeitar a regra incremental do BigQuery
    APPROX_COUNT_DISTINCT(p.pedido_id) AS qtd_pedidos
FROM `unipds-503513.entregaja.pedido_itens` AS it
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON it.pedido_id = p.pedido_id
WHERE p.status = 'Concluído'
GROUP BY p.restaurante_id;
```

**Como funciona:**

- `APPROX_COUNT_DISTINCT` usa o algoritmo **HyperLogLog++** — mantém um "esboço" (sketch) compacto do conjunto de valores em vez do conjunto inteiro. Isso é **incrementável** (dá para fundir dois sketches sem revisitar os dados originais), então o BigQuery aceita.
- **Erro típico:** ~1% para conjuntos grandes. Para métricas de negócio como "quantidade aproximada de pedidos concluídos por restaurante", isso é **totalmente aceitável**.
- **Quando NÃO usar:** quando o número precisa ser exato — por exemplo, cobrança, conciliação financeira, reportes regulatórios. Aí Opção 2.

## Opção 2 — desligar o modo incremental (`allow_non_incremental_definition`)

Se precisa de `COUNT(DISTINCT)` **exato** (ou de qualquer outra agregação não-incremental), dá para pedir ao BigQuery: "esquece o incremental, atualize o bloco todo de vez em quando".

```sql
-- Opção 2: desativar o modo incremental
CREATE OR REPLACE MATERIALIZED VIEW `unipds-503513.entregaja.mvw_faturamento_por_restaurante2`
OPTIONS (
  allow_non_incremental_definition = true, -- permite o uso de COUNT(DISTINCT)
  max_staleness = INTERVAL 1 HOUR          -- resultado pode ter até 1 hora de "atraso"
) AS
SELECT
    p.restaurante_id,
    SUM(it.quantidade * it.preco_unitario) AS faturamento_total,
    COUNT(DISTINCT p.pedido_id) AS qtd_pedidos
FROM `unipds-503513.entregaja.pedido_itens` AS it
INNER JOIN `unipds-503513.entregaja.pedidos` AS p
    ON it.pedido_id = p.pedido_id
WHERE p.status = 'Concluído'
GROUP BY p.restaurante_id;
```

**Como ler cada opção:**

- **`allow_non_incremental_definition = true`** — libera a definição para usar agregações não-incrementáveis (`COUNT(DISTINCT)`, `ARRAY_AGG`, subqueries, `LEFT JOIN` mais complexos, etc.). Em troca, você abre mão da atualização incremental.
- **`max_staleness = INTERVAL 1 HOUR`** — o BigQuery se compromete a manter o resultado da MV **com no máximo 1 hora de defasagem** em relação à tabela base. Ao consultar a MV, se o resultado estiver "fresco o suficiente" (dentro da janela), lê direto do cache; se estiver "velho demais", executa um **refresh completo** antes de servir. Você paga pelo refresh, mas amortiza entre todas as leituras que caem na mesma janela.
- **Quando usar:** dashboards que rodam de hora em hora e não precisam de dado "ao vivo" — é o cenário clássico. Se você precisa de tempo real, opção 2 não é o caminho.

> 🧭 **Regra prática para escolher entre Opção 1 e Opção 2:**
> - Cardinalidade alta + tolerância a ~1% de erro → **Opção 1 (`APPROX_COUNT_DISTINCT`)**. Mais barato, mais rápido.
> - Precisão exata obrigatória → **Opção 2 (`allow_non_incremental_definition`)**. Aceita o custo do refresh periódico em troca do resultado exato.

---

## 📝 Resumo geral — regras da `MATERIALIZED VIEW` no BigQuery

**O que uma MV incremental "clássica" aceita:**

| ✅ Permitido | ❌ Proibido |
|-------------|-------------|
| Referenciar **tabelas base** | Referenciar `VIEW` comum |
| `SUM`, `COUNT(*)`, `MIN`, `MAX`, `AVG` | `COUNT(DISTINCT)` |
| `GROUP BY` | `ORDER BY`, `LIMIT` |
| `INNER JOIN` (com limitações) | Subqueries correlacionadas |
| `WHERE` simples | Window functions (`OVER`) |
| `APPROX_COUNT_DISTINCT` | Funções não-determinísticas (`CURRENT_TIMESTAMP()`, `RAND()`) |

**Cheatsheet de decisão:**

```
Preciso pré-calcular esse agregado?
├── Não é caro nem frequente ......... use VIEW comum (aula 30)
└── É caro e/ou frequente ............ MATERIALIZED VIEW
    │
    ├── Definição usa outra VIEW? ..... faça inline da view na MV
    │
    └── Usa COUNT(DISTINCT)?
        ├── Aceita ~1% de erro? ....... APPROX_COUNT_DISTINCT (incremental)
        └── Precisa ser exato? ........ allow_non_incremental_definition + max_staleness
```

---

## ⚠️ Cuidados importantes

1. **MV **não** pode referenciar VIEW comum.** A restrição existe para permitir atualização incremental. Solução: repita a lógica da view diretamente na MV (inline), mesmo que isso duplique código. Se a lógica está em três MVs diferentes, avalie promover a view intermediária para uma **tabela materializada** com `CREATE TABLE AS SELECT` + job agendado.

2. **MV **não** aceita `COUNT(DISTINCT)` no modo incremental.** Use `APPROX_COUNT_DISTINCT` para métricas aproximadas ou `allow_non_incremental_definition = true` quando a precisão for obrigatória.

3. **MV **não** aceita window functions, `ORDER BY`, `LIMIT` nem subqueries correlacionadas.** Se a lógica exigir alguma dessas, ou você move para MV não-incremental, ou mantém como view comum, ou materializa manualmente com `CREATE TABLE AS SELECT`.

4. **`max_staleness` custa dinheiro em cada refresh completo.** Escolher `INTERVAL 5 MINUTE` numa tabela de 500 GB significa refresh completo a cada 5 minutos — cara. Comece com `1 HOUR` ou `1 DAY` e ajuste conforme a necessidade real do dashboard.

5. **Smart tuning: o BigQuery pode redirecionar suas queries para a MV automaticamente.** Se você tem `mvw_faturamento_por_restaurante` e alguém roda uma query direto na tabela `pedidos` que casa com a agregação, o otimizador **pode** ler da MV em vez da tabela base — sem a pessoa saber. Isso é ótimo (economia grátis), mas significa que **remover uma MV pode piorar o custo de queries que nem a referenciam explicitamente**. Antes de remover uma MV antiga, verifique no INFORMATION_SCHEMA se ela está sendo usada.

6. **Primeira execução da MV custa a query inteira.** Se você materializar uma agregação sobre uma tabela de 5 TB, a criação da MV vai processar os 5 TB. As leituras seguintes é que ficam baratas. Planeje esse custo inicial.

7. **MV consome storage.** Diferente de VIEW, ela **guarda dados** — você paga por armazenamento no dataset. É desprezível para agregados (poucas linhas resultantes), mas relevante se você materializar uma tabela quase completa.
