-- =================================================--------------------
-- CONSULTAS ANALÍTICAS SOBRE O ESQUEMA ESTRELA ACADÊMICO
-- =================================================--------------------

-- ---------------------------------------------------------------------
-- 1. Desempenho e retenção por escola de origem (pública x privada)
-- ---------------------------------------------------------------------
SELECT
    a.escola_em,
    COUNT(DISTINCT a.sk_dim_aluno)                                        AS alunos,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
               / COUNT(*) AS NUMERIC), 2)                                 AS taxa_aprovacao_pct,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                                 AS taxa_reprovacao_pct,
    ROUND(CAST(100.0 * COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status IN ('Evadido', 'Desligado'))
               / COUNT(DISTINCT a.sk_dim_aluno) AS NUMERIC), 2)          AS taxa_evasao_pct,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                          AS nota_media
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY a.escola_em
ORDER BY taxa_reprovacao_pct DESC;


-- ---------------------------------------------------------------------
-- 2. Retenção por gênero e por curso
-- ---------------------------------------------------------------------
SELECT
    c.nome                                                                AS curso,
    a.genero,
    COUNT(DISTINCT a.sk_dim_aluno)                                        AS alunos,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                                 AS taxa_reprovacao_pct,
    ROUND(CAST(100.0 * COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status IN ('Evadido', 'Desligado'))
               / COUNT(DISTINCT a.sk_dim_aluno) AS NUMERIC), 2)          AS taxa_evasao_pct,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                          AS nota_media
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
JOIN dim_curso c ON c.sk_dim_curso = f.sk_dim_curso
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY c.nome, a.genero
ORDER BY c.nome, taxa_reprovacao_pct DESC;


-- ---------------------------------------------------------------------
-- 3. Avaliação das políticas de cotas (ações afirmativas)
-- ---------------------------------------------------------------------
WITH cr_aluno AS (
    SELECT
        f.sk_dim_aluno,
        SUM(f.nota_final * d.creditos) / NULLIF(SUM(d.creditos), 0)     AS cr
    FROM fato_disciplina f
    JOIN dim_disciplina d ON d.sk_dim_disciplina = f.sk_dim_disciplina
    WHERE f.situacao_disciplina <> 'Trancado'
    GROUP BY f.sk_dim_aluno
)
SELECT
    CASE WHEN a.tipo_cota IN ('Ampla concorrência', 'Não se aplica', 'Ampla Concorrência')
         THEN 'Não cotista' ELSE 'Cotista' END                          AS grupo,
    COUNT(DISTINCT a.sk_dim_aluno)                                        AS alunos,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                                 AS taxa_reprovacao_pct,
    ROUND(CAST(100.0 * COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status IN ('Evadido', 'Desligado'))
               / COUNT(DISTINCT a.sk_dim_aluno) AS NUMERIC), 2)          AS taxa_evasao_pct,
    ROUND(CAST(AVG(ca.cr) AS NUMERIC), 2)                                 AS cr_medio
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
JOIN cr_aluno ca ON ca.sk_dim_aluno = a.sk_dim_aluno
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY grupo
ORDER BY grupo;


-- ---------------------------------------------------------------------
-- 4. Evolução histórica da taxa global de reprovação
-- ---------------------------------------------------------------------
SELECT
    dt.semestre,
    COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado')          AS matriculas_avaliadas,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado') AS NUMERIC), 2)
                                                                         AS taxa_reprovacao_pct
FROM fato_disciplina f
JOIN dim_data dt ON dt.sk_dim_data = f.sk_dim_data
GROUP BY dt.semestre
ORDER BY dt.semestre;


