-- 1. Taxa de aprovação e nota média por disciplina
--    Ordenada da disciplina mais difícil para a mais fácil.
-- ---------------------------------------------------------------------
SELECT
    d.codigo,
    d.nome                                                         AS disciplina,
    COUNT(*)                                                       AS matriculas_avaliadas,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                   AS nota_media,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
               / COUNT(*) AS NUMERIC), 2)                          AS taxa_aprovacao_pct
FROM fato_disciplina f
JOIN dim_disciplina d ON d.sk_dim_disciplina = f.sk_dim_disciplina
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY d.codigo, d.nome
HAVING COUNT(*) >= 30
ORDER BY taxa_aprovacao_pct ASC;
 
 
-- ---------------------------------------------------------------------
-- 2. Professores que mais reprovam (mínimo de 50 alunos avaliados)
--    Separa reprovação por nota e por falta.
-- ---------------------------------------------------------------------
SELECT
    p.nome                                                         AS professor,
    p.titulo,
    COUNT(*)                                                       AS alunos_avaliados,
    COUNT(*) FILTER (WHERE f.situacao_disciplina = 'Reprovado por nota')  AS reprov_nota,
    COUNT(*) FILTER (WHERE f.situacao_disciplina = 'Reprovado por falta') AS reprov_falta,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                          AS taxa_reprovacao_pct,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                   AS nota_media_turmas
FROM fato_disciplina f
JOIN dim_grupo_professor p ON p.sk_grupo_professor = f.sk_grupo_professor
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY p.nome, p.titulo
HAVING COUNT(*) >= 50
ORDER BY taxa_reprovacao_pct DESC
LIMIT 10;
 
 
-- ---------------------------------------------------------------------
-- 3. Percentual de alunos que nunca reprovaram
--    (considera apenas alunos com ao menos uma disciplina registrada)
-- ---------------------------------------------------------------------
WITH por_aluno AS (
    SELECT
        sk_dim_aluno,
        COUNT(*) FILTER (WHERE situacao_disciplina LIKE 'Reprovado%') AS reprovacoes
    FROM fato_disciplina
    GROUP BY sk_dim_aluno
)
SELECT
    COUNT(*)                                                       AS total_alunos,
    COUNT(*) FILTER (WHERE reprovacoes = 0)                        AS nunca_reprovaram,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE reprovacoes = 0)
               / COUNT(*) AS NUMERIC), 2)                          AS pct_nunca_reprovaram
FROM por_aluno;
 
 
-- 3b. O mesmo indicador aberto por curso
WITH por_aluno AS (
    SELECT
        sk_dim_aluno,
        sk_dim_curso,
        COUNT(*) FILTER (WHERE situacao_disciplina LIKE 'Reprovado%') AS reprovacoes
    FROM fato_disciplina
    GROUP BY sk_dim_aluno, sk_dim_curso
)
SELECT
    c.nome                                                         AS curso,
    COUNT(*)                                                       AS alunos,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE pa.reprovacoes = 0)
               / COUNT(*) AS NUMERIC), 2)                          AS pct_nunca_reprovaram
FROM por_aluno pa
JOIN dim_curso c ON c.sk_dim_curso = pa.sk_dim_curso
GROUP BY c.nome
ORDER BY pct_nunca_reprovaram DESC;
 
 
-- ---------------------------------------------------------------------
-- 4. Forma de ingresso x reprovações
-- ---------------------------------------------------------------------
SELECT
    a.forma_ingresso,
    COUNT(DISTINCT a.sk_dim_aluno)                                 AS alunos,
    COUNT(*)                                                       AS matriculas_avaliadas,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                          AS taxa_reprovacao_pct,
    ROUND(CAST(1.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(DISTINCT a.sk_dim_aluno) AS NUMERIC), 2)    AS reprovacoes_por_aluno,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                   AS nota_media
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY a.forma_ingresso
ORDER BY taxa_reprovacao_pct DESC;
 
 
-- ---------------------------------------------------------------------
-- 5. Raça/etnia x reprovações
--    Leitura recomendada junto com a consulta 5b (tipo de escola e cota),
--    porque eventuais diferenças tendem a refletir trajetória escolar e
--    condição socioeconômica, não a raça/etnia em si.
-- ---------------------------------------------------------------------
SELECT
    a.raca_etnia,
    COUNT(DISTINCT a.sk_dim_aluno)                                 AS alunos,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                          AS taxa_reprovacao_pct,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina = 'Reprovado por falta')
               / COUNT(*) AS NUMERIC), 2)                          AS taxa_reprov_falta_pct,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                   AS nota_media
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY a.raca_etnia
ORDER BY taxa_reprovacao_pct DESC;
 
 
-- 5b. Tipo de escola no ensino médio e modalidade de cota x desempenho
SELECT
    a.escola_em,
    a.tipo_cota,
    COUNT(DISTINCT a.sk_dim_aluno)                                 AS alunos,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Reprovado%')
               / COUNT(*) AS NUMERIC), 2)                          AS taxa_reprovacao_pct,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                   AS nota_media
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY a.escola_em, a.tipo_cota
ORDER BY a.escola_em, taxa_reprovacao_pct DESC;
 
 
-- ---------------------------------------------------------------------
-- 6. Qual turno é mais eficiente
--    Eficiência = aprovação alta, poucas faltas e poucos trancamentos.
--    Aqui os trancamentos entram no denominador de propósito.
-- ---------------------------------------------------------------------
SELECT
    t.turno,
    COUNT(*)                                                       AS matriculas,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
               / COUNT(*) AS NUMERIC), 2)                          AS taxa_aprovacao_pct,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina = 'Reprovado por falta')
               / COUNT(*) AS NUMERIC), 2)                          AS taxa_reprov_falta_pct,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina = 'Trancado')
               / COUNT(*) AS NUMERIC), 2)                          AS taxa_trancamento_pct,
    ROUND(CAST(AVG(f.nota_final) FILTER (WHERE f.situacao_disciplina <> 'Trancado')
               AS NUMERIC), 2)                                     AS nota_media,
    ROUND(CAST(AVG(100.0 * f.falta / d.carga_horaria)
               FILTER (WHERE f.situacao_disciplina <> 'Trancado') AS NUMERIC), 2)
                                                                   AS faltas_medias_pct_ch
