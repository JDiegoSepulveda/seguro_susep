use susep_seguros;

-- Tabela de ramos (3 ramos do projeto)
INSERT INTO ramos (ramo, nome) VALUES
  ('0114', 'Compreensivo Residencial'),
  ('0531', 'Automóvel - Casco'),
  ('1391', 'Vida');

-- Empresas: empresas.csv (código;nome), gerado a partir de Ses_cias.csv
-- com espaços removidos.
LOAD DATA LOCAL INFILE 'empresas.csv'
INTO TABLE empresas
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n';

-- Prêmios e sinistros: uf2_limpo.csv, gerado a partir de SES_UF2.csv
-- (3 ramos, 202301 a 202607, decimal com ponto).
-- flag_anomalia_uf já vem calculada no CSV:
-- 1 = Allianz (05177), ramo 0531, de 202301 a 202308.
LOAD DATA LOCAL INFILE 'uf2_limpo.csv'
INTO TABLE uf2
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
