USE susep_seguros;

-- BLOCO A: ONDE ESTÁ O DINHEIRO? 

/* 
PERGUNTA 1A: QUANTO CADA RAMO ARRECADA (PRÊMIO DIRETO) E PAGA EM SINISTROS (SINISTRO
DIRETO), ANO A ANO?

Esta consulta serve para ver o tamanho de cada ramo em cada ano.
O ano de 2026 fica de fora por não estar completo os 12 meses. (ver consulta 1B)
*/

SELECT 
    CASE u.ramo
        WHEN '0531' THEN 'Auto'
        WHEN '0114' THEN 'Resid'
        WHEN '1391' THEN 'Vida'
    END AS ramo_nome,
    ROUND(SUM(u.premio_dir) / 1E9, 2) premio_direto_bi,
    ROUND(SUM(u.sin_dir) / 1E9, 2) sin_direto_bi,
    ROUND(SUM(u.sin_dir) / SUM(u.premio_dir) * 100,
            2) razao,
    LEFT(u.ano_mes, 4) ano
FROM
    uf2 u
where left(u.ano_mes,4) between '2023' and '2025'
GROUP BY u.ramo , ano
ORDER BY ramo_nome , ano DESC;

/*PERGUNTA 1B:
A RAZÃO SINISTRO/PRÊMIO MUDOU DE UM ANO PARA OUTRO, NO MESMO PERÍODO?

Compara só janeiro a julho em todos os anos, porque 2026 só tem esses meses.
A razão é sum(sinistro)/sum(prêmio), e não a média das razões mensais,
para que meses grandes pesem mais que meses pequenos.
*/

SELECT 
    CASE u.ramo
        WHEN '0531' THEN 'Auto'
        WHEN '0114' THEN 'Resid'
        WHEN '1391' THEN 'Vida'
    END AS ramo_nome,
    LEFT(u.ano_mes, 4) ano,
    ROUND(SUM(u.premio_dir) / 1E9, 2) premio_bi_jan_jul,
    ROUND(SUM(u.sin_dir) / 1E9, 2) sin_bi_jan_jul,
    ROUND(SUM(u.sin_dir) / SUM(u.premio_dir) * 100, 2) razao_jan_jul
FROM
    uf2 u
WHERE
    RIGHT(u.ano_mes, 2) BETWEEN '01' AND '07'
GROUP BY u.ramo , ano
ORDER BY ramo_nome , ano desc;

/*
PERGUNTA 2:
COMO A razao SINISTRO/PRÊMIO DE CADA RAMO EVOLUIU MÊS A MÊS,
E EM QUAIS MESES FOI MAIS CRÍTICA?
*/

SELECT 
	case u.ramo
    when '0531' then 'Auto'
    when '0114' then 'Resid'
    when '1391' then 'Vida'
    end as ramo_nome,
    left(u.ano_mes,4) ano,
    RIGHT(u.ano_mes, 2) mes,
   ROUND(SUM(u.sin_dir) / SUM(u.premio_dir)*100,2) razao_sinistro_premio
FROM
    uf2 u
Where left(u.ano_mes,4) <> '2026'
GROUP BY ano, ramo_nome
order by ramo_nome, ano, mes;



WITH razao_mensal AS (
    SELECT
        CASE u.ramo
            WHEN '0531' THEN 'Auto'
            WHEN '0114' THEN 'Resid'
            WHEN '1391' THEN 'Vida'
        END AS ramo_nome,
        LEFT(u.ano_mes, 4) ano,
        RIGHT(u.ano_mes, 2) mes,
        ROUND(SUM(u.sin_dir) / SUM(u.premio_dir) * 100, 2) razao_porcentagem
    FROM uf2 u
    GROUP BY ramo_nome, u.ano_mes
),
ranking AS (
    SELECT
        ramo_nome,
        ano,
        mes,
        razao_porcentagem,
        ROW_NUMBER() OVER (PARTITION BY ramo_nome ORDER BY razao_porcentagem DESC) posicao
    FROM razao_mensal
)
SELECT ramo_nome, ano, mes, razao_porcentagem, posicao
FROM ranking
WHERE posicao <= 3
ORDER BY ramo_nome, posicao;


/*
PERGUNTA 3: 
QUAIS SÃO AS 10 MAIORES EMPRESAS DE CADA RAMO?
*/

