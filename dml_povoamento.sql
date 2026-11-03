-- 1. Dimensao Curso
INSERT INTO dim_curso VALUES 
(1, 'CC01', 'Ciência da Computação', 'CIn', 'Ciência da Computação'),
(2, 'EC01', 'Engenharia da Computação', 'CIn', 'Engenharia');

-- 2. Dimensao Disciplina
INSERT INTO dim_disciplina VALUES 
(1, 'IF669', 'Introdução à Programação', 4, 60),
(2, 'MA011', 'Cálculo 1', 4, 60),
(3, 'IF682', 'Data Warehousing', 4, 60),
(4, 'MA014', 'Álgebra Linear', 4, 60),
(5, 'IF685', 'Inteligência Artificial', 4, 60);

-- 3. Dimensao Turma Disciplina
INSERT INTO dim_turma_disciplina VALUES 
(1, '2026.1', '24M12', 'Manhã'),
(2, '2026.1', '35T34', 'Tarde'),
(3, '2026.2', '24M34', 'Manhã'),
(4, '2026.2', '35T12', 'Tarde');

-- 4. Dimensao Data
INSERT INTO dim_data VALUES 
(1, '2026-06-30', '2026.1'),
(2, '2026-11-30', '2026.2');

-- 5. Dimensao Grupo Professor
INSERT INTO dim_grupo_professor VALUES 
(1, 'Márcio Cornélio', 'Doutorado', 15000.00),
(2, 'Anjolina Grisi', 'Doutorado', 15500.00),
(3, 'Katia Guimarães', 'Doutorado', 16000.00);

-- 6. Dimensao Aluno
INSERT INTO dim_aluno VALUES 
(1, '2026001', 'Arthur Silva', '111.222.333-01', 'Masculino', 'Parda', 'Pública', 'SISU', 'Escola Pública', 'Ativo'),
(2, '2026002', 'Felipe Almeida', '111.222.333-02', 'Masculino', 'Branca', 'Privada', 'SISU', 'Ampla Concorrência', 'Ativo'),
(3, '2026003', 'João Duarte', '111.222.333-03', 'Masculino', 'Branca', 'Privada', 'SISU', 'Ampla Concorrência', 'Ativo'),
(4, '2026004', 'João Motta', '111.222.333-04', 'Masculino', 'Parda', 'Pública', 'SISU', 'Cota Renda', 'Ativo'),
(5, '2026005', 'Mirella Fontinelle', '111.222.333-05', 'Feminino', 'Branca', 'Privada', 'SISU', 'Ampla Concorrência', 'Ativo'),
(6, '2026006', 'Severino Junior', '111.222.333-06', 'Masculino', 'Preta', 'Pública', 'SISU', 'PPI', 'Ativo'),
(7, '2026007', 'Beatriz Souza', '111.222.333-07', 'Feminino', 'Parda', 'Pública', 'SISU', 'Escola Pública', 'Ativo'),
(8, '2026008', 'Lucas Lima', '111.222.333-08', 'Masculino', 'Branca', 'Privada', 'SISU', 'Ampla Concorrência', 'Ativo'),
(9, '2026009', 'Mariana Costa', '111.222.333-09', 'Feminino', 'Preta', 'Pública', 'SISU', 'PPI', 'Ativo'),
(10, '2026010', 'Gabriel Rocha', '111.222.333-10', 'Masculino', 'Parda', 'Privada', 'SISU', 'Ampla Concorrência', 'Ativo');

