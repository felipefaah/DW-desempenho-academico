
-- ---------------------------------------------------------------------
-- 1. Desempenho e retenção por escola de origem (pública x privada)
--    Utilidade: orienta verba de assistência estudantil e programas de
--    nivelamento para quem veio de escola pública.
-- ---------------------------------------------------------------------
SELECT
    a.escola_em,
    COUNT(DISTINCT a.sk_dim_aluno)                                       AS alunos,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
               / COUNT(*) AS NUMERIC), 2)                                AS taxa_aprovacao_pct,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                                AS taxa_reprovacao_pct,
    ROUND(CAST(100.0 * COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status IN ('Evadido', 'Desligado'))
               / COUNT(DISTINCT a.sk_dim_aluno) AS NUMERIC), 2)          AS taxa_evasao_pct,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                         AS nota_media
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY a.escola_em
ORDER BY taxa_reprovacao_pct DESC;


-- ---------------------------------------------------------------------
-- 2. Retenção por gênero e por curso
-- ---------------------------------------------------------------------
SELECT
    c.nome                                                               AS curso,
    a.genero,
    COUNT(DISTINCT a.sk_dim_aluno)                                       AS alunos,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                                AS taxa_reprovacao_pct,
    ROUND(CAST(100.0 * COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status IN ('Evadido', 'Desligado'))
               / COUNT(DISTINCT a.sk_dim_aluno) AS NUMERIC), 2)          AS taxa_evasao_pct,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                         AS nota_media
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
JOIN dim_curso c ON c.sk_dim_curso = f.sk_dim_curso
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY c.nome, a.genero
ORDER BY c.nome, taxa_reprovacao_pct DESC;


-- ---------------------------------------------------------------------
-- 3. Avaliação das políticas de cotas (ações afirmativas)
--    Utilidade: verifica se cotistas progridem no mesmo ritmo que a
--    ampla concorrência (reprovação, evasão e coeficiente de rendimento).
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
    CASE WHEN a.tipo_cota IN ('Ampla concorrência', 'Não se aplica')
         THEN 'Não cotista' ELSE 'Cotista' END                          AS grupo,
    COUNT(DISTINCT a.sk_dim_aluno)                                       AS alunos,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                                AS taxa_reprovacao_pct,
    ROUND(CAST(100.0 * COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status IN ('Evadido', 'Desligado'))
               / COUNT(DISTINCT a.sk_dim_aluno) AS NUMERIC), 2)          AS taxa_evasao_pct,
    ROUND(CAST(AVG(ca.cr) AS NUMERIC), 2)                                AS cr_medio
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
JOIN cr_aluno ca ON ca.sk_dim_aluno = a.sk_dim_aluno
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY grupo
ORDER BY grupo;

-- 3b. O mesmo indicador aberto por modalidade de cota específica
SELECT
    a.tipo_cota,
    COUNT(DISTINCT a.sk_dim_aluno)                                       AS alunos,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                                AS taxa_reprovacao_pct,
    ROUND(CAST(100.0 * COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status IN ('Evadido', 'Desligado'))
               / COUNT(DISTINCT a.sk_dim_aluno) AS NUMERIC), 2)          AS taxa_evasao_pct
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY a.tipo_cota
ORDER BY taxa_reprovacao_pct DESC;


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
--    "Período" aqui é a posição relativa do aluno no curso (1º, 2º...),
--    não o semestre do calendário, para responder à pergunta real:
--    "os alunos reprovam/evadem mais no início ou no fim do curso?"
--    Cada aluno conta uma única vez como "reprovado" em cada período,
--    mesmo que tenha reprovado em mais de uma disciplina nesse período
--    (a taxa de reprovação é sobre alunos, não sobre matrículas).
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
               / ap.alunos_ativos AS NUMERIC), 2)                       AS taxa_reprovacao_pct,
    COALESCE(ep.evasoes, 0)                                             AS evasoes_neste_periodo,
    ROUND(CAST(100.0 * COALESCE(ep.evasoes, 0)
               / ap.alunos_ativos AS NUMERIC), 2)                       AS taxa_evasao_pct
FROM ativos_periodo ap
LEFT JOIN reprov_periodo rp ON rp.periodo_relativo = ap.periodo_relativo
LEFT JOIN evasao_periodo ep ON ep.periodo_relativo = ap.periodo_relativo
ORDER BY ap.periodo_relativo;


-- ---------------------------------------------------------------------
-- 6. Evolução temporal do desempenho de uma disciplina específica
--    Troque o código em d.codigo = '...' pela disciplina de interesse.
--    Útil para ver se uma mudança de professor, ementa ou monitoria
--    melhorou a aprovação ao longo dos semestres.
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
WHERE d.codigo = 'IF103'   -- Teoria da Computação, como exemplo
GROUP BY dt.semestre
ORDER BY dt.semestre;