with premio_por_empresa as (
	SELECT 
    u.empresa,
    CASE u.ramo
        WHEN '0531' THEN 'Auto'
        WHEN '0114' THEN 'Resid'
        WHEN '1391' THEN 'Vida'
    END AS ramo_nome,
    SUM(u.premio_dir) premio_direto_total
FROM
    uf2 u
GROUP BY u.empresa , u.ramo
),
rank_empresas as (
	select 
    empresa,
    ramo_nome,
    premio_direto_total,
    sum(premio_direto_total) over(partition by ramo_nome) premio_total_ramo,
    row_number() over (partition by ramo_nome order by premio_direto_total desc) posicao
    from premio_por_empresa
)
select r.ramo_nome,
r.posicao,
r.empresa,
e.nome nome_empresa,
round(r.premio_direto_total/1e9,2) premio_bi,
round(r.premio_direto_total/r.premio_total_ramo*100,1) porcentagem_ramo
from rank_empresas r
left join empresas e on r.empresa = e.empresa
where r.posicao <=10
order by r.ramo_nome, r.posicao;
    
/* 
PERGUNTA 4:
QUANTAS EMPRESAS SOMAM 80% DO PRÊMIO DE CADA RAMO?
*/

with premio_por_empresa_ramo AS(
select
	CASE u.ramo
        WHEN '0531' THEN 'Auto'
        WHEN '0114' THEN 'Resid'
        WHEN '1391' THEN 'Vida'
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
    
-- BLOCO B: PARA ONDE O MERCADO CRESCE?

/*
PERGUNTA 5: 
O PRÊMIO DE CADA RAMO ESTÁ CRESCENDO DE UM ANO PARA O OUTRO?
(Comparação entre janeiro a julho em todos os anos,
porque 2026 só tem esses 7 meses para análise)
*/

with premio_anual_ramo as(
select 
		CASE u.ramo
        WHEN '0531' THEN 'Auto'
        WHEN '0114' THEN 'Resid'
        WHEN '1391' THEN 'vida'
    END AS ramo_nome,
    sum(u.premio_dir) premio_direto_total,
    left(u.ano_mes,4) ano
FROM uf2 u
WHERE RIGHT(u.ano_mes,2) between '01' and '07'
group by ramo_nome, ano
),
comparacao_anual as(
select
	ramo_nome,
    ano,
    premio_direto_total,
    lag(premio_direto_total) over (partition by ramo_nome order by ano) premio_ano_anterior
from premio_anual_ramo
)
select 
	ramo_nome,
    ano,
    premio_direto_total,
    premio_ano_anterior,
    premio_direto_total - premio_ano_anterior variacao_ano,
    round((premio_direto_total - premio_ano_anterior)/premio_ano_anterior *100,2) variacao_percentual
from comparacao_anual
order by ramo_nome, ano;


-- BLOCO C: ONDE ESTÁ O RISCO?

/*
PERGUNTA 6:
EM AUTOMÓVEL, QUAIS ESTADOS TÊM A RAZÃO MAIS ALTA, E ESSES ESTADOS PESSAM EM VOLUME?
*/

with faturamento_por_estado as(
SELECT 
    CASE u.ramo
        WHEN '0531' THEN 'Auto'
        WHEN '0114' THEN 'Resid'
        WHEN '1391' THEN 'vida'
    END AS ramo_nome,
    u.uf estado,
    SUM(u.premio_dir) premio_dir_total,
    SUM(u.sin_dir) sin_total
FROM uf2 u
WHERE u.ramo = '0531'
	AND u.empresa <> '05177'
    and u.ano_mes between '202301' and '202512'
GROUP BY estado , ramo_nome
),
premio_total_auto as(
select
	sum(premio_dir_total) premio_total_auto
from faturamento_por_estado
where ramo_nome = 'Auto'
)
select
	fe.ramo_nome,
    fe.estado, 
    fe.premio_dir_total,
    fe.sin_total,
    pta.premio_total_auto,
    round((fe.sin_total/fe.premio_dir_total)*100,2) razao,
    round((fe.premio_dir_total/pta.premio_total_auto)*100,2) peso_estado
from faturamento_por_estado fe
cross join premio_total_auto pta 
where fe.ramo_nome = 'Auto'
order by razao desc;


/*
PERGUNTA 7:
O PIOR RESULTADO DE UM ESTADO É TENDÊNCIA OU EVENTO PONTUAL?
*/

#Qual Estado (UF) comm pior razão Auto e como ela evoluiu.
# A Allianz (05177) fica fora em todos os anos e 2026 fica fora por ter só jan~jul.
with faturamento_por_estado as(
SELECT 
    CASE u.ramo
        WHEN '0531' THEN 'Auto'
        WHEN '0114' THEN 'Resid'
        WHEN '1391' THEN 'vida'
    END AS ramo_nome,
    u.uf estado,
    SUM(u.premio_dir) premio_dir_total,
    SUM(u.sin_dir) sin_total
FROM uf2 u
WHERE u.ramo = '0531' 
	and u.empresa <> '05177' 
	and u.ano_mes between '202301' and '202512'
GROUP BY estado , ramo_nome
), razao_por_estado as(
select
	fe.ramo_nome,
    fe.estado, 
    fe.premio_dir_total,
    fe.sin_total,
    (fe.sin_total/fe.premio_dir_total) razao
from faturamento_por_estado fe
where fe.ramo_nome = 'Auto' 
),
pior_razao as(
	Select *
    from razao_por_estado
    order by razao desc
    limit 1
)
select
	left(u.ano_mes,4) ano,
    sum(u.premio_dir) premio_dir_total,
    sum(u.sin_dir) sin_total,
    round((sum(u.sin_dir)/sum(u.premio_dir))*100,2) razao_pior_estado,
	pr.estado
from uf2 u
cross join pior_razao pr
where u.uf = pr.estado 
	AND u.ramo = '0531'
    and u.empresa <> '05177'
    and u.ano_mes between '202301' and '202512'
group by ano, pr.estado;

# O mesmo Estado(UF) comparado com RS e SP
# Razão de todos os estados por ano, com o mesmo filtro (sem Allianz, 2023 a 2025)
SELECT 
    u.uf estado,
    LEFT(u.ano_mes, 4) ano,
    ROUND(SUM(u.premio_dir) / 1E6, 1) premio_mi,
    ROUND(SUM(u.sin_dir) / SUM(u.premio_dir) * 100,
            2) razao
FROM
    uf2 u
WHERE
    u.ramo = '0531' AND u.empresa <> '05177'
        AND u.ano_mes BETWEEN '202301' AND '202512'
       and u.uf in ('AP', 'RS', 'SP', 'TO')
GROUP BY u.uf , ano
ORDER BY u.uf , ano;

/*
PERGUNTA 8:
EM 2023, O RESULTADO EXTREMO DE SERGIPE ESTÁ CONCENTRADO EM POUCOS MESES
OU DISTRIBUÍDO AO LONGO DO ANO?
(Aqui NÃO se filtra flag_anomalia_uf, de propósito: o objetivo é ver a anomalia.)
*/

SELECT
    RIGHT(u.ano_mes, 2) mes,
    ROUND(SUM(u.premio_dir) / 1e6, 1) premio_mi,
    ROUND(SUM(u.sin_dir) / 1e6, 1) sinistro_mi,
    ROUND(SUM(u.sin_dir) / SUM(u.premio_dir) * 100, 2) razao,
    SUM(u.flag_anomalia_uf) linhas_sinalizadas
FROM uf2 u
WHERE u.uf = 'SE'
  AND u.ramo = '0531'
  AND u.ano_mes BETWEEN '202301' AND '202312'
GROUP BY mes
ORDER BY mes;

-- BLOCO D: DÁ PARA CONFIAR NOS NÚMEROS?

/*
PERGUNTA 9: 
OS NÚMEROS POR ESTADOS SÃO CONFIÁVEIS?

NOTA:Esta pergunta foi construída com apoio de IA: 
a estratégia de comparar o total nacional da empresa com o pior estado foi sugerida, 
e eu executei as consultas e conferi os resultados. Ainda estou estudando os detalhes 
das funções usadas.
*/
SELECT empresa, ramo, LEFT(ano_mes, 4) ano,
       COUNT(*) linhas,
       ROUND(SUM(ABS(sin_dir)) / 1e9, 2) soma_abs_bi
FROM uf2
WHERE ABS(sin_dir) > 50000000
  AND ABS(sin_dir) > 20 * premio_dir
GROUP BY empresa, ramo, LEFT(ano_mes, 4)
order by soma_abs_bi desc;

SELECT uf, premio_dir, sin_dir
FROM uf2
WHERE empresa = '05177' AND ramo = '0531' AND ano_mes = '202303'
ORDER BY sin_dir;

SELECT ano_mes,
       ROUND(SUM(premio_dir) / 1e6, 1) premio_mi,
       ROUND(SUM(sin_dir) / 1e6, 1) sinistro_mi,
       ROUND(SUM(sin_dir) / SUM(premio_dir), 2) razao_nacional,
       ROUND(MAX(sin_dir / NULLIF(premio_dir, 0)), 1) razao_maxima_uf
FROM uf2
WHERE empresa = '05177' AND ramo = '0531'
  AND ano_mes BETWEEN '202301' AND '202312'
GROUP BY ano_mes
ORDER BY ano_mes;