# Gabarito da aula 16:

## Conteúdo acumulado (aulas 10 a 15):
- SELECT, FROM
- DISTINCT
- LIMIT
- ORDER BY
- Operadores aritméticos (`+`, `-`, `*`, `/`)
- Operadores de comparação (`>`, `<`, `>=`, `<=`, `=`, `<>`)
- Operadores lógicos (`AND`, `OR`, `NOT`)
- WHERE
- IF
- CASE
- COALESCE


### EXERCÍCIOS:


* **Exercício 01**: O time de CRM quer lançar uma campanha exclusiva para clientes fiéis. Precisa da lista de clientes do plano **Premium** com **mais de 45 anos**, mostrando ID, nome, idade e cidade, **ordenados por idade em ordem decrescente**.

```sql
SELECT 
    cliente_id,
    nome,
    idade,
    cidade
FROM `unipds-503513.entregaja.clientes`
WHERE plano = 'Premium' AND idade > 45
ORDER BY idade DESC;
```

> 💡 Combinamos duas condições com `AND` no `WHERE` — o cliente precisa ser Premium **e** ter mais de 60 anos.

---
* **Exercício 02**: A equipe de Operações está avaliando os melhores pedidos de referência para treinamento de novos entregadores. Quer visualizar pedidos com **status Concluído** e **tempo de entrega menor ou igual a 25 minutos**, exibindo o ID do pedido, o tempo de entrega e a forma de pagamento, **ordenados do menor para o maior tempo**, limitados a **10 resultados**.

```sql
SELECT 
    pedido_id,
    tempo_entrega_min,
    forma_pagamento
FROM `unipds-503513.entregaja.pedidos`
WHERE status = 'Concluído' AND tempo_entrega_min <= 25
ORDER BY tempo_entrega_min ASC
LIMIT 10;
```

> 💡 Combinação clássica: `WHERE` filtra, `ORDER BY` ordena e `LIMIT` corta os primeiros resultados — nessa ordem.

---
* **Exercício 03**: O time Financeiro precisa identificar itens de pedido com **valor total** (quantidade × preço unitário) **acima de 30 reais**. Traga o ID do item do pedido, a quantidade, o preço unitário e uma coluna calculada chamada `valor_total`, **ordenada do maior para o menor valor total**, limitada a **15 resultados**.

```sql
SELECT 
    pedido_item_id,
    quantidade,
    preco_unitario,
    quantidade * preco_unitario AS valor_total
FROM `unipds-503513.entregaja.pedido_itens`
WHERE quantidade * preco_unitario > 30
ORDER BY valor_total DESC
LIMIT 15;
```

> 💡 A expressão aritmética pode aparecer no `SELECT` (para exibir) **e** no `WHERE` (para filtrar). No `ORDER BY`, também é possível usar o **alias** (`valor_total`) porque a ordenação acontece depois do `SELECT`.

---
* **Exercício 04**: A equipe de Marketing quer descobrir as **cidades únicas** onde há clientes do plano **Grátis** da região **Sudeste**, para focar ações de conversão para Premium. Ordene alfabeticamente.

```sql
SELECT DISTINCT 
    cidade
FROM `unipds-503513.entregaja.clientes`
WHERE plano = 'Grátis' AND regiao = 'Sudeste'
ORDER BY cidade ASC;
```

> 💡 O `WHERE` filtra as linhas primeiro; depois o `DISTINCT` elimina cidades repetidas no resultado.

---
* **Exercício 05**: O time de BI quer classificar os pedidos por **duração da entrega** para um dashboard. Crie uma consulta que retorne o ID do pedido, o tempo de entrega em minutos e uma coluna `categoria_entrega` com as seguintes regras:
  - Até 20 minutos → `'Rápida'`
  - De 21 a 45 minutos → `'Normal'`
  - Acima de 45 minutos → `'Lenta'`

Limite o resultado a **20 linhas** e ordene por `tempo_entrega_min` **crescente**.

```sql
SELECT 
    pedido_id,
    tempo_entrega_min,
    CASE 
        WHEN tempo_entrega_min <= 20 THEN 'Rápida'
        WHEN tempo_entrega_min BETWEEN 21 AND 45 THEN 'Normal'
        WHEN tempo_entrega_min IS NULL THEN 'Sem Entrega'
        ELSE 'Lenta'
    END AS categoria_entrega
FROM `unipds-503513.entregaja.pedidos`
ORDER BY tempo_entrega_min ASC
LIMIT 20;
```

> 💡 Como o `CASE` avalia os `WHEN` **de cima para baixo**, a primeira condição verdadeira "vence". O `ELSE` cobre os casos que não caem em nenhum `WHEN` — inclusive `NULL`, que aqui também será classificado como `'Lenta'`.

---
* **Exercício 06**: O time de Cadastro quer marcar cada cliente como **maior ou menor de idade** (para revisão de política de cadastro). Retorne o ID, nome, idade e uma coluna `situacao` que mostre `'Maior de idade'` se a idade for **maior ou igual a 18**, e `'Menor de idade'` caso contrário. **Use IF.** Limite a **15 linhas**.

