<!--
RASCUNHO. Antes de publicar:
1. Preencha a seção "Sobre o uso de IA" (marcada com [PREENCHER]).
2. Explique de onde vêm os arquivos CSV (marcado com [PREENCHER]).
3. Resolva os comentários "CONFERIR" (não aparecem quando o README é aberto no GitHub).
4. Reescreva os trechos "O que mostra" com suas palavras.
5. Renomeie dll_s.sql para ddl_s.sql (o README já usa o nome certo).
-->

# Seguro SUSEP

Projeto de análise de dados reais de seguros no Brasil, feito em MariaDB/SQL, com a base pública do SES (Sistema de Estatísticas da SUSEP).

Montei o banco a partir dos arquivos da SUSEP, conferi se os dados fazem sentido e respondi perguntas que um gestor do setor poderia ter sobre três ramos: **Automóvel – Casco**, **Vida** e **Compreensivo Residencial**.

## O que descobri

- **Automóvel** é o maior ramo em prêmio. No mesmo período (janeiro a julho), a razão sinistro/prêmio foi de 63,5% em 2023 para 74,3% em 2026, com queda em 2025. Parte do salto de 2024 vem do Rio Grande do Sul (enchentes).
- **Residencial e Vida:** o prêmio cresce e a razão cai (Residencial de 21,3% para 18,5%; Vida de 6,8% para 5,5%, em janeiro a julho).
- **Poucas empresas concentram o mercado:** de 5 a 8 empresas somam 80% do prêmio em cada ramo.
- **Estados em Automóvel:** o Amapá piora a cada ano e passa de 100% em 2025, mas com prêmio pequeno, então trato como indício. O Rio Grande do Sul teve um pico em 2024 e caiu em 2025.
- **Dados por estado da Allianz em 2023 não são confiáveis.** Sinalizei essas linhas e deixei fora das análises por estado de Automóvel.

## Sobre os dados e o período

- Fonte: base do SES, tabela de prêmios e sinistros por empresa, ramo, mês e estado (UF), só com os três ramos acima.
<!-- CONFERIR: se a base tem outros ramos e você filtrou, diga "filtrei três ramos". -->
- Período: janeiro de 2023 a julho de 2026. **2026 tem só sete meses**, então quando comparo anos uso o mesmo período (janeiro a julho) ou deixo 2026 de fora.
- 109.142 registros, 27 UFs (26 estados e o Distrito Federal), 769 empresas no cadastro.
- Os valores estão em reais correntes, **sem correção pela inflação**.
- Conferência: o prêmio direto de Automóvel em 2024 no meu banco (R$ 35.633.163.776) é praticamente igual ao do portal da SUSEP (R$ 35.633.145.412), uma diferença de cerca de R$ 18 mil.

## Banco de dados

Banco `susep_seguros`, com três tabelas: `uf2` (prêmios e sinistros), `ramos` e `empresas`.

Os detalhes das tabelas e como recriar o banco estão em [ESTRUTURA_BANCO.md](ESTRUTURA_BANCO.md). As consultas estão em `analise_susep.sql`.

## Como ler os resultados

- **Prêmio direto:** o que as seguradoras arrecadam dos clientes.
- **Sinistro direto:** o valor da coluna `sin_dir`. A documentação da SUSEP diz só "Sinistros Diretos", então não sei se é sinistro pago, avisado ou ocorrido.
- **Razão sinistro/prêmio:** sinistro ÷ prêmio × 100. Se a razão é 70, para cada R$ 100 de prêmio apareceram R$ 70 de sinistro.

Essa razão é uma aproximação. **Não é a sinistralidade oficial da SUSEP**, que usa outros conceitos (para Automóvel em 2024, o portal mostra 61% e a minha razão dá 71%). Por isso uso a razão para comparar períodos dentro do mesmo ramo, e não para dizer qual é a sinistralidade do mercado.

---

## BLOCO A: onde está o dinheiro?

### Pergunta 1: quanto cada ramo arrecada e paga em sinistros, e a razão mudou de um ano para o outro?

**1A. Anos completos (2023 a 2025), valores em R$ bilhões.** Serve para ver o tamanho de cada ramo. Deixei 2026 de fora porque só tem janeiro a julho.

| Ramo | Ano | Prêmio direto | Sinistro direto | Razão |
|---|---|---|---|---|
| Auto | 2023 | 36,72 | 22,86 | 62,24% |
| Auto | 2024 | 35,63 | 25,30 | 70,99% |
| Auto | 2025 | 37,49 | 26,01 | 69,38% |
| Resid | 2023 | 5,15 | 1,22 | 23,73% |
| Resid | 2024 | 6,00 | 1,23 | 20,45% |
| Resid | 2025 | 6,67 | 1,32 | 19,85% |
| Vida | 2023 | 14,71 | 0,93 | 6,29% |
| Vida | 2024 | 17,86 | 1,06 | 5,93% |
| Vida | 2025 | 20,37 | 1,09 | 5,33% |

