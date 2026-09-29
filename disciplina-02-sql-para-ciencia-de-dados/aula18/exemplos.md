# Aula 18: Funções de Data e Texto

**Objetivo:** Aprender as funções mais úteis para trabalhar com **datas** (extrair partes, agrupar por período, calcular diferenças, somar/subtrair, formatar/converter) e **textos** (padronizar caixa, remover espaços, extrair pedaços, substituir, medir tamanho).

> 💡 **Diferença chave:** essas funções são usadas dentro do `SELECT` — elas **não filtram linhas**, só **transformam colunas** ou criam novas. Também podem aparecer no `WHERE` para filtrar por partes/valores derivados (ex.: filtrar só o mês de dezembro com `EXTRACT`).

---

## 📅 Parte 1 — Funções de Data e Hora

### Exemplo 1: `EXTRACT` — pegar uma parte da data (ano/mês/dia)

```sql
SELECT 
    cliente_id,
    nome,
    data_cadastro,
    EXTRACT(YEAR FROM data_cadastro) AS ano_cadastro,
    EXTRACT(MONTH FROM data_cadastro) AS mes_cadastro,
    EXTRACT(DAY FROM data_cadastro) AS dia_cadastro
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

**Explicação:** O `EXTRACT` isola **uma parte** da data. Também funciona com `QUARTER`, `WEEK`, `DAYOFWEEK`, `DAYOFYEAR`, entre outros. É a função ideal para **agrupar** ou **filtrar** por período (ex.: `WHERE EXTRACT(MONTH FROM data) = 12`).

---

### Exemplo 2: `DATE_TRUNC` — arredondar a data para o início do período

```sql
SELECT 
    pedido_id,
    data_hora_pedido,
    DATE_TRUNC(DATE(data_hora_pedido), MONTH) AS inicio_mes,
    DATE_TRUNC(DATE(data_hora_pedido), WEEK) AS inicio_semana,
    DATE_TRUNC(DATE(data_hora_pedido), YEAR) AS inicio_ano
FROM `unipds-503513.entregaja.pedidos`
LIMIT 15;
```

**Explicação:** Enquanto o `EXTRACT` devolve um **número** (só o mês, só o ano), o `DATE_TRUNC` **preserva a data completa** mas "arredondada" para o começo do período. É perfeito para **agrupar** por semana/mês/ano sem perder o formato de data. Como `data_hora_pedido` é `DATETIME`, convertemos para `DATE` primeiro.

---

### Exemplo 3: `DATE_DIFF` — quantos dias/meses/anos entre duas datas

```sql
SELECT 
    cliente_id,
    nome,
    data_cadastro,
    DATE_DIFF(CURRENT_DATE(), data_cadastro, DAY) AS dias_como_cliente,
    DATE_DIFF(CURRENT_DATE(), data_cadastro, MONTH) AS meses_como_cliente,
    DATE_DIFF(CURRENT_DATE(), data_cadastro, YEAR) AS anos_como_cliente
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

**Explicação:** `DATE_DIFF(final, inicial, unidade)` retorna a diferença nas unidades escolhidas (`DAY`, `MONTH`, `YEAR`…). Usamos `CURRENT_DATE()` para pegar a data de hoje. **Cuidado com a ordem** dos argumentos — se invertermos, o resultado fica negativo. Para colunas do tipo `DATETIME`/`TIMESTAMP`, use `DATETIME_DIFF` ou `TIMESTAMP_DIFF`.

---

### Exemplo 4: `DATE_ADD` e `DATE_SUB` — somar ou subtrair períodos

```sql
SELECT 
    cliente_id,
    nome,
    data_cadastro,
    DATE_ADD(data_cadastro, INTERVAL 1 YEAR) AS aniversario_1_ano,
    DATE_ADD(data_cadastro, INTERVAL 30 DAY) AS trinta_dias_depois,
    DATE_SUB(data_cadastro, INTERVAL 6 MONTH) AS seis_meses_antes
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

**Explicação:** `DATE_ADD` **soma** e `DATE_SUB` **subtrai** um intervalo de tempo. A sintaxe do intervalo é `INTERVAL n <unidade>` (`DAY`, `MONTH`, `YEAR`…). Muito útil para calcular vencimentos, datas de renovação e prazos.

---

### Exemplo 5: `FORMAT_DATE` e `PARSE_DATE` — data ↔ texto

```sql
SELECT 
    pedido_id,
    data_hora_pedido,
    -- data → texto formatado
    FORMAT_DATE('%d/%m/%Y', DATE(data_hora_pedido)) AS data_br,
    FORMAT_DATE('%A', DATE(data_hora_pedido)) AS dia_semana,
    -- texto → data (útil quando o dado veio como string)
    PARSE_DATE('%d/%m/%Y', '25/12/2023') AS natal_convertido
