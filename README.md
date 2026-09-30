# Análise de prêmios e sinistros — SUSEP/SES

Projeto de análise de dados com a base pública do **SES (Sistema de Estatísticas da SUSEP)**, focado em três ramos de seguro: **Automóvel – Casco (0531)**, **Vida (1391)** e **Compreensivo Residencial (0114)**.

> **Uso de IA:** usei Claude e ChatGPT como apoio no tratamento dos dados,
> conferindo as informações na fonte. Detalhes na seção 12.

O foco desta primeira etapa é a **análise exploratória e a validação da base**: entender o que cada coluna significa, conferir a qualidade dos dados, documentar o que é fato e o que é hipótese, e só então montar o banco de dados (MariaDB) para as análises em SQL.

## Resumo

- Base real da SUSEP, recorte de 109.142 linhas (jan/2023 a jul/2026), importado no MariaDB.
- Conferi o prêmio direto do Automóvel em 2024 contra o portal oficial da SUSEP: diferença de 0,00005%.
- Encontrei dados estranhos da Allianz em Automóvel (jan–ago/2023), marquei as linhas em vez de apagar e expliquei a regra de uso.
- Em 2024, o Rio Grande do Sul teve sinistros muito acima do normal em maio e junho (enchentes).
- A razão sinistro ÷ prêmio que calculei não é a sinistralidade oficial (0,71 contra 0,61 no Automóvel em 2024). Serve só para comparar anos.

---

## 1. Fonte dos dados

| Item | Detalhe |
|---|---|
| Origem | Base completa do SES, baixada do site da SUSEP (`BaseCompleta.zip`) |
| Tabela usada | `SES_UF2.csv` — "Seguros: Prêmios e Sinistros (UF)" |
| Documentação | `Documentacao_das_tabelas.rtf` (fornecida no mesmo pacote) |
| Validação externa | Portal de consulta do SES (`www2.susep.gov.br/menuestatistica/SES/premiosesinistros.aspx?id=54`) |
| Formato | CSV, separador `;`, decimal com vírgula, codificação Latin-1 |

---

## 2. Escopo do recorte

| Item | Valor |
|---|---|
| Ramos | 0531 (Automóvel – Casco), 1391 (Vida), 0114 (Compreensivo Residencial) |
| Período | 01/2023 a 07/2026 (43 meses) |
| Combinações mês/ramo | 129 (nenhum mês faltante) |
| Registros | 109.142 |
| UFs | 27 (em todos os três ramos) |
| Empresas no período | 56 (Automóvel), 61 (Residencial), 65 (Vida) |
| Granularidade | 1 registro = 1 empresa + 1 mês + 1 ramo + 1 UF (sem duplicidades) |

**Atenção:** 2026 cobre apenas jan–jul. Para comparar com anos completos, use a janela jan–jul de cada ano ou razões (e não totais em reais).

---

## 3. Dicionário de dados (SES_UF2)

| Coluna | Descrição (documentação oficial) | Situação no projeto |
|---|---|---|
| `coenti` | Código da empresa | Usada (`empresa`) |
| `damesano` | Ano/mês (AAAAMM) | Usada (`ano_mes`) |
| `ramos` | Código do ramo | Usada (`ramo`) |
| `UF` | Unidade da Federação | Usada (`uf`) |
| `premio_dir` | Prêmios Diretos | Usada |
| `premio_ret` | Prêmios Retidos | Usada |
| `sin_dir` | Sinistros Diretos | Usada |
| `prem_ret_liq` | "Prêmios Retidos" | **Descartada**: duplicata de `premio_ret` |
| `gracodigo` | Código do grupamento de ramos | Usada (`grupamento`) |
| `salvados` | Salvados de sinistros | **Descartada**: zero em todas as linhas do recorte |
| `recuperacao` | Recuperações | **Descartada**: zero em todas as linhas do recorte |

Códigos de ramo confirmados em `Ses_ramos.csv`: 0114 = Compreensivo Residencial, 0531 = Automóvel – Casco, 1391 = Vida.

---

## 4. Validações realizadas

