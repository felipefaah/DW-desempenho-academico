## **Perguntas de negócio** 

Consultas analíticas sobre o esquema estrela acadêmico 

**\. Desempenho e retenção por escola de origem (pública x privada)**

* **Pergunta que responde:** Qual é o impacto da escola de origem (pública vs. privada) nas taxas de aprovação, reprovação, evasão e nota média dos alunos?  
* **Utilidade:** Fundamental para direcionar as verbas de assistência estudantil e justificar a criação de programas de nivelamento (aulas de reforço iniciais) focados nos alunos que vieram da rede pública e sofrem com a transição para o nível superior.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_aluno.

**\. Retenção por gênero e por curso**

* **Pergunta que responde:** Existem disparidades de retenção, evasão e nota média entre homens e mulheres dentro de cada curso?  
* **Utilidade:** Serve para monitorar a inclusão e o ambiente acadêmico. Em cursos de Exatas e Computação, ajuda a desmistificar preconceitos e embasar políticas de atração e retenção de talentos femininos, comprovando com dados o desempenho real.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_aluno, dim\_curso.

**\. Avaliação das políticas de cotas (Ações Afirmativas)**

* **Pergunta que responde:** Os alunos ingressantes por cotas conseguem progredir no curso mantendo o mesmo Coeficiente de Rendimento (CR) e taxas de aprovação que os alunos da ampla concorrência?  
* **Utilidade:** Avalia a eficácia das políticas de inclusão a longo prazo. Demonstra que garantir o acesso (cota) não basta; é preciso garantir a permanência (suporte acadêmico e financeiro) para equiparar as taxas de sucesso.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_aluno, dim\_disciplina (usada no CTE para calcular o peso dos créditos no CR).

**\. Evolução histórica da taxa global de reprovação**

* **Pergunta que responde:** Como a taxa de reprovação do curso como um todo está evoluindo a cada semestre calendário?  
* **Utilidade:** Fornece um "termômetro" macro da instituição. Se a taxa sobe consistentemente ano após ano, pode indicar que a régua do curso subiu demais, ou que o perfil do ingressante mudou, exigindo intervenção da diretoria.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_data.

**\. Mapeamento dos períodos de maior reprovação e evasão**

* **Pergunta que responde:** Em qual momento da jornada (1º período, 2º período, reta final) os alunos mais reprovam e abandonam o curso?  
* **Utilidade:** Descobre os "picos" de desistência ou bomba. Identifica se o problema está no choque inicial (disciplinas de base estrutural matemática) ou na transição para metodologias de pesquisa (como o TCC).  
* **Tabelas utilizadas:** fato\_disciplina, dim\_turma\_disciplina, dim\_aluno.

**\. Evolução temporal do desempenho de uma disciplina específica**

* **Pergunta que responde:** Como o desempenho (taxa de aprovação e nota média) da matéria "X" se comportou ao longo dos últimos semestres?  
* **Utilidade:** Permite medir o ROI (Retorno sobre Investimento) de mudanças pedagógicas. Se a coordenação mudou a ementa, o professor ou adicionou monitores em "Teoria da Computação", essa consulta prova se a mudança deu resultado.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_disciplina, dim\_data.

**\. Top 10 disciplinas gargalo do fluxo curricular (por curso)**

* **Pergunta que responde:** Quais são as 10 matérias que, em volume absoluto de alunos retidos, representam o maior gargalo para a formatura no curso "Y"?  
* **Utilidade:** Foca os esforços da coordenação onde o impacto é maior. O uso do volume absoluto (e não percentual) evita que matérias optativas minúsculas poluam o ranking, revelando as verdadeiras "travas" da grade.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_disciplina, dim\_curso.

**\. Composição da reprovação: dificuldade (nota) vs. abandono (falta)**

* **Pergunta que responde:** Nas matérias onde os alunos mais reprovam, essa reprovação acontece por nota baixa (dificuldade técnica) ou por faltas (abandono)?  
* **Utilidade:** Separa problemas pedagógicos de problemas estruturais. Reprovação por nota exige rever método de ensino e aplicar monitoria; reprovação por falta indica choque de horário, desengajamento ou necessidade do aluno trabalhar.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_disciplina.


**\. Desempenho por turno de oferta, disciplina a disciplina**

* **Pergunta que responde:** Uma mesma disciplina possui uma discrepância grande de aprovação quando ofertada de manhã em comparação à noite?  
* **Utilidade:** Avalia o impacto do cansaço e da jornada dupla (trabalho \+ estudo) no rendimento. Pode forçar a coordenação a adaptar a didática, o volume de trabalhos ou a avaliação para as turmas noturnas.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_disciplina, dim\_turma\_disciplina.


**\. Top 10 disciplinas com maior índice de absenteísmo (Faltas)**

* **Pergunta que responde:** Quais disciplinas apresentam o maior volume e a maior média de faltas por aluno ao longo do semestre?  
* **Utilidade:** Identificar matérias que causam desengajamento sistemático. Se uma disciplina tem média de notas razoável, mas um absenteísmo gigantesco, pode indicar que as aulas não são atrativas, a didática não exige presença, ou há um conflito de horários que força os alunos a faltarem (como disciplinas no fim da noite ou início da manhã).  
* **Tabelas utilizadas:** fato\_disciplina, dim\_disciplina.

**\.Top 10 Disciplinas com as menores médias de notas**

* **Pergunta que responde:** Quais são as disciplinas onde os alunos, em média, obtêm as notas finais mais baixas, independentemente da taxa de aprovação/reprovação?  
* **Utilidade:** Detectar falhas de aprendizado generalizadas ou rigor excessivo na avaliação. Uma disciplina pode ter uma taxa de aprovação razoável porque os alunos passam "raspando" (média 5,0), o que indica que o domínio real do conteúdo pela turma é muito fraco, prejudicando disciplinas futuras que dependam desse conhecimento.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_disciplina.

**\. Top 10 Disciplinas com as maiores médias**

* **Pergunta que responde:** Quais disciplinas apresentam as médias de nota finais mais altas (ex: turmas onde a média geral é 8,5 ou 9,0)?  
* **Utilidade:** Pode indicar duas coisas para a gestão: disciplinas com metodologias de ensino de extremo sucesso e alto engajamento (que devem ser replicadas), ou disciplinas com avaliações pouco rigorosas ("fáceis demais"), o que ajuda o Núcleo Docente Estruturante (NDE) a equilibrar o nível de exigência da grade curricular.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_disciplina.

**\. Top 10 Cursos com maior taxa de abandono da universidade**

* **Pergunta que responde:** Quais cursos da universidade apresentam as maiores taxas percentuais e o maior volume absoluto de abandono (evasão) de alunos?  
* **Utilidade:** Visão puramente estratégica para a Reitoria e Pró-Reitoria. Se um curso tem uma taxa de abandono discrepante do resto da universidade, isso acende um alerta vermelho para problemas estruturais: o currículo pode estar desatualizado, o mercado de trabalho pode não estar atrativo para a profissão, ou a infraestrutura e o corpo docente do centro estão falhando em engajar os estudantes.  
* **Tabelas utilizadas:** fato\_disciplina, dim\_aluno, dim\_curso.