FROM `unipds-503513.entregaja.pedidos`
LIMIT 15;
```

**Explicação:** As duas funções são **espelhos**:
- `FORMAT_DATE('formato', data)` transforma uma **data em texto** no formato desejado (`%d/%m/%Y` = `25/12/2023`; `%A` = nome do dia da semana).
- `PARSE_DATE('formato', 'texto')` faz o **inverso**: recebe uma string e devolve `DATE`. Útil quando importamos dados de planilhas onde a data veio como texto.

---

## 🔤 Parte 2 — Funções de Texto

### Exemplo 6: `UPPER`, `LOWER`, `INITCAP` — padronizar a caixa

```sql
SELECT 
    cliente_id,
    nome,
    UPPER(nome) AS nome_maiusculo,
    LOWER(email) AS email_minusculo,
    INITCAP(LOWER(nome)) AS nome_inicial_maiuscula
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

**Explicação:** As três padronizam a caixa do texto:
- `UPPER` — TUDO EM MAIÚSCULAS
- `LOWER` — tudo em minúsculas
- `INITCAP` — **Primeira Letra De Cada Palavra Em Maiúscula**

Muito útil para **comparações** no `WHERE`: comparar `nome = 'joao'` não casa com `'João'`. Padronizar com `LOWER(nome) = 'joão'` dos dois lados resolve.

---

### Exemplo 7: `TRIM`, `LTRIM`, `RTRIM` — remover espaços das pontas

```sql
SELECT 
    '   Ana Beatriz     ' AS texto_original,
    LENGTH('   Ana Beatriz     ') AS tam_original,
    TRIM('   Ana Beatriz     ') AS trim_completo,
    LENGTH(TRIM('   Ana Beatriz     ')) AS tam_apos_trim,
    LTRIM('   Ana Beatriz     ') AS ltrim_nome,
    LENGTH(LTRIM('   Ana Beatriz     ')) AS tam_apos_ltrim,
    RTRIM('   Ana Beatriz     ') AS rtrim_nome,
    LENGTH(RTRIM('   Ana Beatriz     ')) AS tam_apos_rtrim;
```

**Explicação:** As três removem espaços — a diferença é **onde**:
- `TRIM` — remove das **duas pontas**
- `LTRIM` — só da **esquerda** (*left*)
- `RTRIM` — só da **direita** (*right*)

Muito importante em dados vindos de planilhas ou formulários (onde usuários digitam espaços sem querer). Aqui usamos um **texto literal** para deixar o efeito visível: no relatório, `LENGTH` cai de 18 para 12 caracteres depois do `TRIM`.

---

### Exemplo 8: `LENGTH` — contar caracteres

```sql
SELECT 
    cliente_id,
    nome,
    email,
    LENGTH(nome) AS tamanho_nome,
    LENGTH(email) AS tamanho_email
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

**Explicação:** `LENGTH` conta o número de **caracteres** (incluindo espaços). Muito usado no `WHERE` para achar valores anormais (nomes curtos demais, comentários vazios, etc.). Textos `NULL` viram `LENGTH` `NULL`.

---

### Exemplo 9: `SUBSTR`, `STRPOS` e `SPLIT` — extrair pedaços do texto

```sql
SELECT 
    cliente_id,
    email,
    -- Onde está o '@'?
    STRPOS(email, '@') AS posicao_arroba,
    -- Recortar do começo até o '@'
    SUBSTR(email, 1, STRPOS(email, '@') - 1) AS usuario,
    -- Recortar depois do '@'
    SUBSTR(email, STRPOS(email, '@') + 1) AS dominio,
    -- Mesmo resultado, mais simples, com SPLIT:
    SPLIT(email, '@')[OFFSET(0)] AS usuario_split,
    SPLIT(email, '@')[OFFSET(1)] AS dominio_split
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

