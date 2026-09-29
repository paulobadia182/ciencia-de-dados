# Aula 14: Operadores Aritméticos, de Comparação e Lógicos

**Objetivo:** Aplicar operadores aritméticos, de comparação e lógicos utilizando apenas `SELECT`, `FROM`, `LIMIT` e `DISTINCT`.

> ⚠️ **Importante:** Nesta aula ainda **não** usamos `WHERE`. Por isso, os operadores de comparação e lógicos aparecem no `SELECT`, retornando `true`/`false` (ou `1`/`0`) para cada linha.

---

## 📊 Operadores Aritméticos

Permitem realizar cálculos matemáticos: `+`, `-`, `*`, `/`

### Exemplo 1: Calcular o valor total de cada item no pedido (quantidade × preço unitário)

```sql
SELECT 
    pedido_item_id,
    quantidade,
    preco_unitario,
    quantidade * preco_unitario AS valor_total
FROM `unipds-503513.entregaja.pedido_itens`
LIMIT 10;
```

**Explicação:** Multiplicamos `quantidade` por `preco_unitario` usando o operador `*` para calcular o valor total pago por cada item do pedido.

---

### Exemplo 2: Calcular a taxa de entrega por minuto (taxa ÷ tempo de entrega)

```sql
SELECT 
    pedido_id,
    taxa_entrega,
    tempo_entrega_min,
    taxa_entrega / tempo_entrega_min AS taxa_por_minuto
FROM `unipds-503513.entregaja.pedidos`
LIMIT 15;
```

**Explicação:** Dividimos a `taxa_entrega` pelo `tempo_entrega_min` usando o operador `/` para descobrir quanto foi cobrado por minuto de entrega.

---

### Exemplo 3: Calcular o valor do pedido após aplicar o cupom de desconto (taxa_entrega - (cupom_desconto/100) * taxa_entrega)

```sql
SELECT 
    pedido_id,
    taxa_entrega,
    cupom_desconto,
    ROUND(taxa_entrega - (cupom_desconto/100) * taxa_entrega, 2) AS taxa_com_desconto
FROM `unipds-503513.entregaja.pedidos`;
```

**Explicação:** Subtraímos o `cupom_desconto` da `taxa_entrega` usando o operador `-` para obter a taxa final paga pelo cliente após o desconto.

---

## 🔍 Operadores de Comparação

Comparam dois valores e retornam `true`/`false`: `>`, `<`, `>=`, `<=`, `=`, `<>` (ou `!=`)

### Exemplo 4: Verificar quais itens têm preço unitário maior que 50 reais

```sql
SELECT 
    pedido_item_id,
    preco_unitario,
    preco_unitario > 50 AS eh_item_caro
FROM `unipds-503513.entregaja.pedido_itens`
LIMIT 15;
```

**Explicação:** O operador `>` (maior que) compara cada `preco_unitario` com 50 e retorna `true` se o item for caro, `false` caso contrário.

---

### Exemplo 5: Identificar pedidos com tempo de entrega igual ou menor a 30 minutos (entrega rápida)

```sql
SELECT 
    pedido_id,
    tempo_entrega_min,
    tempo_entrega_min <= 40 AS entrega_rapida
FROM `unipds-503513.entregaja.pedidos`
LIMIT 20;
```

**Explicação:** O operador `<=` (menor ou igual) verifica se o `tempo_entrega_min` foi de até 30 minutos, marcando as entregas consideradas rápidas.

---

### Exemplo 6: Verificar quais pedidos foram pagos com cartão de crédito

```sql
SELECT 
    pedido_id,
    forma_pagamento,
    forma_pagamento = 'Cartão de Crédito' AS pagou_com_cartao
FROM `unipds-503513.entregaja.pedidos`;
```

**Explicação:** O operador `=` (igual) compara textos. Aqui identificamos quais pedidos utilizaram Cartão de Crédito como forma de pagamento.

---

## ⚙️ Operadores Lógicos

Combinam múltiplas condições: `AND` (e), `OR` (ou), `NOT` (não).

### Exemplo 7: Verificar pedidos com quantidade maior que 1 E preço unitário acima de 40

```sql
SELECT 
    pedido_item_id,
    quantidade,
    preco_unitario,
    (quantidade > 1) AND (preco_unitario > 40) AS item_volume_e_caro
FROM `unipds-503513.entregaja.pedido_itens`
LIMIT 15;
```

**Explicação:** O operador `AND` retorna `true` apenas quando **ambas** as condições são verdadeiras: quantidade acima de 1 **E** preço acima de 40.

---

### Exemplo 8: Verificar pedidos com entrega gratuita OU entrega demorada (mais de 60 minutos)

```sql
SELECT 
    pedido_id,
    taxa_entrega,
    tempo_entrega_min,
    (taxa_entrega = 0) OR (tempo_entrega_min > 60) AS entrega_gratis_ou_lenta
FROM `unipds-503513.entregaja.pedidos`
LIMIT 15;
```

**Explicação:** O operador `OR` retorna `true` quando **pelo menos uma** das condições é verdadeira: taxa gratuita **OU** entrega demorada.

---

### Exemplo 9: Identificar clientes que NÃO são idosos (idade não superior a 60 anos)

```sql
SELECT 
    cliente_id,
    nome,
    idade,
    NOT (idade > 60) AS nao_eh_idoso
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

**Explicação:** O operador `NOT` inverte o resultado da comparação. Se a idade for maior que 60, o `NOT` transforma em `false`; caso contrário, em `true`.

---

## 🔗 Combinando DISTINCT com Operadores

### Exemplo 10: Listar as formas de pagamento únicas usadas na plataforma

```sql
SELECT DISTINCT
    forma_pagamento
FROM `unipds-503513.entregaja.pedidos`
LIMIT 10;
```

**Explicação:** Com `DISTINCT` eliminamos duplicatas, retornando apenas os valores únicos de `forma_pagamento`.

---

### Exemplo 11: Listar combinações únicas entre canal de pedido e se teve desconto aplicado

```sql
SELECT DISTINCT
    canal,
    cupom_desconto > 0 AS teve_desconto
FROM `unipds-503513.entregaja.pedidos`
LIMIT 10;
```

**Explicação:** Combinamos `DISTINCT` com o operador de comparação `>`. O resultado mostra pares únicos de canal e se houve desconto (`true`/`false`).

---

### Exemplo 12: Listar combinações únicas entre categoria e se o item é premium (preço acima de 40)

```sql
SELECT DISTINCT
    categoria_item,
    preco > 40 AS eh_premium
FROM `unipds-503513.entregaja.itens`
LIMIT 15;
```

**Explicação:** Unimos `DISTINCT` com uma comparação. Cada linha retornada é uma combinação única de categoria e status premium do item.

---

## 📝 Resumo dos Operadores

| Tipo | Operadores | Exemplo |
|------|-----------|---------|
| **Aritméticos** | `+`, `-`, `*`, `/` | `quantidade * preco_unitario` |
| **Comparação** | `>`, `<`, `>=`, `<=`, `=`, `<>` | `preco_unitario > 50` |
| **Lógicos** | `AND`, `OR`, `NOT` | `(quantidade > 1) AND (preco_unitario > 40)` |

---

## ✅ Próximos Passos

Na próxima aula, aprenderemos a usar `WHERE` para **filtrar** linhas com base nessas operações — em vez de apenas mostrar `true`/`false` no resultado, vamos poder retornar somente as linhas que atendem às condições!
