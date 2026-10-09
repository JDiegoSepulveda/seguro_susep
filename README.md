# Seguro SUSEP

Projeto de análise de dados reais de seguros no Brasil, feito em MariaDB/SQL, com a base pública do SES (Sistema de Estatísticas da SUSEP).

Montei o banco a partir dos arquivos da SUSEP, conferi se os dados fazem sentido e respondi perguntas que um gestor do setor poderia ter sobre três ramos: **Automóvel – Casco**, **Vida** e **Compreensivo Residencial**.

## Sobre os dados e o período

- Fonte: base completa do SES, tabela de prêmios e sinistros por empresa, ramo, mês e estado (UF).
- Período: janeiro de 2023 a julho de 2026. **2026 tem só sete meses**, então quando comparo anos uso o mesmo período (janeiro a julho) em todos.
- 109.142 registros, 27 estados, 769 empresas no cadastro.
- Os valores estão em reais correntes, **sem correção pela inflação**.
- Conferência: o prêmio direto de Automóvel em 2024 no meu banco (R$ 35.633.163.776) bate com o portal da SUSEP (R$ 35.633.145.412).

## Banco de dados

Banco `susep_seguros`, com três tabelas: `uf2` (prêmios e sinistros), `ramos` e `empresas`.

Os detalhes das tabelas e como recriar o banco estão em [ESTRUTURA_BANCO.md](ESTRUTURA_BANCO.md). As consultas estão em `analise_susep.sql`.

## Como ler os resultados

- **Prêmio direto:** o que as seguradoras arrecadam dos clientes.
- **Sinistro direto:** o que aparece como sinistro.
- **Razão sinistro/prêmio:** sinistro ÷ prêmio × 100. Se a razão é 70, para cada R$ 100 de prêmio apareceram R$ 70 de sinistro.

Essa razão é uma aproximação. **Não é a sinistralidade oficial da SUSEP**, que usa outros conceitos (para Automóvel em 2024, o portal mostra 61% e a minha razão dá 71%). Por isso uso a razão para comparar períodos dentro do mesmo ramo, não para dizer qual é a sinistralidade do mercado.

---

## BLOCO A: onde está o dinheiro?

### Pergunta 1: quanto cada ramo arrecada e paga em sinistros, ano a ano?

Valores em R$ bilhões.

| Ramo | Ano | Prêmio direto | Sinistro direto | Razão |
|---|---|---|---|---|
| Auto | 2023 | 36,72 | 22,86 | 62,24% |
| Auto | 2024 | 35,63 | 25,30 | 70,99% |
| Auto | 2025 | 37,49 | 26,01 | 69,38% |
| Auto | 2026 (jan–jul) | 21,75 | 16,16 | 74,31% |
| Resid | 2023 | 5,15 | 1,22 | 23,73% |
| Resid | 2024 | 6,00 | 1,23 | 20,45% |
| Resid | 2025 | 6,67 | 1,32 | 19,85% |
| Resid | 2026 (jan–jul) | 4,02 | 0,74 | 18,48% |
| Vida | 2023 | 14,71 | 0,93 | 6,29% |
| Vida | 2024 | 17,86 | 1,06 | 5,93% |
| Vida | 2025 | 20,37 | 1,09 | 5,33% |
| Vida | 2026 (jan–jul) | 12,65 | 0,69 | 5,47% |

**O que mostra:**
- Automóvel é o maior ramo em prêmio. O prêmio caiu em 2024 e subiu em 2025. A razão subiu de 62% (2023) para 74% (2026), ou seja, o sinistro pesa cada vez mais em relação ao que entra.
- Residencial: o prêmio cresceu e a razão caiu, de 24% para 18%.
- Vida: o prêmio cresceu, mas o ritmo diminuiu de 2024 para 2025. A razão fica perto de 5% a 6%.

**Cuidado:** a razão de Vida é muito baixa e não sei dizer o que o sinistro direto captura nesse ramo. Por isso comparo cada ramo com ele mesmo ao longo do tempo, e não os ramos entre si.

### Pergunta 2: como a razão evoluiu mês a mês, e em quais meses foi mais crítica?

Os 3 meses com a razão mais alta de cada ramo:

