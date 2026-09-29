# Aula 15: WHERE, IF, CASE e COALESCE

**Objetivo:** Aprender a **filtrar linhas** com `WHERE` e a **transformar valores** no `SELECT` com `IF`, `CASE` e `COALESCE`.

> 💡 **Diferença chave:** o `WHERE` decide **quais linhas** aparecem no resultado. Já `IF`, `CASE` e `COALESCE` são usados no `SELECT` e criam ou ajustam **colunas** — sem descartar linhas.

---

## 🔍 Parte 1 — WHERE (Filtrar Linhas)

A cláusula `WHERE` vem **depois do FROM** e **antes do LIMIT**. Só as linhas que atendem à condição aparecem no resultado.

### Exemplo 1: Filtrar clientes Premium com mais de 40 anos

```sql
SELECT 
    cliente_id,
    nome,
    idade,
    plano
FROM `unipds-503513.entregaja.clientes`
WHERE plano = 'Premium' AND idade > 40
LIMIT 15;
```

**Explicação:** O `WHERE` mantém apenas as linhas em que **ambas** as condições são verdadeiras: o cliente é do plano Premium **e** tem mais de 40 anos. As demais linhas são descartadas antes do resultado ser exibido.

---

## 🔀 Parte 2 — IF (Decisão Binária)

O `IF(condição, valor_se_verdadeiro, valor_se_falso)` cria uma nova coluna com base em uma decisão de **duas saídas**.

### Exemplo 2: Classificar pedidos como entrega grátis ou paga

```sql
SELECT 
    pedido_id,
    taxa_entrega,
    IF(taxa_entrega = 0, 'Entrega grátis', 'Entrega paga') AS tipo_entrega
FROM `unipds-503513.entregaja.pedidos`
LIMIT 15;
```

**Explicação:** Para cada linha, o `IF` avalia se `taxa_entrega = 0`. Se for verdadeiro, retorna `'Entrega grátis'`; caso contrário, retorna `'Entrega paga'`. O resultado aparece na nova coluna `tipo_entrega`.

---

## 🎚️ Parte 3 — CASE (Múltiplas Condições)

O `CASE` avalia várias condições em sequência e retorna o valor do **primeiro `WHEN`** que for verdadeiro. O `ELSE` cobre os casos restantes.

### Exemplo 3: Classificar clientes em faixas etárias

```sql
SELECT 
    cliente_id,
    nome,
    idade,
    CASE 
        WHEN idade < 25 THEN 'Jovem'
        WHEN idade BETWEEN 25 AND 50 THEN 'Adulto'
        ELSE 'Sênior'
    END AS faixa_etaria
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

**Explicação:** Diferente do `IF` (que tem só duas saídas), o `CASE` permite **múltiplas ramificações**. Aqui, cada cliente é classificado como `'Jovem'`, `'Adulto'` ou `'Sênior'` conforme a faixa de idade. O `END` é obrigatório para fechar o `CASE`.

---

## 🕳️ Parte 4 — COALESCE (Substituir Nulos)

O `COALESCE(valor1, valor2, ...)` retorna o **primeiro valor não nulo** da lista. Muito útil para exibir um texto padrão no lugar de células vazias.

### Exemplo 4: Substituir comentários vazios por texto padrão

```sql
SELECT 
    avaliacao_id,
    pedido_id,
    nota,
    COALESCE(comentario, 'Sem comentário') AS comentario
FROM `unipds-503513.entregaja.avaliacoes`
LIMIT 15;
```

**Explicação:** Sempre que `comentario` estiver `NULL`, o `COALESCE` retorna `'Sem comentário'` no lugar. Se o comentário existir, retorna o próprio texto. Isso deixa o relatório mais legível, sem deixar espaços vazios.

---

## 📝 Resumo

| Recurso | Onde é usado | Serve para |
|---------|--------------|------------|
| `WHERE` | Depois do `FROM` | **Filtrar linhas** do resultado |
| `IF` | Dentro do `SELECT` | Decisão **binária** (2 saídas) |
| `CASE` | Dentro do `SELECT` | Decisão com **múltiplas condições** |
| `COALESCE` | Dentro do `SELECT` | Substituir valores `NULL` por um padrão |

## ⚠️ Cuidados Importantes

1. **`WHERE` filtra linhas; `IF`/`CASE`/`COALESCE` criam colunas** — não confunda os papéis.
2. **`= NULL` NÃO funciona** — para verificar nulos, use `IS NULL` ou `COALESCE`.
3. **Todo `CASE` precisa terminar com `END`** (e opcionalmente `AS nome_da_coluna`).
4. **Textos entre aspas simples:** `'Premium'`, não `"Premium"`.
5. **`COALESCE` aceita vários argumentos:** `COALESCE(a, b, c)` retorna o primeiro que não for nulo.

---

