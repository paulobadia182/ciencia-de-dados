# 1 SELECT e FROM: O Básico da Consulta

### Exemplo 1: Selecionar todas as colunas da tabela de restaurantes.

```sql
SELECT
    *
FROM
    `unipds-503513.entregaja.restaurantes`;
```

### Exemplo 2: Selecionar o nome e a cidade dos clientes.

```sql
SELECT
    nome,
    cidade
FROM
    `unipds-503513.entregaja.clientes`;
```

### Exemplo 3: Selecionar o nome e veículo dos entregadores

```sql
SELECT
    nome,
    cidade
FROM
    `unipds-503513.entregaja.entregadores`;
```