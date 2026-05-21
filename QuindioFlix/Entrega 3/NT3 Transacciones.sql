------------------------------------------------------------
-- NT3 - TRANSACCIONES Y CONCURRENCIA
------------------------------------------------------------

SET SERVEROUTPUT ON;

------------------------------------------------------------
-- TRANSACCIÓN 1: REGISTRO COMPLETO DE USUARIO
-- Usando SP_REGISTRAR_USUARIO
-- Estados: activa -> parcialmente confirmada -> confirmada/abortada
------------------------------------------------------------

DECLARE
    v_id_usuario    usuario.id_usuario%TYPE;
    v_id_perfil     perfil.id_perfil%TYPE;
    v_id_pago       pago_suscripcion.id_pago%TYPE;

    -- datos de prueba
    v_id_plan               usuario.id_plan%TYPE := 1;
    v_id_usuario_referidor  usuario.id_usuario_referidor%TYPE := NULL;
    v_nombre                usuario.nombre%TYPE := 'Nuevo';
    v_apellido              usuario.apellido%TYPE := 'Usuario';
    v_email                 usuario.email%TYPE := 'nuevo.usuario.nt3@correo.co';
    v_telefono              usuario.telefono%TYPE := '3100000000';
    v_fecha_nacimiento      usuario.fecha_nacimiento%TYPE := DATE '2000-01-01';
    v_ciudad_residencia     usuario.ciudad_residencia%TYPE := 'Armenia';
    v_fecha_vencimiento     usuario.fecha_vencimiento_pago%TYPE := TRUNC(SYSDATE) + 30;

    v_periodo_inicio        DATE := TRUNC(SYSDATE);
    v_periodo_fin           DATE := TRUNC(SYSDATE) + 30;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TRANSACCION 1: REGISTRO COMPLETO DE USUARIO ===');

    SAVEPOINT sp_registro_inicio;

    --------------------------------------------------------
    -- Paso 1: registrar usuario usando procedimiento
    --------------------------------------------------------
    sp_registrar_usuario(
        p_id_plan                => v_id_plan,
        p_id_usuario_referidor   => v_id_usuario_referidor,
        p_nombre                 => v_nombre,
        p_apellido               => v_apellido,
        p_email                  => v_email,
        p_telefono               => v_telefono,
        p_fecha_nacimiento       => v_fecha_nacimiento,
        p_ciudad_residencia      => v_ciudad_residencia,
        p_fecha_vencimiento_pago => v_fecha_vencimiento
    );


    --------------------------------------------------------
    -- Paso 2: recuperar el id del usuario recién creado
    --------------------------------------------------------
    SELECT id_usuario
    INTO v_id_usuario
    FROM usuario
    WHERE email = v_email;

    DBMS_OUTPUT.PUT_LINE('Usuario creado con id ' || v_id_usuario);
    
    
    --------------------------------------------------------
    -- Paso 3: crear perfil principal
    --------------------------------------------------------
    INSERT INTO perfil (
        id_usuario,
        nombre,
        avatar_url,
        tipo_perfil,
        fecha_creacion,
        activo
    ) VALUES (
        v_id_usuario,
        'Principal',
        'avatar_default.png',
        'ADULTO',
        SYSDATE,
        'S'
    )
    RETURNING id_perfil INTO v_id_perfil;

    DBMS_OUTPUT.PUT_LINE('Perfil creado con id ' || v_id_perfil);

    --------------------------------------------------------
    -- Paso 4: registrar primer pago
    --------------------------------------------------------
    INSERT INTO pago_suscripcion (
        id_usuario,
        fecha_pago,
        periodo_inicio,
        periodo_fin,
        monto_base,
        porcentaje_descuento,
        monto_pagado,
        metodo_pago,
        estado_pago,
        referencia_transaccion
    ) VALUES (
        v_id_usuario,
        SYSTIMESTAMP,
        v_periodo_inicio,
        v_periodo_fin,
        14900,
        0,
        14900,
        'PSE',
        'EXITOSO',
        'REGISTRO_INICIAL_NT3'
    )
    RETURNING id_pago INTO v_id_pago;

    DBMS_OUTPUT.PUT_LINE('Pago inicial registrado con id ' || v_id_pago);

    --------------------------------------------------------
    -- Confirmación total
    --------------------------------------------------------
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('TRANSACCION 1 CONFIRMADA');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error en transaccion 1: ' || SQLERRM);
        ROLLBACK TO sp_registro_inicio;
        DBMS_OUTPUT.PUT_LINE('TRANSACCION 1 ABORTADA (ROLLBACK)');
