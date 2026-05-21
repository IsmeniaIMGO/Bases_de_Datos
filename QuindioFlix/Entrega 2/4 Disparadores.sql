-- ============================================================
-- DISPARADORES 
-- ============================================================

-- ============================================================
-- TRIGGER 1: TRG_VALIDAR_CUENTA_ACTIVA
-- Tipo: BEFORE INSERT - A nivel de FILA en REPRODUCCION
-- Propósito: Verificar que el usuario dueño del perfil tenga
--            estado_cuenta = 'ACTIVA' antes de registrar una
--            reproducción. Si no, rechaza la inserción.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_validar_cuenta_activa BEFORE
    INSERT ON reproduccion
    FOR EACH ROW
DECLARE
    v_estado_cuenta usuario.estado_cuenta%TYPE;
BEGIN
    -- Obtener el estado de cuenta del usuario dueño del perfil
    SELECT
        u.estado_cuenta
    INTO v_estado_cuenta
    FROM
             usuario u
        JOIN perfil p ON p.id_usuario = u.id_usuario
    WHERE
        p.id_perfil = :new.id_perfil;

    -- Si la cuenta no está activa, rechazar la reproducción
    IF v_estado_cuenta != 'ACTIVA' THEN
        raise_application_error(-20030, 'No se puede registrar la reproducción: la cuenta del usuario '
                                        || 'no está activa (estado actual: '
                                        || v_estado_cuenta
                                        || ').');
    END IF;

EXCEPTION
    WHEN no_data_found THEN
        raise_application_error(-20031,
                                'No se encontró el perfil o el usuario asociado al perfil id: ' || :new.id_perfil);
END trg_validar_cuenta_activa;
/


-- ============================================================
-- TRIGGER 2: TRG_VALIDAR_MAX_PERFILES
-- Tipo: BEFORE INSERT - A nivel de FILA en PERFIL
-- Propósito: Verificar que al insertar un nuevo perfil, el
--            usuario no supere el número máximo permitido por
--            su plan (Básico: 2, Estándar: 3, Premium: 5).
--            Si lo excede, rechaza la inserción.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_validar_max_perfiles BEFORE
    INSERT ON perfil
    FOR EACH ROW
DECLARE
    v_max_perfiles   plan_suscripcion.max_perfiles%TYPE;
    v_total_perfiles NUMBER;
BEGIN
    -- Obtener el máximo de perfiles permitido según el plan del usuario
    SELECT
        ps.max_perfiles
    INTO v_max_perfiles
    FROM
             plan_suscripcion ps
        JOIN usuario u ON u.id_plan = ps.id_plan
    WHERE
        u.id_usuario = :new.id_usuario;

    -- Contar cuántos perfiles activos ya tiene ese usuario
    SELECT
        COUNT(*)
    INTO v_total_perfiles
    FROM
        perfil
    WHERE
        id_usuario = :new.id_usuario;

    -- Si ya alcanzó el máximo, rechazar
    IF v_total_perfiles >= v_max_perfiles THEN
        raise_application_error(-20032,
                                'El usuario id '
                                || :new.id_usuario
                                || ' ya tiene el número máximo de perfiles permitidos ('
                                || v_max_perfiles
                                || ') según su plan.');
    END IF;

EXCEPTION
    WHEN no_data_found THEN
        raise_application_error(-20033,
                                'No se encontró el plan asociado al usuario id: ' || :new.id_usuario);
END trg_validar_max_perfiles;
/


-- ============================================================
-- TRIGGER 3: TRG_VALIDAR_CALIFICACION
-- Tipo: BEFORE INSERT - A nivel de FILA en CALIFICACION
-- Propósito: Verificar que el perfil haya reproducido al menos
--            el 50% del contenido antes de permitir calificar.
--            Si no lo ha visto lo suficiente, rechaza.
-- Nota: Se toma el mayor porcentaje_avance registrado de ese
--       perfil para ese contenido (puede haberlo reproducido
--       varias veces parcialmente).
-- ============================================================
CREATE OR REPLACE TRIGGER trg_validar_calificacion BEFORE
    INSERT ON calificacion_contenido
    FOR EACH ROW
DECLARE
    v_max_avance NUMBER;