-- ---------------------------------------------------------------------
-- 5. Mapeamento dos períodos de maior reprovação e evasão
-- ---------------------------------------------------------------------
WITH periodo_aluno AS (
    SELECT DISTINCT f.sk_dim_aluno, t.periodo_disciplina AS semestre
    FROM fato_disciplina f
    JOIN dim_turma_disciplina t ON t.sk_dim_turma_disciplina = f.sk_dim_turma_disciplina
),
periodo_rel AS (
    SELECT sk_dim_aluno, semestre,
           DENSE_RANK() OVER (PARTITION BY sk_dim_aluno ORDER BY semestre) AS periodo_relativo
    FROM periodo_aluno
),
reprov_periodo AS (
    SELECT pr.periodo_relativo,
           COUNT(DISTINCT f.sk_dim_aluno) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
                                                                         AS alunos_reprovados
    FROM fato_disciplina f
    JOIN dim_turma_disciplina t ON t.sk_dim_turma_disciplina = f.sk_dim_turma_disciplina
    JOIN periodo_rel pr ON pr.sk_dim_aluno = f.sk_dim_aluno AND pr.semestre = t.periodo_disciplina
    GROUP BY pr.periodo_relativo
),
ultimo_periodo AS (
    SELECT sk_dim_aluno, MAX(periodo_relativo) AS periodo_relativo
    FROM periodo_rel
    GROUP BY sk_dim_aluno
),
ativos_periodo AS (
    SELECT periodo_relativo, COUNT(DISTINCT sk_dim_aluno) AS alunos_ativos
    FROM periodo_rel
    GROUP BY periodo_relativo
),
evasao_periodo AS (
    SELECT up.periodo_relativo, COUNT(*) AS evasoes
    FROM ultimo_periodo up
    JOIN dim_aluno a ON a.sk_dim_aluno = up.sk_dim_aluno
    WHERE a.status IN ('Evadido', 'Desligado')
    GROUP BY up.periodo_relativo
)
SELECT
    ap.periodo_relativo                                                 AS periodo_do_curso,
    ap.alunos_ativos,
    COALESCE(rp.alunos_reprovados, 0)                                   AS alunos_reprovados,
    ROUND(CAST(100.0 * COALESCE(rp.alunos_reprovados, 0)
               / ap.alunos_ativos AS NUMERIC), 2)                        AS taxa_reprovacao_pct,
    COALESCE(ep.evasoes, 0)                                             AS evasoes_neste_periodo,
    ROUND(CAST(100.0 * COALESCE(ep.evasoes, 0)
               / ap.alunos_ativos AS NUMERIC), 2)                        AS taxa_evasao_pct
FROM ativos_periodo ap
LEFT JOIN reprov_periodo rp ON rp.periodo_relativo = ap.periodo_relativo
LEFT JOIN evasao_periodo ep ON ep.periodo_relativo = ap.periodo_relativo
ORDER BY ap.periodo_relativo;


-- ---------------------------------------------------------------------
-- 6. Evolução temporal do desempenho de uma disciplina específica
-- ---------------------------------------------------------------------
SELECT
    dt.semestre,
    COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado')          AS matriculas_avaliadas,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
               / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado'), 0)
               AS NUMERIC), 2)                                           AS taxa_aprovacao_pct,
    ROUND(CAST(AVG(f.nota_final) FILTER (WHERE f.situacao_disciplina <> 'Trancado')
               AS NUMERIC), 2)                                           AS nota_media
FROM fato_disciplina f
JOIN dim_disciplina d ON d.sk_dim_disciplina = f.sk_dim_disciplina
JOIN dim_data dt       ON dt.sk_dim_data       = f.sk_dim_data
WHERE d.codigo = 'IF103'   -- troque pelo código da disciplina desejada
GROUP BY dt.semestre
ORDER BY dt.semestre;


-- ---------------------------------------------------------------------
-- 7. Top 10 disciplinas gargalo do fluxo curricular (por curso)
-- ---------------------------------------------------------------------
SELECT
    d.codigo,
    d.nome                                                               AS disciplina,
    COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado')          AS matriculas_avaliadas,
    COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')      AS total_reprovacoes,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado'), 0)
               AS NUMERIC), 2)                                           AS taxa_reprovacao_pct
FROM fato_disciplina f
JOIN dim_disciplina d ON d.sk_dim_disciplina = f.sk_dim_disciplina
JOIN dim_curso c      ON c.sk_dim_curso      = f.sk_dim_curso
WHERE c.nome = 'Ciência da Computação'   -- troque pelo curso de interesse
GROUP BY d.codigo, d.nome
HAVING COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%') > 0
ORDER BY total_reprovacoes DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 8. Composição da reprovação: dificuldade (nota) vs. abandono (falta)
-- ---------------------------------------------------------------------
SELECT
    d.codigo,
    d.nome                                                               AS disciplina,
    COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')      AS total_reprovacoes,
    COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE '%nota%')          AS reprov_nota,
    COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE '%falta%')         AS reprov_falta,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE '%nota%')
               / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%'), 0)
               AS NUMERIC), 2)                                           AS pct_reprov_por_nota,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE '%falta%')
               / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%'), 0)
               AS NUMERIC), 2)                                           AS pct_reprov_por_falta
FROM fato_disciplina f
JOIN dim_disciplina d ON d.sk_dim_disciplina = f.sk_dim_disciplina
GROUP BY d.codigo, d.nome
HAVING COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%') > 0
ORDER BY total_reprovacoes DESC;