-- ---------------------------------------------------------------------
-- 7. Top 10 disciplinas gargalo do fluxo curricular, de um curso
--    Ranking por volume absoluto de reprovações (não por percentual),
--    para mostrar onde reestruturar o curso traria o maior ganho.
--    Troque o nome em c.nome = '...' pelo curso de interesse: como
--    várias disciplinas são compartilhadas entre cursos (ex.: Cálculo 1
--    em várias engenharias), a reprovação só conta aqui se o aluno
--    reprovado estava matriculado no curso filtrado.
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
--    Muita reprovação por nota pede reforço pedagógico. Já muita reprovação
--    por falta aponta conflito de horário ou desengajamento.
-- ---------------------------------------------------------------------
SELECT
    d.codigo,
    d.nome                                                               AS disciplina,
    COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')      AS total_reprovacoes,
    COUNT(*) FILTER (WHERE f.situacao_disciplina = 'Reprovado por nota')  AS reprov_nota,
    COUNT(*) FILTER (WHERE f.situacao_disciplina = 'Reprovado por falta') AS reprov_falta,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina = 'Reprovado por nota')
               / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%'), 0)
               AS NUMERIC), 2)                                           AS pct_reprov_por_nota,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina = 'Reprovado por falta')
               / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%'), 0)
               AS NUMERIC), 2)                                           AS pct_reprov_por_falta
FROM fato_disciplina f
JOIN dim_disciplina d ON d.sk_dim_disciplina = f.sk_dim_disciplina
GROUP BY d.codigo, d.nome
HAVING COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%') >= 15
ORDER BY total_reprovacoes DESC;


-- ---------------------------------------------------------------------
-- 9. Impacto do modelo de co-docência no desempenho
--    Compara turmas lecionadas por um único professor (grupo solo) com
--    turmas lecionadas por dois professores em conjunto (co-docência).
-- ---------------------------------------------------------------------
WITH professores_por_grupo AS (
    SELECT sk_grupo_professor, COUNT(*) AS qtd_professores
    FROM bridge_grupo_professor
    GROUP BY sk_grupo_professor
)
SELECT
    CASE WHEN pg.qtd_professores > 1 THEN 'Co-docência (2+ professores)'
         ELSE 'Professor único' END                                     AS modelo_de_ensino,
    COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado')          AS matriculas_avaliadas,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
               / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado'), 0)
               AS NUMERIC), 2)                                           AS taxa_aprovacao_pct,
    ROUND(CAST(AVG(f.nota_final) FILTER (WHERE f.situacao_disciplina <> 'Trancado')
               AS NUMERIC), 2)                                           AS nota_media
FROM fato_disciplina f
JOIN professores_por_grupo pg ON pg.sk_grupo_professor = f.sk_grupo_professor
GROUP BY modelo_de_ensino
ORDER BY modelo_de_ensino;


-- ---------------------------------------------------------------------
-- 10. Desempenho por turno de oferta, disciplina a disciplina
--     Mostra se uma matéria sofre mais no turno em que os alunos
--     costumam trabalhar (em geral, o noturno).
--     Só disciplinas ofertadas em mais de um turno, com pelo menos
--     20 matrículas no turno, para não ranquear amostra pequena.
-- ---------------------------------------------------------------------
WITH por_turno AS (
    SELECT
        d.codigo,
        d.nome                                                           AS disciplina,
        t.turno,
        COUNT(*)                                                         AS matriculas,
        100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
            / COUNT(*)                                                   AS taxa_aprovacao,
        AVG(f.nota_final) FILTER (WHERE f.situacao_disciplina <> 'Trancado') AS nota_media
    FROM fato_disciplina f
    JOIN dim_disciplina d       ON d.sk_dim_disciplina       = f.sk_dim_disciplina
    JOIN dim_turma_disciplina t ON t.sk_dim_turma_disciplina = f.sk_dim_turma_disciplina
    GROUP BY d.codigo, d.nome, t.turno
    HAVING COUNT(*) >= 20
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
-- 11. Rendimento por titulação do corpo docente
-- ---------------------------------------------------------------------
SELECT
    p.titulo,
    COUNT(DISTINCT p.sk_professor)                                       AS professores,
    ROUND(CAST(AVG(p.salario) AS NUMERIC), 2)                            AS salario_medio,
    COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado')          AS matriculas_avaliadas,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
               / NULLIF(COUNT(*) FILTER (WHERE f.situacao_disciplina <> 'Trancado'), 0)
               AS NUMERIC), 2)                                           AS taxa_aprovacao_pct,
    ROUND(CAST(AVG(f.nota_final) FILTER (WHERE f.situacao_disciplina <> 'Trancado')
               AS NUMERIC), 2)                                           AS nota_media
FROM fato_disciplina f
JOIN bridge_grupo_professor bp ON bp.sk_grupo_professor = f.sk_grupo_professor
JOIN dim_professor p            ON p.sk_professor        = bp.sk_professor
GROUP BY p.titulo
ORDER BY taxa_aprovacao_pct DESC;