BEGIN
    -- Buscar el porcentaje máximo de avance del perfil en ese contenido
    SELECT
        nvl(
            max(porcentaje_avance),
            0
        )
    INTO v_max_avance
    FROM
        reproduccion
    WHERE
            id_perfil = :new.id_perfil
        AND id_contenido = :new.id_contenido;

    -- Si nunca llegó al 50%, rechazar la calificación
    IF v_max_avance < 50 THEN
        raise_application_error(-20034,
                                'El perfil id '
                                || :new.id_perfil
                                || ' no puede calificar el contenido id '
                                || :new.id_contenido
                                || '. Avance máximo registrado: '
                                || v_max_avance
                                || '%. Se requiere al menos 50%.');

    END IF;

END trg_validar_calificacion;
/


-- ============================================================
-- TRIGGER 4: TRG_ACTIVAR_CUENTA_PAGO
-- Tipo: AFTER INSERT - A nivel de SENTENCIA en PAGO
-- Propósito: Después de insertar uno o más pagos exitosos,
--            actualizar el estado_cuenta del usuario a 'ACTIVA'
--            y la fecha_vencimiento_pago (próximos 30 días).
-- Nota: Como es a nivel de sentencia (no FOR EACH ROW), se
--       procesan todos los pagos exitosos recién insertados
--       en una sola pasada usando un cursor interno.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_activar_cuenta_pago AFTER
    INSERT ON pago_suscripcion
-- Sin FOR EACH ROW → nivel de sentencia
DECLARE
    CURSOR c_pagos_exitosos IS
        SELECT
            p.id_usuario,
            p.fecha_pago
        FROM
            pago_suscripcion p
        WHERE
            p.estado_pago = 'EXITOSO'
            AND p.fecha_pago >= TRUNC(SYSDATE); -- pagos exitosos de hoy

BEGIN
    FOR reg IN c_pagos_exitosos LOOP
        UPDATE usuario
        SET
            estado_cuenta            = 'ACTIVA',
            fecha_vencimiento_pago   = TRUNC(reg.fecha_pago) + 30
        WHERE
            id_usuario = reg.id_usuario;
    END LOOP;
END trg_activar_cuenta_pago;
/


-- ============================================================
-- PRUEBAS DE VERIFICACIÓN
-- ============================================================

-- PRUEBA 1: Trigger cuenta activa
-- Cambiar estado a SUSPENDIDA e intentar insertar reproducción
--UPDATE usuario SET estado_cuenta = 'SUSPENDIDA' WHERE id_usuario = 1;
--INSERT INTO reproduccion (id_perfil, id_contenido, fecha_hora_inicio, dispositivo, porcentaje_avance)
--VALUES (1, 1, SYSDATE, 'CELULAR', 0);
-- Resultado esperado: ORA-20030

-- PRUEBA 2: Trigger máximo de perfiles (usuario con plan Básico = max 2 perfiles)
-- Si el usuario 2 ya tiene 2 perfiles y trata de agregar un tercero:
--INSERT INTO perfil (id_usuario, nombre, avatar_url, tipo_perfil)
--VALUES (2, 'Nuevo Perfil', 'avatar_default.png', 'ADULTO');
-- Resultado esperado: ORA-20032

-- PRUEBA 3: Trigger calificación sin haber visto suficiente
--INSERT INTO calificacion_contenido (id_perfil, id_contenido, estrellas, fecha_calificacion)
--VALUES (5, 10, 4, SYSDATE);
-- Si el perfil 5 solo ha visto 30% del contenido 10: ORA-20034



-- PRUEBA 4: Trigger activación por pago exitoso

/*INSERT INTO pago_suscripcion (
    id_pago,
    id_usuario,
    fecha_pago,
    periodo_inicio,
    periodo_fin,
    monto_base,
    monto_pagado,
    metodo_pago,
    estado_pago
) VALUES (
    107,
    3,
    SYSDATE,
    TRUNC(SYSDATE),
    TRUNC(SYSDATE) + 30,
    24900,
    24900,
    'PSE',
    'EXITOSO'
); */
-- Resultado esperado: estado_cuenta = 'ACTIVA', fecha_vencimiento_pago = SYSDATE + 30