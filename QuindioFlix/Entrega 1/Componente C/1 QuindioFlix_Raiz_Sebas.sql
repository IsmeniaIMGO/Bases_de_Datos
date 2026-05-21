-- creacion del tbs del proyecto----- en una carpeta personal de tbs para el proyecto

CREATE TABLESPACE tbs_quindioflix
    DATAFILE 'C:\app\SEBASTIAN_SSD_ADATA\product\21c\oradata\XE\XEPDB1\tbs_QuindioFlix\quindioflix01.dbf'
    SIZE 200M
    AUTOEXTEND ON NEXT 50M
    MAXSIZE 2048M;
    
-----Creacion del usuario del tbs del proyecto----------
CREATE USER quindioflix
    IDENTIFIED BY "QuindioFlix2026"  --> contraseña
    DEFAULT TABLESPACE tbs_quindioflix
    QUOTA UNLIMITED ON tbs_quindioflix; --> por ahora no le asignare cuota, la idea es que sea el pro DBA
    
    
-- Ver qué contenedores existen
SELECT name, open_mode FROM v$pdbs;

-- Otorgar permisos al pro dba quindioflix  para la bd
GRANT CONNECT, RESOURCE TO quindioflix;
GRANT CREATE SESSION    TO quindioflix;
GRANT CREATE TABLE      TO quindioflix;
GRANT CREATE SEQUENCE   TO quindioflix;
GRANT CREATE TRIGGER    TO quindioflix;
GRANT CREATE VIEW       TO quindioflix;


    