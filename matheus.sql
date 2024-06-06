-- Habilitando saída de dados no ambiente
set serveroutput on
 
-- Desabilitando repetição de código nas mensagens
set verify off

-- drop nas tabelas
DROP TABLE tb_bp_usuario cascade constraints;
DROP TABLE tb_bp_reciclagem cascade constraints;
DROP TABLE tb_bp_pessoa cascade constraints;
DROP TABLE tb_bp_foto cascade constraints;
DROP TABLE tb_bp_log_erro cascade constraints;



-- drop nas sequences (vou usar sequences pra ficar a par de java)
DROP SEQUENCE sq_bp_usuario;
DROP SEQUENCE sq_bp_reciclagem;
DROP SEQUENCE sq_bp_pessoa;
DROP SEQUENCE sq_bp_foto;
DROP SEQUENCE sq_bp_log_erro;


-- criação de sequences
CREATE SEQUENCE sq_bp_foto START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE sq_bp_pessoa START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE sq_bp_reciclagem START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE sq_bp_usuario START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE sq_bp_log_erro START WITH 1 INCREMENT BY 1;



-- criação de tabelas
CREATE TABLE tb_bp_foto (
    id_foto NUMBER(10) CONSTRAINT PK_TB_BP_FOTO_ID PRIMARY KEY,
    src VARCHAR2(255 CHAR)
);

CREATE TABLE tb_bp_pessoa (
    id_pessoa NUMBER(10) CONSTRAINT PK_TB_BP_PESSOA_ID PRIMARY KEY,
    pontos NUMBER(20),
    nm_pessoa VARCHAR2(25 CHAR),
    sobrenome VARCHAR2(25 CHAR)
);

-- Tem o check para verificar se é true ou false
CREATE TABLE tb_bp_reciclagem (
    id_reciclagem NUMBER(10) CONSTRAINT PK_TB_BP_RECICLAGEM_ID PRIMARY KEY,
    foto NUMBER(10) CONSTRAINT UK_TB_BP_RECICLAGEM_FOTO UNIQUE,
    validado NUMBER(1,0) CHECK (validado IN (0,1)),
    pontos NUMBER(10),
    usuario NUMBER(10)
);

CREATE TABLE tb_bp_usuario (
    id_usuario NUMBER(10) CONSTRAINT PK_TB_BP_USUARIO_ID PRIMARY KEY,
    email VARCHAR2(100 CHAR) CONSTRAINT UK_BP_USUARIO_USERNAME UNIQUE,
    senha VARCHAR2(30 CHAR),
    pessoa NUMBER(10)
);

CREATE TABLE tb_bp_log_erro (
    id_erro NUMBER(10) CONSTRAINT PK_TB_BP_LOG_ERRO_ID PRIMARY KEY,
    procedure_name VARCHAR2(100),
    username VARCHAR2(100),
    error_date DATE,
    error_code NUMBER
);

-- Alteração pra colocar as FKs
ALTER TABLE tb_bp_reciclagem ADD CONSTRAINT FK_BP_RECICLAGEM_FOTO FOREIGN KEY (foto) REFERENCES tb_bp_foto;
ALTER TABLE tb_bp_reciclagem ADD CONSTRAINT FK_BP_RECICLAGEM_USUARIO FOREIGN KEY (usuario) REFERENCES tb_bp_usuario;
ALTER TABLE tb_bp_usuario ADD CONSTRAINT FK_BP_USUARIO_PESSOA FOREIGN KEY (pessoa) REFERENCES tb_bp_pessoa;


-- criando as procedures:
CREATE OR REPLACE PROCEDURE inserir_dados_pessoa (
    p_pontos IN NUMBER,
    p_nm_pessoa IN VARCHAR2,
    p_sobrenome IN VARCHAR2
)
AS
    v_sqlcode NUMBER;
BEGIN
    INSERT INTO tb_bp_pessoa (id_pessoa, pontos, nm_pessoa, sobrenome)
    VALUES (sq_bp_pessoa.NEXTVAL, p_pontos, p_nm_pessoa, p_sobrenome);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        v_sqlcode := SQLCODE;
        INSERT INTO tb_bp_log_erro (procedure_name, username, error_date, error_code)
        VALUES ('inserir_dados_pessoa', USER, SYSDATE, v_sqlcode);
        COMMIT;