| Ramo | 1º | 2º | 3º |
|---|---|---|---|
| Auto | 05/2024 (96,16%) | 01/2025 (79,19%) | 01/2026 (79,04%) |
| Resid | 11/2023 (33,98%) | 10/2023 (33,46%) | 01/2024 (31,87%) |
| Vida | 03/2023 (8,29%) | 05/2023 (7,71%) | 07/2024 (7,46%) |

**O que mostra:** o pior mês de Automóvel, maio de 2024, destoa dos vizinhos (entre 66% e 72%). Esse mês coincide com as enchentes no Rio Grande do Sul (veja a pergunta 7). Os outros meses mais altos de Automóvel são janeiros.

**Cuidado:** a razão de um mês isolado oscila mais que a anual, e três anos de dados são poucos para falar em "época do ano" com segurança.

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

**O que mostra:** em Vida, a líder tem quase metade do ramo, e a segunda tem um terço do tamanho dela. A empresa 05886 lidera Automóvel e Residencial e aparece em 7º lugar em Vida.

A consulta completa traz as 10 maiores de cada ramo. Os nomes das empresas vêm da tabela `empresas` (cadastro da SUSEP), e aqui mostro os códigos.

### Pergunta 4: quantas empresas somam 80% do prêmio de cada ramo?

| Ramo | Empresas no ramo | Empresas que somam 80% |
|---|---|---|
| Vida | 65 | 5 |
| Automóvel | 56 | 7 |
| Residencial | 61 | 8 |

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
- Residencial cresceu cerca de 45% no período e Vida cerca de 60%. Nos dois, o ritmo desacelerou depois de 2024.

**Cuidado:** os valores são nominais. Com a inflação descontada, o crescimento real é menor, e Automóvel provavelmente não cresceu em termos reais. Não consigo explicar com os dados a queda de Automóvel em 2024.

---

## BLOCO C: onde está o risco?

### Pergunta 6: em Automóvel, quais estados têm a razão mais alta, e eles pesam em volume?

Sem as linhas sinalizadas da Allianz de 2023 (veja a pergunta 9).

| Estado | Razão | Peso no prêmio de Auto |
|---|---|---|
| AP | 84,82% | 0,03% |
| RS | 81,75% | 6,40% |
| TO | 79,26% | 0,33% |
| RO | 78,56% | 0,32% |
| PI | 77,51% | 0,28% |
| SP | 64,79% | 42,42% |
| RN (menor) | 56,54% | 0,71% |

**O que mostra:** os estados do topo (AP, TO, RO, PI) pesam menos de 0,4% do prêmio cada. Com pouco volume, um único sinistro grande muda bastante a razão. O RS é a exceção: razão alta e peso de 6,4%. SP, MG, PR, RJ e RS somam cerca de 72% do prêmio.

**Cuidado:** a razão do RS inclui maio e junho de 2024 (veja a pergunta 7). Também não sei como a SUSEP atribui cada valor a um estado, então não dá para dizer que os motoristas de um estado "custam mais".

### Pergunta 7: o pior resultado de um estado é tendência ou evento pontual?

Razão sinistro/prêmio de Automóvel por ano, sem as linhas sinalizadas:

| Estado | 2023 | 2024 | 2025 | 2026 (jan–jul) |
|---|---|---|---|---|
| AP (pior razão) | 58,61% | 83,28% | 96,17% | 95,49% |
| RS | 61% | 110% | 76% | 78% |
| SP | 63% | 63% | 65% | 71% |

Mês a mês, o RS em 2024: maio foi 517% e junho 130%, enquanto os outros meses ficaram entre 62% e 79%.

