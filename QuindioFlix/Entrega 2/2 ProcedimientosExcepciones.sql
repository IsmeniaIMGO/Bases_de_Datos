/*
Procedimiento 1:  SP_REGISTRAR_USUARIO
Este procedimiento inserta un nuevo usuario validando plan y correo único
*/

CREATE OR REPLACE PROCEDURE sp_registrar_usuario (
    p_id_plan                IN usuario.id_plan%TYPE,
    p_id_usuario_referidor   IN usuario.id_usuario_referidor%TYPE DEFAULT NULL,
    p_nombre                 IN usuario.nombre%TYPE,
    p_apellido               IN usuario.apellido%TYPE,
    p_email                  IN usuario.email%TYPE,
    p_telefono               IN usuario.telefono%TYPE,
    p_fecha_nacimiento       IN usuario.fecha_nacimiento%TYPE,
    p_ciudad_residencia      IN usuario.ciudad_residencia%TYPE,
    p_fecha_vencimiento_pago IN usuario.fecha_vencimiento_pago%TYPE DEFAULT NULL
)
IS
    v_count NUMBER;

    e_plan_no_existe EXCEPTION;
    e_email_duplicado EXCEPTION;
    e_referidor_no_existe EXCEPTION;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM plan_suscripcion
    WHERE id_plan = p_id_plan
      AND activo = 'S';

    IF v_count = 0 THEN
        RAISE e_plan_no_existe;
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM usuario
    WHERE UPPER(email) = UPPER(p_email);

    IF v_count > 0 THEN
        RAISE e_email_duplicado;
    END IF;

    IF p_id_usuario_referidor IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_count
        FROM usuario
        WHERE id_usuario = p_id_usuario_referidor;

        IF v_count = 0 THEN
            RAISE e_referidor_no_existe;
        END IF;
    END IF;

    INSERT INTO usuario (
    id_plan,
    id_usuario_referidor,
    nombre,
    apellido,
    email,
    telefono,
    fecha_nacimiento,
    ciudad_residencia,
    fecha_registro,
    fecha_vencimiento_pago,
    estado_cuenta,
    referido_activo,
    descuento_proximo_pago
)
VALUES (
    p_id_plan,
    p_id_usuario_referidor,
    p_nombre,
    p_apellido,
    p_email,
    p_telefono,
    p_fecha_nacimiento,
    p_ciudad_residencia,
    SYSDATE,
    p_fecha_vencimiento_pago,
    'ACTIVA',
    'N',
    0
);
    

    DBMS_OUTPUT.PUT_LINE('Usuario registrado correctamente.');
EXCEPTION
    WHEN e_plan_no_existe THEN
        RAISE_APPLICATION_ERROR(-20001, 'El plan no existe o está inactivo.');
    WHEN e_email_duplicado THEN
        RAISE_APPLICATION_ERROR(-20002, 'El correo ya está registrado.');
    WHEN e_referidor_no_existe THEN
        RAISE_APPLICATION_ERROR(-20003, 'El usuario referidor no existe.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Error al registrar usuario: ' || SQLERRM);
END;
/


/*
Procedimiento 2: SP_CAMBIAR_PLAN
Este procedimiento cambia el plan del usuario, pero valida que
el usuario exista, que el nuevo plan exista y que el usuario
no esté suspendido o desactivado.
*/

CREATE OR REPLACE PROCEDURE sp_cambiar_plan (
    p_id_usuario     IN usuario.id_usuario%TYPE,
    p_nuevo_id_plan  IN usuario.id_plan%TYPE
)
IS
    v_count NUMBER;
    v_estado usuario.estado_cuenta%TYPE;

    e_usuario_no_existe EXCEPTION;
    e_plan_no_existe EXCEPTION;
    e_usuario_bloqueado EXCEPTION;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM usuario
    WHERE id_usuario = p_id_usuario;

    IF v_count = 0 THEN
        RAISE e_usuario_no_existe;
    END IF;

    SELECT estado_cuenta
    INTO v_estado
    FROM usuario
    WHERE id_usuario = p_id_usuario;

    IF v_estado IN ('SUSPENDIDA', 'DESACTIVADA') THEN
        RAISE e_usuario_bloqueado;
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM plan_suscripcion
    WHERE id_plan = p_nuevo_id_plan
      AND activo = 'S';

    IF v_count = 0 THEN
        RAISE e_plan_no_existe;
    END IF;

    UPDATE usuario
    SET id_plan = p_nuevo_id_plan
    WHERE id_usuario = p_id_usuario;

    DBMS_OUTPUT.PUT_LINE('Plan actualizado correctamente.');