**1B. Razão no mesmo período (janeiro a julho de todos os anos).** Serve para comparar a razão entre anos, incluindo 2026.

| Ramo | 2023 | 2024 | 2025 | 2026 |
|---|---|---|---|---|
| Auto | 63,53% | 73,09% | 70,75% | 74,31% |
| Resid | 21,32% | 21,83% | 18,96% | 18,48% |
| Vida | 6,79% | 6,14% | 5,60% | 5,47% |

**O que mostra:**
- **Automóvel** é o maior ramo em prêmio. A razão subiu de 2023 para 2024, caiu um pouco em 2025 e subiu de novo em 2026. Parte da subida de 2024 pode vir do Rio Grande do Sul (veja a pergunta 7).
- **Residencial:** a razão ficou perto de 21% até 2024 e caiu a partir de 2025.
- **Vida:** a razão cai todo ano, mas quase parou entre 2025 e 2026.

**Cuidado:** a razão de Vida é muito baixa e não sei dizer o que o sinistro direto captura nesse ramo. Por isso comparo cada ramo com ele mesmo ao longo do tempo, e não os ramos entre si.

### Pergunta 2: como a razão evoluiu mês a mês, e em quais meses foi mais crítica?

Os 3 meses com a razão mais alta de cada ramo:

| Ramo | 1º | 2º | 3º |
|---|---|---|---|
| Auto | 05/2024 (96,16%) | 01/2025 (79,19%) | 01/2026 (79,04%) |
| Resid | 11/2023 (33,98%) | 10/2023 (33,46%) | 01/2024 (31,87%) |
| Vida | 03/2023 (8,29%) | 05/2023 (7,71%) | 07/2024 (7,46%) |

**O que mostra:** o pior mês de Automóvel, maio de 2024, destoa dos vizinhos (entre 66% e 72%). Esse mês coincide com as enchentes no Rio Grande do Sul (veja a pergunta 7). Os outros meses mais altos de Automóvel são janeiros.

**Cuidado:** a razão de um mês isolado oscila mais que a anual, e poucos anos de dados não bastam para falar em "época do ano" com segurança.

### Pergunta 3: quais são as maiores empresas de cada ramo?

As três maiores por prêmio direto no período (jan/2023 a jul/2026):

| Ramo | Código da empresa | Prêmio (R$ bi) | % do ramo |
|---|---|---|---|
| Auto | 05886 | 31,22 | 23,7% |
| Auto | 06190 | 20,58 | 15,6% |
| Auto | 05312 | 17,74 | 13,5% |
| Resid | 05886 | 4,33 | 19,8% |
| Resid | 05312 | 3,44 | 15,7% |
| Resid | 03476 | 3,32 | 15,2% |
| Vida | 06866 | 28,53 | 43,5% |
| Vida | 04367 | 9,76 | 14,9% |
| Vida | 05282 | 7,89 | 12,0% |

<!-- CONFERIR: a coluna "% do ramo", o prêmio em R$ bi e "05886 em 7º em Vida" não saem direto da consulta do arquivo. Troque os códigos pelos nomes (join com a tabela empresas). -->

**O que mostra:** em Vida, a líder tem quase metade do ramo, e a segunda tem um terço do tamanho dela. A empresa 05886 lidera Automóvel e Residencial e aparece em 7º lugar em Vida.

A consulta completa traz as 10 maiores de cada ramo.

### Pergunta 4: quantas empresas somam 80% do prêmio de cada ramo?

| Ramo | Empresas no ramo | Empresas que somam 80% |
|---|---|---|
| Vida | 65 | 5 |
| Automóvel | 56 | 7 |
| Residencial | 61 | 8 |

<!-- CONFERIR: a coluna "Empresas no ramo" não sai da consulta do arquivo. -->

**O que mostra:** nos três ramos, menos de 15% das empresas concentram 80% do prêmio. Vida é o mais concentrado.

**Cuidado:** "empresa" aqui é cada entidade que envia dados à SUSEP. Não juntei empresas do mesmo grupo econômico, o que deixaria o mercado ainda mais concentrado.

---

## BLOCO B: para onde o mercado cresce?

### Pergunta 5: o prêmio de cada ramo está crescendo de um ano para o outro?

Comparação de **janeiro a julho** em todos os anos, porque 2026 só tem esses meses.

