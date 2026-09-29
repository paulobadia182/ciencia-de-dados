# Aula 19: JOINs — combinando tabelas

**Objetivo:** Aprender a **combinar informações de duas tabelas** usando os quatro tipos principais de `JOIN`: `INNER`, `LEFT`, `RIGHT` e `FULL`.

> 💡 **Diferença chave:** todo `JOIN` combina linhas de duas tabelas com base em uma condição (`ON`). O tipo do `JOIN` decide **o que fazer com as linhas que não têm correspondência**.

---

## 🎯 Modelo mental

Imagine as duas tabelas como dois círculos que se cruzam:

- **INNER JOIN** → só a **interseção** (linhas que existem nas duas)
- **LEFT JOIN** → tudo da **esquerda** + interseção
- **RIGHT JOIN** → tudo da **direita** + interseção
- **FULL JOIN** → **união completa** (tudo dos dois lados)

Onde não há correspondência, as colunas da outra tabela vêm preenchidas com `NULL`.

---

## 🔗 Parte 1 — INNER JOIN (só o que casa nas duas)

O `INNER JOIN` retorna **apenas as linhas que têm par nas duas tabelas**. Se um registro não tem correspondência, ele **fica de fora** do resultado.

### Exemplo 1: Pedidos com o nome e o plano do cliente que fez cada um

```sql
SELECT 
    p.pedido_id,
    p.data_hora_pedido,
    p.status,
    c.nome AS nome_cliente,
    c.plano
FROM `unipds-503513.entregaja.pedidos` AS p
INNER JOIN `unipds-503513.entregaja.clientes` AS c
    ON p.cliente_id = c.cliente_id
LIMIT 15;
```

**Explicação:** O `INNER JOIN` conecta cada pedido ao cliente com o mesmo `cliente_id`. Se algum pedido apontasse para um cliente inexistente na tabela `clientes` (ou vice-versa), ele **seria descartado**. Usamos os **alias** `p` e `c` para encurtar o nome das tabelas — o `AS` é opcional.

---

## ⬅️ Parte 2 — LEFT JOIN (tudo da esquerda)

O `LEFT JOIN` retorna **todas as linhas da tabela da esquerda** e, para cada uma, tenta encontrar par na da direita. Quando não encontra, preenche as colunas da direita com `NULL`.

### Exemplo 2: Todos os pedidos + nome do entregador (inclusive os cancelados sem entregador)

```sql
SELECT 
    p.pedido_id,
    p.status,
    p.entregador_id,
    e.nome AS nome_entregador,
    e.veiculo
FROM `unipds-503513.entregaja.pedidos` AS p
LEFT JOIN `unipds-503513.entregaja.entregadores` AS e
    ON p.entregador_id = e.entregador_id
LIMIT 15;
```

**Explicação:** Pedidos cancelados têm `entregador_id` **nulo**, então **não têm par** na tabela `entregadores`. Com `LEFT JOIN`, esses pedidos continuam aparecendo — só que as colunas `nome_entregador` e `veiculo` vêm como `NULL`. Se usássemos `INNER JOIN` aqui, os pedidos cancelados sumiriam do resultado.

---

## ➡️ Parte 3 — RIGHT JOIN (tudo da direita)

O `RIGHT JOIN` é o **espelho** do `LEFT JOIN`: retorna **todas as linhas da tabela da direita**, mesmo que não haja par na esquerda.

### Exemplo 3: Todos os restaurantes + os pedidos que receberam (inclusive restaurantes sem nenhum pedido)

```sql
SELECT 
    r.restaurante_id,
    r.nome AS nome_restaurante,
    r.categoria,
    p.pedido_id,
    p.status
FROM `unipds-503513.entregaja.pedidos` AS p
RIGHT JOIN `unipds-503513.entregaja.restaurantes` AS r
    ON p.restaurante_id = r.restaurante_id
LIMIT 15;
```

**Explicação:** Aqui a tabela da **direita** é `restaurantes`. Todos os restaurantes aparecem no resultado — se algum nunca recebeu um pedido, as colunas de `pedidos` (pedido_id, status) viriam como `NULL`. Repare: essa consulta pode ser reescrita como `restaurantes LEFT JOIN pedidos` — o resultado é idêntico. Por isso, muitas equipes preferem usar **sempre `LEFT JOIN`** por consistência de leitura.

---

## 🔄 Parte 4 — FULL JOIN (tudo dos dois lados)

O `FULL JOIN` (também chamado `FULL OUTER JOIN`) traz **tudo**: linhas com correspondência, linhas só da esquerda **e** linhas só da direita. Onde falta o par, as colunas viram `NULL`.

### Exemplo 4: Entregadores e pedidos — auditar os dois lados em um único relatório

```sql
SELECT 
    e.entregador_id,
    e.nome AS nome_entregador,
    p.pedido_id,
    p.status
FROM `unipds-503513.entregaja.entregadores` AS e
FULL JOIN `unipds-503513.entregaja.pedidos` AS p
    ON e.entregador_id = p.entregador_id
LIMIT 15;
```

**Explicação:** O `FULL JOIN` mostra três situações no mesmo resultado:
- Entregadores **com** pedidos → linhas casadas dos dois lados
- Entregadores **sem** pedidos → colunas de `pedidos` viram `NULL`
- Pedidos **sem entregador** (cancelados) → colunas de `entregadores` viram `NULL`

É útil para **auditoria**: quando você quer detectar registros órfãos nos dois lados de uma vez.

---

## 📝 Resumo

| Tipo | O que retorna |
|------|---------------|
| `INNER JOIN` | Só linhas com par nas duas tabelas |
| `LEFT JOIN` | Tudo da **esquerda** + pares (NULL onde não casa) |
| `RIGHT JOIN` | Tudo da **direita** + pares (NULL onde não casa) |
| `FULL JOIN` | Tudo dos **dois lados** (NULL onde não casa) |

## ⚠️ Cuidados importantes

1. **Sempre use `ON`** para dizer *como* as tabelas se conectam — normalmente `tabela1.chave = tabela2.chave`.
2. **Use `alias` curtos** (`AS p`, `AS c`) para encurtar a query e evitar repetir o nome longo da tabela em cada coluna.
3. **`INNER JOIN` descarta linhas sem par**. Se quiser preservar linhas "órfãs", use um `OUTER JOIN` (`LEFT`, `RIGHT` ou `FULL`).
4. **`RIGHT JOIN` pode sempre ser reescrito como `LEFT JOIN`** invertendo a ordem das tabelas.
5. **Cuidado com colunas de mesmo nome nas duas tabelas** (ex.: `cidade` em `clientes` e `restaurantes`): sempre qualifique com o alias (`c.cidade`, `r.cidade`) para o SQL não ficar ambíguo.

---