END;
/


CREATE OR REPLACE PROCEDURE inserir_dados_usuario (
    p_email IN VARCHAR2,
    p_senha IN VARCHAR2,
    p_pessoa IN NUMBER
)
AS
    invalid_email_exception EXCEPTION;
    v_sqlcode NUMBER;
BEGIN
    IF REGEXP_LIKE(p_email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') = FALSE THEN
        RAISE invalid_email_exception;
    END IF;

    INSERT INTO tb_bp_usuario (id_usuario, email, senha, pessoa)
    VALUES (sq_bp_usuario.NEXTVAL, p_email, p_senha, p_pessoa);
    COMMIT;
EXCEPTION
    WHEN invalid_email_exception THEN
        INSERT INTO tb_bp_log_erro (procedure_name, username, error_date, error_code)
        VALUES ('inserir_dados_usuario - O email fornecido não é válido.', USER, SYSDATE, -20002);
        COMMIT;
    WHEN OTHERS THEN
        v_sqlcode := SQLCODE;
        INSERT INTO tb_bp_log_erro (procedure_name, username, error_date, error_code)
        VALUES ('inserir_dados_usuario', USER, SYSDATE, v_sqlcode);
        COMMIT;
END;
/


CREATE OR REPLACE PROCEDURE inserir_dados_foto (
    p_src IN VARCHAR2
)
AS
    invalid_path_exception EXCEPTION;
    v_sqlcode NUMBER;
BEGIN
    IF INSTR(p_src, '/') = 0 AND INSTR(p_src, '\') = 0 THEN
        RAISE invalid_path_exception;
    END IF;

    INSERT INTO tb_bp_foto (id_foto, src)
    VALUES (sq_bp_foto.NEXTVAL, p_src);
    COMMIT;
EXCEPTION
    WHEN invalid_path_exception THEN
        INSERT INTO tb_bp_log_erro (procedure_name, username, error_date, error_code)
        VALUES ('inserir_dados_foto - O caminho da foto deve conter "/" ou "\".', USER, SYSDATE, -20001);
        COMMIT;
    WHEN OTHERS THEN
        v_sqlcode := SQLCODE;
        INSERT INTO tb_bp_log_erro (procedure_name, username, error_date, error_code)
        VALUES ('inserir_dados_foto', USER, SYSDATE, v_sqlcode);
        COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE inserir_dados_reciclagem (
    p_foto IN NUMBER,
    p_validado IN NUMBER,
    p_pontos IN NUMBER,
    p_usuario IN NUMBER
)
AS
    v_sqlcode NUMBER;
BEGIN
    INSERT INTO tb_bp_reciclagem (id_reciclagem, foto, validado, pontos, usuario)
    VALUES (sq_bp_reciclagem.NEXTVAL, p_foto, p_validado, p_pontos, p_usuario);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        v_sqlcode := SQLCODE;
        INSERT INTO tb_bp_log_erro (procedure_name, username, error_date, error_code)
        VALUES ('inserir_dados_reciclagem', USER, SYSDATE, v_sqlcode);
        COMMIT;
END;
/





-- inserindo dados de pessoas por preocedure
BEGIN
    inserir_dados_pessoa(100, 'Ana', 'Meireles');
    inserir_dados_pessoa(50, 'Ana', 'Menendes');
    inserir_dados_pessoa(150, 'Maria', 'Bezerra');
    inserir_dados_pessoa(75, 'Carlos', 'Bezerra');
    inserir_dados_pessoa(30, 'Sara', 'Connor');
END;
/
-- inserindo dados de usuarios por preocedure
BEGIN
    inserir_dados_usuario('ana.meireles@example.com', 'senha123', 1);
    inserir_dados_usuario('ana.menendes@example.com', 'senha321', 2);
    inserir_dados_usuario('maria.bezerra@example.com', 'senha132', 3);
    inserir_dados_usuario('carlos.bezerra@example.com', 'senha231', 4);
    inserir_dados_usuario('sara.connor@example.com', 'senha213', 5);
END;
/
-- inserindo dados de fotos por preocedure
BEGIN
    inserir_dados_foto('path/to/latinha.jpg');
    inserir_dados_foto('path/to/sacolinha.jpg');
    inserir_dados_foto('path/to/plastico.jpg');
    inserir_dados_foto('path/to/vidro.jpg');
    inserir_dados_foto('path/to/papel.jpg');
END;
/
-- inserindo dados de reciclagens por preocedure
BEGIN
    inserir_dados_reciclagem(1, 1, 100, 1);
    inserir_dados_reciclagem(2, 1, 50, 2);
    inserir_dados_reciclagem(3, 1, 150, 3);
    inserir_dados_reciclagem(4, 1, 75, 4);
    inserir_dados_reciclagem(5, 1, 30, 5);
END;
/








-- Blocos anônimos de relatório


-- 1º relatório
DECLARE
    v_total_pontos NUMBER := 0;
BEGIN
    -- Listar todos os dados da tabela
    FOR pessoa_rec IN (SELECT * FROM tb_bp_pessoa) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || pessoa_rec.id_pessoa || ', Nome: ' || pessoa_rec.nm_pessoa || ', Pontos: ' || pessoa_rec.pontos);
        v_total_pontos := v_total_pontos + pessoa_rec.pontos;
    END LOOP;
    
    -- Mostrar dados numéricos sumarizados
    DBMS_OUTPUT.PUT_LINE('Total de Pontos: ' || v_total_pontos);
    
    -- Sumarização dos dados agrupados por critério definido (por exemplo, somar pontos por sobrenome)
    FOR sobrenome_rec IN (SELECT sobrenome, SUM(pontos) AS total_pontos FROM tb_bp_pessoa GROUP BY sobrenome) LOOP
        DBMS_OUTPUT.PUT_LINE('Sobrenome: ' || sobrenome_rec.sobrenome || ', Total de Pontos: ' || sobrenome_rec.total_pontos);
    END LOOP;
END;
/

-- 2º relatório
DECLARE
    v_total_usuarios NUMBER := 0;
BEGIN
    -- Listar todos os dados da tabela Usuario
    FOR usuario_rec IN (SELECT * FROM tb_bp_usuario) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || usuario_rec.id_usuario || ', Email: ' || usuario_rec.email);
        v_total_usuarios := v_total_usuarios + 1;
    END LOOP;
    
    -- Mostrar total de usuários
    DBMS_OUTPUT.PUT_LINE('Total de Usuários: ' || v_total_usuarios);
