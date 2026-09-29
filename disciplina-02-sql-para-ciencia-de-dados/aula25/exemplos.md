# Aula 25: Plano de execução e bytes processados no BigQuery

**Objetivo:** entender **como o BigQuery lê os dados** e **como ele calcula o custo** de uma query antes mesmo de rodar — para você escrever consultas mais rápidas e mais baratas.

> 💡 **Ideia central:** o BigQuery **cobra por bytes lidos**, não por linhas nem por tempo. Aprender a ler o "medidor de bytes" e o plano de execução é o que separa quem escreve SQL de quem escreve **SQL eficiente**.

---

## 🎯 Modelo mental

Antes de rodar qualquer query, o BigQuery mostra no **canto inferior esquerdo** do editor uma estimativa:

> ✅ *This query will process X MB when run.*

Esse número é o **custo real da query**. Ele depende de **quais colunas** você pediu — não de quantas linhas você vai receber no final.

**Por que isso acontece?** Porque o BigQuery guarda os dados em formato **colunar**: cada coluna é um arquivo separado. Quando você faz `SELECT nome, idade`, ele abre **só 2 arquivos** — os outros nem são tocados.

| Formato tradicional (linha por linha) | BigQuery (colunar) |
|--------------------------------------|-------------------|
| Uma planilha: cada linha é um registro completo | Cada coluna é um arquivo separado |
| Para ler `nome`, precisa varrer todas as linhas | Para ler `nome`, abre só o arquivo `nome` |
| `SELECT *` e `SELECT nome` custam quase o mesmo | `SELECT *` custa **muito mais** que `SELECT nome` |

---

# 📘 Parte 1 — O medidor de bytes

Antes de cada query abaixo, **olhe o número no canto superior direito** e anote. Depois compare.

## 🔎 1.1 — SELECT * vs. colunas específicas

### Exemplo 1: A query mais cara possível

```sql
SELECT *
FROM `unipds-503513.entregaja.pedidos`;
```

**Anote os bytes:** _______ MB

### Exemplo 2: Só duas colunas

```sql
SELECT pedido_id, taxa_entrega
FROM `unipds-503513.entregaja.pedidos`;
```

**Anote os bytes:** _______ MB

### Exemplo 3: Só uma coluna

```sql
SELECT pedido_id
FROM `unipds-503513.entregaja.pedidos`;
```

**Anote os bytes:** _______ MB

**Explicação:** os três exemplos leem a **mesma quantidade de linhas** (a tabela inteira), mas o custo cai drasticamente conforme reduzimos as **colunas**. Cada coluna é um arquivo — quanto menos arquivos abrir, menos bytes ler, menos dinheiro gastar.

> 🚫 **Regra de ouro:** `SELECT *` é o inimigo do bolso. Em produção, sempre liste as colunas que você realmente vai usar.

---

## 🆓 1.2 — `COUNT(*)` é grátis

### Exemplo 4: Zero bytes!

```sql
SELECT COUNT(*)
FROM `unipds-503513.entregaja.pedidos`;
```

**Anote os bytes:** _______ B

### Exemplo 5: Já `COUNT(coluna)` custa

```sql
SELECT COUNT(cliente_id)
FROM `unipds-503513.entregaja.pedidos`;
```

**Anote os bytes:** _______ MB

**Explicação:** `COUNT(*)` é respondido pelos **metadados** da tabela — o BigQuery já sabe quantas linhas ela tem, não precisa ler nada. Já `COUNT(cliente_id)` precisa ler a coluna inteira (para checar quantos valores **não são nulos**).

---

## 🎯 1.3 — WHERE também não reduz bytes (em tabelas comuns)

### Exemplo 6: Sem filtro

```sql
SELECT pedido_id, status
FROM `unipds-503513.entregaja.pedidos`;
```

**Anote os bytes:** _______ MB

### Exemplo 7: Com filtro — mesmo custo!

```sql
SELECT pedido_id, status
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído';
```

**Anote os bytes:** _______ MB

**Explicação:** o `WHERE` filtra **depois** de ler os dados. Para reduzir bytes de verdade, a tabela precisa ser **particionada** pela coluna do filtro (ex.: particionada por `data_hora_pedido`). Aí sim, filtrar por data pula partições inteiras.

> 🧭 **Regra prática:** `WHERE` acelera o processamento, mas **não reduz o custo** de leitura em tabelas não-particionadas.

---

## 🔗 1.4 — JOIN paga pelas duas tabelas

### Exemplo 8: Só clientes

```sql
SELECT nome, plano
FROM `unipds-503513.entregaja.clientes`;
```

**Anote os bytes:** _______ MB

### Exemplo 9: Só pedidos

```sql
SELECT pedido_id, cliente_id
FROM `unipds-503513.entregaja.pedidos`;
```

**Anote os bytes:** _______ MB

### Exemplo 10: JOIN — soma das duas

```sql
SELECT c.nome, c.plano, p.pedido_id
FROM `unipds-503513.entregaja.clientes` AS c
JOIN `unipds-503513.entregaja.pedidos` AS p
    ON c.cliente_id = p.cliente_id;
```

**Anote os bytes:** _______ MB (≈ soma dos exemplos 9 + 10)

**Explicação:** cada tabela referenciada é lida separadamente. Selecionar poucas colunas **de cada lado** do JOIN é a forma mais direta de reduzir custo.