| Validação | Resultado |
|---|---|
| Cobertura temporal dos 3 ramos | Sem mês faltante (129 combinações) |
| Duplicidade em empresa + mês + ramo + UF | Nenhuma |
| Cabeçalho real do arquivo vs. ordem assumida | Confere (11 colunas) |
| `prem_ret_liq` vs. `premio_ret` | Iguais em 100% das 76.186 linhas com prêmio retido ≠ 0; somas idênticas |
| `salvados` e `recuperacao` | Zero nas 109.142 linhas |
| Leitura direta do zip vs. recorte filtrado | Mesmas linhas e valores (o filtro não altera dados) |
| **Prêmio direto 0531 em 2024 vs. portal da SUSEP** | Portal: R$ 35.633.145.412. Base: R$ 35.633.163.776,11. Diferença ≈ R$ 18 mil (≈ 0,00005%) |
| Importação no MariaDB vs. arquivo | 109.142 linhas; prêmio 0531/2024 idêntico; soma de `sin_dir` difere em R$ 0,05 sobre R$ 98,6 bi (arredondamento) |

A diferença de ≈ R$ 18 mil contra o portal **não teve a causa investigada**.

---

## 5. Achados e decisões

### 5.1 `sin_dir` negativo é esperado
Existem valores negativos de `sin_dir` na própria fonte (não criados pelo tratamento). Foram **mantidos**. Nas consultas, use sempre o valor líquido (`SUM`), nunca só positivos ou só negativos.

### 5.2 Anomalia de dados: Allianz (05177), Automóvel, jan–ago/2023
- Em vários estados, o `sin_dir` tem valores positivos e negativos de ordem de bilhões, incompatíveis com o prêmio de cada UF. Exemplo (mar/2023): MT com sinistro de R$ 5,32 bi para prêmio de R$ 12 mi; SE com −R$ 4,16 bi para prêmio de R$ 2,6 mi.
- Os valores estão na fonte (conferido direto no zip).
- O **total nacional** da empresa parece coerente (razão sinistro/prêmio entre 0,68 e 1,09 nos 12 meses de 2023) e o prêmio é estável. O problema parece restrito à **distribuição por UF**.
- De set–dez/2023 e em 2024–2026 não há sinistros negativos da empresa em Automóvel.
- **Causa não determinada** (possíveis: erro de envio, reclassificação ou regra de alocação por UF).
- **Tratamento:** linhas mantidas e sinalizadas em `flag_anomalia_uf = 1` (Allianz, ramo 0531, 202301 a 202308, todas as 27 UFs = 216 linhas). A janela foi definida de forma conservadora, a partir da presença de UFs negativas ou com sinistro acima de 5× o prêmio em todos esses meses.
- **Regra de uso:** análises nacionais podem usar todas as linhas. Análises **por UF em Automóvel** devem filtrar `flag_anomalia_uf = 0` (nesse caso, os valores em reais de 2023 ficam subestimados; as razões continuam comparáveis).

### 5.3 Evento real: Rio Grande do Sul, maio e junho de 2024
- Razão sinistro/prêmio do RS em Automóvel Casco: 0,61 (2023), **1,10 (2024)**, 0,76 (2025).
- Em 2024 o desvio se concentra em **maio (5,17)** e **junho (1,30)**. Nos demais meses a razão fica entre 0,62 e 0,79.
- A SUSEP publicou (nota de 05/07/2024) que a sinistralidade dos seguros de **danos** no país saltou de 42,1% para 66,1% de abril a maio, com os sinistros diretos de danos no RS subindo 192,5% no mês.
- Os valores foram **mantidos** por refletirem um evento real. A nota da SUSEP trata de danos como um todo; a coincidência com o ramo 0531 é observada nos dados deste projeto.

---

## 6. Resultados preliminares (base validada)

Razão = `sin_dir` ÷ `premio_dir` (ver limitações).

