# Aula 32: Otimização Física — `PARTITION BY` e `CLUSTER BY`

**Objetivo:** aprender a **organizar fisicamente** uma tabela no BigQuery para que as consultas leiam **menos dados** e rodem mais rápido — usando **particionamento** (dividir a tabela em "gavetas" por data) e **clustering** (ordenar cada gaveta pelas colunas mais consultadas). São recursos de **modelagem física**, não mudam o resultado da query — mudam **quanto ele custa e quanto ele demora**.

> 💡 **Pré-requisito:** você já viu `CREATE TABLE AS SELECT` e sabe filtrar por data com `WHERE data_hora_pedido BETWEEN ...`. Aqui vamos usar essa mesma sintaxe, só que anotando **como** o BigQuery deve guardar os dados por baixo dos panos.

---

## 🎯 Modelo mental

Uma tabela sem particionamento é como um **arquivo único gigante** — para achar os pedidos de ontem, o BigQuery precisa **ler tudo** e descartar o que não interessa.

**Particionar** é como **abrir um armário com uma gaveta por dia**: quando você filtra por `data_hora_pedido = '2025-06-14'`, o BigQuery **abre só aquela gaveta** e ignora o resto do histórico. Você paga por muito menos bytes lidos.

**Clusterizar** é como **ordenar os papéis dentro de cada gaveta**: mesmo depois de abrir a gaveta do dia, se você buscar por um `restaurante_id` específico, o BigQuery pula direto para o bloco daquele restaurante em vez de ler a gaveta inteira.

| Recurso | O que faz | Ganho principal |
|---------|-----------|-----------------|
| **`PARTITION BY`** | Divide a tabela em blocos independentes por coluna (data, inteiro, etc.) | Reduz bytes lidos quando o `WHERE` filtra pela coluna de partição |
| **`CLUSTER BY`** | Ordena fisicamente as linhas dentro de cada partição por até 4 colunas | Reduz bytes lidos em filtros e `GROUP BY` pelas colunas de cluster |

> 🧭 **Regra de bolso:** particione pela coluna que aparece no **`WHERE` de quase toda query** (geralmente data). Clusterize pelas colunas usadas em **filtros ou `GROUP BY` frequentes** (IDs de entidades: restaurante, cliente, produto).

---

# 📘 Exemplo — Tabela `pedidos` particionada por data e clusterizada por restaurante + cliente

**Cenário:** a tabela `pedidos` da EntregaJá é a mais consultada da base analítica. Praticamente todo relatório filtra por **período** (vendas do dia, da semana, do mês) e agrupa por **restaurante** ou **cliente** (faturação por restaurante, comportamento do cliente). Queremos criar uma versão otimizada dela.

**Decisões de modelagem:**

- **Particionar por `data_hora_pedido`** — porque quase toda consulta filtra por período. O BigQuery vai criar uma "gaveta" diária; ao filtrar por um dia específico, lê apenas os dados desse dia e ignora o resto do histórico.
- **Clusterizar por `restaurante_id` e `cliente_id`** — porque são as colunas mais usadas em `GROUP BY` e filtros de relatórios analíticos. Dentro de cada partição diária, os dados ficam fisicamente ordenados por ID de restaurante e, dentro dele, por ID de cliente — acelerando buscas específicas.

```sql
CREATE OR REPLACE TABLE `unipds-503513.entregaja.pedidos_otimizados2`
-- PARTITION BY DATE(data_hora_pedido)              -- particionar por data (ver nota sobre sandbox abaixo)
CLUSTER BY restaurante_id, cliente_id               -- clusterizar por restaurante_id e cliente_id
AS
SELECT * FROM `unipds-503513.entregaja.pedidos`;    -- popular a tabela com os dados dos pedidos
```

**Como ler, peça por peça:**

1. `CREATE OR REPLACE TABLE ...` — cria a tabela do zero (ou substitui, se já existir). Diferente de `CREATE TABLE IF NOT EXISTS`, aqui a tabela é **sempre** recriada, o que é útil enquanto você está iterando na modelagem.
2. `PARTITION BY DATE(data_hora_pedido)` — instrui o BigQuery a guardar os dados em **partições diárias** baseadas na data extraída de `data_hora_pedido`. Como a coluna é `TIMESTAMP`, usamos `DATE(...)` para "arredondar para o dia".
3. `CLUSTER BY restaurante_id, cliente_id` — dentro de cada partição, ordena os blocos primeiro por restaurante e depois, dentro de cada restaurante, por cliente. A **ordem das colunas importa**: filtros por `restaurante_id` são otimizados sozinhos; filtros só por `cliente_id` **não** ganham tanto (o cluster é hierárquico).
4. `AS SELECT * FROM ...` — popula a tabela nova com os dados da tabela original.

**Como validar o ganho:**

Depois de criar a tabela, execute a mesma query na tabela original e na otimizada, e compare o **"bytes processed"** na aba de detalhes do BigQuery:

```sql
-- Na tabela original: lê a tabela inteira
SELECT COUNT(*) FROM `unipds-503513.entregaja.pedidos`
WHERE DATE(data_hora_pedido) = '2025-06-14';

-- Na tabela otimizada: lê só a partição do dia
SELECT COUNT(*) FROM `unipds-503513.entregaja.pedidos_otimizados2`
WHERE DATE(data_hora_pedido) = '2025-06-14';
```

Se o particionamento funcionou, a segunda query mostra uma fração dos bytes processados da primeira.

---

## ⚠️ Limitações no BigQuery Sandbox (e por que a linha `PARTITION BY` está comentada)