END;
/


------------------------------------------------------------
-- TRANSACCIÓN 2: RENOVACIÓN MENSUAL MASIVA
-- Uso de SAVEPOINT por usuario para no perder las anteriores
------------------------------------------------------------

DECLARE
    CURSOR c_usuarios_activos IS
        SELECT id_usuario
        FROM   usuario
        WHERE  estado_cuenta = 'ACTIVA';

    v_monto   NUMBER(10,2);
    v_hoy     DATE := TRUNC(SYSDATE);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TRANSACCION 2: RENOVACION MENSUAL ===');

    FOR reg IN c_usuarios_activos LOOP
        SAVEPOINT sp_usuario;

        BEGIN
            -- 1. Calcular monto con tu función FN_CALCULAR_MONTO
            v_monto := fn_calcular_monto(reg.id_usuario);

            -- Si la función devuelve null, forzamos error
            IF v_monto IS NULL THEN
                RAISE_APPLICATION_ERROR(-21000,
                    'No se pudo calcular monto para usuario ' || reg.id_usuario);
            END IF;

            -- 2. Insertar pago exitoso
            INSERT INTO pago_suscripcion (
                id_usuario,
                fecha_pago,
                periodo_inicio,
                periodo_fin,
                monto_base,
                porcentaje_descuento,
                monto_pagado,
                metodo_pago,
                estado_pago,
                referencia_transaccion
            ) VALUES (
                reg.id_usuario,
                SYSTIMESTAMP,
                v_hoy,
                v_hoy + 30,
                v_monto,
                0,
                v_monto,
                'NEQUI',
                'EXITOSO',
                'RENOVACION_MENSUAL'
            );

            -- 3. Actualizar estado y fecha de vencimiento
            UPDATE usuario
            SET    estado_cuenta = 'ACTIVA',
                   fecha_vencimiento_pago = v_hoy + 30
            WHERE  id_usuario = reg.id_usuario;

            DBMS_OUTPUT.PUT_LINE('Renovacion OK usuario ' || reg.id_usuario ||
                                 ' monto ' || v_monto);

        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error para usuario ' || reg.id_usuario ||
                                     ': ' || SQLERRM);
                ROLLBACK TO sp_usuario; -- se revierte solo este usuario
        END;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transaccion 2 CONFIRMADA (usuarios procesados)');

END;
/

------------------------------------------------------------
-- TRANSACCIÓN 3: ELIMINACIÓN COMPLETA DE CUENTA
-- "Todo o nada" sobre un usuario concreto
------------------------------------------------------------

DECLARE
    v_id_usuario usuario.id_usuario%TYPE := 31; -- tomar el ultimo como ejemplo
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TRANSACCION 3: ELIMINACION DE CUENTA ===');
    SAVEPOINT sp_eliminar;

    -- 1. Borrar pagos explícitamente
    DELETE FROM pago_suscripcion
    WHERE id_usuario = v_id_usuario;

    -- 2. Borrar reportes donde el usuario aparezca como reportante o moderador
    DELETE FROM reporte_contenido
    WHERE id_usuario_reporta   = v_id_usuario
       OR id_moderador_usuario = v_id_usuario;

    -- 3. Borrar el usuario (por ON DELETE CASCADE se eliminan perfiles
    --    y en cascada reproducciones, favoritos, calificaciones, etc.)
    DELETE FROM usuario
    WHERE id_usuario = v_id_usuario;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transaccion 3 CONFIRMADA. Usuario ' ||
                         v_id_usuario || ' eliminado.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error en eliminacion de usuario ' ||
                             v_id_usuario || ': ' || SQLERRM);
        ROLLBACK TO sp_eliminar;
        DBMS_OUTPUT.PUT_LINE('Transaccion 3 ABORTADA (ROLLBACK).');
END;
/


