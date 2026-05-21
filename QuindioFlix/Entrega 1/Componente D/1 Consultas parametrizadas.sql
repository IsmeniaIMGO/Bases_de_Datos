-- 1. Top 10 de contenido más reproducido por ciudad
-- Objetivo:
-- Dada una ciudad, mostrar el top 10 de contenidos más reproducidos
-- por perfiles de usuarios que residen en esa ciudad.
-- Usa variable de sustitución simple &CIUDAD.
-- Se pedirá el valor en cada ejecución.
SET VERIFY OFF;
UNDEFINE CIUDAD;

SELECT
    u.ciudad_residencia      AS ciudad,
    c.titulo                 AS titulo_contenido,
    c.tipo_contenido         AS tipo_contenido,
    COUNT(r.id_reproduccion) AS total_reproducciones
FROM usuario u
JOIN perfil p
    ON p.id_usuario = u.id_usuario
JOIN reproduccion r
    ON r.id_perfil = p.id_perfil
JOIN contenido c
    ON c.id_contenido = r.id_contenido
WHERE u.ciudad_residencia = '&CIUDAD'
GROUP BY
    u.ciudad_residencia,
    c.titulo,
    c.tipo_contenido
ORDER BY
    total_reproducciones DESC,
    titulo_contenido ASC
FETCH FIRST 10 ROWS ONLY;

UNDEFINE CIUDAD;


-- 2. Ingresos por plan de suscripción en un mes/año
-- Objetivo:
-- Dado un mes y un año, mostrar los ingresos totales por plan,
-- considerando solo pagos exitosos en ese periodo.
-- Usa &MES y &ANIO.
-- Se pedirán en cada ejecución.
SET VERIFY OFF;

UNDEFINE MES;
UNDEFINE ANIO;

SELECT
    pl.nombre            AS plan,
    &&MES                AS mes_consulta,
    &&ANIO               AS anio_consulta,
    SUM(pg.monto_pagado) AS ingresos_totales
FROM pago_suscripcion pg
JOIN usuario u
    ON u.id_usuario = pg.id_usuario
JOIN plan_suscripcion pl
    ON pl.id_plan = u.id_plan
WHERE pg.estado_pago = 'EXITOSO'
  AND EXTRACT(MONTH FROM pg.fecha_pago) = &MES
  AND EXTRACT(YEAR  FROM pg.fecha_pago) = &ANIO
GROUP BY
    pl.nombre
ORDER BY
    ingresos_totales DESC;

UNDEFINE MES;
UNDEFINE ANIO;


-- 3. Calificación promedio por género
-- Objetivo:
-- Dado un género, mostrar los contenidos de ese género con su
-- calificación promedio y el número de calificaciones registradas.
-- Usa &GENERO para que se solicite en cada ejecución.
SET VERIFY OFF;
UNDEFINE GENERO;

SELECT
    g.nombre                    AS genero,
    c.titulo                    AS titulo_contenido,
    c.tipo_contenido            AS tipo_contenido,
    ROUND(AVG(cc.estrellas), 2) AS calificacion_promedio,
    COUNT(cc.id_calificacion)   AS cantidad_calificaciones
FROM genero g
JOIN contenido_genero cg
    ON cg.id_genero = g.id_genero
JOIN contenido c
    ON c.id_contenido = cg.id_contenido
LEFT JOIN calificacion_contenido cc
    ON cc.id_contenido = c.id_contenido
WHERE g.nombre = '&GENERO'
GROUP BY
    g.nombre,
    c.titulo,
    c.tipo_contenido
ORDER BY
    calificacion_promedio DESC NULLS LAST,
    cantidad_calificaciones DESC,
    titulo_contenido ASC;

UNDEFINE GENERO;