| Ramo | Ano | Prêmio direto (R$ bi) | Sinistro direto (R$ bi) | Razão |
|---|---|---|---|---|
| 0114 | 2023 | 5,15 | 1,22 | 0,24 |
| 0114 | 2024 | 6,00 | 1,23 | 0,20 |
| 0114 | 2025 | 6,67 | 1,32 | 0,20 |
| 0114 | 2026 (jan–jul) | 4,02 | 0,74 | 0,18 |
| 0531 | 2023 | 36,72 | 22,86 | 0,62 |
| 0531 | 2024 | 35,63 | 25,30 | 0,71 |
| 0531 | 2025 | 37,49 | 26,01 | 0,69 |
| 0531 | 2026 (jan–jul) | 21,75 | 16,16 | 0,74 |
| 1391 | 2023 | 14,71 | 0,93 | 0,06 |
| 1391 | 2024 | 17,86 | 1,06 | 0,06 |
| 1391 | 2025 | 20,37 | 1,09 | 0,05 |
| 1391 | 2026 (jan–jul) | 12,65 | 0,69 | 0,05 |

---

## 7. Limitações e pontos em aberto

1. **A razão usada é uma proxy, não a sinistralidade oficial.** O portal da SUSEP calcula a sinistralidade como sinistro ocorrido ÷ prêmio ganho. Para o ramo 0531 em 2024, o portal mostra sinistralidade de **0,61**, contra **0,71** da proxy deste projeto. A diferença vem do conceito: `sin_dir` não é o sinistro ocorrido, e o denominador é prêmio direto, não prêmio ganho. Use a proxy para **comparar anos dentro do mesmo ramo**, não para afirmar a sinistralidade do mercado.
2. **Comparação entre ramos:** as razões de Vida (5–6%) e Residencial não são comparáveis às de Automóvel como medida de desempenho; o ramo 1391 tem composição própria.
3. **`sin_dir`:** a documentação diz apenas "Sinistros Diretos". Não foi confirmado se é pago, avisado ou ocorrido. A coluna `salvados` é zero nesta tabela, então `sin_dir` **não está líquido de salvados e ressarcimentos** nesta base.
4. **Sinistro retido não existe nesta tabela.** (`prem_ret_liq` é cópia de prêmio retido.)
5. **Nível baixo de 2023 em Automóvel (razão 0,62)** persiste mesmo sem a Allianz (0,60) e não foi explicado.
6. **Importação no MariaDB:** 5.608 avisos de truncamento de casas decimais (`DECIMAL(18,2)`), com impacto de R$ 0,05 sobre R$ 98,6 bi no total de `sin_dir`.
7. **Recorte estatístico:** o detector de anomalias usado (sinistro acima de R$ 50 mi e acima de 20× o prêmio da UF) só capturou distorções grandes. Distorções menores não foram testadas.

---

## 8. Como reproduzir

### 8.1 Gerar o recorte (terminal)
```bash
unzip -p BaseCompleta.zip SES_UF2.csv | awk -F';' \
  'NR==1 || (($3=="0531"||$3=="1391"||$3=="0114") && $2>=202301)' > recorte_uf2.csv
# esperado: 109143 linhas (com cabeçalho)
```

### 8.2 Gerar o arquivo limpo para o banco
Converte vírgula decimal em ponto, remove colunas sem informação e cria a flag:
```bash
awk -F';' 'BEGIN{OFS=";"; print "empresa","ano_mes","ramo","uf","premio_dir","premio_ret","sin_dir","grupamento","flag_anomalia_uf"}
NR>1 { p=$5; r=$6; s=$7; gsub(",",".",p); gsub(",",".",r); gsub(",",".",s);
       f=($1=="05177" && $3=="0531" && $2>=202301 && $2<=202308)?1:0;
       print $1,$2,$3,$4,p,r,s,$9,f }' recorte_uf2.csv > uf2_limpo.csv
# esperado: 109143 linhas; 216 linhas com flag = 1
```

### 8.3 Criar o banco e a tabela (DDL)
```sql
CREATE DATABASE susep_seguros CHARACTER SET utf8mb4;
USE susep_seguros;

CREATE TABLE uf2 (
  empresa          CHAR(5)       NOT NULL,
  ano_mes          CHAR(6)       NOT NULL,
  ramo             CHAR(4)       NOT NULL,
  uf               CHAR(2)       NOT NULL,
  premio_dir       DECIMAL(18,2) NOT NULL,
  premio_ret       DECIMAL(18,2) NOT NULL,
  sin_dir          DECIMAL(18,2) NOT NULL,
  grupamento       CHAR(2),
  flag_anomalia_uf TINYINT       NOT NULL DEFAULT 0,
  PRIMARY KEY (empresa, ano_mes, ramo, uf)
);
```