---

# 📗 Parte 2 — O plano de execução (depois de rodar)

Enquanto a Parte 1 é sobre o que acontece **antes** de rodar (estimativa), agora vamos ver o que aconteceu **depois** — o BigQuery mostra o **plano de execução** de cada query executada.

## 🍕 2.1 — A analogia da pizzaria

Uma query no BigQuery é como o **caminho de uma pizza** no restaurante:

1. **Massa** — ler os dados da tabela
2. **Molho** — aplicar filtros
3. **Recheio** — juntar (JOIN) com outras tabelas
4. **Forno** — agrupar e agregar (`GROUP BY`, `COUNT`, `AVG`)
5. **Entrega** — ordenar e devolver ao usuário

Cada etapa é um **stage** (S00, S01, S02...). Cada stage lê a saída do anterior, transforma, e passa adiante. É assim que o BigQuery paraleliza — cada stage roda em **muitos "slots"** ao mesmo tempo.

---

## 🔬 2.2 — Executando e olhando o plano

### Exemplo 12: Query com CTE + JOIN + agregação

Rode esta query **de verdade** (clique em **RUN**):

```sql
WITH pedidos_por_cliente AS (
    SELECT 
        cliente_id,
        COUNT(*) AS qtd_pedidos,
        SUM(taxa_entrega) AS total_taxas
    FROM `unipds-503513.entregaja.pedidos`
    GROUP BY cliente_id
)
SELECT 
    c.nome,
    c.cidade,
    ppc.qtd_pedidos,
    ppc.total_taxas
FROM pedidos_por_cliente AS ppc
JOIN `unipds-503513.entregaja.clientes` AS c
    ON c.cliente_id = ppc.cliente_id
WHERE ppc.qtd_pedidos > 5
ORDER BY ppc.qtd_pedidos DESC
LIMIT 20;
```

Depois de rodar, clique na aba **"Detalhes da execução"** (ou **"Execution details"**) — ao lado dos "Resultados".

### O que observar:

| Métrica | O que significa |
|---------|----------------|
| **Stages (S00, S01, ...)** | Cada fase do "caminho da pizza" |
| **Records read** | Linhas que o stage recebeu de entrada |
| **Records written** | Linhas que o stage passou adiante — repare como o funil **diminui** |
| **Slot time consumed** | Tempo de processamento **paralelo** somado (se 10 slots trabalharam 1s cada, dá 10s) |
| **Wait / Read / Compute / Write** | Barras coloridas — onde o tempo foi gasto em cada stage |
| **Shuffle** | Redistribuição de dados entre slots (JOIN e GROUP BY causam shuffle) |

**Explicação:** o plano de execução é o **raio-X** da query. É lá que você descobre onde uma consulta lenta está travando — normalmente é um stage com muito **shuffle** (JOIN pesado) ou uma leitura enorme no S00 (falta de filtro/coluna).

---

# 📕 Parte 3 — A pegadinha final

Antes de rodar, **pergunte à turma** qual das duas processa **menos bytes**:

### Opção A

```sql
SELECT COUNT(*)
FROM `unipds-503513.entregaja.pedidos`;
```

### Opção B

```sql
SELECT COUNT(*)
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído';
```

<details>
<summary>🎁 <strong>Resposta (clique para ver)</strong></summary>

- **A** = **0 B** (metadados)
- **B** = **lê a coluna `status` inteira** para poder filtrar

Contra-intuitivo, né? Filtrar **parece** que deveria ser mais barato, mas para saber quais linhas passam no filtro, o BigQuery **precisa ler a coluna do filtro**. Já `COUNT(*)` sem filtro é servido direto pelos metadados.

</details>

---

## 📝 Resumo geral

| Situação | Impacto nos bytes |
|----------|-------------------|
| `SELECT *` | 💸 Lê **todas as colunas** — o mais caro |
| `SELECT col1, col2` | ✅ Lê só as colunas listadas |
| `LIMIT 10` | ❌ **Não reduz bytes** — lê tudo e joga fora |
| `WHERE` (tabela comum) | ❌ **Não reduz bytes** — filtra depois de ler |
| `WHERE` (tabela particionada) | ✅ Pula partições inteiras |
| `COUNT(*)` | 🆓 **Zero bytes** — vem dos metadados |
| `COUNT(coluna)` | 💸 Lê a coluna inteira |
| `JOIN` | 💸 Soma bytes das **duas tabelas** |

---

## ⚠️ Cuidados importantes

1. **Sempre olhe o medidor de bytes** antes de rodar. É a diferença entre uma query de 1 MB e uma de 10 GB.
2. **`SELECT *` só em exploração inicial** — nunca em queries recorrentes ou em produção.
3. **`LIMIT` não é filtro de custo.** Para explorar barato, restrinja **colunas**.
4. **`WHERE` acelera, mas raramente reduz custo** — só em tabelas particionadas.
5. **`COUNT(*)` é grátis**, mas `COUNT(coluna)` não é.
6. **Em JOINs**, selecione poucas colunas de cada tabela.
7. **O plano de execução** (Execution details) mostra onde a query gastou tempo — use quando algo estiver lento.

---

## 🧭 Regra prática de bolso

> Antes de clicar em **RUN**, olhe para o canto superior direito. Se o número te assustar, **repense** o `SELECT` antes do `WHERE`.