END;
/
-- 3º relatório
DECLARE
    v_total_fotos NUMBER := 0;
BEGIN
    -- Listar todos os dados da tabela Foto
    FOR foto_rec IN (SELECT * FROM tb_bp_foto) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || foto_rec.id_foto || ', Source: ' || foto_rec.src);
        v_total_fotos := v_total_fotos + 1;
    END LOOP;
    
    -- Mostrar total de fotos
    DBMS_OUTPUT.PUT_LINE('Total de Fotos: ' || v_total_fotos);
END;
/




-- 4º relatório
DECLARE
    v_total_reciclagens NUMBER := 0;
BEGIN
    -- Listar todos os dados da tabela Reciclagem
    FOR reciclagem_rec IN (SELECT * FROM tb_bp_reciclagem) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || reciclagem_rec.id_reciclagem || ', Foto: ' || reciclagem_rec.foto || ', Pontos: ' || reciclagem_rec.pontos);
        v_total_reciclagens := v_total_reciclagens + 1;
    END LOOP;
    
    -- Mostrar total de reciclagens
    DBMS_OUTPUT.PUT_LINE('Total de Reciclagens: ' || v_total_reciclagens);
END;
/



-- Selects na tabela para verificar se estão criadas corretamente
SELECT * FROM tb_bp_pessoa;
SELECT * FROM tb_bp_usuario;
SELECT * FROM tb_bp_reciclagem;
SELECT * FROM tb_bp_foto;
SELECT * FROM tb_bp_log_erro;
