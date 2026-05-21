-- 1. Vista materializada de consumo por contenido
-- Precalcula el total de reproducciones y la calificación 
-- promedio por contenido; sirve como base para un reporte 
-- de “Contenido más popular”.

CREATE MATERIALIZED VIEW MV_CONSUMO_CONTENIDO
BUILD IMMEDIATE
REFRESH COMPLETE
AS
SELECT
    c.ID_CONTENIDO,
    c.TITULO,
    c.TIPO_CONTENIDO,
    c.CLASIFICACION_EDAD,
    COUNT(r.ID_REPRODUCCION) AS TOTAL_REPRODUCCIONES,
    ROUND(
        AVG(
            CASE
                WHEN r.PORCENTAJE_AVANCE >= 90 THEN 1
                ELSE 0
            END
        ) * 100,
        2
    ) AS PORC_REPRODUCCIONES_COMPLETAS,
    ROUND(AVG(cc.ESTRELLAS), 2) AS CALIFICACION_PROMEDIO,
    COUNT(cc.ID_CALIFICACION)   AS TOTAL_CALIFICACIONES
FROM CONTENIDO c
LEFT JOIN REPRODUCCION r
    ON r.ID_CONTENIDO = c.ID_CONTENIDO
LEFT JOIN CALIFICACION_CONTENIDO cc
    ON cc.ID_CONTENIDO = c.ID_CONTENIDO
GROUP BY
    c.ID_CONTENIDO,
    c.TITULO,
    c.TIPO_CONTENIDO,
    c.CLASIFICACION_EDAD;

-- Ejemplo de uso:
SELECT *
FROM MV_CONSUMO_CONTENIDO
ORDER BY TOTAL_REPRODUCCIONES DESC
FETCH FIRST 20 ROWS ONLY;



--------------------------------------------------------------------------------------
-- 2. Vista materializada de reproducciones diarias por ciudad
-- Precalcula el número de reproducciones por día y por ciudad
-- de residencia del usuario (a través de PERFIL → USUARIO).
-- Sirve para dashboards simples de consumo diario.

CREATE MATERIALIZED VIEW MV_REPRODUCCIONES_DIARIAS_CIUDAD
BUILD IMMEDIATE
REFRESH COMPLETE
AS
SELECT
    TRUNC(r.FECHA_HORA_INICIO) AS FECHA,
    u.CIUDAD_RESIDENCIA        AS CIUDAD,
    COUNT(r.ID_REPRODUCCION)   AS TOTAL_REPRODUCCIONES
FROM REPRODUCCION r
JOIN PERFIL p
    ON p.ID_PERFIL = r.ID_PERFIL
JOIN USUARIO u
    ON u.ID_USUARIO = p.ID_USUARIO
GROUP BY
    TRUNC(r.FECHA_HORA_INICIO),
    u.CIUDAD_RESIDENCIA;

-- Ejemplo de uso:
SELECT FECHA, CIUDAD, TOTAL_REPRODUCCIONES
FROM MV_REPRODUCCIONES_DIARIAS_CIUDAD
WHERE CIUDAD = 'Armenia'
ORDER BY FECHA;