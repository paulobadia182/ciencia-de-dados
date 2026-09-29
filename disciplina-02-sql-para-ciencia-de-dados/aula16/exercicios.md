# Exercícios da aula 16:

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


* **Exercício 01**: O time de CRM quer lançar uma campanha exclusiva para clientes fiéis. Precisa da lista de clientes do plano **Premium** com **mais de 60 anos**, mostrando ID, nome, idade e cidade, **ordenados por idade em ordem decrescente**.

---
* **Exercício 02**: A equipe de Operações está avaliando os melhores pedidos de referência para treinamento de novos entregadores. Quer visualizar pedidos com **status Concluído** e **tempo de entrega menor ou igual a 25 minutos**, exibindo o ID do pedido, o tempo de entrega e a forma de pagamento, **ordenados do menor para o maior tempo**, limitados a **10 resultados**.

---
* **Exercício 03**: O time Financeiro precisa identificar itens de pedido com **valor total** (quantidade × preço unitário) **acima de 200 reais**. Traga o ID do item do pedido, a quantidade, o preço unitário e uma coluna calculada chamada `valor_total`, **ordenada do maior para o menor valor total**, limitada a **15 resultados**.

---
* **Exercício 04**: A equipe de Marketing quer descobrir as **cidades únicas** onde há clientes do plano **Grátis** da região **Sudeste**, para focar ações de conversão para Premium. Ordene alfabeticamente.

---
* **Exercício 05**: O time de BI quer classificar os pedidos por **duração da entrega** para um dashboard. Crie uma consulta que retorne o ID do pedido, o tempo de entrega em minutos e uma coluna `categoria_entrega` com as seguintes regras:
  - Até 20 minutos → `'Rápida'`
  - De 21 a 45 minutos → `'Normal'`
  - Acima de 45 minutos → `'Lenta'`

Limite o resultado a **20 linhas** e ordene por `tempo_entrega_min` **crescente**.

---
* **Exercício 06**: O time de Cadastro quer marcar cada cliente como **maior ou menor de idade** (para revisão de política de cadastro). Retorne o ID, nome, idade e uma coluna `situacao` que mostre `'Maior de idade'` se a idade for **maior ou igual a 18**, e `'Menor de idade'` caso contrário. **Use IF.** Limite a **15 linhas**.

---
* **Exercício 07**: O time de Operações vai gerar um relatório com o tempo de entrega dos pedidos. Como os pedidos **cancelados** ficam com `tempo_entrega_min` **NULL**, o time quer que esses casos apareçam como **0** no relatório. Traga o ID do pedido, o status e uma coluna `tempo_entrega` que use `COALESCE` para substituir os nulos por `0`. Ordene por `tempo_entrega` **crescente** e limite a **15 linhas**.

---
* **Exercício 08**: A equipe de Operações quer identificar pedidos que ainda **não foram atribuídos a um entregador** e foram pagos com **PIX ou Cartão de Crédito**. Retorne o ID do pedido, o status, a forma de pagamento e o ID do entregador. Ordene pela `data_hora_pedido` **decrescente** e limite a **15 linhas**.

---
* **Exercício 09**: O time de Parcerias quer os **restaurantes com taxa de entrega gratuita OU com tempo médio de preparo abaixo de 25 minutos**, para uma vitrine de "Restaurantes Ágeis". Retorne o ID, o nome, a categoria, a taxa de entrega e o tempo médio, **ordenados por tempo médio crescente**. Limite a **10 resultados**.

---
* **Exercício 10**: O time de Financeiro quer calcular o **valor final** da taxa de entrega após o desconto do cupom (considerando o cupom como **percentual de desconto**), somente dos pedidos onde a taxa original era **maior que zero**. Traga o ID do pedido, a taxa original, o cupom e uma coluna `taxa_final` **arredondada em 2 casas decimais**. Classifique também com `CASE` uma coluna `faixa_desconto`:
  - Cupom igual a 0 → `'Sem desconto'`
  - Cupom entre 1 e 10 → `'Desconto pequeno'`
  - Cupom acima de 10 → `'Desconto alto'`

Ordene pela `taxa_final` **decrescente** e limite a **15 linhas**.
