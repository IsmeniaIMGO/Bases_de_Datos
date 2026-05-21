------------------------------------------------------------
-- NT5 - USUARIOS Y ROLES
------------------------------------------------------------

------------------------------------------------------------
-- 1. CREACION DE ROLES LOGICOS
------------------------------------------------------------
 
CREATE ROLE rol_admin;
CREATE ROLE rol_analista;
CREATE ROLE rol_soporte;
CREATE ROLE rol_contenido;

------------------------------------------------------------
-- 2. ASIGNACION DE PRIVILEGIOS A ROLES
------------------------------------------------------------

-- 2.1 ROL_ADMIN: acceso completo operacional al esquema

GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.usuario               TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.perfil                TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.plan_suscripcion      TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.contenido             TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.genero                TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.contenido_genero      TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.contenido_relacionado TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.temporada             TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.episodio              TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.reproduccion          TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.calificacion_contenido TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.favorito_perfil       TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.reporte_contenido     TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.pago_suscripcion      TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.departamento          TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.empleado              TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.rol                   TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.usuario_rol           TO rol_admin;

GRANT EXECUTE ON quindioflix.fn_calcular_monto        TO rol_admin;
GRANT EXECUTE ON quindioflix.fn_contenido_recomendado TO rol_admin;
GRANT EXECUTE ON quindioflix.sp_registrar_usuario     TO rol_admin;
GRANT EXECUTE ON quindioflix.sp_cambiar_plan          TO rol_admin;
GRANT EXECUTE ON quindioflix.sp_reporte_consumo       TO rol_admin;

GRANT SELECT ON quindioflix.mv_consumo_contenido             TO rol_admin;
GRANT SELECT ON quindioflix.mv_reproducciones_diarias_ciudad TO rol_admin;

------------------------------------------------------------
-- 2.2 ROL_ANALISTA: solo lectura y vistas de reporte
------------------------------------------------------------

GRANT SELECT ON quindioflix.usuario               TO rol_analista;
GRANT SELECT ON quindioflix.perfil                TO rol_analista;
GRANT SELECT ON quindioflix.plan_suscripcion      TO rol_analista;
GRANT SELECT ON quindioflix.contenido             TO rol_analista;
GRANT SELECT ON quindioflix.genero                TO rol_analista;
GRANT SELECT ON quindioflix.reproduccion          TO rol_analista;
GRANT SELECT ON quindioflix.calificacion_contenido TO rol_analista;
GRANT SELECT ON quindioflix.favorito_perfil       TO rol_analista;
GRANT SELECT ON quindioflix.pago_suscripcion      TO rol_analista;
GRANT SELECT ON quindioflix.reporte_contenido     TO rol_analista;
GRANT SELECT ON quindioflix.departamento          TO rol_analista;
GRANT SELECT ON quindioflix.empleado              TO rol_analista;
GRANT SELECT ON quindioflix.rol                   TO rol_analista;
GRANT SELECT ON quindioflix.usuario_rol           TO rol_analista;

GRANT SELECT ON quindioflix.mv_consumo_contenido             TO rol_analista;
GRANT SELECT ON quindioflix.mv_reproducciones_diarias_ciudad TO rol_analista;

------------------------------------------------------------
-- 2.3 ROL_SOPORTE: atención a usuarios y pagos
------------------------------------------------------------

GRANT SELECT ON quindioflix.usuario          TO rol_soporte;
GRANT SELECT ON quindioflix.perfil           TO rol_soporte;
GRANT SELECT ON quindioflix.pago_suscripcion TO rol_soporte;
GRANT SELECT ON quindioflix.reproduccion     TO rol_soporte;
GRANT SELECT ON quindioflix.plan_suscripcion TO rol_soporte;

GRANT INSERT, UPDATE ON quindioflix.pago_suscripcion TO rol_soporte;

GRANT EXECUTE ON quindioflix.sp_cambiar_plan TO rol_soporte;

