-- 1. ROLLUP – Ingresos por ciudad y plan con subtotales
-- Reporte de ingresos por ciudad y plan de suscripción, 
-- con subtotales por ciudad y un gran total final.

SELECT
    NVL(u.ciudad_residencia, '*** TOTAL GENERAL ***') AS ciudad,
    NVL(pl.nombre,           '*** SUBTOTAL CIUDAD ***') AS plan,
    SUM(pg.monto_pagado)                              AS ingresos_totales
FROM pago_suscripcion pg
JOIN usuario u
    ON u.id_usuario = pg.id_usuario
JOIN plan_suscripcion pl
    ON pl.id_plan = u.id_plan
WHERE pg.estado_pago = 'EXITOSO'
GROUP BY ROLLUP (u.ciudad_residencia, pl.nombre)
ORDER BY
    ciudad NULLS LAST,
    plan   NULLS LAST;
-- La fila con ciudad y plan ambos nulos representa el total general,
-- y las filas con solo plan nulo son subtotales por ciudad.


------------------------------------------------------------------------------------

-- 2. CUBE – Reproducciones por tipo de contenido y dispositivo
-- Reporte de reproducciones cruzando tipo de contenido y dispositivo,
-- incluyendo todas las combinaciones de totales (por tipo, por dispositivo y total general) usando CUBE.

SELECT
    NVL(c.tipo_contenido, '*** TODOS LOS TIPOS ***')          AS tipo_contenido,
    NVL(r.dispositivo,    '*** TODOS LOS DISPOSITIVOS ***')   AS dispositivo,
    COUNT(r.id_reproduccion)                                  AS total_reproducciones
FROM reproduccion r
JOIN contenido c
    ON c.id_contenido = r.id_contenido
GROUP BY CUBE (c.tipo_contenido, r.dispositivo)
ORDER BY
    tipo_contenido NULLS LAST,
    dispositivo    NULLS LAST;
-- CUBE genera totales por tipo, por dispositivo 
-- y un total general de reproducciones.
------------------------------------------------------------------------------------


-- 3. GROUPING() – Marcar totales y subtotales en el reporte de ingresos
-- Reutiliza la idea de ingresos por ciudad y plan, 
-- pero usando GROUPING() para identificar si una fila es detalle,
-- subtotal por ciudad o total general.

SELECT
    CASE
        WHEN GROUPING(u.ciudad_residencia) = 1
             AND GROUPING(pl.nombre) = 1 THEN 'TOTAL_GENERAL'
        WHEN GROUPING(u.ciudad_residencia) = 0
             AND GROUPING(pl.nombre) = 1 THEN 'SUBTOTAL_CIUDAD'
        ELSE 'DETALLE'
    END                                             AS tipo_fila,
    NVL(u.ciudad_residencia, 'TODAS_LAS_CIUDADES') AS ciudad,
    NVL(pl.nombre,           'TODOS_LOS_PLANES')   AS plan,
    SUM(pg.monto_pagado)                           AS ingresos_totales
FROM pago_suscripcion pg
JOIN usuario u
    ON u.id_usuario = pg.id_usuario
JOIN plan_suscripcion pl
    ON pl.id_plan = u.id_plan
WHERE pg.estado_pago = 'EXITOSO'
GROUP BY ROLLUP (u.ciudad_residencia, pl.nombre)
ORDER BY
    DECODE(tipo_fila, 'DETALLE', 1, 'SUBTOTAL_CIUDAD', 2, 'TOTAL_GENERAL', 3),
    ciudad,
    plan;
-- GROUPING(columna) devuelve 1 en filas de subtotal/total para esa columna,
-- y 0 en filas de detalle.
-----------------------------------------------------------------------------------


-- 4. GROUPING SETS – Totales selectivos por género y ciudad
-- Reporte que muestra solo los totales por género y solo los 
-- totales por ciudad, sin el cruce género–ciudad.

SELECT
    CASE
        WHEN GROUPING(g.nombre) = 0
             AND GROUPING(u.ciudad_residencia) = 1 THEN 'POR_GENERO'
        WHEN GROUPING(g.nombre) = 1
             AND GROUPING(u.ciudad_residencia) = 0 THEN 'POR_CIUDAD'
        ELSE 'OTRO'
    END                                      AS tipo_resumen,
    NVL(g.nombre,           'TODOS_LOS_GENEROS')   AS genero,
    NVL(u.ciudad_residencia,'TODAS_LAS_CIUDADES')  AS ciudad,
    COUNT(r.id_reproduccion)                        AS total_reproducciones
FROM reproduccion r
JOIN perfil p
    ON p.id_perfil = r.id_perfil
JOIN usuario u
    ON u.id_usuario = p.id_usuario
JOIN contenido c
    ON c.id_contenido = r.id_contenido
JOIN contenido_genero cg
    ON cg.id_contenido = c.id_contenido
JOIN genero g
    ON g.id_genero = cg.id_genero
GROUP BY GROUPING SETS (
    (g.nombre),             -- total por género
    (u.ciudad_residencia)   -- total por ciudad
)
ORDER BY
    tipo_resumen,
    genero,
    ciudad;
-- GROUPING SETS permite pedir explícitamente “solo totales por género”
-- y “solo totales por ciudad”, sin generar el cruce completo.
-- tipo_resumen distingue si la fila corresponde a género o a ciudad.
