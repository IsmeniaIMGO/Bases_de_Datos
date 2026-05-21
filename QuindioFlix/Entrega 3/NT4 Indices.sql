------------------------------------------------------------
-- NT4_INDICES.SQL - QUINDIOFLIX
-- Indices a analizar:
--   1) IX_REPRODUCCION_PERFIL     (REPRODUCCION.ID_PERFIL)
--   2) IX_USUARIO_CIUDAD          (USUARIO.CIUDAD_RESIDENCIA)
--   3) IX_PAGO_ESTADO / IX_PAGO_FECHA (PAGO_SUSCRIPCION.ESTADO_PAGO, FECHA_PAGO)
--   4) IX_CONTENIDO_TIPO          (CONTENIDO.TIPO_CONTENIDO)
--   5) ix_usuario_plan 
--   6) ix_reproduccion_contenido
------------------------------------------------------------

------------------------------------------------------------
-- DESHABILITAR INDICES SELECCIONADOS
------------------------------------------------------------

ALTER INDEX ix_reproduccion_perfil          UNUSABLE;
ALTER INDEX ix_usuario_ciudad               UNUSABLE;
ALTER INDEX ix_pago_estado                  UNUSABLE;
ALTER INDEX ix_pago_fecha                   UNUSABLE;
ALTER INDEX ix_contenido_tipo               UNUSABLE;
ALTER INDEX ix_usuario_plan                 UNUSABLE;
ALTER INDEX ix_reproduccion_contenido       UNUSABLE;
/
------------------------------------------------------------
-- EXPLAIN PLAN FOR SIN INDICES
------------------------------------------------------------

-- Limpiar plan
DELETE FROM plan_table;

-- 1) Historial de reproducciones por perfil y rango de fechas
EXPLAIN PLAN FOR
SELECT
    r.id_reproduccion,
    r.id_perfil,
    r.id_contenido,
    r.fecha_hora_inicio,
    r.fecha_hora_fin,
    r.dispositivo,
    r.porcentaje_avance
FROM   reproduccion r
WHERE  r.id_perfil = 1
AND    r.fecha_hora_inicio BETWEEN
       TO_TIMESTAMP('2025-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
   AND TO_TIMESTAMP('2025-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
ORDER  BY r.fecha_hora_inicio;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/

-- 2) Usuarios por ciudad con conteo, usando ciudad_residencia
DELETE FROM plan_table;

EXPLAIN PLAN FOR
SELECT
    u.ciudad_residencia,
    COUNT(*) AS total_usuarios
FROM   usuario u
GROUP  BY u.ciudad_residencia
ORDER  BY total_usuarios DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/

-- 3) Ingresos por ciudad y plan en un año (usa estado_pago y fecha_pago)
DELETE FROM plan_table;

EXPLAIN PLAN FOR
SELECT
    u.ciudad_residencia,
    pl.nombre            AS plan,
    SUM(pg.monto_pagado) AS ingresos_totales
FROM   pago_suscripcion pg
JOIN   usuario          u  ON u.id_usuario = pg.id_usuario
JOIN   plan_suscripcion pl ON pl.id_plan   = u.id_plan
WHERE  pg.estado_pago = 'EXITOSO'
AND    pg.fecha_pago  BETWEEN
       TO_TIMESTAMP('2025-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
   AND TO_TIMESTAMP('2025-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
GROUP  BY u.ciudad_residencia, pl.nombre
ORDER  BY u.ciudad_residencia, plan;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/

-- 4) Conteo de reproducciones por tipo de contenido
DELETE FROM plan_table;

EXPLAIN PLAN FOR
SELECT
    c.tipo_contenido,
    COUNT(*) AS total_reproducciones
FROM   reproduccion r
JOIN   contenido    c ON c.id_contenido = r.id_contenido
GROUP  BY c.tipo_contenido
ORDER  BY total_reproducciones DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/
------------------------------------------------------------
-- HABILITAR INDICES (RECONSTRUIR)
------------------------------------------------------------

ALTER INDEX ix_reproduccion_perfil          REBUILD;
ALTER INDEX ix_usuario_ciudad               REBUILD;
ALTER INDEX ix_pago_estado                  REBUILD;
ALTER INDEX ix_pago_fecha                   REBUILD;
ALTER INDEX ix_contenido_tipo               REBUILD;
ALTER INDEX ix_usuario_plan                 REBUILD;
ALTER INDEX ix_reproduccion_contenido       REBUILD;
/
------------------------------------------------------------
-- EXPLAIN PLAN FOR CON INDICES
------------------------------------------------------------

-- Limpiar plan
DELETE FROM plan_table;

-- 1) Historial de reproducciones por perfil y rango de fechas
EXPLAIN PLAN FOR
SELECT
    r.id_reproduccion,
    r.id_perfil,
    r.id_contenido,
    r.fecha_hora_inicio,
    r.fecha_hora_fin,
    r.dispositivo,
    r.porcentaje_avance
FROM   reproduccion r
WHERE  r.id_perfil = 1
AND    r.fecha_hora_inicio BETWEEN
       TO_TIMESTAMP('2025-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
   AND TO_TIMESTAMP('2025-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
ORDER  BY r.fecha_hora_inicio;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/

-- 2) Usuarios por ciudad con conteo, usando ciudad_residencia
DELETE FROM plan_table;

EXPLAIN PLAN FOR
SELECT
    u.ciudad_residencia,
    COUNT(*) AS total_usuarios
FROM   usuario u
GROUP  BY u.ciudad_residencia
ORDER  BY total_usuarios DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/

-- 3) Ingresos por ciudad y plan en un año (usa estado_pago y fecha_pago)
DELETE FROM plan_table;

EXPLAIN PLAN FOR
SELECT
    u.ciudad_residencia,
    pl.nombre            AS plan,
    SUM(pg.monto_pagado) AS ingresos_totales
FROM   pago_suscripcion pg
JOIN   usuario          u  ON u.id_usuario = pg.id_usuario
JOIN   plan_suscripcion pl ON pl.id_plan   = u.id_plan
WHERE  pg.estado_pago = 'EXITOSO'
AND    pg.fecha_pago  BETWEEN
       TO_TIMESTAMP('2025-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
   AND TO_TIMESTAMP('2025-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
GROUP  BY u.ciudad_residencia, pl.nombre
ORDER  BY u.ciudad_residencia, plan;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/

-- 4) Conteo de reproducciones por tipo de contenido
DELETE FROM plan_table;

EXPLAIN PLAN FOR
SELECT
    c.tipo_contenido,
    COUNT(*) AS total_reproducciones
FROM   reproduccion r
JOIN   contenido    c ON c.id_contenido = r.id_contenido
GROUP  BY c.tipo_contenido
ORDER  BY total_reproducciones DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
/