**O que mostra:**
- **RS:** sobe em 2024 e volta em 2025. O desenho é de **evento pontual**. A SUSEP publicou em julho de 2024 que a sinistralidade dos seguros de danos no país saltou de 42,1% em abril para 66,1% em maio, por causa da tragédia no sul ([nota da SUSEP](https://www.gov.br/susep/pt-br/central-de-conteudos/noticias/2024/julho/reflexo-da-tragedia-no-sul-sinistralidade-nos-seguros-de-danos-salta-em-maio-para-66-1)). Os dados do projeto mostram o pico, e a explicação vem dessa fonte externa.
- **AP:** sobe por três anos e fica alto, o desenho de **tendência**. Mas o prêmio é de só R$ 7 a 12 milhões por ano, então poucos sinistros grandes mudam o número. Trato como indício.
- **SP:** quase estável.

---

## BLOCO D: dá para confiar nos números?

### Pergunta 8: em 2023, o resultado extremo de Sergipe está concentrado em poucos meses?

| Mês de 2023 | Prêmio (R$ mi) | Sinistro (R$ mi) | Razão |
|---|---|---|---|
| Março | 18,2 | **−4.153,7** | −22.875% |
| Os outros 11 meses | 15 a 18 | 5 a 12 | 29% a 68% |

**O que mostra:** o valor extremo está num mês só, março. Os outros meses têm valores normais. Um sinistro negativo de R$ 4,15 bilhões para um prêmio mensal de R$ 18 milhões é impossível para um estado.

### Pergunta 9: os números por estado são confiáveis?

> *Nota: esta pergunta foi construída com apoio de IA. A estratégia de comparar o total nacional da empresa com o pior estado foi sugerida, e eu executei as consultas. Ainda estou estudando os detalhes das funções usadas.*

**O que encontrei:**
- Procurei linhas em que o sinistro passa de R$ 50 milhões e de 20 vezes o prêmio daquele estado. Em toda a base, só uma combinação apareceu: **Allianz (05177), Automóvel, 2023**, com 20 linhas.
- Exemplo (março de 2023): Mato Grosso com sinistro de +R$ 5,32 bi para prêmio de R$ 12 mi, e Sergipe com −R$ 4,16 bi para prêmio de R$ 2,6 mi. Os valores estão assim na fonte da SUSEP, conferi no arquivo original.
- O **total nacional** da empresa parece coerente: razão entre 68% e 109% nos 12 meses de 2023. O problema parece estar na distribuição por estado.
- De janeiro a agosto de 2023 a empresa tem sinistros negativos em vários estados. De setembro a dezembro de 2023, e em 2024 a 2026, não.

**O que fiz:** mantive as linhas e marquei com `flag_anomalia_uf = 1` (Allianz, Automóvel, janeiro a agosto de 2023: 216 linhas). Nas análises por estado de Automóvel (perguntas 6, 7), excluo essas linhas. Nas análises nacionais, uso tudo, porque o total parece certo.

**O que não sei:** a causa. Pode ser erro de envio, reclassificação ou uma regra de alocação por estado que eu desconheço.

**Limite:** o teste só pega distorções grandes. Erros menores podem ter passado.

---

## Limitações

- A razão sinistro/prêmio não é a sinistralidade oficial (explicado acima).
- A tabela não tem sinistro retido. A coluna `prem_ret_liq` é cópia de prêmio retido, então descartei. `salvados` e `recuperacao` são zero em todo o período e também foram descartadas.
- Não sei se `sin_dir` é sinistro pago, avisado ou ocorrido: a documentação diz só "Sinistros Diretos".
- A base é agregada por empresa, ramo e estado. Não tem clientes nem apólices individuais.
- O prêmio de Automóvel em 2024 no meu banco difere do portal em cerca de R$ 18 mil (0,00005%). Não investiguei a causa.
- Por causa da anomalia da Allianz, os valores em reais de Automóvel por estado em 2023 ficam subestimados quando excluo as linhas sinalizadas (as razões continuam comparáveis).

## SQL utilizado

- `INNER JOIN` e `CROSS JOIN`
- `GROUP BY`, `SUM`, `ROUND`, `MAX`
- `CASE WHEN`
- `LEFT` e `RIGHT` para separar ano e mês
- `NULLIF`
- CTEs (`WITH`)
- Funções de janela: `ROW_NUMBER`, `SUM() OVER`, `LAG`

## Sobre o uso de IA

Usei IA (ChatGPT e Claude) como guia: para entender a estrutura dos arquivos da SUSEP, conferir os dados e discutir como interpretar os resultados. As consultas foram escritas por mim, com correções apontadas na revisão. A investigação de qualidade dos dados (dicionário de colunas, anomalia da Allianz) foi feita com orientação de IA, e conferi os números contra o portal da SUSEP.

## Como recriar o banco

1. Rodar `dll_s.sql` (cria o banco e as tabelas).
2. Rodar `dml_s.sql` na pasta onde estão `uf2_limpo.csv` e `empresas.csv` (carrega os dados).
3. Conferir: `SELECT COUNT(*) FROM uf2;` deve dar 109142.