O **BigQuery Sandbox** é o modo gratuito, sem cartão de crédito — é o que usamos nas aulas. Ele tem restrições que **não existem** no BigQuery pago, e algumas afetam diretamente o exemplo acima.

### 1. Expiração automática de 60 dias

No sandbox, **toda tabela e toda partição** recebe um `expiration_time` padrão de **60 dias**. Depois desse prazo, o BigQuery **apaga** a partição (ou a tabela inteira) automaticamente.

**O que isso significa na prática:** se você particiona por `data_hora_pedido` e os dados são de **antes de 2024** — como é o caso da base `entregaja`, cuja carga histórica é bem anterior à data de hoje (superior ao ano de 2026) — **todas as partições nascem já vencidas**. O BigQuery cria a tabela, mas as partições são consideradas expiradas na hora e **não retornam dados** em nenhuma consulta.

O sintoma típico é exatamente o que aconteceu no exemplo:

```sql
SELECT COUNT(*) FROM `unipds-503513.entregaja.pedidos_otimizados2`;
-- retorna 0, mesmo tendo populado a tabela com milhares de linhas
```

**Por isso a linha `PARTITION BY` está comentada** — sem ela, a tabela é criada sem particionamento, os dados históricos permanecem visíveis e o `CLUSTER BY` continua funcionando normalmente.

### 2. Como testar particionamento no sandbox mesmo assim

Se quiser **exercitar a sintaxe** de `PARTITION BY` no sandbox, tem três alternativas:

- **Usar dados sintéticos com data atual** — gere uma tabela pequena com `CURRENT_TIMESTAMP()` ou datas dos últimos 30 dias, particione por ela e valide.
- **Particionar por uma coluna que não seja data histórica** — por exemplo, `PARTITION BY RANGE_BUCKET(restaurante_id, GENERATE_ARRAY(0, 1000, 100))` cria partições por faixas de ID, sem envolver expiração temporal.
- **Desativar a expiração explicitamente** (só funciona em conta paga):

  ```sql
  CREATE OR REPLACE TABLE `unipds-503513.entregaja.pedidos_otimizados2`
  PARTITION BY DATE(data_hora_pedido)
  OPTIONS (partition_expiration_days = NULL)   -- ignorado no sandbox
  AS
  SELECT * FROM `unipds-503513.entregaja.pedidos`;
  ```

  No sandbox, essa `OPTIONS` é **ignorada** e a expiração de 60 dias continua valendo.

### 3. Outras limitações do sandbox que valem lembrar

| Limitação | Efeito no dia a dia |
|-----------|---------------------|
| Sem billing habilitado | Não dá para exportar via streaming, não dá para usar DML em escala grande |
| 1 TB de dados processados por mês (grátis) | Suficiente para as aulas; monitore o consumo se rodar muitas queries pesadas |
| Máximo de 4.000 partições por tabela | Relevante para dados diários de muitos anos — 10 anos ≈ 3.650 partições, ainda cabe |
| Sem `CREATE PROCEDURE` persistente | Procedures rodam mas expiram junto com a tabela |

---

## 📝 Resumo geral

**Estrutura padrão para criar uma tabela otimizada:**

```sql
CREATE OR REPLACE TABLE `projeto.dataset.tabela_otimizada`
PARTITION BY DATE(coluna_de_data)                   -- opcional; escolha a coluna mais filtrada
CLUSTER BY coluna1_frequente, coluna2_frequente     -- opcional; até 4 colunas, ordem importa
AS
SELECT * FROM `projeto.dataset.tabela_original`;
```

**Como escolher:**

| Situação | O que usar |
|----------|------------|
| Query quase sempre filtra por um período de tempo | `PARTITION BY DATE(coluna)` |
| Query quase sempre filtra por uma faixa de IDs | `PARTITION BY RANGE_BUCKET(...)` |
| Query filtra ou agrupa por IDs frequentes | `CLUSTER BY id_principal, id_secundario` |
| Tabela pequena (< 1 GB) | Nem particione nem clusterize — não compensa |

---

## ⚠️ Cuidados importantes

1. **Particionamento e clustering são de escrita, não de leitura.** Você define ao **criar** a tabela; não dá para "adicionar" particionamento a uma tabela existente sem recriá-la (via `CREATE OR REPLACE` ou export/import).

2. **A ordem do `CLUSTER BY` importa.** `CLUSTER BY restaurante_id, cliente_id` otimiza filtros por `restaurante_id` sozinho, e por `restaurante_id + cliente_id` combinados. Filtros só por `cliente_id` **não** ganham tanto — a hierarquia é da esquerda pra direita, igual índice composto em banco relacional.

3. **Máximo de 4 colunas no `CLUSTER BY`.** Mais que isso o BigQuery rejeita. Escolha as que aparecem em mais queries.

4. **Particionar por coluna de altíssima cardinalidade é ruim.** Não particione por `pedido_id` — cria milhões de partições minúsculas e piora a performance. Particione por dimensões com **granularidade razoável** (dia, mês, faixa de ID).

5. **No sandbox, cuidado com `PARTITION BY DATE(...)` em dados históricos.** Como explicado acima, partições com mais de 60 dias somem. Para exercitar a sintaxe, use datas recentes ou particione por uma coluna não-temporal.

6. **Sempre valide o ganho olhando "bytes processed".** É o único jeito de saber se o particionamento/clustering está sendo **usado** pela query. Se o filtro no `WHERE` não bate com a coluna de partição (por exemplo, envolve `EXTRACT` ou cast), o BigQuery pode ignorar a otimização e ler a tabela inteira mesmo assim.
