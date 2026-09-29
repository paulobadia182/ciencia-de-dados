# Detecção de Fraude em Transações

Análise SQL de **150.000 transações** para mapear fatores de risco de fraude, avaliar o desempenho do modelo de score existente e desenhar uma fila de revisão priorizada.

> **Insight central:** revisar apenas os **30% de maior score** captura **70% de toda a fraude** — reduz a carga operacional em dois terços sem perder cobertura.

📄 Relatório completo (com gráficos e análise seção a seção): [`relatorios/relatorio_fraude.md`](relatorios/relatorio_fraude.md) · versão PDF: [`relatorios/relatorio_fraude.pdf`](relatorios/relatorio_fraude.pdf)
🎯 Apresentação executiva: [`apresentacao/insights_fraude.pptx`](apresentacao/insights_fraude.pptx)

---

## Contexto do problema

Uma operação de pagamentos precisa decidir **quais transações revisar manualmente** para conter fraude, sem inflar a fila de revisão e sem perder cobertura. Existe um modelo de score já em produção, mas ninguém validou se ele ordena risco de forma confiável ao longo de toda a base.

O projeto responde a três perguntas:

1. **Onde a fraude se concentra?** — quais atributos da transação (valor, país, período) mais elevam a probabilidade de fraude.
2. **O score do modelo é útil na operação?** — o quanto o score consegue separar transações fraudulentas das legítimas, faixa a faixa.
3. **Qual seria a fila de revisão ideal?** — como priorizar a revisão manual para maximizar captura de fraude por unidade de esforço.

---

## Principais achados

| # | Achado | Número | Ação recomendada |
|---|--------|--------|-------------------|
| 1 | **Valor do ticket é o sinal mais forte** | Compras > R$ 500 têm **14,9% de fraude** (3× a média) | Regra dura: revisão obrigatória acima de R$ 500 |
| 2 | **O score só separa bem no topo** | Decil 10 → **21,3% de fraude** (~4× a média); faixa intermediária é irregular | Usar score como fila de prioridade, não como corte único |
| 3 | **70% da fraude em 30% da fila** | Revisar os 30% de maior score captura **70%** de toda a fraude | Concentrar esforço de revisão no terço superior |
| 4 | **Risco concentrado no Brasil** | BR: 5,5% de fraude e 74% do volume; UY: apenas 1,0% | Calibrar limiares por país |

### Onde está o risco ≠ onde está o dinheiro

A *taxa* de fraude sobe de forma monotônica com o valor, mas a *perda em reais* não acompanha esse ranking: ela se concentra na **faixa intermediária (R$ 100–500)**, que responde por ~43% de todo o valor exposto apesar de reunir só ~14% dos casos. Os casos, por sua vez, empilham-se na faixa de baixo ticket (~84% deles abaixo de R$ 100), onde a perda média por fraude é de apenas ~R$ 27.

| Faixa de valor | % dos casos de fraude | % do valor exposto | Valor exposto | Perda média / fraude |
|---|---:|---:|---:|---:|
| até R$ 100 | ~84% | ~31% | R$ 170 mil | ~R$ 27 |
| R$ 100–500 | ~14% | ~43% | R$ 233 mil | ~R$ 226 |
| acima de R$ 500 | ~2% | ~26% | R$ 144 mil | ~R$ 931 |

> Percentuais de casos reconstruídos a partir das taxas de fraude arredondadas — servem para dimensionar a divergência, não como número contábil exato.

**Leitura para priorização:** a regra dura acima de R$ 500 acerta o segmento de maior *taxa* e maior *perda por caso*, mas em reais totais ele é o menor dos três. A faixa **R$ 100–500** é onde o score/modelo tem a maior alavancagem por real evitado (mais dinheiro, volume grande demais para revisar tudo na mão). E a faixa de baixo ticket pede automação barata — vale investigar se essas microfraudes antecedem compras grandes do mesmo cartão (padrão de *card testing*).

**Recomendação de negócio:** montar uma fila de revisão priorizada pelo score, com regra dura para tickets altos e limiares por país. Direcionar o investimento em modelo para a faixa intermediária de valor, onde mora a maior exposição financeira. Em paralelo, abrir ciclo de recalibração para corrigir a faixa intermediária do score, onde o modelo hoje não ordena risco de forma confiável.

---

## Prints do relatório

<p align="center">
  <img src="assets/faixa.png" alt="Taxa de fraude por faixa de valor" width="48%" />
  <img src="assets/decis.png" alt="Taxa de fraude por decil de score" width="48%" />
</p>
<p align="center">
  <img src="assets/captura.png" alt="Captura acumulada de fraude por percentual da fila revisada" width="48%" />
  <img src="assets/pais.png" alt="Taxa de fraude por país" width="48%" />
</p>

---

## Estrutura do repositório

