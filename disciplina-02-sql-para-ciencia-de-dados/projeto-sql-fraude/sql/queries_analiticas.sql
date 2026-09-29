/* =====================================================================
   ANÁLISE DE FRAUDE EM TRANSAÇÕES — queries analíticas
   Base: abt_fraude (150.000 linhas × 20 colunas), grão = 1 transação
   Dialeto: BigQuery (GoogleSQL / Standard SQL)
   Notas de portabilidade ao final do arquivo.
   ===================================================================== */


/* ---------------------------------------------------------------------
   1) PANORAMA — tamanho do problema
   Total de transações, nº de fraudes, taxa (%) e valor financeiro exposto.
   AVG(fraude) funciona como taxa porque fraude é 0/1.
   --------------------------------------------------------------------- */
SELECT
    COUNT(*)                                                          AS total,
    SUM(fraude)                                                       AS fraudes,
    ROUND(100.0*AVG(fraude), 3)                                       AS taxa_fraude_pct,
    ROUND(SUM(CASE WHEN fraude = 1 THEN valor_compra ELSE 0 END), 2)  AS valor_exposto,
    ROUND(AVG(CASE WHEN fraude = 1 THEN valor_compra END), 2)         AS ticket_medio_fraude,
    ROUND(AVG(valor_compra), 2)                                       AS ticket_medio_geral
FROM `unipds-503513.projeto_fraude.abt_fraude`;
-- Resultado: 150000 | 7500 | 5.000% | R$547.271,12 | R$72,97 | R$43,52


/* ---------------------------------------------------------------------
   2) FRAUDE POR PAÍS  (JOIN com dimensão + piso de volume)
   O HAVING descarta praças pequenas demais para uma taxa confiável.
   --------------------------------------------------------------------- */
SELECT
    p.nome_pais,
    p.regiao,
    COUNT(*)                       AS transacoes,
    ROUND(100.0*AVG(a.fraude), 2)  AS taxa_fraude_pct
FROM `unipds-503513.projeto_fraude.abt_fraude` a
JOIN `unipds-503513.projeto_fraude.dim_paises` p ON p.sigla_pais = a.pais
GROUP BY p.nome_pais, p.regiao
HAVING COUNT(*) >= 1000
ORDER BY taxa_fraude_pct DESC;
-- BR 5,52% (111.628) | AR 3,69% (31.964) | US 3,08% (2.273) | UY 0,98% (2.967)

-- Versão sem a dimensão (apenas com a sigla), caso dim_paises não esteja disponível:
SELECT
    pais,
    COUNT(*)                     AS transacoes,
    ROUND(100.0*AVG(fraude), 2)  AS taxa_fraude_pct
FROM `unipds-503513.projeto_fraude.abt_fraude`
GROUP BY pais
HAVING COUNT(*) >= 1000
ORDER BY taxa_fraude_pct DESC;


/* ---------------------------------------------------------------------
   3) RISCO CADASTRADO vs. REALIDADE  (JOIN com dim_categorias)
   Confronta o nivel_risco_categoria pré-cadastrado com a taxa observada.
   --------------------------------------------------------------------- */
SELECT
    c.nivel_risco_categoria,
    COUNT(*)                       AS transacoes,
    ROUND(100.0*AVG(a.fraude), 2)  AS taxa_fraude_pct
FROM `unipds-503513.projeto_fraude.abt_fraude` a
JOIN `unipds-503513.projeto_fraude.dim_categorias` c ON c.id_categoria = a.categoria_produto
GROUP BY c.nivel_risco_categoria
ORDER BY taxa_fraude_pct DESC;


/* ---------------------------------------------------------------------
   4) FRAUDE POR FAIXA DE VALOR  (CASE WHEN)
   Transforma o valor contínuo em faixas comparáveis.
   --------------------------------------------------------------------- */

WITH base AS (
  SELECT
    CASE
      WHEN valor_compra < 100 THEN '1) ate 100'
      WHEN valor_compra < 500 THEN '2) 100-500'
      WHEN valor_compra >= 500 THEN '3) acima de 500'
      ELSE                          '4) valor NULL'   -- separa nulos em vez de escondê-los na faixa 3
    END AS faixa_valor,
    fraude,
    valor_compra
  FROM `unipds-503513.capstone_fraude.abt_fraude`
)