### 8.4 Importar (DML)
Abra o cliente com `mariadb -u root -p --local-infile=1`, na pasta do arquivo:
```sql
LOAD DATA LOCAL INFILE 'uf2_limpo.csv'
INTO TABLE uf2
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
```

### 8.5 Conferências pós-importação
```sql
SELECT COUNT(*) FROM uf2;                                  -- 109142
SELECT SUM(premio_dir) FROM uf2
 WHERE ramo='0531' AND ano_mes LIKE '2024%';               -- 35633163776.11
SELECT SUM(flag_anomalia_uf) FROM uf2;                     -- 216
```

---

## 9. Consultas de referência

Série anual por ramo (todas as UFs):
```sql
SELECT ramo,
       SUBSTRING(ano_mes,1,4)                 AS ano,
       ROUND(SUM(premio_dir)/1e9, 2)          AS premio_bi,
       ROUND(SUM(sin_dir)/1e9, 2)             AS sinistro_bi,
       ROUND(SUM(sin_dir)/SUM(premio_dir), 2) AS razao_sin_prem
FROM uf2
GROUP BY ramo, SUBSTRING(ano_mes,1,4)
ORDER BY ramo, ano;
```

Razão por UF em Automóvel, **excluindo a anomalia**:
```sql
SELECT uf, ROUND(SUM(sin_dir)/SUM(premio_dir), 2) AS razao
FROM uf2
WHERE ramo='0531' AND flag_anomalia_uf = 0
GROUP BY uf
ORDER BY razao DESC;
```

Mês a mês do RS em 2024 (evento das enchentes):
```sql
SELECT ano_mes,
       ROUND(SUM(premio_dir)/1e6, 1)          AS premio_mi,
       ROUND(SUM(sin_dir)/1e6, 1)             AS sinistro_mi,
       ROUND(SUM(sin_dir)/SUM(premio_dir), 2) AS razao
FROM uf2
WHERE ramo='0531' AND uf='RS' AND flag_anomalia_uf = 0
  AND ano_mes BETWEEN '202401' AND '202412'
GROUP BY ano_mes
ORDER BY ano_mes;
```

---

## 10. Próximos passos

- [ ] Série mensal por ramo, com o evento do RS em 2024 destacado
- [ ] Concentração de mercado: quantas empresas somam 80% do prêmio de cada ramo
- [ ] Comparação entre UFs, com o volume de prêmio ao lado (UFs pequenas oscilam mais)
- [ ] Gráficos (Python) a partir das consultas SQL
- [ ] Investigar a diferença de ≈ R$ 18 mil contra o portal (opcional)
- [ ] Segunda conferência externa (Vida e Residencial em 2024 no portal)

---

## 11. Ferramentas

MariaDB 11.8, `awk` e `unzip` (exploração inicial, sem descompactar a base de ~2,8 GB), SQL para as análises.

---

## 12. Como este projeto foi feito

Usei IA (Claude e ChatGPT) como apoio, principalmente pela praticidade no
tratamento e na limpeza dos dados. Não tratei as respostas como verdade:
sempre que possível, fui conferir na fonte.

O que conferi por conta própria:

- **Dicionário de dados:** comparei o que a IA me passou com a documentação
  da SUSEP e com o arquivo. Isso mostrou que `prem_ret_liq` era cópia de
  `premio_ret`, e descartei a coluna.
- **Valores da Allianz:** verifiquei direto no arquivo original para saber se
  o problema estava na fonte ou no meu tratamento.
- **Prêmio do Automóvel em 2024:** comparei com o portal oficial da SUSEP.
- **Enchentes no RS:** confirmei que o pico de sinistros em maio e junho de
  2024 coincide com a nota publicada pela SUSEP.

Rodei todos os comandos e consultas no meu computador e conferi as saídas.