| Ramo | 2023 | 2024 | 2025 | 2026 |
|---|---|---|---|---|
| Auto (R$ bi) | 21,31 | 20,26 | 21,17 | 21,75 |
| variação | – | −4,92% | +4,50% | +2,73% |
| Resid (R$ bi) | 2,77 | 3,46 | 3,73 | 4,02 |
| variação | – | +25,10% | +7,78% | +7,76% |
| Vida (R$ bi) | 7,91 | 9,93 | 11,21 | 12,65 |
| variação | – | +25,56% | +12,88% | +12,84% |

**O que mostra:**
- Automóvel ficou praticamente estável: cerca de +2% de 2023 a 2026, com queda em 2024.
- Residencial cresceu cerca de 45% no período e Vida cerca de 60%. Nos dois, o ritmo diminuiu depois de 2024.

**Cuidado:** os valores são nominais. Com a inflação descontada, o crescimento real é menor, e Automóvel provavelmente não cresceu em termos reais. Não consigo explicar com os dados a queda de Automóvel em 2024.

---

## BLOCO C: onde está o risco?

### Pergunta 6: em Automóvel, quais estados têm a razão mais alta, e eles pesam em volume?

**Sem a Allianz e sem 2026** (janeiro de 2023 a dezembro de 2025). Os 5 estados com a razão mais alta e dois de referência:

| Estado | Razão | Peso no prêmio de Auto |
|---|---|---|
| AP | 82,43% | 0,02% |
| RS | 81,24% | 6,51% |
| TO | 77,85% | 0,29% |
| RO | 74,58% | 0,26% |
| PI | 72,81% | 0,24% |
| SP (maior estado) | 61,94% | 43,99% |
| RN (menor razão) | 54,92% | 0,68% |

**O que mostra:**
- Os estados do topo, menos o RS, pesam menos de 0,3% do prêmio cada. Com pouco volume, um único sinistro grande muda bastante a razão.
- O RS é a exceção: a razão dele é quase igual à do AP (81,24% contra 82,43%) e ele pesa 6,5% do prêmio. Sem exigir um volume mínimo, o AP aparece como o pior estado, e o RS vem logo atrás.
- SP, MG, PR, RJ e RS somam cerca de 73% do prêmio.
- A razão fica entre 55% e 82% nos 27 estados.

**Cuidado:** a razão do RS inclui maio e junho de 2024 (veja a pergunta 7). Também não sei como a SUSEP atribui cada valor a um estado, então não dá para dizer que os motoristas de um estado "custam mais".

### Pergunta 7: o pior resultado de um estado em Automóvel é tendência ou evento pontual?

Razão sinistro/prêmio de Automóvel por ano, **sem a Allianz e sem 2026** (2026 só tem sete meses):

| Estado | 2023 | 2024 | 2025 | Prêmio por ano |
|---|---|---|---|---|
| AP (pior razão) | 63,88% | 78,74% | 100,07% | R$ 6,6 a 8,4 milhões |
| TO | 59,40% | 77,23% | 97,36% | R$ 92 a 94 milhões |
| RS | 60,29% | 107,89% | 76,20% | cerca de R$ 2,1 bilhões |
| SP | 62,20% | 61,19% | 62,42% | cerca de R$ 14 bilhões |

Escolhi esses estados depois de olhar os dados: o AP é o pior estado, o RS é o estado das enchentes, o SP é o maior estado e o TO tem o mesmo desenho do AP com mais volume. Não usei uma regra automática de escolha.

