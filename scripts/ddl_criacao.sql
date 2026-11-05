CREATE TABLE dim_aluno (
    sk_dim_aluno INTEGER PRIMARY KEY,
    matricula VARCHAR(20) UNIQUE NOT NULL,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL,
    genero VARCHAR(20),
    raca_etnia VARCHAR(30),
    escola_em VARCHAR(30),
    forma_ingresso VARCHAR(40),
    tipo_cota VARCHAR(50),
    status VARCHAR(30)
);

CREATE TABLE dim_disciplina (
    sk_dim_disciplina INTEGER PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    creditos INTEGER NOT NULL,
    carga_horaria INTEGER NOT NULL
);

CREATE TABLE dim_curso (
    sk_dim_curso INTEGER PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    centro VARCHAR(50),
    departamento VARCHAR(50)
);

CREATE TABLE dim_turma_disciplina (
    sk_dim_turma_disciplina INTEGER PRIMARY KEY,
    periodo_disciplina VARCHAR(10) NOT NULL,
    horario VARCHAR(50),
    turno VARCHAR(20)
);

CREATE TABLE dim_data (
    sk_dim_data INTEGER PRIMARY KEY,
    data_registro DATE NOT NULL,
    semestre VARCHAR(10) NOT NULL
);

CREATE TABLE dim_professor (
    sk_professor INTEGER PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) NOT NULL,
    data_contratacao DATE,
    salario DECIMAL(10,2),
    titulo VARCHAR(50)
);

CREATE TABLE bridge_grupo_professor (
    sk_grupo_professor INTEGER NOT NULL,
    sk_professor INTEGER NOT NULL,
    PRIMARY KEY (sk_grupo_professor, sk_professor),
    FOREIGN KEY (sk_professor) REFERENCES dim_professor(sk_professor)
);
CREATE SEQUENCE seq_fato_disciplina_id START 1;
CREATE TABLE fato_disciplina (
    sk_fato INTEGER PRIMARY KEY DEFAULT nextval('seq_fato_disciplina_id'),
    sk_dim_aluno INTEGER NOT NULL,
    sk_dim_disciplina INTEGER NOT NULL,
    sk_dim_curso INTEGER NOT NULL,
    sk_dim_turma_disciplina INTEGER NOT NULL,
    sk_dim_data INTEGER NOT NULL,
    sk_grupo_professor INTEGER NOT NULL, 
    nota_final DECIMAL(4,2) NOT NULL,
    falta INTEGER NOT NULL,
    situacao_disciplina VARCHAR(30) NOT NULL,
    
    FOREIGN KEY (sk_dim_aluno) REFERENCES dim_aluno(sk_dim_aluno),
    FOREIGN KEY (sk_dim_disciplina) REFERENCES dim_disciplina(sk_dim_disciplina),
    FOREIGN KEY (sk_dim_curso) REFERENCES dim_curso(sk_dim_curso),
    FOREIGN KEY (sk_dim_turma_disciplina) REFERENCES dim_turma_disciplina(sk_dim_turma_disciplina),
    FOREIGN KEY (sk_dim_data) REFERENCES dim_data(sk_dim_data)
);