-- 7. Tabela Fato Disciplina (50 Registros)
INSERT INTO fato_disciplina (sk_dim_aluno, sk_dim_disciplina, sk_dim_curso, sk_dim_turma_disciplina, sk_dim_data, sk_grupo_professor, nota_final, falta, situacao_disciplina) VALUES 
(1, 1, 1, 1, 1, 1, 8.5, 2, 'Aprovado'),
(2, 1, 1, 1, 1, 1, 9.0, 0, 'Aprovado'),
(3, 1, 1, 1, 1, 1, 6.5, 4, 'Aprovado'),
(4, 1, 1, 1, 1, 1, 4.0, 10, 'Reprovado por Nota'),
(5, 1, 1, 1, 1, 1, 9.5, 1, 'Aprovado'),
(6, 1, 1, 1, 1, 1, 5.0, 18, 'Reprovado por Falta'),
(7, 1, 1, 1, 1, 1, 7.8, 4, 'Aprovado'),
(8, 1, 1, 1, 1, 1, 8.2, 2, 'Aprovado'),
(9, 1, 1, 1, 1, 1, 3.5, 12, 'Reprovado por Nota'),
(10, 1, 1, 1, 1, 1, 7.0, 6, 'Aprovado'),
(1, 2, 1, 2, 1, 2, 3.0, 8, 'Reprovado por Nota'),
(2, 2, 1, 2, 1, 2, 8.0, 2, 'Aprovado'),
(3, 2, 1, 2, 1, 2, 7.5, 4, 'Aprovado'),
(4, 2, 1, 2, 1, 2, 2.5, 20, 'Reprovado por Falta'),
(5, 2, 1, 2, 1, 2, 9.8, 0, 'Aprovado'),
(6, 2, 1, 2, 1, 2, 4.5, 14, 'Reprovado por Nota'),
(7, 2, 1, 2, 1, 2, 6.0, 6, 'Aprovado'),
(8, 2, 1, 2, 1, 2, 8.7, 2, 'Aprovado'),
(9, 2, 1, 2, 1, 2, 5.5, 10, 'Reprovado por Nota'),
(10, 2, 1, 2, 1, 2, 7.2, 4, 'Aprovado'),
(1, 3, 1, 3, 2, 3, 9.0, 0, 'Aprovado'),
(2, 3, 1, 3, 2, 3, 8.5, 2, 'Aprovado'),
(3, 3, 1, 3, 2, 3, 7.0, 4, 'Aprovado'),
(4, 3, 1, 3, 2, 3, 6.8, 6, 'Aprovado'),
(5, 3, 1, 3, 2, 3, 10.0, 0, 'Aprovado'),
(6, 3, 1, 3, 2, 3, 5.2, 12, 'Reprovado por Nota'),
(7, 3, 1, 3, 2, 3, 8.1, 2, 'Aprovado'),
(8, 3, 1, 3, 2, 3, 9.2, 1, 'Aprovado'),
(9, 3, 1, 3, 2, 3, 6.5, 8, 'Aprovado'),
(10, 3, 1, 3, 2, 3, 7.9, 4, 'Aprovado'),
(1, 4, 1, 4, 2, 1, 4.0, 6, 'Reprovado por Nota'),
(2, 4, 1, 4, 2, 1, 7.5, 2, 'Aprovado'),
(3, 4, 1, 4, 2, 1, 6.0, 4, 'Aprovado'),
(4, 4, 1, 4, 2, 1, 3.2, 16, 'Reprovado por Falta'),
(5, 4, 1, 4, 2, 1, 8.9, 2, 'Aprovado'),
(6, 4, 1, 4, 2, 1, 4.8, 10, 'Reprovado por Nota'),
(7, 4, 1, 4, 2, 1, 7.1, 4, 'Aprovado'),
(8, 4, 1, 4, 2, 1, 8.0, 0, 'Aprovado'),
(9, 4, 1, 4, 2, 1, 2.0, 18, 'Reprovado por Falta'),
(10, 4, 1, 4, 2, 1, 6.7, 6, 'Aprovado'),
(1, 5, 1, 3, 2, 2, 8.8, 2, 'Aprovado'),
(2, 5, 1, 3, 2, 2, 9.4, 0, 'Aprovado'),
(3, 5, 1, 3, 2, 2, 8.0, 2, 'Aprovado'),
(4, 5, 1, 3, 2, 2, 5.0, 8, 'Reprovado por Nota'),
(5, 5, 1, 3, 2, 2, 9.7, 1, 'Aprovado'),
(6, 5, 1, 3, 2, 2, 6.0, 6, 'Aprovado'),
(7, 5, 1, 3, 2, 2, 7.5, 4, 'Aprovado'),
(8, 5, 1, 3, 2, 2, 8.9, 0, 'Aprovado'),
(9, 5, 1, 3, 2, 2, 4.2, 14, 'Reprovado por Nota'),
(10, 5, 1, 3, 2, 2, 7.8, 2, 'Aprovado');
