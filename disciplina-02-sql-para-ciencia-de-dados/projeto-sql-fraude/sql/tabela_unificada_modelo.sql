/* =====================================================================
   ANÁLISE DE FRAUDE EM TRANSAÇÕES — construção da tabela de modelagem
   Base: abt_fraude (150.000 linhas × 20 colunas), grão = 1 transação
   Dialeto: BigQuery (GoogleSQL / Standard SQL)
   ===================================================================== */

-- Ajuste o projeto e o dataset conforme o seu ambiente do BigQuery.
-- Todas as tabelas fonte (transacoes, scores_*, dim_*) devem estar no
-- mesmo dataset que a abt_fraude criada abaixo.


/* ---------------------------------------------------------------------
   0) CONSTRUÇÃO DA TABELA DE MODELAGEM (abt_fraude)
   Une as 4 tabelas no grão de transação e remove registros de teste.
   As dimensões (dim_paises, dim_categorias) não entram aqui — são usadas
   apenas para enriquecer a análise.
   --------------------------------------------------------------------- */
CREATE OR REPLACE TABLE `unipds-503513.projeto_fraude.abt_fraude` AS (
    SELECT
        cb.score_1,
        cb.score_2,
        fi.score_3,
        cb.score_4,
        cb.score_5,
        fi.score_6,
        t.pais,
        cb.score_7,
        t.produto,
        t.categoria_produto,
        mo.score_8,
        fi.score_9,
        fi.score_10,
        t.entrega_doc_1,
        t.entrega_doc_2,
        t.entrega_doc_3,
        t.data_compra,
        t.valor_compra,
        mo.score_fraude_modelo,
        mo.fraude
    FROM `unipds-503513.projeto_fraude.transacoes` t
    JOIN `unipds-503513.projeto_fraude.scores_comportamentais` cb ON cb.id_transacao = t.id_transacao
    JOIN `unipds-503513.projeto_fraude.scores_financeiros`     fi ON fi.id_transacao = t.id_transacao
    JOIN `unipds-503513.projeto_fraude.scores_modelo`          mo ON mo.id_transacao = t.id_transacao
    WHERE t.is_teste = 0      -- remove 200 transações de teste (150.200 -> 150.000)
);

-- Conferências de aceite
SELECT COUNT(*)                    AS linhas          FROM `unipds-503513.projeto_fraude.abt_fraude`;  -- 150000
SELECT ROUND(100.0*AVG(fraude), 3) AS taxa_fraude_pct FROM `unipds-503513.projeto_fraude.abt_fraude`;  -- 5.000