```sql
SELECT 
    cliente_id,
    nome,
    idade,
    IF(idade >= 18, 'Maior de idade', 'Menor de idade') AS situacao
FROM `unipds-503513.entregaja.clientes`
LIMIT 15;
```

> 💡 O `IF` é ideal quando temos apenas **duas saídas possíveis**. Se houvesse mais categorias (ex.: criança, adolescente, adulto), o `CASE` seria a melhor escolha.

---
* **Exercício 07**: O time de Operações vai gerar um relatório com o tempo de entrega dos pedidos. Como os pedidos **cancelados** ficam com `tempo_entrega_min` **NULL**, o time quer que esses casos apareçam como **0** no relatório. Traga o ID do pedido, o status e uma coluna `tempo_entrega` que use `COALESCE` para substituir os nulos por `0`. Ordene por `tempo_entrega` **crescente** e limite a **15 linhas**.

```sql
SELECT 
    pedido_id,
    status,
    COALESCE(tempo_entrega_min, 0) AS tempo_entrega
FROM `unipds-503513.entregaja.pedidos`
ORDER BY tempo_entrega ASC
LIMIT 15;
```

> 💡 O `COALESCE` retorna o **primeiro valor não nulo** da lista — funciona tanto para textos quanto para números. Aqui, todo pedido cancelado (que tem `tempo_entrega_min` nulo) aparece com `0` no relatório, evitando células vazias.

---
* **Exercício 08**: A equipe de Operações quer identificar pedidos que ainda **não foram atribuídos a um entregador** e foram pagos com **PIX ou Cartão de Crédito**. Retorne o ID do pedido, o status, a forma de pagamento e o ID do entregador. Ordene pela `data_hora_pedido` **decrescente** e limite a **15 linhas**.

```sql
SELECT 
    pedido_id,
    status,
    forma_pagamento,
    entregador_id
FROM `unipds-503513.entregaja.pedidos`
WHERE entregador_id IS NULL
    AND (forma_pagamento = 'PIX' OR forma_pagamento = 'Cartão de Crédito')
ORDER BY data_hora_pedido DESC
LIMIT 15;
```

> ⚠️ **Atenção aos parênteses no `OR`:** sem eles, a lógica muda. A regra do "AND + OR" exige agrupar o `OR` para garantir que o filtro seja `entregador_id nulo` **E** (uma das duas formas de pagamento).
>
> 💡 Também repare: para checar valores nulos, use `IS NULL` — **nunca** `= NULL`.

---
* **Exercício 09**: O time de Parcerias quer os **restaurantes com taxa de entrega gratuita OU com tempo médio de preparo abaixo de 25 minutos**, para uma vitrine de "Restaurantes Ágeis". Retorne o ID, o nome, a categoria, a taxa de entrega e o tempo médio, **ordenados por tempo médio crescente**. Limite a **10 resultados**.

```sql
SELECT 
    restaurante_id,
    nome,
    categoria,
    taxa_entrega,
    tempo_medio_min
FROM `unipds-503513.entregaja.restaurantes`
WHERE taxa_entrega = 0 OR tempo_medio_min < 25
ORDER BY tempo_medio_min ASC
LIMIT 10;
```

> 💡 O `OR` retorna linhas onde **pelo menos uma** das condições é verdadeira — perfeito para "vitrines" que combinam critérios independentes.

---
* **Exercício 10**: O time de Financeiro quer calcular o **valor final** da taxa de entrega após o desconto do cupom (considerando o cupom como **percentual de desconto**), somente dos pedidos onde a taxa original era **maior que zero**. Traga o ID do pedido, a taxa original, o cupom e uma coluna `taxa_final` **arredondada em 2 casas decimais**. Classifique também com `CASE` uma coluna `faixa_desconto`:
  - Cupom igual a 0 → `'Sem desconto'`
  - Cupom entre 1 e 10 → `'Desconto pequeno'`
  - Cupom acima de 10 → `'Desconto alto'`

Ordene pela `taxa_final` **decrescente** e limite a **15 linhas**.

```sql
SELECT 
    pedido_id,
    taxa_entrega,
    cupom_desconto,
    ROUND(taxa_entrega - (cupom_desconto/100) * taxa_entrega, 2) AS taxa_final,
    CASE 
        WHEN cupom_desconto = 0 THEN 'Sem desconto'
        WHEN cupom_desconto BETWEEN 1 AND 10 THEN 'Desconto pequeno'
        ELSE 'Desconto alto'
    END AS faixa_desconto
FROM `unipds-503513.entregaja.pedidos`
WHERE taxa_entrega > 0
ORDER BY taxa_final DESC
LIMIT 15;
```

> 💡 Exercício que junta tudo: `WHERE` para filtrar, **aritmética** para calcular o desconto percentual, `ROUND` para evitar problemas de casas decimais do `FLOAT64` e `CASE` para categorizar o desconto — tudo na mesma query.

---

## 📌 Ordem correta das cláusulas

```sql
SELECT [DISTINCT] colunas       -- 1º: o que mostrar (aqui entram IF, CASE, COALESCE)
FROM tabela                     -- 2º: de onde vem
WHERE condição                  -- 3º: quais linhas manter
ORDER BY coluna [ASC|DESC]      -- 4º: como ordenar
LIMIT n;                        -- 5º: quantas linhas trazer
```
