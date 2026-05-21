/*
Función 1: FN_CALCULAR_MONTO
Recibe p_idusuario y devuelve el valor a pagar del próximo periodo; 
esto tiene sentido porque cada usuario está asociado a un plan por 
usuario.idplan, cada plan tiene preciomensual, y el usuario puede 
tener un descuentoproximopago entre 0 y 00.

1.Declaras el encabezado de la función con retorno NUMBER.

2.Buscas el precio del plan y el descuento del usuario con 
un JOIN entre usuario y plansuscripcion.

3.Calculas 
monto=precio∗(1−descuento/100).

4.Retornas el monto redondeado a 2 decimales.
*/

CREATE OR REPLACE FUNCTION FN_CALCULAR_MONTO (
    p_idusuario IN NUMBER
) RETURN NUMBER
IS
    v_preciobase   NUMBER(10,2);
    v_descuento    NUMBER(5,2);
    v_monto        NUMBER(10,2);
BEGIN
    SELECT p.PRECIO_MENSUAL,
           u.DESCUENTO_PROXIMO_PAGO
    INTO   v_preciobase,
           v_descuento
    FROM   USUARIO u
    JOIN   PLAN_SUSCRIPCION p
           ON u.ID_PLAN = p.ID_PLAN
    WHERE  u.ID_USUARIO = p_idusuario;

    v_monto := v_preciobase
               - (v_preciobase * NVL(v_descuento, 0) / 100);

    RETURN ROUND(v_monto, 2);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END;
/

/*
Función 2 : FN_CONTENIDO_RECOMENDADO, 
Se devuelve el idcontenido recomendado para un perfil; 
una forma limpia de hacerlo es recomendar un contenido 
que comparta género con lo más visto por ese perfil y 
que todavía no haya sido reproducido por ese mismo perfil.

Eso encaja con el modelo porque reproduccion guarda qué ha 
consumido el perfil, contenidogenero relaciona los contenidos 
con géneros y contenido.activo permite filtrar contenido disponible.

1. Identificar el género más consumido por el perfil 
a partir de sus reproducciones.

2. Buscar otro contenido activo de ese mismo género.

3. Excluir contenidos ya vistos por ese perfil.

4. Elegir uno, por ejemplo el más reciente o el de mayor idcontenido.
*/

CREATE OR REPLACE FUNCTION FN_CONTENIDO_RECOMENDADO (
    p_idperfil IN NUMBER
) RETURN NUMBER
IS
    v_idcontenido NUMBER;
BEGIN
    SELECT ID_CONTENIDO
    INTO   v_idcontenido
    FROM (
        SELECT c.ID_CONTENIDO
        FROM   CONTENIDO c
        JOIN   CONTENIDO_GENERO cg
               ON c.ID_CONTENIDO = cg.ID_CONTENIDO
        WHERE  c.ACTIVO = 'S'
          AND  cg.ID_GENERO = (
                SELECT ID_GENERO
                FROM (
                    SELECT cg2.ID_GENERO,
                           COUNT(*) AS total
                    FROM   REPRODUCCION r
                    JOIN   CONTENIDO_GENERO cg2
                           ON r.ID_CONTENIDO = cg2.ID_CONTENIDO
                    WHERE  r.ID_PERFIL = p_idperfil
                    GROUP  BY cg2.ID_GENERO
                    ORDER  BY total DESC, cg2.ID_GENERO
                )
                WHERE ROWNUM = 1
          )
          AND  c.ID_CONTENIDO NOT IN (
                SELECT r2.ID_CONTENIDO
                FROM   REPRODUCCION r2
                WHERE  r2.ID_PERFIL = p_idperfil
          )
        ORDER BY c.FECHA_AGREGADO DESC,
                 c.ID_CONTENIDO DESC
    )
    WHERE ROWNUM = 1;

    RETURN v_idcontenido;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END;
/


/* Ejecutar pruebas

Funcion: FN_CALCULAR_MONTO--------------------------------------------- 
*/

SELECT
    ID_USUARIO,
    ID_PLAN,
    DESCUENTO_PROXIMO_PAGO,
    FN_CALCULAR_MONTO(ID_USUARIO) AS MONTO_CALCULADO
FROM USUARIO
FETCH FIRST 10 ROWS ONLY;

/
/* Funcion: FN_CONTENIDO_RECOMENDADO------------------------------------
*/

SELECT
    ID_PERFIL,
    FN_CONTENIDO_RECOMENDADO(ID_PERFIL) AS CONTENIDO_RECOMENDADO
FROM PERFIL
FETCH FIRST 10 ROWS ONLY;
/