**O que mostra:**
- **RS:** sobe em 2024 e cai em 2025. O desenho é de **evento pontual**. A SUSEP publicou em julho de 2024 que a sinistralidade dos seguros de danos no país saltou de 42,1% em abril para 66,1% em maio, por causa da tragédia no sul ([nota da SUSEP](https://www.gov.br/susep/pt-br/central-de-conteudos/noticias/2024/julho/reflexo-da-tragedia-no-sul-sinistralidade-nos-seguros-de-danos-salta-em-maio-para-66-1)). Os dados do projeto mostram o pico, e a explicação vem dessa fonte externa.
- **AP e TO:** sobem nos três anos e passam de 97% em 2025, o desenho de **tendência**. Mas a maioria dos estados também subiu de 2023 para 2024. O que destaca o AP e o TO é 2025, quando mais da metade dos estados ficou entre 72% e 79%.
- **SP:** quase estável.

**Cuidado:** são três anos de dados. O prêmio do AP é pequeno, então poucos sinistros grandes mudam o número, e trato o AP como indício. Refiz a análise sem a Allianz em todos os anos, porque a marcação de anomalia só tirava essa empresa em parte de 2023, e o desenho se manteve.

---

## BLOCO D: dá para confiar nos números?

### Pergunta 8: em 2023, o resultado extremo de Sergipe em Automóvel está concentrado em poucos meses?

Todas as empresas somadas:

| Mês de 2023 | Prêmio (R$ mi) | Sinistro (R$ mi) | Razão |
|---|---|---|---|
| Março | 18,2 | **−4.153,7** | −22.875% |
| Os outros 11 meses | 15 a 18 | 5 a 12 | 29% a 68% |

**O que mostra:** o valor extremo está num mês só, março. Os outros meses têm valores normais. Um sinistro negativo de R$ 4,15 bilhões para um prêmio mensal de R$ 18 milhões não é plausível para um estado.

### Pergunta 9: os números por estado são confiáveis?

> *Nota: esta pergunta foi construída com apoio de IA. A estratégia de comparar o total nacional da empresa com o pior estado foi sugerida, e eu executei as consultas. Ainda estou estudando os detalhes das funções usadas.*

**O que encontrei:**
- Procurei linhas em que o sinistro, em valor absoluto, passa de R$ 50 milhões e de 20 vezes o prêmio daquele estado. Em toda a base, só uma combinação apareceu: **Allianz (05177), Automóvel, 2023**, com 20 linhas.
- Exemplo (março de 2023, só a Allianz): Mato Grosso com sinistro de +R$ 5,32 bi para prêmio de R$ 12 mi, e Sergipe com −R$ 4,16 bi para prêmio de R$ 2,6 mi. Os valores estão assim na fonte da SUSEP, conferi no arquivo original.
- O **total nacional** da empresa parece coerente: razão entre 68% e 109% nos 12 meses de 2023. O problema parece estar na distribuição por estado.
- De janeiro a agosto de 2023 a empresa tem sinistros negativos em vários estados. De setembro a dezembro de 2023, e em 2024 a 2026, não.

**O que fiz:** mantive as linhas e marquei com `flag_anomalia_uf = 1` o bloco inteiro da Allianz em Automóvel, de janeiro a agosto de 2023 (216 linhas), e não só as 20 mais extremas. Nas análises nacionais uso tudo, porque o total parece certo. Nas análises por estado de Automóvel, deixo a Allianz de fora.
<!-- CONFERIR: 216 = 27 UFs x 8 meses. Confirme que foi assim que marcou, e onde a coluna flag_anomalia_uf é criada (dml_s.sql ou ddl_s.sql). -->

**O que não sei:** a causa. Pode ser erro de envio, reclassificação ou uma regra de alocação por estado que eu desconheço.

**Limite:** o teste só pega distorções grandes. Erros menores podem ter passado.

---

## Limitações

- A razão sinistro/prêmio não é a sinistralidade oficial (explicado acima).
- A tabela não tem sinistro retido. A coluna `prem_ret_liq` é cópia de prêmio retido, então descartei. `salvados` e `recuperacao` são zero em todo o período e também foram descartadas.
- Não sei se `sin_dir` é sinistro pago, avisado ou ocorrido.
- A base é agregada por empresa, ramo e estado. Não tem clientes nem apólices individuais.
- O prêmio de Automóvel em 2024 no meu banco difere do portal em cerca de R$ 18 mil. Não investiguei a causa.
- Nas análises por estado de Automóvel, a Allianz fica de fora, então os valores em reais por estado ficam menores que os reais.

## SQL utilizado

- `CASE WHEN`, `GROUP BY`, `SUM`, `ROUND`, `LEFT` e `RIGHT` (todas as perguntas)
- CTEs com `WITH` (perguntas 2 a 7)
- Funções de janela: `ROW_NUMBER` (2, 3, 4), `SUM() OVER` (4), `LAG` (5)
- `CROSS JOIN` (6 e 7)
- `NULLIF`, `ABS` e `MAX` (9)

## Sobre o uso de IA

[PREENCHER, por etapa: quem definiu as perguntas, quem escreveu cada consulta, quem revisou, quem investigou a qualidade dos dados, quem escreveu o texto deste README. O que já sei:]

- A consulta da razão no mesmo período (1B), o teste sem a Allianz na pergunta 7 e a pergunta 9 foram feitos com apoio de IA.
- As outras consultas foram escritas por mim, com correções apontadas na revisão.
- A investigação de qualidade dos dados (dicionário de colunas e anomalia da Allianz) foi feita com orientação de IA, e conferi os números contra o portal da SUSEP.
- Usei ChatGPT e Claude.

## Como recriar o banco

[PREENCHER: de onde vêm os arquivos originais da SUSEP e o que fiz para chegar em `uf2_limpo.csv`.]

1. Rodar `ddl_s.sql` (cria o banco e as tabelas).
2. Rodar `dml_s.sql` na pasta onde estão `uf2_limpo.csv` e `empresas.csv` (carrega os dados).
3. Conferir: `SELECT COUNT(*) FROM uf2;` deve dar 109142.
