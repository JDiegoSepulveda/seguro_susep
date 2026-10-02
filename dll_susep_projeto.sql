/* BANCO DE PROJETO SUSEP/SES*/

create database if not exists susep_seguros;
use susep_seguros;

CREATE TABLE ramos (
    ramo CHAR(4) NOT NULL PRIMARY KEY,
    nome VARCHAR(60) NOT NULL
);

CREATE TABLE empresas (
    empresa CHAR(5) NOT NULL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL
);

# 1. Registro = 1 empresa + 1 mês + 1 ramo + 1 UF

CREATE TABLE uf2 (
    empresa CHAR(5) NOT NULL,
    ano_mes CHAR(6) NOT NULL,
    ramo CHAR(4) NOT NULL,
    uf CHAR(2) NOT NULL,
    premio_dir DECIMAL(18 , 2 ) NOT NULL,
    premio_ret DECIMAL(18 , 2 ) NOT NULL,
    sin_dir DECIMAL(18 , 2 ) NOT NULL,
    grupamento CHAR(2),
    flag_anomalia_uf TINYINT NOT NULL DEFAULT 0,
    PRIMARY KEY (empresa , ano_mes , ramo , uf)
);