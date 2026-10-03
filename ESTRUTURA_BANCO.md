# Seguro SUSEP

Projeto de análise de dados reais de seguros, com a base pública do SES (Sistema de Estatísticas da SUSEP), desenvolvido em MariaDB/SQL.

O objetivo foi montar o banco a partir dos arquivos da SUSEP, conferir a qualidade dos dados e responder perguntas de negócio com SQL, em três ramos: **Automóvel – Casco**, **Vida** e **Compreensivo Residencial**.

## Dados

- Fonte: base completa do SES (tabela `SES_UF2.csv`, prêmios e sinistros por empresa, ramo, mês e UF).
- Período: janeiro/2023 a julho/2026 (43 meses). **2026 tem só 7 meses.**
- 109.142 registros, 27 UFs.
- Conferência: o prêmio direto de Automóvel em 2024 no meu banco (R$ 35.633.163.776) bate com o portal da SUSEP (R$ 35.633.145.412).

## Estrutura do banco

Banco `susep_seguros`, com três tabelas:

* `uf2`: prêmios e sinistros por empresa, mês, ramo e UF
* `ramos`: código e nome dos 3 ramos
* `empresas`: código e nome das empresas (769)

Arquivos do projeto:

* `dll_s.sql`: criação do banco e das tabelas
* `dml_s.sql`: carga dos dados (lê `uf2_limpo.csv` e `empresas.csv`)
* `analises_susep.sql`: as consultas das perguntas abaixo

## Perguntas analisadas

1. Quanto cada ramo arrecada (prêmio direto) e paga em sinistros (sinistro direto), ano a ano?
2. Como a razão sinistro/prêmio de cada ramo evoluiu mês a mês, e em quais meses foi mais crítica?
3. Quais são as 10 maiores empresas de cada ramo?
4. Quantas empresas somam 80% do prêmio de cada ramo?

## Principais resultados

**Tamanho dos ramos (2024, ano completo)**

| Ramo | Prêmio direto | Sinistro direto |
|---|---|---|
| Automóvel | R$ 35,63 bi | R$ 25,30 bi |
| Vida | R$ 17,86 bi | R$ 1,06 bi |
| Residencial | R$ 6,00 bi | R$ 1,23 bi |

Automóvel é o maior ramo em prêmio e é também onde o sinistro pesa mais em relação ao prêmio.

**Razão sinistro/prêmio mês a mês**

Maio de 2024 em Automóvel foi o pior mês da série: 96,16, contra 66 a 72 nos meses vizinhos. Isso coincide com as enchentes no Rio Grande do Sul. Olhando só o RS, a razão do estado em maio de 2024 foi 5,17.

Meses mais críticos de cada ramo (3 maiores razões):

| Ramo | 1º | 2º | 3º |
|---|---|---|---|
| Auto | 05/2024 (96,16) | 01/2025 (79,19) | 01/2026 (79,04) |
| Resid | 11/2023 (33,98) | 10/2023 (33,46) | 01/2024 (31,87) |
| Vida | 03/2023 (8,29) | 05/2023 (7,71) | 07/2024 (7,46) |

**Concentração de mercado (2023 a jul/2026)**

| Ramo | Empresas no ramo | Empresas que somam 80% do prêmio |
|---|---|---|
| Vida | 65 | 5 |
| Automóvel | 56 | 7 |
| Residencial | 61 | 8 |

Em Automóvel, a maior empresa por prêmio é o código 05886 (R$ 31,22 bi no período), seguida de 06190 e 05312.

## Limitações

* **A razão sinistro/prêmio é uma aproximação.** Calculo sinistro direto ÷ prêmio direto × 100. A sinistralidade oficial da SUSEP usa outros conceitos (sinistro ocorrido ÷ prêmio ganho): para Automóvel em 2024, o portal mostra 61% e a minha razão dá 71%. Por isso uso a razão para comparar períodos dentro do mesmo ramo, e não como a sinistralidade do mercado.
* **A tabela não tem sinistro retido.** A coluna `prem_ret_liq` é uma cópia de prêmio retido, então foi descartada. `salvados` e `recuperacao` são zero em todo o período e também foram descartadas.
* **Anomalia nos dados:** a Allianz (05177) em Automóvel, de janeiro a agosto de 2023, tem valores de sinistro por UF incompatíveis com o prêmio de cada estado. O total nacional da empresa parece coerente. Mantive as linhas e marquei com `flag_anomalia_uf = 1` (216 linhas). Análises por estado em Automóvel devem excluir essas linhas. A causa não foi determinada.
* Valores em reais não foram corrigidos pela inflação.
* A base é agregada por empresa, ramo e UF: não há clientes nem apólices individuais.

## SQL utilizado

* `INNER JOIN`
* `GROUP BY`
* `SUM` e `ROUND`
* `CASE WHEN`
* `LEFT` e `RIGHT` para separar ano e mês
* CTEs (`WITH`)
* Funções de janela: `ROW_NUMBER`, `SUM() OVER`

## Sobre o uso de IA

Usei IA (ChatGPT e Claude) como guia durante o projeto: para entender a estrutura dos arquivos da SUSEP, conferir os dados e discutir como interpretar os resultados. As consultas das perguntas acima foram escritas por mim, com correções apontadas durante a revisão. A investigação de qualidade dos dados (dicionário de colunas, anomalia da Allianz) foi feita com orientação de IA, e conferi os números contra o portal da SUSEP.

## Próximos passos

* Crescimento do prêmio de um ano para o outro (comparando jan–jul de cada ano)
* Razão por UF em Automóvel, com o prêmio ao lado
* O caso do RS em 2024: evento pontual ou tendência?