```
projeto-sql-fraude/
├── README.md                          ← você está aqui
├── orientacao_e_gabarito/
│   └── orientacoes_do_case.docx       ← enunciado original do case
├── sql/
│   ├── tabela_unificada_modelo.sql    ← ETL: constrói a abt_fraude
│   └── queries_analiticas.sql         ← queries de todas as seções do relatório
├── relatorios/
│   ├── relatorio_fraude.md            ← relatório final (Markdown, versionado)
│   └── relatorio_fraude.pdf           ← mesmo relatório em PDF
├── apresentacao/
│   └── insights_fraude.pptx           ← deck executivo com os achados
└── assets/                             ← gráficos usados no relatório
    ├── ticket.png · faixa.png · decis.png · captura.png · pais.png
```

---

## Dados

**Grão:** 1 linha por transação. **Volume:** 150.000 transações (após remoção de 200 registros de teste). **Rótulo:** coluna `fraude` binária (0/1), com prevalência de 5,0%.

A tabela de modelagem `abt_fraude` (150.000 × 20) é construída pela junção de 4 tabelas fonte no grão de transação:

| Tabela | Papel |
|--------|-------|
| `transacoes` | Atributos da compra (valor, país, produto, datas) |
| `scores_comportamentais` | Sinais de comportamento do cliente |
| `scores_financeiros` | Sinais financeiros (limite, histórico de pagamento) |
| `scores_modelo` | Score do modelo em produção + rótulo `fraude` |

Duas dimensões auxiliares (`dim_paises`, `dim_categorias`) enriquecem a análise sem entrar na ABT.

---

## Método

1. **ETL** — junção das 4 tabelas fonte no grão de transação, remoção de registros de teste (`is_teste = 1`). Resultado: `abt_fraude`.
2. **Panorama** — volume, prevalência de fraude e valor financeiro exposto.
3. **Análise univariada** — taxa de fraude por faixa de valor, país e período (mês), cruzada com a exposição financeira (valor em reais) de cada faixa.
4. **Avaliação do modelo** — segmentação por decis do score + curva de captura acumulada.
5. **Síntese e recomendações** — combinando fatores de risco e capacidade operacional.

**Convenção métrica:** taxa de fraude = `100 × AVG(fraude)` (funciona porque `fraude` é 0/1). Em segmentações, aplica-se **piso mínimo de 1.000 transações** por grupo para evitar taxas ruidosas em amostras pequenas — as queries usam `HAVING COUNT(*) >= 1000`.

**Por que taxa e não contagem?** Como fraude é uma classe rara (5%), contar valores absolutos favorece automaticamente os segmentos mais volumosos. A taxa isola o efeito do atributo — permite comparar, por exemplo, o Brasil (grande e arriscado) com o Uruguai (pequeno e seguro) em pé de igualdade. A exceção deliberada é a análise de exposição financeira, em que o interesse é justamente o **valor absoluto em reais** de cada faixa — por isso taxa e reais são reportados lado a lado.

**Nota de qualidade de dados:** a segmentação por faixa de valor usa um `CASE` com `ELSE` para a faixa mais alta; como `NULL < 500` não é verdadeiro em SQL, eventuais `valor_compra` nulos caem nessa faixa. Recomenda-se checar `COUNT(*) WHERE valor_compra IS NULL` e isolar nulos numa faixa própria antes de reportar a faixa "acima de R$ 500".

---

## Stack

- **SQL / BigQuery (GoogleSQL)** — construção da ABT e todas as análises. `sql/queries_analiticas.sql` traz notas de portabilidade para PostgreSQL, MySQL, SQLite e SQL Server.
- **Markdown + PDF** — relatório versionado ao lado do código, garantindo reprodutibilidade.
- **PowerPoint** — apresentação executiva dos insights.

---

## Como reproduzir

**Pré-requisitos:** acesso ao BigQuery (Console ou CLI `bq`) e as tabelas fonte listadas em [Dados](#dados) carregadas em um dataset do seu projeto. Ajuste `unipds-503513.projeto_fraude` nos scripts para o seu `projeto.dataset`.

**Via BigQuery Console:** abra cada arquivo em [`sql/`](sql/) e cole no editor de queries, na ordem abaixo.

**Via CLI (`bq`):**

```bash
# 1. Construir a tabela de modelagem
bq query --use_legacy_sql=false < sql/tabela_unificada_modelo.sql

# 2. Rodar as queries analíticas — cada seção do relatório aponta para a sua query
bq query --use_legacy_sql=false < sql/queries_analiticas.sql
```

Cada query em `queries_analiticas.sql` está comentada com a seção do relatório que ela alimenta e com o resultado esperado (contagens, taxas, tickets), servindo como teste de aceite implícito.

---

## Leia mais

- **Relatório completo** → [`relatorios/relatorio_fraude.md`](relatorios/relatorio_fraude.md)
- **Enunciado do case** → [`orientacao_e_gabarito/orientacoes_do_case.docx`](orientacao_e_gabarito/orientacoes_do_case.docx)
- **Apresentação executiva** → [`apresentacao/insights_fraude.pptx`](apresentacao/insights_fraude.pptx)
