# Medidas DAX do relatório SUSEP

Medidas do relatório do Power BI sobre os dados SES/SUSEP (Automóvel, Vida e Residencial, jan/2023 a jul/2026).

Todas as fórmulas foram escritas por mim. Em alguns momentos pedi ajuda de IA para entender o que cada comando faz e quando usá-lo.

Cada medida tem a pergunta que responde, como funciona e a consulta equivalente no `analise_susep.sql`, que calcula o mesmo indicador em SQL. Só o Prêmio Direto teve a conferência feita por mim contra o README.

## Medidas-base

### Prêmio Direto
```dax
Prêmio Direto = SUM(uf2_limpo[premio_dir])
```
- **Responde:** quanto as seguradoras arrecadaram em prêmio no recorte selecionado.
- **Como funciona:** soma a coluna `premio_dir`, respeitando os filtros da página (ramo, ano, empresa).
- **Consulta equivalente em SQL:** 1A, coluna `premio_direto_bi`.
- **Conferi:** os totais de prêmio por ramo bateram com os do README (Auto Casco: R$ 131,60 bi).

### Sinistro Direto
```dax
Sinistro Direto = SUM(uf2_limpo[sin_dir])
```
- **Responde:** quanto as seguradoras pagaram em sinistros no recorte selecionado.
- **Como funciona:** soma a coluna `sin_dir`, com os mesmos filtros do Prêmio Direto.
- **Consulta equivalente em SQL:** 1A, coluna `sin_direto_bi`.

## Medidas derivadas

### Razão S/P
```dax
Razão S/P = DIVIDE([Sinistro Direto], [Prêmio Direto])
```
- **Responde:** de cada real recebido em prêmio, quanto volta em sinistro. Não é a sinistralidade oficial da SUSEP: serve para comparar anos, estados e empresas entre si.
- **Como funciona:** divide a soma do sinistro pela soma do prêmio, e não a média das razões de cada linha. O `DIVIDE` devolve vazio, e não erro, quando o prêmio é zero.
- **Consultas equivalentes em SQL:** 1B (jan a jul por ano, coluna `razao_jan_jul`), 6 (por estado, coluna `razao`) e a segunda consulta da pergunta 7 (AP, RS, SP e TO por ano).

### Peso UF
```dax
Peso UF = DIVIDE([Prêmio Direto], CALCULATE([Prêmio Direto], ALL(uf2_limpo[uf])))
```
- **Responde:** quanto cada estado pesa no prêmio do recorte.
- **Como funciona:** divide o prêmio do estado pelo prêmio de todos os estados. O `ALL` na coluna `uf` tira só o filtro de estado. Os outros filtros (ramo, ano, sem Allianz) continuam valendo.
- **Consulta equivalente em SQL:** 6, coluna `peso_estado`.

### Participação %
```dax
Participação % = DIVIDE([Prêmio Direto], CALCULATE([Prêmio Direto], ALL(empresas)))
```
- **Responde:** quanto cada empresa pesa no prêmio do recorte.
- **Como funciona:** divide o prêmio da empresa pelo prêmio de todas as empresas. O `ALL` na tabela `empresas` tira o filtro de empresa.
- **Cuidado:** se o filtro "não é 05177" estiver em uma coluna da tabela `empresas`, o `ALL(empresas)` também o remove, e o denominador volta a incluir a Allianz.
- **Consulta equivalente em SQL:** 3, coluna `porcentagem_ramo` (inclui a Allianz).

## Ranking

### Prêmio Top 5
```dax
Prêmio Top 5 = SUMX(TOPN(5, VALUES(uf2_limpo[empresa]), [Prêmio Direto]), [Prêmio Direto])
```
- **Responde:** quanto as 5 maiores seguradoras arrecadaram no recorte.
- **Como funciona:** o `TOPN` devolve as 5 empresas de maior Prêmio Direto. O `SUMX` percorre essas 5 e soma o Prêmio Direto de cada uma.
- **Consulta equivalente em SQL:** 3, soma do prêmio das 5 primeiras posições do Auto.

### Concentração Top 5
```dax
Concentração Top 5 = DIVIDE([Prêmio Top 5], [Prêmio Direto])
```
- **Responde:** que parte do prêmio do ramo fica com as 5 maiores seguradoras. Quanto maior, mais concentrado é o mercado.
- **Como funciona:** divide o prêmio das 5 maiores empresas pelo prêmio total do recorte.
- **Consulta equivalente em SQL:** 3, soma de `porcentagem_ramo` das 5 primeiras do Auto (a soma dos percentuais arredondados pode diferir em 0,1 ponto).

## Tempo

### Prêmio Ano Anterior
```dax
Prêmio Ano Anterior = CALCULATE([Prêmio Direto], SAMEPERIODLASTYEAR(calendario[Date]))
```
- **Responde:** quanto foi o prêmio no mesmo período do ano anterior.
- **Como funciona:** o `SAMEPERIODLASTYEAR` devolve as mesmas datas um ano antes, e o `CALCULATE` calcula o Prêmio Direto nelas. Precisa da tabela calendário marcada como tabela de datas.
- **Cuidado:** 2026 só tem 7 meses. Para comparar anos, filtrar jan a jul em todos eles, como na consulta 5.
- **Consulta equivalente em SQL:** 5, coluna `premio_ano_anterior`.

### Variação %
```dax
Variação % = DIVIDE([Prêmio Direto] - [Prêmio Ano Anterior], [Prêmio Ano Anterior])
```
- **Responde:** quanto o prêmio cresceu ou caiu em relação ao mesmo período do ano anterior.
- **Como funciona:** divide a diferença entre o prêmio atual e o do ano anterior pelo prêmio do ano anterior.
- **Consulta equivalente em SQL:** 5, coluna `variacao_percentual`.
