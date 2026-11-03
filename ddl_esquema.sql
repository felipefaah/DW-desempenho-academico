CREATE TABLE dim_aluno (
    sk_dim_aluno INT PRIMARY KEY,
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
    sk_dim_disciplina INT PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    creditos INT NOT NULL,
    carga_horaria INT NOT NULL
);

CREATE TABLE dim_curso (
    sk_dim_curso INT PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    centro VARCHAR(50),
    departamento VARCHAR(50)
);

CREATE TABLE dim_turma_disciplina (
    sk_dim_turma_disciplina INT PRIMARY KEY,
    periodo_disciplina VARCHAR(10) NOT NULL,
    horario VARCHAR(50),
    turno VARCHAR(20)
);

CREATE TABLE dim_data (
    sk_dim_data INT PRIMARY KEY,
    data_registro DATE NOT NULL,
    semestre VARCHAR(10) NOT NULL
);

CREATE TABLE dim_grupo_professor (
    sk_grupo_professor INT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    titulo VARCHAR(50),
    salario DECIMAL(10,2)
);

CREATE TABLE fato_disciplina (
    sk_fato INT PRIMARY KEY AUTO_INCREMENT,
    sk_dim_aluno INT NOT NULL,
    sk_dim_disciplina INT NOT NULL,
    sk_dim_curso INT NOT NULL,
    sk_dim_turma_disciplina INT NOT NULL,
    sk_dim_data INT NOT NULL,
    sk_grupo_professor INT NOT NULL,
    nota_final DECIMAL(4,2) NOT NULL,
    falta INT NOT NULL,
    situacao_disciplina VARCHAR(30) NOT NULL,
    FOREIGN KEY (sk_dim_aluno) REFERENCES dim_aluno(sk_dim_aluno),
    FOREIGN KEY (sk_dim_disciplina) REFERENCES dim_disciplina(sk_dim_disciplina),
    FOREIGN KEY (sk_dim_curso) REFERENCES dim_curso(sk_dim_curso),
    FOREIGN KEY (sk_dim_turma_disciplina) REFERENCES dim_turma_disciplina(sk_dim_turma_disciplina),
    FOREIGN KEY (sk_dim_data) REFERENCES dim_data(sk_dim_data),
    FOREIGN KEY (sk_grupo_professor) REFERENCES dim_grupo_professor(sk_grupo_professor)
);