------------------------------------------------------------
-- 2.4 ROL_CONTENIDO: gestión del catálogo
------------------------------------------------------------

GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.contenido             TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.genero                TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.contenido_genero      TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.contenido_relacionado TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.temporada             TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON quindioflix.episodio              TO rol_contenido;

GRANT SELECT ON quindioflix.reproduccion           TO rol_contenido;
GRANT SELECT ON quindioflix.calificacion_contenido TO rol_contenido;

------------------------------------------------------------
-- 3. CREACION DE USUARIOS ORACLE Y ASIGNACION DE ROLES
------------------------------------------------------------

-- Ajustar contraseñas y tablespace según entorno

CREATE USER usr_admin IDENTIFIED BY Admin2026
  DEFAULT TABLESPACE tbs_quindioflix
  QUOTA 100M ON tbs_quindioflix;
GRANT CREATE SESSION TO usr_admin;
GRANT rol_admin      TO usr_admin;

CREATE USER usr_analista IDENTIFIED BY Analista2026
  DEFAULT TABLESPACE tbs_quindioflix
  QUOTA 50M ON tbs_quindioflix;
GRANT CREATE SESSION TO usr_analista;
GRANT rol_analista   TO usr_analista;

CREATE USER usr_soporte IDENTIFIED BY Soporte2026
  DEFAULT TABLESPACE tbs_quindioflix
  QUOTA 50M ON tbs_quindioflix;
GRANT CREATE SESSION TO usr_soporte;
GRANT rol_soporte    TO usr_soporte;

CREATE USER usr_contenido IDENTIFIED BY Contenido2026
  DEFAULT TABLESPACE tbs_quindioflix
  QUOTA 50M ON tbs_quindioflix;
GRANT CREATE SESSION TO usr_contenido;
GRANT rol_contenido  TO usr_contenido;

------------------------------------------------------------
-- 4. PRUEBAS DE RESTRICCION DE ACCESO (PARA EJECUTAR CON CADA USUARIO)
------------------------------------------------------------

-- Como USR_ANALISTA:
-- 1) Debería funcionar:
--    SELECT COUNT(*) FROM quindioflix.pago_suscripcion;
-- 2) Debería FALLAR (sin privilegios DML):
--    INSERT INTO quindioflix.usuario (id_plan, nombre, apellido, email,
--             fecha_nacimiento, ciudad_residencia)
--    VALUES (1, 'Prueba', 'Analista', 'prueba.analista@uqvirtual.edu.co',
--            DATE '2000-01-01', 'Armenia');

-- Como USR_SOPORTE:
-- 1) Debería funcionar:
--    INSERT INTO quindioflix.pago_suscripcion (
--      id_usuario, fecha_pago, periodo_inicio, periodo_fin,
--      monto_base, porcentaje_descuento, monto_pagado,
--      metodo_pago, estado_pago
--    ) VALUES (
--      1, SYSTIMESTAMP, TRUNC(SYSDATE), TRUNC(SYSDATE)+30,
--      24900, 0, 24900,
--      'PSE', 'EXITOSO'
--    );
-- 2) Debería FALLAR:
--    DELETE FROM quindioflix.usuario WHERE id_usuario = 1;

-- Como USR_CONTENIDO:
-- 1) Debería funcionar:
--    INSERT INTO quindioflix.contenido (
 /* id_empleado_publica,
  tipo_contenido,
  titulo,
  anio_lanzamiento,
  clasificacion_edad,
  fecha_agregado,
  es_original,
  activo
) VALUES (
  5,
  'PELICULA',
  'Prueba NT5',
  2025,
  '+13',
  SYSDATE,
  'N',
  'S'
);*/
-- 2) Debería FALLAR:
--    UPDATE quindioflix.pago_suscripcion
--    SET monto_pagado = 0
--    WHERE id_pago = 1;