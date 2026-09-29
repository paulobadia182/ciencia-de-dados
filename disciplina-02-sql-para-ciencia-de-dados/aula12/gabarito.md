# Exercícios da aula 12:

## Conteúdo:
- SELECT
- FROM
- DISTINCT
- LIMIT
- ORDER BY


### EXERCÍCIOS:


* **Exercício 01**: O time de CRM precisa de uma lista simples com o ID, nome e e-mail dos clientes para realizar uma verificação cadastral. A lista deve estar em **ordem alfabética por nome**, facilitando a busca manual.

```sql
SELECT 
    cliente_id,
    nome,
    email
FROM `unipds-503513.entregaja.clientes`
ORDER BY nome ASC;
```

> 💡 `ASC` (crescente) é o padrão do `ORDER BY` — poderia ser omitido, mas deixar explícito ajuda na leitura.

---
* **Exercício 02**: A equipe de Parcerias quer visualizar o ID, o nome, a categoria e a cidade de todos os restaurantes cadastrados na plataforma. Ordene o resultado **por cidade em ordem alfabética** e, dentro de cada cidade, **por nome do restaurante**.

```sql
SELECT 
    restaurante_id,
    nome,
    categoria,
    cidade
FROM `unipds-503513.entregaja.restaurantes`
ORDER BY cidade ASC, nome ASC;
```

> 💡 Ao separar colunas por vírgula no `ORDER BY`, criamos uma ordenação **hierárquica**: primeiro por cidade, depois pelos nomes dos restaurantes dentro de cada cidade.

---
* **Exercício 03**: A equipe de Operações de Entregas está planejando uma ação com a frota e precisa de um relatório inicial contendo as informações básicas dos entregadores cadastrados.

Escreva uma consulta SQL que selecione o ID do entregador, o nome, a cidade e o tipo de veículo. O resultado deve estar ordenado **por tipo de veículo (A→Z)** e, dentro de cada veículo, **pelo nome do entregador**.

```sql
SELECT 
    entregador_id,
    nome,
    cidade,
    veiculo
FROM `unipds-503513.entregaja.entregadores`
ORDER BY veiculo ASC, nome ASC;
```

---
* **Exercício 04**: O time de Financeiro precisa saber quais formas de pagamento já foram utilizadas pelos clientes nos pedidos da plataforma para atualizar o contrato com as credenciadoras de cartão.

Escreva uma consulta SQL que retorne todas as formas de pagamento únicas / sem repetição utilizadas, **em ordem alfabética**.

```sql
SELECT DISTINCT 
    forma_pagamento
FROM `unipds-503513.entregaja.pedidos`
ORDER BY forma_pagamento ASC;
```

> 💡 O `DISTINCT` remove duplicatas e o `ORDER BY` organiza as formas de pagamento únicas em ordem alfabética.

---
* **Exercício 05**: A equipe de Marketing e Categoria quer montar um banner promocional e precisa de 3 exemplos de categorias de itens do cardápio para ilustrar a campanha.

Escreva uma consulta que retorne uma lista com as categorias de itens sem duplicatas, **ordenadas em ordem alfabética decrescente (Z→A)**, limitando o resultado a apenas 3 linhas.

```sql
SELECT DISTINCT 
    categoria_item
FROM `unipds-503513.entregaja.itens`
ORDER BY categoria_item DESC
LIMIT 3;
```

> ⚠️ **Atenção à ordem das cláusulas:** `ORDER BY` vem **antes** do `LIMIT`. Isso é importante porque a base é ordenada primeiro e depois pegamos as 3 primeiras linhas — não o contrário!

---
* **Exercício 06**: O time de Operações quer identificar os pedidos mais demorados para investigar gargalos na entrega.

Escreva uma consulta que retorne o ID do pedido, a forma de pagamento e o tempo de entrega em minutos, **ordenado do maior para o menor tempo de entrega**, limitando a 10 resultados.

```sql
SELECT 
    pedido_id,
    forma_pagamento,
    tempo_entrega_min
FROM `unipds-503513.entregaja.pedidos`
ORDER BY tempo_entrega_min DESC
LIMIT 10;
```

> 💡 Usamos `DESC` (decrescente) para trazer os maiores tempos primeiro. Combinado com `LIMIT 10`, obtemos rapidamente o "TOP 10" das entregas mais lentas.

---
* **Exercício 07**: O time de Cadastro quer identificar os clientes mais jovens da base para uma campanha voltada ao público jovem.

Escreva uma consulta que retorne o ID, o nome e a idade dos clientes, **ordenados por idade em ordem crescente**, limitando a 5 resultados.

```sql
SELECT 
    cliente_id,
    nome,
    idade
FROM `unipds-503513.entregaja.clientes`
ORDER BY idade ASC
LIMIT 5;
```

> 💡 Padrão comum de "TOP N": `ORDER BY` + `LIMIT` juntos. Aqui pegamos os 5 clientes mais jovens.

---

## 📝 Resumo — ORDER BY

| Palavra-chave | Significado | Exemplo |
|---------------|-------------|---------|
| `ASC` | Ordem crescente (padrão) | `ORDER BY nome ASC` |
| `DESC` | Ordem decrescente | `ORDER BY idade DESC` |
| Múltiplas colunas | Ordenação hierárquica | `ORDER BY cidade, nome` |

## 📌 Ordem correta das cláusulas

```sql
SELECT [DISTINCT] colunas
FROM tabela
ORDER BY coluna [ASC|DESC]
LIMIT n;
```