**Explicação:** As três funções trabalham juntas quando queremos **extrair pedaços**:
- `STRPOS(texto, alvo)` — devolve a **posição** onde o alvo aparece (começa em **1**, não em 0). Retorna 0 se não achar.
- `SUBSTR(texto, início, tamanho)` — **recorta** um pedaço. O tamanho é opcional (sem ele, vai até o fim).
- `SPLIT(texto, separador)` — **quebra** o texto num array de pedaços. Acessamos cada pedaço com `[OFFSET(n)]` (zero-indexado).

Quando o texto tem separador definido (como `@` no email), `SPLIT` é mais legível.

---

### Exemplo 10: `REPLACE` e `REGEXP_REPLACE` — substituir dentro do texto

```sql
SELECT 
    cliente_id,
    email,
    -- Troca simples de uma string por outra
    REPLACE(email, '@exemplo.com', '@entregaja.com.br') AS email_novo,
    -- Troca por padrão (regex): remove tudo antes e incluindo o '@'
    REGEXP_REPLACE(email, r'^.+@', '') AS so_dominio
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

**Explicação:** As duas funções fazem substituição, mas com poder diferente:
- `REPLACE(texto, procurar, substituir)` — busca **exatamente** o texto informado e troca. Simples e direto.
- `REGEXP_REPLACE(texto, padrão, substituir)` — usa **expressões regulares** para casar padrões complexos. O `r'...'` marca o texto como *raw* (evita interpretação de caracteres especiais). O padrão `^.+@` significa "tudo do começo até um `@`".

Use `REPLACE` quando souber o texto exato; use `REGEXP_REPLACE` quando precisar de flexibilidade (ex.: remover todos os dígitos, normalizar espaços múltiplos, etc.).

---

## 📝 Resumo

### 📅 Funções de Data e Hora

| Função | Serve para |
|--------|------------|
| `EXTRACT(parte FROM data)` | Isolar ano, mês, dia, quarter, dia da semana… |
| `DATE_TRUNC(data, período)` | Agrupar por período (mantém formato de data) |
| `DATE_DIFF(final, inicial, unidade)` | Calcular diferença entre datas |
| `DATE_ADD(data, INTERVAL n unidade)` | Somar período |
| `DATE_SUB(data, INTERVAL n unidade)` | Subtrair período |
| `FORMAT_DATE('formato', data)` | Data → texto formatado |
| `PARSE_DATE('formato', texto)` | Texto → data |
| `CURRENT_DATE()` | Data de hoje |

### 🔤 Funções de Texto

| Função | Serve para |
|--------|------------|
| `UPPER(texto)` / `LOWER(texto)` / `INITCAP(texto)` | Padronizar caixa |
| `TRIM(t)` / `LTRIM(t)` / `RTRIM(t)` | Remover espaços |
| `LENGTH(texto)` | Contar caracteres |
| `STRPOS(texto, alvo)` | Posição de um trecho |
| `SUBSTR(texto, início, tamanho)` | Recortar pedaço |
| `SPLIT(texto, separador)[OFFSET(n)]` | Quebrar em pedaços |
| `REPLACE(texto, de, para)` | Substituir texto exato |
| `REGEXP_REPLACE(texto, padrão, para)` | Substituir por padrão regex |

## ⚠️ Cuidados importantes

1. **Datas ≠ texto**: uma coluna do tipo `DATE`/`DATETIME` **não é** string. Para exibir formatada, use `FORMAT_DATE`; para comparar, use literal com `DATE '2023-01-01'` ou `PARSE_DATE`.
2. **`DATE_DIFF` respeita a ordem**: `(final, inicial, unidade)`. Invertido, dá negativo.
3. **`STRPOS` e `SUBSTR` começam em 1**, não em 0 (diferente de várias linguagens). `SPLIT` com `OFFSET` **começa em 0**.
4. **Padronize antes de comparar**: comparações de texto são **sensíveis a maiúsculas/minúsculas e a espaços**. `LOWER` + `TRIM` dos dois lados evita surpresas.
5. **`REPLACE` é literal, `REGEXP_REPLACE` é padrão**: se só quer trocar um texto fixo, `REPLACE` é mais rápido e mais legível. Regex é para quando o alvo varia.

---