EXCEPTION
    WHEN e_usuario_no_existe THEN
        RAISE_APPLICATION_ERROR(-20010, 'El usuario no existe.');
    WHEN e_plan_no_existe THEN
        RAISE_APPLICATION_ERROR(-20011, 'El nuevo plan no existe o está inactivo.');
    WHEN e_usuario_bloqueado THEN
        RAISE_APPLICATION_ERROR(-20012, 'No se puede cambiar el plan de un usuario suspendido o desactivado.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Error al cambiar plan: ' || SQLERRM);
END;
/


/*
Procedimiento 3: SP_REPORTE_CONSUMO
Como el nombre del taller dice “reporte consumo”, 
este procedimiento puede generar un resumen por perfil 
en un rango de fechas, usando un cursor de salida SYS_REFCURSOR
*/

CREATE OR REPLACE PROCEDURE sp_reporte_consumo (
    p_id_perfil      IN perfil.id_perfil%TYPE,
    p_fecha_inicio   IN DATE,
    p_fecha_fin      IN DATE,
    p_resultado      OUT SYS_REFCURSOR
)
IS
    v_count NUMBER;

    e_perfil_no_existe EXCEPTION;
    e_rango_fechas_invalido EXCEPTION;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM perfil
    WHERE id_perfil = p_id_perfil;

    IF v_count = 0 THEN
        RAISE e_perfil_no_existe;
    END IF;

    IF p_fecha_inicio > p_fecha_fin THEN
        RAISE e_rango_fechas_invalido;
    END IF;

    OPEN p_resultado FOR
        SELECT
            c.id_contenido,
            c.titulo,
            c.tipo_contenido,
            COUNT(r.id_reproduccion) AS total_reproducciones,
            ROUND(AVG(r.porcentaje_avance), 2) AS promedio_avance
        FROM reproduccion r
        JOIN contenido c
          ON c.id_contenido = r.id_contenido
        WHERE r.id_perfil = p_id_perfil
          AND TRUNC(r.fecha_hora_inicio) BETWEEN p_fecha_inicio AND p_fecha_fin
        GROUP BY c.id_contenido, c.titulo, c.tipo_contenido
        ORDER BY total_reproducciones DESC, promedio_avance DESC;
EXCEPTION
    WHEN e_perfil_no_existe THEN
        RAISE_APPLICATION_ERROR(-20020, 'El perfil no existe.');
    WHEN e_rango_fechas_invalido THEN
        RAISE_APPLICATION_ERROR(-20021, 'La fecha inicial no puede ser mayor que la fecha final.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20022, 'Error al generar reporte de consumo: ' || SQLERRM);
END;
/


-------------------------------------------------------------------------------------------------
--EJECUTAR PRUEBAS
Para 1. SP_REGISTRAR_USUARIO---------------------------------------------
*/
BEGIN
    sp_registrar_usuario(
        p_id_plan => 1,
        p_id_usuario_referidor => 2,
        p_nombre => 'Marcela',
        p_apellido => 'Guevara',
        p_email => 'marcela.guevara@correo.co',
        p_telefono => '3109999999',
        p_fecha_nacimiento => TO_DATE('2000-05-10','YYYY-MM-DD'),
        p_ciudad_residencia => 'Armenia',
        p_fecha_vencimiento_pago => TO_DATE('2026-06-30','YYYY-MM-DD')
    );
END;
/

/*
Para 2. SP_CAMBIAR_PLAN-------------------------------------------------
*/

BEGIN
    sp_cambiar_plan(1, 3);
END;
/


/*
Para 3. SP_REPORTE_CONSUMO------------------------------------------
*/

VARIABLE rc REFCURSOR;

BEGIN
    sp_reporte_consumo(
        p_id_perfil => 1,
        p_fecha_inicio => TO_DATE('2025-01-01','YYYY-MM-DD'),
        p_fecha_fin => TO_DATE('2026-12-31','YYYY-MM-DD'),
        p_resultado => :rc
    );
END;
/

PRINT rc;







