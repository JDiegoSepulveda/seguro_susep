USE susep_seguros;

-- BLOCO A: ONDE ESTÁ O DINHEIRO? 

/* 
PERGUNTA 1: QUANTO CADA RAMO ARRECADA (PRÊMIO DIRETO) E PAGA EM SINISTROS (SINISTRO
DIRETO), ANO A ANO?
*/

SELECT 
    CASE u.ramo
        WHEN '0531' THEN 'Auto'
        WHEN '0114' THEN 'Resid'
        WHEN '1391' THEN 'Vida'
    END AS ramo_nome,
    SUM(u.premio_dir) premio_direto_total,
    sum(u.sin_dir) sin_dir_total,
    LEFT(u.ano_mes,4) ano
FROM uf2 u
GROUP BY u.ramo, left(u.ano_mes,4)
ORDER BY ano DESC;

/*
PERGUNTA 2: COMO A RAZÃO DE SINISTRO/PRÊMIO VARIA MÊS A MÊS? EXISTE UMA ÉPOCA
MAIS ARRISCADA?
*/

SELECT 
	case u.ramo
    when '0531' then 'Auto'
    when '0114' then 'Resid'
    when '1391' then 'vida'
    end as ramo_nome,
    left(u.ano_mes,4) ano,
    RIGHT(u.ano_mes, 2) mes,
   SUM(u.sin_dir) / SUM(u.premio_dir) razao_sinistro_premio
FROM
    uf2 u
GROUP BY ano, mes, ramo_nome;

/*
PERGUNTA 3: 
QUAIS SÃO AS 10 MAIORES EMPRESAS DE CADA RAMO?
*/

with premio_por_empresa as(
SELECT 
    u.empresa,
    CASE u.ramo
        WHEN '0531' THEN 'Auto'
        WHEN '0114' THEN 'Resid'
        WHEN '1391' THEN 'vida'
    END AS ramo_nome,
    SUM(u.premio_dir) premio_direto_total
FROM uf2 u
GROUP BY 
	u.empresa, 
    u.ramo
),
rank_empresas AS (
	select 
		empresa, 
        ramo_nome,
        premio_direto_total,
	row_number() 
		over(partition by ramo_nome order by premio_direto_total desc) posicao
from premio_por_empresa
)
SELECT 
    empresa, 
    ramo_nome, 
    premio_direto_total, 
    posicao
FROM
    rank_empresas
WHERE
    posicao <= 10
ORDER BY 
	ramo_nome ,
    posicao;
    
/* 
PERGUNTA 4:
QUANTAS EMPRESAS SOMAM 80% DO PRÊMIO DE CADA RAMO?
*/

with premio_por_empresa_ramo AS(
select
	CASE u.ramo
        WHEN '0531' THEN 'Auto'
        WHEN '0114' THEN 'Resid'
        WHEN '1391' THEN 'vida'
    END AS ramo_nome,
    Sum(u.premio_dir) premio_direto_total,
    u.empresa
from uf2 u
group by ramo_nome, u.empresa
),
posicao_premio_ramo as(
select
	empresa,
    ramo_nome,
    premio_direto_total,
   sum(premio_direto_total)
		over(partition by ramo_nome order by premio_direto_total desc
			rows between unbounded preceding and current row) premio_acumulado,
	SUM(premio_direto_total) over (partition by ramo_nome) premio_total_ramo,
    row_number() over (partition by ramo_nome order by premio_direto_total desc) posicao
from premio_por_empresa_ramo
),
percentual_acumulado as (
select 
	empresa,
    ramo_nome,
    premio_direto_total,
    premio_acumulado,
    premio_total_ramo,
    posicao,
    premio_acumulado/premio_total_ramo percentual_acumulado
FROM posicao_premio_ramo
)
select
	ramo_nome,
    min(posicao) qtd_empresas_80,
    round(min(percentual_acumulado) * 100,2) percentual
    from percentual_acumulado
    where percentual_acumulado >= 0.80
    group by ramo_nome
    order by qtd_empresas_80;