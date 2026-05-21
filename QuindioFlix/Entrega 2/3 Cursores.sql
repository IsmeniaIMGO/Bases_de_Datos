/*
Cursor 1: USUARIOS MOROSOS
Definimos usuarios morosos como aquellos con estado SUSPENDIDA 
o con fecha de vencimiento ya pasada respecto a la fecha actual; 
*/
CREATE OR REPLACE PROCEDURE c_listar_usuarios_morosos
IS
    CURSOR c_usuarios_morosos IS
        SELECT
            u.id_usuario,
            u.nombre,
            u.apellido,
            u.email,
            u.estado_cuenta,
            u.fecha_vencimiento_pago
        FROM usuario u
        WHERE u.estado_cuenta = 'SUSPENDIDA'
           OR (u.fecha_vencimiento_pago IS NOT NULL
               AND u.fecha_vencimiento_pago < SYSDATE);

    v_id_usuario          usuario.id_usuario%TYPE;
    v_nombre              usuario.nombre%TYPE;
    v_apellido            usuario.apellido%TYPE;
    v_email               usuario.email%TYPE;
    v_estado_cuenta       usuario.estado_cuenta%TYPE;
    v_fecha_vencimiento   usuario.fecha_vencimiento_pago%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- USUARIOS MOROSOS ---');

    OPEN c_usuarios_morosos;
    LOOP
        FETCH c_usuarios_morosos INTO
            v_id_usuario,
            v_nombre,
            v_apellido,
            v_email,
            v_estado_cuenta,
            v_fecha_vencimiento;
        EXIT WHEN c_usuarios_morosos%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            'ID: ' || v_id_usuario ||
            ' | ' || v_nombre || ' ' || v_apellido ||
            ' | Email: ' || v_email ||
            ' | Estado: ' || v_estado_cuenta ||
            ' | Vence: ' || TO_CHAR(v_fecha_vencimiento, 'YYYY-MM-DD')
        );
    END LOOP;
    CLOSE c_usuarios_morosos;
END;
/


/*
Cursor 2: CALCULO DE POPULARIDAD
Calculamos popularidad por contenido como el conteo de reproducciones
y el promedio del porcentaje de avance; ordenamos primero por reproducciones
y luego por promedio de avance, por eso los contenidos más vistos quedaran arriba.
*/

CREATE OR REPLACE PROCEDURE c_calcular_popularidad_contenido
IS
    CURSOR c_popularidad IS
        SELECT
            c.id_contenido,
            c.titulo,
            c.tipo_contenido,
            COUNT(r.id_reproduccion) AS total_reproducciones,
            ROUND(AVG(r.porcentaje_avance), 2) AS promedio_avance
        FROM contenido c
        JOIN reproduccion r
          ON r.id_contenido = c.id_contenido
        GROUP BY c.id_contenido, c.titulo, c.tipo_contenido
        ORDER BY total_reproducciones DESC, promedio_avance DESC;

    v_id_contenido        contenido.id_contenido%TYPE;
    v_titulo              contenido.titulo%TYPE;
    v_tipo_contenido      contenido.tipo_contenido%TYPE;
    v_total_reproducciones NUMBER;
    v_promedio_avance      NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- POPULARIDAD POR CONTENIDO ---');

    OPEN c_popularidad;
    LOOP
        FETCH c_popularidad INTO
            v_id_contenido,
            v_titulo,
            v_tipo_contenido,
            v_total_reproducciones,
            v_promedio_avance;
        EXIT WHEN c_popularidad%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
              'ID: ' || v_id_contenido
           || ' | ' || v_titulo
           || ' | Tipo: ' || v_tipo_contenido
           || ' | Reproducciones: ' || v_total_reproducciones
           || ' | Avance promedio: ' || v_promedio_avance || '%'
        );
    END LOOP;
    CLOSE c_popularidad;
END;
/

/*Ejecutar pruebas 
Para USUARIOS MOROSOS------------------------------------------------------
*/
SET SERVEROUTPUT ON;

BEGIN
    c_listar_usuarios_morosos;
END;
/

/*
Para CALCULO POPULARIDAD--------------------------------------------------
*/
SET SERVEROUTPUT ON;

BEGIN
    c_calcular_popularidad_contenido;
END;
/

