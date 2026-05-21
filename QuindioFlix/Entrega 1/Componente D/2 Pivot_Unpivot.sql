-- 1. PIVOT – Usuarios activos por ciudad y plan
-- Reporte donde las filas son las ciudades y las columnas los planes,
-- mostrando la cantidad de usuarios ACTIVOS en cada combinación.

SELECT *
FROM (
    SELECT
        u.ciudad_residencia AS ciudad,
        pl.nombre           AS plan,
        u.id_usuario        AS id_usuario
    FROM usuario u
    JOIN plan_suscripcion pl
        ON pl.id_plan = u.id_plan
    WHERE u.estado_cuenta = 'ACTIVA'
) src
PIVOT (
    COUNT(id_usuario)
    FOR plan IN (
        'BASICO'   AS BASICO,
        'ESTANDAR' AS ESTANDAR,
        'PREMIUM'  AS PREMIUM
    )
)
ORDER BY ciudad;
-- Usa la dimensión de ciudad y plan, como sugiere el enunciado.
-- Los alias BASICO, ESTANDAR, PREMIUM generan columnas claras para el informe.


------------------------------------------------------------------------------------------

-- 2. PIVOT – Reproducciones por categoría de contenido y dispositivo
-- Reporte donde las filas son las categorías (tipo de contenido) y las 
-- columnas, los dispositivos, mostrando el número total de reproducciones.

SELECT *
FROM (
    SELECT
        c.tipo_contenido AS tipo_contenido,
        r.dispositivo    AS dispositivo,
        r.id_reproduccion
    FROM reproduccion r
    JOIN contenido c
        ON c.id_contenido = r.id_contenido
) src
PIVOT (
    COUNT(id_reproduccion)
    FOR dispositivo IN (
        'CELULAR'    AS CELULAR,
        'TABLET'     AS TABLET,
        'TV'         AS TV,
        'COMPUTADOR' AS COMPUTADOR
    )
)
ORDER BY tipo_contenido;

-- Usa TIPO_CONTENIDO como “categoría” (película, serie, documental, música, podcast).
-- Cubre el ejemplo de “reproducciones por categoría y dispositivo” 
-- del enunciado.

---------------------------------------------------------------------------------------------


-- 3. UNPIVOT – Métricas de usuarios por plan en forma vertical
-- Se quiere transformar columnas métricas por plan en filas
-- para análisis genérico (útil si luego se aplican filtros o joins adicionales).

WITH resumen_plan AS (
    SELECT
        pl.nombre                         AS plan,
        COUNT(u.id_usuario)               AS usuarios_totales,
        SUM(CASE WHEN u.estado_cuenta = 'ACTIVA' THEN 1 ELSE 0 END)  AS usuarios_activos,
        SUM(CASE WHEN u.estado_cuenta <> 'ACTIVA' THEN 1 ELSE 0 END) AS usuarios_no_activos
    FROM plan_suscripcion pl
    LEFT JOIN usuario u
        ON u.id_plan = pl.id_plan
    GROUP BY pl.nombre
)
SELECT
    plan,
    tipo_metrica,
    valor
FROM resumen_plan
UNPIVOT (
    valor FOR tipo_metrica IN (
        usuarios_totales     AS 'USUARIOS_TOTALES',
        usuarios_activos     AS 'USUARIOS_ACTIVOS',
        usuarios_no_activos  AS 'USUARIOS_NO_ACTIVOS'
    )
)
ORDER BY plan, tipo_metrica;
-- UNPIVOT convierte columnas de métricas en filas (tipo_metrica + valor).
-----------------------------------------------------------------------------------


-- 4. UNPIVOT – Reproducciones por dispositivo a formato vertical
-- A partir de un PIVOT previo (o de una tabla resumen), convertimos 
-- columnas por dispositivo en filas para análisis flexible.

-- Primero, un resumen por tipo de contenido con columnas por dispositivo
WITH resumen_dispositivo AS (
    SELECT *
    FROM (
        SELECT
            c.tipo_contenido AS tipo_contenido,
            r.dispositivo    AS dispositivo,
            r.id_reproduccion
        FROM reproduccion r
        JOIN contenido c
            ON c.id_contenido = r.id_contenido
    ) src
    PIVOT (
        COUNT(id_reproduccion)
        FOR dispositivo IN (
            'CELULAR'    AS CELULAR,
            'TABLET'     AS TABLET,
            'TV'         AS TV,
            'COMPUTADOR' AS COMPUTADOR
        )
    )
)
SELECT
    tipo_contenido,
    dispositivo,
    total_reproducciones
FROM resumen_dispositivo
UNPIVOT (
    total_reproducciones FOR dispositivo IN (
        CELULAR     AS 'CELULAR',
        TABLET      AS 'TABLET',
        TV          AS 'TV',
        COMPUTADOR  AS 'COMPUTADOR'
    )
)
ORDER BY tipo_contenido, dispositivo;