-- ---------------------------------------------------------------------
-- 9. Desempenho por turno de oferta, disciplina a disciplina
-- ---------------------------------------------------------------------
WITH por_turno AS (
    SELECT
        d.codigo,
        d.nome                                                           AS disciplina,
        t.turno,
        COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado')      AS matriculas,
        100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
            / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado'), 0) AS taxa_aprovacao,
        AVG(f.nota_final) FILTER (WHERE f.situacao_disciplina <> 'Trancado') AS nota_media
    FROM fato_disciplina f
    JOIN dim_disciplina d        ON d.sk_dim_disciplina        = f.sk_dim_disciplina
    JOIN dim_turma_disciplina t ON t.sk_dim_turma_disciplina = f.sk_dim_turma_disciplina
    GROUP BY d.codigo, d.nome, t.turno
    HAVING COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado') >= 10
)
SELECT codigo, disciplina, turno, matriculas, taxa_aprovacao_pct, nota_media
FROM (
    SELECT
        codigo, disciplina, turno, matriculas,
        ROUND(CAST(taxa_aprovacao AS NUMERIC), 2)                        AS taxa_aprovacao_pct,
        ROUND(CAST(nota_media AS NUMERIC), 2)                            AS nota_media,
        COUNT(*) OVER (PARTITION BY codigo)                              AS turnos_ofertados
    FROM por_turno
) sub
WHERE turnos_ofertados > 1
ORDER BY codigo, taxa_aprovacao_pct DESC;


-- ---------------------------------------------------------------------
-- 10. Top 10 disciplinas com maior índice de absenteísmo (Faltas)
-- ---------------------------------------------------------------------
SELECT
    d.codigo,
    d.nome                                                               AS disciplina,
    COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado')          AS matriculas_avaliadas,
    SUM(f.falta)                                                         AS total_faltas,
    ROUND(CAST(AVG(f.falta) AS NUMERIC), 2)                              AS media_faltas_por_aluno,
    ROUND(CAST(AVG(100.0 * f.falta / NULLIF(d.carga_horaria, 0)) AS NUMERIC), 2) 
                                                                         AS pct_media_absenteismo_ch
FROM fato_disciplina f
JOIN dim_disciplina d ON d.sk_dim_disciplina = f.sk_dim_disciplina
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY d.codigo, d.nome, d.carga_horaria
HAVING COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado') > 0
ORDER BY media_faltas_por_aluno DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 11. Top 10 disciplinas com as menores médias de notas
-- ---------------------------------------------------------------------
SELECT
    d.codigo,
    d.nome                                                               AS disciplina,
    COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado')          AS matriculas_avaliadas,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                          AS nota_media,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
               / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado'), 0) 
               AS NUMERIC), 2)                                           AS taxa_aprovacao_pct
FROM fato_disciplina f
JOIN dim_disciplina d ON d.sk_dim_disciplina = f.sk_dim_disciplina
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY d.codigo, d.nome
HAVING COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado') > 0
ORDER BY nota_media ASC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 12. Top 10 disciplinas com as maiores médias de notas
-- ---------------------------------------------------------------------
SELECT
    d.codigo,
    d.nome                                                               AS disciplina,
    COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado')          AS matriculas_avaliadas,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                          AS nota_media,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
               / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado'), 0) 
               AS NUMERIC), 2)                                           AS taxa_aprovacao_pct
FROM fato_disciplina f
JOIN dim_disciplina d ON d.sk_dim_disciplina = f.sk_dim_disciplina
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY d.codigo, d.nome
HAVING COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado') > 0
ORDER BY nota_media DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 13. Top 10 cursos com maior taxa de abandono (evasão) da universidade
-- ---------------------------------------------------------------------
SELECT
    c.codigo,
    c.nome                                                               AS curso,
    COUNT(DISTINCT a.sk_dim_aluno)                                       AS total_alunos_vinculados,
    COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status IN ('Evadido', 'Desligado', 'Cancelado'))
                                                                         AS alunos_evadidos,
    ROUND(CAST(100.0 * COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status IN ('Evadido', 'Desligado', 'Cancelado'))
               / NULLIF(COUNT(DISTINCT a.sk_dim_aluno), 0) AS NUMERIC), 2)
                                                                         AS taxa_evasao_pct
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
JOIN dim_curso c ON c.sk_dim_curso = f.sk_dim_curso
GROUP BY c.codigo, c.nome
HAVING COUNT(DISTINCT a.sk_dim_aluno) > 0
ORDER BY taxa_evasao_pct DESC, alunos_evadidos DESC
LIMIT 10;