SELECT
  faixa_valor,
  COUNT(*)     AS transacoes,
  SUM(fraude)  AS fraudes,
  ROUND(100.0 * SUM(fraude) / SUM(SUM(fraude)) OVER (), 1) AS pct_dos_casos,
  ROUND(SUM(CASE WHEN fraude = 1 THEN valor_compra ELSE 0 END), 2) AS valor_exposto,
  ROUND(100.0 * SUM(CASE WHEN fraude = 1 THEN valor_compra ELSE 0 END)
        / SUM(SUM(CASE WHEN fraude = 1 THEN valor_compra ELSE 0 END)) OVER (), 1)   AS pct_do_valor,
  ROUND(SAFE_DIVIDE(
          SUM(CASE WHEN fraude = 1 THEN valor_compra ELSE 0 END),
          SUM(fraude)
        ), 2)   AS perda_media_por_fraude
FROM base
GROUP BY faixa_valor
ORDER BY faixa_valor;



/* ---------------------------------------------------------------------
   5) O SCORE DO MODELO SEPARA FRAUDE?  (NTILE — função de janela)
   Divide a base em 10 faixas iguais por score e mede a taxa em cada uma.
   Espera-se que a taxa cresça de forma consistente do decil 1 ao 10.
   --------------------------------------------------------------------- */
WITH faixas AS (
    SELECT
        fraude,
        NTILE(10) OVER (ORDER BY score_fraude_modelo) AS decil
    FROM `unipds-503513.projeto_fraude.abt_fraude`
)
SELECT
    decil,
    COUNT(*)                     AS transacoes,
    ROUND(100.0*AVG(fraude), 2)  AS taxa_fraude_pct
FROM faixas
GROUP BY decil
ORDER BY decil;
-- 1:2,77  2:4,59  3:3,33  4:0,31  5:0,62  6:1,27  7:2,05  8:5,10  9:8,63  10:21,33
-- Leitura: separa bem só no topo (decil 10 ~= 4x a base); o meio nao e monotonico.


/* ---------------------------------------------------------------------
   6) CURVA DE CAPTURA ACUMULADA
   Ordenando a fila do maior score para o menor, quanto da fraude total
   é capturada ao revisar os X% de maior risco?
   --------------------------------------------------------------------- */
WITH faixas AS (
    SELECT
        fraude,
        NTILE(10) OVER (ORDER BY score_fraude_modelo DESC) AS decil_desc
    FROM `unipds-503513.projeto_fraude.abt_fraude`
),
por_decil AS (
    SELECT decil_desc, SUM(fraude) AS fraudes
    FROM faixas
    GROUP BY decil_desc
)
SELECT
    decil_desc                                                        AS decil_top,
    10 * decil_desc                                                   AS pct_fila_revisada,
    SUM(fraudes) OVER (ORDER BY decil_desc)                           AS fraudes_acumuladas,
    ROUND(100.0 * SUM(fraudes) OVER (ORDER BY decil_desc)
                / SUM(fraudes) OVER (), 1)                            AS pct_fraude_capturada
FROM por_decil
ORDER BY decil_desc;
-- 10% da fila -> 42,7% da fraude | 20% -> 59,9% | 30% -> 70,1% | 50% -> 76,8% | 100% -> 100%


/* ---------------------------------------------------------------------
   7) BÔNUS — FRAUDE POR MÊS  (série temporal)
   No BigQuery, DATE_TRUNC recebe a data primeiro e o intervalo como
   palavra-chave (MONTH), diferente do PostgreSQL.
   --------------------------------------------------------------------- */
SELECT
    DATE_TRUNC(data_compra, MONTH)  AS mes,
    COUNT(*)                        AS transacoes,
    ROUND(100.0*AVG(fraude), 2)     AS taxa_fraude_pct
FROM `unipds-503513.projeto_fraude.abt_fraude`
GROUP BY mes
ORDER BY mes;
-- 2020-03: 5,04% (76.961) | 2020-04: 4,96% (73.039) — sem sazonalidade nos 2 meses.


/* =====================================================================
   NOTAS DE PORTABILIDADE (partindo deste dialeto BigQuery)
   - Tabelas totalmente qualificadas em BigQuery: `projeto.dataset.tabela`
     entre crases (obrigatório quando o projeto tem hífen).
   - NTILE, ROUND, AVG, SUM, CASE, JOIN e GROUP BY funcionam igual nos
     principais bancos (PostgreSQL, MySQL 8+, SQL Server, Snowflake).
   - Ao adaptar para outros dialetos, o principal ajuste é DATE_TRUNC:
       * PostgreSQL:  DATE_TRUNC('month', data_compra)::date
       * MySQL:       DATE_FORMAT(data_compra, '%Y-%m-01')
       * SQLite:      strftime('%Y-%m', data_compra)
       * SQL Server:  DATEFROMPARTS(YEAR(data_compra), MONTH(data_compra), 1)
   ===================================================================== */