FROM fato_disciplina f
JOIN dim_turma_disciplina t ON t.sk_dim_turma_disciplina = f.sk_dim_turma_disciplina
JOIN dim_disciplina d       ON d.sk_dim_disciplina       = f.sk_dim_disciplina
GROUP BY t.turno
ORDER BY taxa_aprovacao_pct DESC;
 
 
-- ---------------------------------------------------------------------
-- 7. Cursos com maior tempo de permanência (estadia)
--    Permanência = número de semestres distintos com matrícula.
--    Mostra a média geral e a média só dos formados (tempo até concluir).
-- ---------------------------------------------------------------------
WITH semestres_aluno AS (
    SELECT
        f.sk_dim_curso,
        f.sk_dim_aluno,
        COUNT(DISTINCT dt.semestre)                                AS semestres
    FROM fato_disciplina f
    JOIN dim_data dt ON dt.sk_dim_data = f.sk_dim_data
    GROUP BY f.sk_dim_curso, f.sk_dim_aluno
)
SELECT
    c.nome                                                         AS curso,
    COUNT(*)                                                       AS alunos,
    ROUND(CAST(AVG(sa.semestres) AS NUMERIC), 2)                   AS media_semestres_todos,
    ROUND(CAST(AVG(sa.semestres) FILTER (WHERE a.status = 'Formado') AS NUMERIC), 2)
                                                                   AS media_semestres_formados,
    MAX(sa.semestres)                                              AS max_semestres,
    COUNT(*) FILTER (WHERE a.status = 'Formado')                   AS formados,
    COUNT(*) FILTER (WHERE a.status IN ('Evadido', 'Desligado'))   AS evadidos_desligados
FROM semestres_aluno sa
JOIN dim_curso c ON c.sk_dim_curso = sa.sk_dim_curso
JOIN dim_aluno a ON a.sk_dim_aluno = sa.sk_dim_aluno
GROUP BY c.nome
ORDER BY media_semestres_todos DESC;
 
 
-- =====================================================================
-- Consultas extras
-- =====================================================================
 
-- ---------------------------------------------------------------------
-- 8. Evasão por curso (status do aluno)
-- ---------------------------------------------------------------------
SELECT
    c.nome                                                         AS curso,
    COUNT(DISTINCT a.sk_dim_aluno)                                 AS alunos,
    ROUND(CAST(100.0 * COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status IN ('Evadido', 'Desligado'))
               / COUNT(DISTINCT a.sk_dim_aluno) AS NUMERIC), 2)    AS taxa_evasao_pct,
    ROUND(CAST(100.0 * COUNT(DISTINCT a.sk_dim_aluno) FILTER (WHERE a.status = 'Trancado')
               / COUNT(DISTINCT a.sk_dim_aluno) AS NUMERIC), 2)    AS taxa_trancamento_pct
