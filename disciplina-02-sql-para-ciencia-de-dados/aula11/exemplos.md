
# 1.2 LIMIT e DISTINCT: Refinando a Visualização

### Exemplo 1: Listar uma amostra de 5 entregadores cadastrados.

```sql
SELECT
  entregador_id,
  nome,
  data_inicio
FROM `unipds-503513.entregaja.entregadores`
ORDER BY data_inicio ASC
LIMIT 5;
```

### Exemplo 2: Listar todas as categorias de itens únicas.

```sql
SELECT
  DISTINCT categoria_item
FROM `unipds-503513.entregaja.itens`;
```

---

# 1.3 ORDER BY: Ordenando Resultados

### Exemplo 3: Listar entregadores ordenados pela data de início (mais recentes primeiro).

```sql
SELECT
  entregador_id,
  nome,
  data_inicio
FROM `unipds-503513.entregaja.entregadores`
ORDER BY data_inicio DESC, nome ASC;
```

### Exemplo 4: Listar itens ordenados alfabeticamente por categoria.

```sql
SELECT
  item_id,
  nome_item,
  categoria_item
FROM `unipds-503513.entregaja.itens`
ORDER BY 3;
```