FROM fato_disciplina f
JOIN dim_aluno a ON a.sk_dim_aluno = f.sk_dim_aluno
JOIN dim_curso c ON c.sk_dim_curso = f.sk_dim_curso
GROUP BY c.nome
ORDER BY taxa_evasao_pct DESC;
 
 
-- ---------------------------------------------------------------------
-- 9. Disciplinas "gargalo": as mais cursadas mais de uma vez pelo
--    mesmo aluno (retenção).
-- ---------------------------------------------------------------------
WITH tentativas AS (
    SELECT sk_dim_aluno, sk_dim_disciplina, COUNT(*) AS vezes
    FROM fato_disciplina
    GROUP BY sk_dim_aluno, sk_dim_disciplina
)
SELECT
    d.codigo,
    d.nome                                                         AS disciplina,
    COUNT(*)                                                       AS alunos_que_cursaram,
    COUNT(*) FILTER (WHERE t.vezes > 1)                            AS alunos_que_repetiram,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE t.vezes > 1)
               / COUNT(*) AS NUMERIC), 2)                          AS pct_repeticao,
    MAX(t.vezes)                                                   AS max_tentativas
FROM tentativas t
JOIN dim_disciplina d ON d.sk_dim_disciplina = t.sk_dim_disciplina
GROUP BY d.codigo, d.nome
HAVING COUNT(*) >= 30
ORDER BY pct_repeticao DESC
LIMIT 10;
 
 
-- ---------------------------------------------------------------------
-- 10. Titulação do professor x desempenho dos alunos
--     (inclui o custo médio da folha por aluno avaliado)
-- ---------------------------------------------------------------------
SELECT
    p.titulo,
    COUNT(DISTINCT p.sk_grupo_professor)                           AS professores,
    ROUND(CAST(AVG(p.salario) AS NUMERIC), 2)                      AS salario_medio,
    ROUND(CAST(100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%')
               / COUNT(*) AS NUMERIC), 2)                          AS taxa_aprovacao_pct,
    ROUND(CAST(AVG(f.nota_final) AS NUMERIC), 2)                   AS nota_media
FROM fato_disciplina f
JOIN dim_grupo_professor p ON p.sk_grupo_professor = f.sk_grupo_professor
WHERE f.situacao_disciplina <> 'Trancado'
GROUP BY p.titulo
ORDER BY taxa_aprovacao_pct DESC;
 
 
-- ---------------------------------------------------------------------
-- 11. Evolução semestral: aprovação e nota média ao longo do tempo,
--     com a variação em relação ao semestre anterior (função de janela).
-- ---------------------------------------------------------------------
WITH por_semestre AS (
    SELECT
        dt.semestre,
        100.0 * COUNT(*) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%') / COUNT(*) AS aprov,
        AVG(f.nota_final)                                          AS nota
    FROM fato_disciplina f
    JOIN dim_data dt ON dt.sk_dim_data = f.sk_dim_data
    WHERE f.situacao_disciplina <> 'Trancado'
    GROUP BY dt.semestre
)
SELECT
    semestre,
    ROUND(CAST(aprov AS NUMERIC), 2)                               AS taxa_aprovacao_pct,
    ROUND(CAST(aprov - LAG(aprov) OVER (ORDER BY semestre) AS NUMERIC), 2)
                                                                   AS variacao_pp,
    ROUND(CAST(nota AS NUMERIC), 2)                                AS nota_media
FROM por_semestre
ORDER BY semestre;
 
 
-- ---------------------------------------------------------------------
-- 12. Top 3 alunos por curso pelo coeficiente de rendimento (CR),
--     média das notas ponderada pelos créditos.
-- ---------------------------------------------------------------------
WITH cr AS (
    SELECT
        f.sk_dim_curso,
        f.sk_dim_aluno,
        SUM(f.nota_final * d.creditos) / SUM(d.creditos)           AS cr,
        SUM(d.creditos) FILTER (WHERE f.situacao_disciplina LIKE 'Aprovado%') AS creditos_integralizados
    FROM fato_disciplina f
    JOIN dim_disciplina d ON d.sk_dim_disciplina = f.sk_dim_disciplina
    WHERE f.situacao_disciplina <> 'Trancado'
    GROUP BY f.sk_dim_curso, f.sk_dim_aluno
    HAVING SUM(d.creditos) >= 40
),
ranking AS (
    SELECT cr.*, RANK() OVER (PARTITION BY sk_dim_curso ORDER BY cr DESC) AS posicao
    FROM cr
)
SELECT
    c.nome                                                         AS curso,
    r.posicao,
    a.matricula,
    a.nome                                                         AS aluno,
    ROUND(CAST(r.cr AS NUMERIC), 2)                                AS cr,
    r.creditos_integralizados
FROM ranking r
JOIN dim_curso c ON c.sk_dim_curso = r.sk_dim_curso
JOIN dim_aluno a ON a.sk_dim_aluno = r.sk_dim_aluno
WHERE r.posicao <= 3
ORDER BY c.nome, r.posicao;
 