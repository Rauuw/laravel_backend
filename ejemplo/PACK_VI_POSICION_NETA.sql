create or replace PACKAGE BODY           PACK_VI_POSICION_NETA
AS
    FUNCTION fn_calcula_temp (p_rol          IN VARCHAR2,
                              p_tc           IN VARCHAR2,
                              p_tipo_local   IN NUMBER,
                              p_bisa_flag    IN VARCHAR2,
                              p_importe      IN NUMBER,
                              p_com_adq      IN NUMBER,
                              p_com_emi      IN NUMBER,
                              p_com_pro      IN NUMBER)
        RETURN NUMBER
    IS
        v_tc_grp   VARCHAR2 (2);
        v_sgn      NUMBER := 1;
        v_temp     NUMBER := 0;
    BEGIN
        -- 1) NORMALIZAR TC
        IF p_tc IN ('05', '06', '25')
        THEN
            v_tc_grp := '05';
        ELSIF p_tc IN ('07', '27')
        THEN
            v_tc_grp := '07';
        ELSIF p_tc = '28'
        THEN
            v_tc_grp := '28';
        ELSE
            v_tc_grp := p_tc;
        END IF;

        -- 2) SIGNO REVERSI¿N
        IF p_tc IN ('06', '25', '27')
        THEN
            v_sgn := -1;
        END IF;

        -- 3) C¿LCULO CONTABLE
        IF p_rol = 'ADQ'
        THEN
            CASE v_tc_grp
                WHEN '07'
                THEN
                    v_temp := NVL (p_importe, 0) + NVL (p_com_adq, 0);
                WHEN '05'
                THEN
                    IF p_tipo_local = 1
                    THEN
                        v_temp :=
                              NVL (p_importe, 0)
                            - NVL (p_com_emi, 0)
                            - NVL (p_com_pro, 0);
                    ELSE
                        v_temp :=
                              NVL (p_importe, 0)
                            - NVL (p_com_adq, 0)
                            - NVL (p_com_emi, 0)
                            - NVL (p_com_pro, 0);
                    END IF;
                WHEN '28'
                THEN
                    v_temp := NVL (p_com_adq, 0);
            END CASE;
        ELSIF p_rol = 'EMI'
        THEN
            CASE v_tc_grp
                WHEN '07'
                THEN
                    v_temp := NVL (p_importe, 0) + NVL (p_com_emi, 0);
                WHEN '05'
                THEN
                    v_temp := NVL (p_importe, 0) - NVL (p_com_emi, 0);
                WHEN '28'
                THEN
                    v_temp := NVL (p_com_emi, 0);
            END CASE;
        END IF;

        RETURN v_sgn * v_temp;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END fn_calcula_temp;

    FUNCTION fn_calcula_temp_pos_neta (p_rol          IN VARCHAR2, -- 'ADQ' | 'EMI'
                                       p_tc           IN VARCHAR2,
                                       p_tipo_local   IN NUMBER, -- 1=Dom,2=Nac,4=Int
                                       p_importe      IN NUMBER,
                                       p_retencion    IN NUMBER, -- SIS_RETENCION_COMERCIO (100%)
                                       p_com_emi      IN NUMBER)
        RETURN NUMBER
    IS
        v_tc_grp    VARCHAR2 (2);
        v_reversa   BOOLEAN := FALSE;
        v_valor     NUMBER := 0;
    BEGIN
        /* ===================== 1. NORMALIZAR TC ===================== */
        IF p_tc IN ('05', '06', '25')
        THEN
            v_tc_grp := '05';                                        -- COMPRA
        ELSIF p_tc IN ('07', '27')
        THEN
            v_tc_grp := '07';                                        -- AVANCE
        ELSIF p_tc = '28'
        THEN
            v_tc_grp := '28';                                 -- NO FINANCIERA
        ELSE
            RETURN 0;
        END IF;

        /* ===================== 2. REVERSA ===================== */
        IF p_tc IN ('06', '25', '27')
        THEN
            v_reversa := TRUE;
        END IF;

        /* ===================== 3. C¿LCULO ===================== */
        IF p_rol = 'ADQ'
        THEN
            CASE v_tc_grp
                /* ---------- AVANCES ---------- */
                WHEN '07'
                THEN
                    IF v_reversa
                    THEN
                        v_valor := -NVL (p_importe, 0) - NVL (p_com_emi, 0);
                    ELSE
                        v_valor := NVL (p_importe, 0) + NVL (p_com_emi, 0);
                    END IF;
                /* ---------- COMPRAS ---------- */
                WHEN '05'
                THEN
                    IF v_reversa
                    THEN
                        v_valor := -NVL (p_importe, 0) + NVL (p_retencion, 0);
                    ELSE
                        v_valor := NVL (p_importe, 0) - NVL (p_retencion, 0);
                    END IF;
                /* ---------- NO FINANCIERAS ---------- */
                WHEN '28'
                THEN
                    v_valor := NVL (p_com_emi, 0);
            END CASE;
        ELSIF p_rol = 'EMI'
        THEN
            CASE v_tc_grp
                /* ---------- AVANCES ---------- */
                WHEN '07'
                THEN
                    IF v_reversa
                    THEN
                        v_valor := -NVL (p_importe, 0) - NVL (p_com_emi, 0);
                    ELSE
                        v_valor := NVL (p_importe, 0) + NVL (p_com_emi, 0);
                    END IF;
                /* ---------- COMPRAS ---------- */
                WHEN '05'
                THEN
                    IF v_reversa
                    THEN
                        v_valor := -NVL (p_importe, 0) + NVL (p_com_emi, 0);
                    ELSE
                        v_valor := NVL (p_importe, 0) - NVL (p_com_emi, 0);
                    END IF;
                /* ---------- NO FINANCIERAS ---------- */
                WHEN '28'
                THEN
                    v_valor := NVL (p_com_emi, 0);
            END CASE;
        END IF;

        RETURN v_valor;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END fn_calcula_temp_pos_neta;


    FUNCTION fn_calcula_temp_sin_comision_compra (p_rol          IN VARCHAR2,
                                                  p_tc           IN VARCHAR2,
                                                  p_tipo_local   IN NUMBER,
                                                  p_bisa_flag    IN VARCHAR2,
                                                  p_importe      IN NUMBER,
                                                  p_com_adq      IN NUMBER,
                                                  p_com_emi      IN NUMBER,
                                                  p_com_pro      IN NUMBER)
        RETURN NUMBER
    IS
        v_tc_grp   VARCHAR2 (2);
        v_sgn      NUMBER := 1;
        v_temp     NUMBER := 0;
    BEGIN
        ------------------------------------------------------------------
        -- 1) NORMALIZAR TC
        ------------------------------------------------------------------
        IF p_tc IN ('05', '06', '25')
        THEN
            v_tc_grp := '05';                                        -- Compra
        ELSIF p_tc IN ('07', '27')
        THEN
            v_tc_grp := '07';                                        -- Avance
        ELSIF p_tc = '28'
        THEN
            v_tc_grp := '28';                                           -- TNF
        ELSE
            v_tc_grp := p_tc;
        END IF;

        ------------------------------------------------------------------
        -- 2) SIGNO PARA REVERSIONES
        ------------------------------------------------------------------
        IF p_tc IN ('06', '25', '27')
        THEN
            v_sgn := -1;
        END IF;

        ------------------------------------------------------------------
        -- 3) C¿LCULO CONTABLE (SIN COMISI¿N EN COMPRAS)
        ------------------------------------------------------------------
        IF p_rol = 'ADQ'
        THEN
            CASE v_tc_grp
                WHEN '05'
                THEN
                    -- COMPRA ADQ: SOLO MONTO
                    v_temp := NVL (p_importe, 0);
                WHEN '07'
                THEN
                    -- AVANCE
                    v_temp := NVL (p_importe, 0) + NVL (p_com_adq, 0);
                WHEN '28'
                THEN
                    -- TNF
                    v_temp := NVL (p_com_adq, 0);
            END CASE;
        ELSIF p_rol = 'EMI'
        THEN
            CASE v_tc_grp
                WHEN '05'
                THEN
                    -- COMPRA EMI: SOLO MONTO
                    v_temp := NVL (p_importe, 0);
                WHEN '07'
                THEN
                    -- AVANCE
                    v_temp := NVL (p_importe, 0) + NVL (p_com_emi, 0);
                WHEN '28'
                THEN
                    -- TNF
                    v_temp := NVL (p_com_emi, 0);
            END CASE;
        END IF;

        RETURN v_sgn * v_temp;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END fn_calcula_temp_sin_comision_compra;



    --------------------------------------------------------------------
    -- Funci¿n gen¿rica que abre el cursor seg¿n p_producto:
    --------------------------------------------------------------------
    PROCEDURE do_calcula_posicion_neta (p_bank_id    IN     NUMBER,
                                        p_fecha      IN     VARCHAR2,
                                        p_producto   IN     NUMBER, -- 1 = d¿bito, 2 = cr¿dito, NULL = ambos
                                        p_cursor        OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_cursor FOR
            WITH
                adq
                AS
                    (  SELECT liad.SIS_TIPO_LOCAL            AS tipo_local,
                              CASE
                                  WHEN liad.SIS_TIPO_LOCAL = 4 THEN 840
                                  ELSE liad.MONEDA
                              END                            AS moneda_uni,
                              SUM (
                                  fn_calcula_temp (
                                      'ADQ',
                                      liad.TC,
                                      liad.SIS_TIPO_LOCAL,
                                      CASE
                                          WHEN coad.adquirente = p_bank_id
                                          THEN
                                              'S'
                                          ELSE
                                              'N'
                                      END,
                                      liad.MONTO_DESTINO,
                                      liad.COMISION_ADQ,
                                      liad.COMISION_EMI,
                                      liad.COMISION_PRO))    AS total_adq
                         FROM sial.vi_liquidaciones_adq liad
                              JOIN sial.comu_adquirentes coad
                                  ON     coad.adquirente = liad.SIS_BANCO_ADQ
                                     AND coad.adquirente = p_bank_id
                        WHERE     TRUNC (liad.SIS_FECHA_LIQUIDADA) =
                                  TO_DATE (p_fecha, 'YYYYMMDD')
                              /* si p_producto es no nulo, filtra por d¿bito/cr¿dito */
                              AND (liad.SIS_PRODUCTO IN (1, 2))
                              --AND liad.TIPO_TX_LIQ_ADQ = 1
                              AND sis_marca = 1
                     GROUP BY liad.SIS_TIPO_LOCAL,
                              CASE
                                  WHEN liad.SIS_TIPO_LOCAL = 4 THEN 840
                                  ELSE liad.MONEDA
                              END),
                emi
                AS
                    (  SELECT liem.SIS_TIPO_LOCAL          AS tipo_local,
                              -- Igual aqu¿, todo internacional va en 840
                              CASE
                                  WHEN liem.SIS_TIPO_LOCAL = 4 THEN 840
                                  ELSE liem.MONEDA
                              END                          AS moneda_uni,
                              SUM (fn_calcula_temp ('EMI',
                                                    liem.TC,
                                                    liem.SIS_TIPO_LOCAL,
                                                    'N',
                                                    liem.MONTO,
                                                    0,
                                                    liem.COMISION_EMI,
                                                    0))    AS total_emi
                         FROM sial.vi_liquidaciones_emi liem
                              JOIN sial.comu_adquirentes coad
                                  ON     coad.adquirente = p_bank_id
                                     AND liem.SIS_BANCO_EMI = coad.emisor_id
                        WHERE     TRUNC (liem.SIS_FECHA_LIQUIDADA) =
                                  TO_DATE (p_fecha, 'YYYYMMDD')
                              /* mismo filtro de producto */
                              AND (liem.SIS_PRODUCTO IN (1, 2))
                     --AND liem.TIPO_TX_LIQ_ADQ = 1
                     GROUP BY liem.SIS_TIPO_LOCAL,
                              CASE
                                  WHEN liem.SIS_TIPO_LOCAL = 4 THEN 840
                                  ELSE liem.MONEDA
                              END)
              SELECT NVL (a.tipo_local, e.tipo_local)               AS tipo_local,
                     NVL (a.moneda_uni, e.moneda_uni)               AS moneda,
                     CASE NVL (a.tipo_local, e.tipo_local)
                         WHEN 1 THEN 'DOM¿STICA'
                         WHEN 2 THEN 'NACIONAL'
                         WHEN 4 THEN 'INTERNACIONAL'
                         ELSE 'Desconocido'
                     END                                            AS tipo_liquidacion,
                     CASE NVL (a.moneda_uni, e.moneda_uni)
                         WHEN 68 THEN 'BS.'
                         WHEN 840 THEN '$US.'
                         ELSE 'OTRA'
                     END                                            AS moneda_liq,
                     NVL (a.total_adq, 0)                           AS total_adq,
                     NVL (e.total_emi, 0)                           AS total_emi,
                     NVL (e.total_emi, 0) - NVL (a.total_adq, 0)    AS neto,
                     CASE
                         WHEN NVL (e.total_emi, 0) > NVL (a.total_adq, 0)
                         THEN
                             'A PAGAR'
                         WHEN NVL (e.total_emi, 0) < NVL (a.total_adq, 0)
                         THEN
                             'A COBRAR'
                         ELSE
                             NULL
                     END                                            AS estado
                FROM adq a
                     FULL OUTER JOIN emi e
                         ON     a.tipo_local = e.tipo_local
                            AND a.moneda_uni = e.moneda_uni
            ORDER BY NVL (a.tipo_local, e.tipo_local),
                     NVL (a.moneda_uni, e.moneda_uni);
    END do_calcula_posicion_neta;


    --------------------------------------------------------------------
    -- Procedimientos p¿blicos que reutilizan la gen¿rica:
    --------------------------------------------------------------------
    PROCEDURE proc_calcula_posicion_neta (p_bank_id   IN     NUMBER,
                                          p_fecha     IN     VARCHAR2,
                                          p_cursor       OUT SYS_REFCURSOR)
    IS
    BEGIN
        -- Ambos (1 y 2)
        do_calcula_posicion_neta (p_bank_id,
                                  p_fecha,
                                  NULL,
                                  p_cursor);
    END proc_calcula_posicion_neta;


    PROCEDURE proc_calcula_posicion_neta_credito (
        p_bank_id   IN     NUMBER,
        p_fecha     IN     VARCHAR2,
        p_cursor       OUT SYS_REFCURSOR)
    IS
    BEGIN
        -- S¿lo cr¿dito (SIS_PRODUCTO = 2)
        do_calcula_posicion_neta (p_bank_id,
                                  p_fecha,
                                  2,
                                  p_cursor);
    END proc_calcula_posicion_neta_credito;


    PROCEDURE proc_calcula_posicion_neta_debito (
        p_bank_id   IN     NUMBER,
        p_fecha     IN     VARCHAR2,
        p_cursor       OUT SYS_REFCURSOR)
    IS
    BEGIN
        -- S¿lo d¿bito (SIS_PRODUCTO = 1)
        do_calcula_posicion_neta (p_bank_id,
                                  p_fecha,
                                  1,
                                  p_cursor);
    END proc_calcula_posicion_neta_debito;


    PROCEDURE sp_obtener_adquirente (
        p_adquirente         IN     sial.comu_adquirentes.adquirente%TYPE,
        o_registro              OUT SYS_REFCURSOR,
        o_codigo_respuesta      OUT PLS_INTEGER,
        o_descripcion_resp      OUT VARCHAR2)
    IS
        v_activo   NUMBER;
    BEGIN
        --------------------------------------------------------------------
        -- REGLA ESPECIAL PARA ADQUIRENTE 99 (LINKSER)
        --------------------------------------------------------------------
        IF p_adquirente = 99
        THEN
            OPEN o_registro FOR
                SELECT 99            AS adquirente,
                       'LINKSER'     AS descripcion,
                       'LKS'         AS institucion_id,
                       99            AS emisor_id,
                       'L'           AS abreviatura,
                       9999          AS codigo_banco
                  FROM DUAL;

            o_codigo_respuesta := 0;
            o_descripcion_resp := 'OK';
            RETURN;
        END IF;

        --------------------------------------------------------------------

        -- L¿GICA NORMAL PARA EL RESTO DE ADQUIRENTES
        SELECT activo
          INTO v_activo
          FROM sial.comu_adquirentes
         WHERE adquirente = p_adquirente;

        IF v_activo != 1
        THEN
            o_codigo_respuesta := -1;
            o_descripcion_resp :=
                'Adquirente ' || p_adquirente || ' est¿ inactivo';
            o_registro := NULL;
            RETURN;
        END IF;

        OPEN o_registro FOR SELECT adquirente,
                                   descripcion,
                                   institucion_id,
                                   emisor_id,
                                   abreviatura,
                                   codigo_banco
                              FROM sial.comu_adquirentes
                             WHERE adquirente = p_adquirente;

        o_codigo_respuesta := 0;
        o_descripcion_resp := 'OK';
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            o_codigo_respuesta := -2;
            o_descripcion_resp :=
                'Adquirente ' || p_adquirente || ' no encontrado';
            o_registro := NULL;
        WHEN OTHERS
        THEN
            o_codigo_respuesta := SQLCODE;
            o_descripcion_resp := SQLERRM;
            o_registro := NULL;
    END sp_obtener_adquirente;

    PROCEDURE sp_obtener_emisor (
        p_emisor             IN     sial.tj_bancos_emisores.banco%TYPE,
        o_registro              OUT SYS_REFCURSOR,
        o_codigo_respuesta      OUT PLS_INTEGER,
        o_descripcion_resp      OUT VARCHAR2)
    IS
        v_dummy   NUMBER;
    BEGIN
        --------------------------------------------------------------------
        -- REGLA ESPECIAL PARA EMISOR 99 (LINKSER)
        --------------------------------------------------------------------
        IF p_emisor = 99
        THEN
            OPEN o_registro FOR
                SELECT 99            AS banco,
                       'LINKSER'     AS descripcion,
                       'S.A.'        AS denominacion,
                       'L'           AS banco_cca,
                       68            AS pais,
                       99            AS adquirente_id,
                       'LKS'         AS abreviatura,
                       9999          AS adquirente_codigo_banco,
                       1             AS adquirente_activo
                  FROM DUAL;

            o_codigo_respuesta := 0;
            o_descripcion_resp := 'OK';
            RETURN;
        END IF;

        --------------------------------------------------------------------

        -- VALIDACI¿N NORMAL
        SELECT 1
          INTO v_dummy
          FROM sial.tj_bancos_emisores
         WHERE banco = p_emisor;

        OPEN o_registro FOR
            SELECT be.banco,
                   be.descripcion,
                   be.denominacion,
                   be.banco_cca,
                   be.pais,
                   be.adquirente_id,
                   ca.institucion_id     AS abreviatura,
                   ca.codigo_banco       AS adquirente_codigo_banco,
                   ca.activo             AS adquirente_activo
              FROM sial.tj_bancos_emisores  be
                   LEFT JOIN sial.comu_adquirentes ca
                       ON ca.adquirente = be.adquirente_id
             WHERE be.banco = p_emisor;

        o_codigo_respuesta := 0;
        o_descripcion_resp := 'OK';
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            o_registro := NULL;
            o_codigo_respuesta := -2;
            o_descripcion_resp := 'Emisor ' || p_emisor || ' no encontrado';
        WHEN OTHERS
        THEN
            o_registro := NULL;
            o_codigo_respuesta := SQLCODE;
            o_descripcion_resp := SQLERRM;
    END sp_obtener_emisor;



    PROCEDURE proc_posicion_neta_por_departamento (
        p_bank_id            IN     NUMBER,
        p_periodo            IN     VARCHAR2,                    -- 'YYYYMMDD'
        p_tipo_liquidacion   IN     NUMBER,
        p_tipo_producto      IN     NUMBER, -- NULL = ambos (1 y 2); en tu l¿gica usas 3 como ¿ambos¿
        p_cursor                OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_cursor FOR
            WITH
                /* ===================== ADQUIRENTE: base por SUCURSAL ===================== */
                adq_base
                AS
                    (SELECT coag.descripcion       AS sucursal,
                            coag.codigo_agencia    AS suc_cod,
                            liad.MONEDA_DESTINO    AS moneda,
                            CASE
                                WHEN liad.TC IN ('05', '06', '25') THEN '05' -- Compra + devoluciones
                                WHEN liad.TC IN ('07', '27') THEN '07' -- Avance + reversi¿n
                                WHEN liad.TC = '28' THEN '28'           -- TNF
                                ELSE liad.TC
                            END                    AS tc_grp,
                            CASE
                                WHEN liad.TC IN ('06', '25', '27') THEN -1
                                ELSE 1
                            END                    AS sgn,
                            liad.MONTO_DESTINO,
                            liad.COMISION_ADQ,
                            liad.SIS_RETENCION_COMERCIO,
                            liad.COMISION_EMI,
                            liad.COMISION_PRO
                       FROM sial.vi_liquidaciones_adq  liad
                            JOIN sial.comu_agencias coag
                                ON coag.CODIGO_AGENCIA =
                                   liad.SIS_SUCURSAL_ADQ
                      WHERE     liad.SIS_BANCO_ADQ = p_bank_id
                            AND liad.sis_marca = 1
                            AND TRUNC (liad.SIS_FECHA_LIQUIDADA) =
                                TO_DATE (p_periodo, 'YYYYMMDD')
                            AND liad.SIS_TIPO_LOCAL = p_tipo_liquidacion
                            AND (   p_tipo_producto = 3
                                 OR liad.SIS_PRODUCTO = p_tipo_producto)),
                adq
                AS
                    (  SELECT sucursal,
                              suc_cod,
                              moneda,
                              tc_grp        AS tc,
                              SUM (
                                  CASE
                                      WHEN tc_grp = '28' THEN 0
                                      ELSE sgn * NVL (MONTO_DESTINO, 0)
                                  END)      AS monto_saliente,
                              /* Comisi¿n saliente unificada (con signo) */
                              SUM (
                                    sgn
                                  * CASE
                                        WHEN tc_grp = '05'
                                        THEN
                                              NVL (COMISION_ADQ, 0)
                                            + NVL (COMISION_EMI, 0)
                                        WHEN tc_grp = '07'
                                        THEN
                                            NVL (COMISION_EMI, 0)
                                        WHEN tc_grp = '28'
                                        THEN
                                            NVL (COMISION_EMI, 0)
                                        ELSE
                                            0
                                    END)    AS comision_saliente,
                              /* Retenci¿n Linkser (solo para dom¿stico y solo COMISION_ADQ) */
                              SUM (
                                    sgn
                                  * CASE
                                        WHEN     p_tipo_liquidacion = 1
                                             AND tc_grp = '05'
                                        THEN
                                            NVL (COMISION_ADQ, 0)
                                        ELSE
                                            0
                                    END)    AS com_lks_saliente,
                              /* Comisi¿n ADQ pura (sin cambios) */
                              SUM (
                                    sgn
                                  * CASE
                                        WHEN p_tipo_liquidacion IN (2, 4)
                                        THEN
                                            NVL (SIS_RETENCION_COMERCIO, 0)
                                        WHEN tc_grp = '07'
                                        THEN
                                            NVL (COMISION_ADQ, 0)
                                        WHEN tc_grp = '05'
                                        THEN
                                            NVL (SIS_RETENCION_COMERCIO, 0)
                                        WHEN tc_grp = '28'
                                        THEN
                                            NVL (COMISION_ADQ, 0)
                                        ELSE
                                            0
                                    END)    AS com_adq_saliente
                         FROM adq_base
                     GROUP BY sucursal,
                              suc_cod,
                              moneda,
                              tc_grp),
                /* ======================= EMISOR: base por SUCURSAL ======================= */
                emi_base
                AS
                    (SELECT /* prioriza desc de cat¿logo de emisores; si no, intenta de agencias; ¿ltimo recurso: id como texto */
                            COALESCE (suem.descripcion,
                                      suad.descripcion,
                                      TO_CHAR (suem.sucursal))
                                AS sucursal,
                            suem.sucursal
                                AS suc_cod,
                            liem.MONEDA
                                AS moneda,
                            CASE
                                WHEN liem.TC IN ('05', '06', '25') THEN '05'
                                WHEN liem.TC IN ('07', '27') THEN '07'
                                WHEN liem.TC = '28' THEN '28'
                                ELSE liem.TC
                            END
                                AS tc_grp,
                            CASE
                                WHEN liem.TC IN ('06', '25', '27') THEN -1
                                ELSE 1
                            END
                                AS sgn,
                            liem.MONTO,
                            liem.COMISION_EMI
                       FROM sial.vi_liquidaciones_emi  liem
                            JOIN sial.tj_sucursales_emisores suem
                                ON suem.sucursal = liem.SIS_SUCURSAL_EMI
                            JOIN sial.comu_adquirentes coad
                                ON     coad.adquirente = p_bank_id
                                   AND liem.SIS_BANCO_EMI = coad.emisor_id
                            /* opcional para intentar obtener descripci¿n de sucursal ADQ (si existe mapeo mismo banco/c¿digo) */
                            LEFT JOIN sial.comu_agencias suad
                                ON     suad.codigo_agencia = suem.sucursal
                                   AND suad.codigo_banco = coad.codigo_banco
                      WHERE     liem.sis_marca = 1
                            AND TRUNC (liem.SIS_FECHA_LIQUIDADA) =
                                TO_DATE (p_periodo, 'YYYYMMDD')
                            AND liem.SIS_TIPO_LOCAL = p_tipo_liquidacion
                            AND (   p_tipo_producto = 3
                                 OR liem.SIS_PRODUCTO = p_tipo_producto)),
                emi
                AS
                    (  SELECT sucursal,
                              suc_cod,
                              moneda,
                              tc_grp      AS tc,
                              /* TNF: monto 0; resto con signo */
                              SUM (
                                  CASE
                                      WHEN tc_grp = '28' THEN 0
                                      ELSE sgn * NVL (MONTO, 0)
                                  END)    AS monto_entrante,
                              /* Comisi¿n entrante (con signo para 06/25/27) */
                              SUM (
                                  CASE
                                      WHEN tc_grp IN ('05', '07', '28')
                                      THEN
                                          sgn * NVL (COMISION_EMI, 0)
                                      ELSE
                                          0
                                  END)    AS comision_entrante
                         FROM emi_base
                     GROUP BY sucursal,
                              suc_cod,
                              moneda,
                              tc_grp)
              /* ======================= UNION/Neteo por SUCURSAL ======================= */
              SELECT COALESCE (e.suc_cod, a.suc_cod)      AS cod_sucursal,
                     COALESCE (e.sucursal, a.sucursal)    AS sucursal,
                     COALESCE (e.moneda, a.moneda)        AS moneda,
                     CASE COALESCE (e.moneda, a.moneda)
                         WHEN 68 THEN 'Bolivianos'
                         WHEN 840 THEN 'Dolares'
                         ELSE 'OTRA'
                     END                                  AS moneda_liq,
                     COALESCE (e.tc, a.tc)                AS tc, -- 05 / 07 / 28
                     NVL (a.monto_saliente, 0)            AS monto_saliente,
                     NVL (a.comision_saliente, 0)         AS comision_saliente,
                     CASE
                         WHEN p_tipo_liquidacion IN (2, 4)
                         THEN
                             NVL (a.comision_saliente, 0)
                         ELSE
                             NVL (a.com_lks_saliente, 0)
                     END                                  AS retencion_linkser,
                     NVL (a.com_adq_saliente, 0)          AS com_adq_saliente,
                     NVL (e.monto_entrante, 0)            AS monto_entrante,
                     NVL (e.comision_entrante, 0)         AS comision_entrante,
                     /* Neto por concepto agrupado:
                        - 07: (ms + cs) - (me + ce)
                        - 05: (ms - cs) - (me - ce)
                        - 28: ce - cs
                     */
                     CASE COALESCE (e.tc, a.tc)
                         WHEN '07'
                         THEN
                               (  NVL (a.monto_saliente, 0)
                                + NVL (a.comision_saliente, 0))
                             - (  NVL (e.monto_entrante, 0)
                                + NVL (e.comision_entrante, 0))
                         WHEN '05'
                         THEN
                               (  NVL (a.monto_saliente, 0)
                                - NVL (a.comision_saliente, 0))
                             - (  NVL (e.monto_entrante, 0)
                                - NVL (e.comision_entrante, 0))
                         WHEN '28'
                         THEN
                               NVL (e.comision_entrante, 0)
                             - NVL (a.comision_saliente, 0)
                         ELSE
                               (  NVL (a.monto_saliente, 0)
                                - NVL (a.comision_saliente, 0))
                             - (  NVL (e.monto_entrante, 0)
                                - NVL (e.comision_entrante, 0))
                     END                                  AS neto
                FROM adq a
                     FULL OUTER JOIN emi e
                         ON     a.suc_cod = e.suc_cod
                            AND a.moneda = e.moneda
                            AND a.tc = e.tc
            ORDER BY COALESCE (e.suc_cod, a.suc_cod),       -- sucursal c¿digo
                     COALESCE (e.sucursal, a.sucursal),     -- sucursal c¿digo
                     COALESCE (e.tc, a.tc),                    -- 05 / 07 / 28
                     COALESCE (e.moneda, a.moneda);                  -- moneda
    END proc_posicion_neta_por_departamento;


    PROCEDURE proc_posicion_neta_por_sucursal (
        p_bank_id            IN     NUMBER, -- ID EMISOR (tj_bancos_emisores.banco)
        p_periodo            IN     VARCHAR2,
        p_tipo_liquidacion   IN     NUMBER,
        p_tipo_producto      IN     NUMBER,                       -- 3 = ambos
        p_cursor                OUT SYS_REFCURSOR)
    IS
        v_producto_fun   NUMBER;
    BEGIN
        v_producto_fun := NVL (p_tipo_producto, 3);

        OPEN p_cursor FOR
            WITH
                /* =====================================================
                   EMISOR ¿ OBTENER ADQUIRENTE ASOCIADO
                ===================================================== */
                emisor
                AS
                    (SELECT be.banco             AS banco_emisor,
                            be.adquirente_id     AS adquirente_id
                       FROM sial.tj_bancos_emisores be
                      WHERE be.banco = p_bank_id),
                /* =====================================================
                   ADQUIRENTE (SALIENTE) - F¿RMULA AJUSTADA PARA TU L¿GICA
                ===================================================== */
                adq
                AS
                    (  SELECT liad.SIS_SUCURSAL_ADQ
                                  AS cod_sucursal,
                              ag.descripcion
                                  AS sucursal,
                              liad.MONEDA_DESTINO
                                  AS moneda,
                              liad.TC
                                  AS tc,
                              /* MONTO SALIENTE - igual que antes */
                              SUM (NVL (liad.MONTO_DESTINO, 0))
                                  AS monto_saliente,
                              /* COMISI¿N SALIENTE - usando fn_calcula_temp_pos_neta para consistencia */
                              SUM (
                                  CASE
                                      WHEN     p_tipo_liquidacion IN (1, 2, 4)
                                           AND liad.TC IN ('05', '06', '25')
                                      THEN
                                          NVL (liad.SIS_RETENCION_COMERCIO, 0)
                                      ELSE
                                            NVL (liad.COMISION_ADQ, 0)
                                          + NVL (liad.COMISION_EMI, 0)
                                  END)
                                  AS comision_saliente,
                              /* RETENCI¿N LINKSER - igual que antes */
                              SUM (
                                  CASE
                                      WHEN p_tipo_liquidacion = 1
                                      THEN
                                          NVL (liad.COMISION_ADQ, 0)
                                      WHEN     p_tipo_liquidacion IN (2, 4)
                                           AND liad.TC IN ('05', '06', '25')
                                      THEN
                                          NVL (liad.SIS_RETENCION_COMERCIO, 0)
                                      ELSE
                                          NVL (liad.SIS_RETENCION_COMERCIO, 0)
                                  END)
                                  AS retencion_linkser,
                              /* TOTAL_ADQ AJUSTADO para tu f¿rmula: para TC 06,25,27 debemos cambiar el signo */
                              SUM (
                                  CASE
                                      /* Para reversiones (06,25,27), la funci¿n devuelve negativo,
                                         pero para tu f¿rmula necesitamos positivo */
                                      WHEN liad.TC IN ('06', '25', '27')
                                      THEN
                                            -1
                                          * fn_calcula_temp_pos_neta (
                                                'ADQ',
                                                liad.TC,
                                                liad.SIS_TIPO_LOCAL,
                                                liad.MONTO_DESTINO,
                                                liad.SIS_RETENCION_COMERCIO,
                                                liad.COMISION_EMI)
                                      ELSE
                                          fn_calcula_temp_pos_neta (
                                              'ADQ',
                                              liad.TC,
                                              liad.SIS_TIPO_LOCAL,
                                              liad.MONTO_DESTINO,
                                              liad.SIS_RETENCION_COMERCIO,
                                              liad.COMISION_EMI)
                                  END)
                                  AS total_adq,
                              COUNT (*)
                                  AS total_tx_adq
                         FROM sial.vi_liquidaciones_adq liad
                              JOIN emisor e
                                  ON liad.SIS_BANCO_ADQ = e.adquirente_id
                              JOIN sial.comu_adquirentes ca
                                  ON ca.adquirente = liad.SIS_BANCO_ADQ
                              JOIN sial.comu_agencias ag
                                  ON     ag.codigo_agencia =
                                         liad.SIS_SUCURSAL_ADQ
                                     AND ag.codigo_banco = ca.codigo_banco
                        WHERE     liad.SIS_MARCA = 1
                              --AND liad.tipo_tx_liq_adq = 1
                              AND TRUNC (liad.SIS_FECHA_LIQUIDADA) =
                                  TO_DATE (p_periodo, 'YYYYMMDD')
                              AND liad.SIS_TIPO_LOCAL = p_tipo_liquidacion
                              AND (   v_producto_fun = 3
                                   OR liad.SIS_PRODUCTO = v_producto_fun)
                     GROUP BY liad.SIS_SUCURSAL_ADQ,
                              ag.descripcion,
                              liad.MONEDA_DESTINO,
                              liad.TC),
                /* =====================================================
                   EMISOR (ENTRANTE) - F¿RMULA AJUSTADA PARA TU L¿GICA
                ===================================================== */
                emi
                AS
                    (  SELECT liem.SIS_SUCURSAL_EMI
                                  AS cod_sucursal,
                              se.descripcion
                                  AS sucursal,
                              liem.MONEDA_DESTINO
                                  AS moneda,
                              liem.TC
                                  AS tc,
                              /* MONTO ENTRANTE - igual que antes */
                              SUM (NVL (liem.MONTO_DESTINO, 0))
                                  AS monto_entrante,
                              /* COMISI¿N ENTRANTE - igual que antes */
                              SUM (NVL (liem.COMISION_EMI, 0))
                                  AS comision_entrante,
                              /* TOTAL_EMI AJUSTADO para tu f¿rmula: para TC 06,25,27 debemos cambiar el signo */
                              SUM (
                                  CASE
                                      /* Para reversiones (06,25,27), la funci¿n devuelve negativo,
                                         pero para tu f¿rmula necesitamos que monto_entrante sea negativo */
                                      WHEN liem.TC IN ('06', '25', '27')
                                      THEN
                                            -1
                                          * fn_calcula_temp_pos_neta (
                                                'EMI',
                                                liem.TC,
                                                liem.SIS_TIPO_LOCAL,
                                                liem.MONTO_DESTINO,
                                                0,
                                                liem.COMISION_EMI)
                                      ELSE
                                          fn_calcula_temp_pos_neta (
                                              'EMI',
                                              liem.TC,
                                              liem.SIS_TIPO_LOCAL,
                                              liem.MONTO_DESTINO,
                                              0,
                                              liem.COMISION_EMI)
                                  END)
                                  AS total_emi,
                              COUNT (*)
                                  AS total_tx_emi
                         FROM sial.vi_liquidaciones_emi liem
                              JOIN sial.tj_sucursales_emisores se
                                  ON     se.sucursal = liem.SIS_SUCURSAL_EMI
                                     AND se.banco = liem.SIS_BANCO_EMI
                        WHERE     liem.SIS_BANCO_EMI = p_bank_id
                              AND liem.SIS_MARCA = 1
                              --AND liem.tipo_tx_liq_adq = 1
                              AND TRUNC (liem.SIS_FECHA_LIQUIDADA) =
                                  TO_DATE (p_periodo, 'YYYYMMDD')
                              AND liem.SIS_TIPO_LOCAL = p_tipo_liquidacion
                              AND (   v_producto_fun = 3
                                   OR liem.SIS_PRODUCTO = v_producto_fun)
                     GROUP BY liem.SIS_SUCURSAL_EMI,
                              se.descripcion,
                              liem.MONEDA_DESTINO,
                              liem.TC)
              /* =====================================================
                 NETO POR SUCURSAL / MONEDA / TC
              ===================================================== */
              SELECT COALESCE (a.cod_sucursal, e.cod_sucursal)
                         AS cod_sucursal,
                     COALESCE (a.sucursal, e.sucursal)
                         AS sucursal,
                     COALESCE (a.moneda, e.moneda)
                         AS moneda,
                     CASE COALESCE (a.moneda, e.moneda)
                         WHEN 68 THEN 'Bolivianos'
                         WHEN 840 THEN 'D¿lares'
                         ELSE 'OTRA'
                     END
                         AS moneda_liq,
                     COALESCE (a.tc, e.tc)
                         AS tc,
                     NVL (a.monto_saliente, 0)
                         AS monto_saliente,
                     NVL (a.comision_saliente, 0)
                         AS comision_saliente,
                     NVL (a.retencion_linkser, 0)
                         AS retencion_linkser,
                     NVL (e.monto_entrante, 0)
                         AS monto_entrante,
                     NVL (e.comision_entrante, 0)
                         AS comision_entrante,
                     /* F¿RMULA: ADQ - EMI (como quieres) */
                     NVL (a.total_adq, 0) - NVL (e.total_emi, 0)
                         AS neto
                FROM adq a
                     FULL OUTER JOIN emi e
                         ON     a.cod_sucursal = e.cod_sucursal
                            AND a.moneda = e.moneda
                            AND a.tc = e.tc
            ORDER BY COALESCE (a.cod_sucursal, e.cod_sucursal),
                     COALESCE (a.tc, e.tc),
                     COALESCE (a.moneda, e.moneda);
    END proc_posicion_neta_por_sucursal;


    PROCEDURE do_calcula_posicion_neta_rango (
        p_bank_id       IN     NUMBER,                    -- SIEMPRE ID EMISOR
        p_fecha_desde   IN     VARCHAR2,
        p_fecha_hasta   IN     VARCHAR2,
        p_producto      IN     NUMBER,      -- 1=d¿bito, 2=cr¿dito, NULL=ambos
        p_cursor           OUT SYS_REFCURSOR)
    IS
        v_desde   DATE := TO_DATE (p_fecha_desde, 'YYYYMMDD');
        v_hasta   DATE := TO_DATE (p_fecha_hasta, 'YYYYMMDD');
    BEGIN
        ------------------------------------------------------------------
        -- CASO LINKSER
        ------------------------------------------------------------------
        IF p_bank_id = 99
        THEN
            SIAL.PACK_VI_RESUMEN_COMISIONES.proc_posicion_neta_linkser (
                p_fecha_desde   => p_fecha_desde,
                p_fecha_hasta   => p_fecha_hasta,
                p_cursor        => p_cursor);
            RETURN;
        END IF;

        ------------------------------------------------------------------
        -- C¿LCULO CORRECTO (EMISOR COMO ENTRADA)
        ------------------------------------------------------------------
        OPEN p_cursor FOR
            WITH
                /* ================= ADQUIRIENTE ================= */
                adq
                AS
                    (  SELECT liad.SIS_TIPO_LOCAL            AS tipo_local,
                              liad.MONEDA_DESTINO            AS moneda,
                              SUM (
                                  fn_calcula_temp_pos_neta (
                                      'ADQ',
                                      liad.TC,
                                      liad.SIS_TIPO_LOCAL,
                                      liad.MONTO_DESTINO,
                                      liad.SIS_RETENCION_COMERCIO,
                                      liad.COMISION_EMI))    AS total_adq
                         FROM sial.vi_liquidaciones_adq liad
                        WHERE     liad.SIS_BANCO_ADQ IN
                                      (SELECT ca.adquirente
                                         FROM sial.comu_adquirentes ca
                                        WHERE ca.emisor_id = p_bank_id)
                              AND TRUNC (liad.SIS_FECHA_LIQUIDADA) BETWEEN v_desde
                                                                       AND v_hasta
                              --AND liad.TIPO_TX_LIQ_ADQ = 1
                              AND liad.SIS_MARCA = 1
                              AND (   p_producto IS NULL
                                   OR liad.SIS_PRODUCTO = p_producto)
                     GROUP BY liad.SIS_TIPO_LOCAL, liad.MONEDA_DESTINO),
                /* ================= EMISOR ================= */
                emi
                AS
                    (  SELECT liem.SIS_TIPO_LOCAL            AS tipo_local,
                              liem.MONEDA_DESTINO            AS moneda,
                              SUM (
                                  fn_calcula_temp_pos_neta (
                                      'EMI',
                                      liem.TC,
                                      liem.SIS_TIPO_LOCAL,
                                      liem.MONTO_DESTINO,
                                      0,
                                      liem.COMISION_EMI))    AS total_emi
                         FROM sial.vi_liquidaciones_emi liem
                        WHERE     liem.SIS_BANCO_EMI = p_bank_id
                              AND TRUNC (liem.SIS_FECHA_LIQUIDADA) BETWEEN v_desde
                                                                       AND v_hasta
                              -- AND liem.TIPO_TX_LIQ_ADQ = 1
                              AND liem.SIS_MARCA = 1
                              AND (   p_producto IS NULL
                                   OR liem.SIS_PRODUCTO = p_producto)
                     GROUP BY liem.SIS_TIPO_LOCAL, liem.MONEDA_DESTINO)
              /* ================= NETO ================= */
              SELECT COALESCE (a.tipo_local, e.tipo_local)
                         AS tipo_local,
                     COALESCE (a.moneda, e.moneda)
                         AS moneda,
                     CASE COALESCE (a.tipo_local, e.tipo_local)
                         WHEN 1 THEN 'DOM¿STICA'
                         WHEN 2 THEN 'NACIONAL'
                         WHEN 4 THEN 'INTERNACIONAL'
                     END
                         AS tipo_liquidacion,
                     CASE COALESCE (a.moneda, e.moneda)
                         WHEN 68 THEN 'BS.'
                         WHEN 840 THEN '$US.'
                     END
                         AS moneda_liq,
                     NVL (a.total_adq, 0)
                         AS total_adq,
                     NVL (e.total_emi, 0)
                         AS total_emi,
                     NVL (e.total_emi, 0) - NVL (a.total_adq, 0)
                         AS neto,
                     CASE
                         WHEN NVL (e.total_emi, 0) > NVL (a.total_adq, 0)
                         THEN
                             'A PAGAR'
                         WHEN NVL (e.total_emi, 0) < NVL (a.total_adq, 0)
                         THEN
                             'A COBRAR'
                         ELSE
                             'NEUTRO'
                     END
                         AS estado
                FROM adq a
                     FULL JOIN emi e
                         ON a.tipo_local = e.tipo_local AND a.moneda = e.moneda
            ORDER BY tipo_local, moneda;
    END do_calcula_posicion_neta_rango;


    -- ===== Wrappers p¿blicos =====

    PROCEDURE proc_calcula_posicion_neta_rango (
        p_bank_id       IN     NUMBER,
        p_fecha_desde   IN     VARCHAR2,
        p_fecha_hasta   IN     VARCHAR2,
        p_cursor           OUT SYS_REFCURSOR)
    IS
    BEGIN
        -- Ambos productos (1 y 2)
        do_calcula_posicion_neta_rango (p_bank_id,
                                        p_fecha_desde,
                                        p_fecha_hasta,
                                        NULL,
                                        p_cursor);
    END proc_calcula_posicion_neta_rango;


    PROCEDURE proc_calcula_posicion_neta_credito_rango (
        p_bank_id       IN     NUMBER,
        p_fecha_desde   IN     VARCHAR2,
        p_fecha_hasta   IN     VARCHAR2,
        p_cursor           OUT SYS_REFCURSOR)
    IS
    BEGIN
        -- Solo cr¿dito (SIS_PRODUCTO = 2)
        do_calcula_posicion_neta_rango (p_bank_id,
                                        p_fecha_desde,
                                        p_fecha_hasta,
                                        2,
                                        p_cursor);
    END proc_calcula_posicion_neta_credito_rango;


    PROCEDURE proc_calcula_posicion_neta_debito_rango (
        p_bank_id       IN     NUMBER,
        p_fecha_desde   IN     VARCHAR2,
        p_fecha_hasta   IN     VARCHAR2,
        p_cursor           OUT SYS_REFCURSOR)
    IS
    BEGIN
        -- Solo d¿bito (SIS_PRODUCTO = 1)
        do_calcula_posicion_neta_rango (p_bank_id,
                                        p_fecha_desde,
                                        p_fecha_hasta,
                                        1,
                                        p_cursor);
    END proc_calcula_posicion_neta_debito_rango;

    /* =========================================================================
       * POSICI¿N NETA (TODOS LOS BANCOS) POR RANGO DE FECHAS
       * ========================================================================= */

    -- Helper privado: calcula para TODOS los bancos, opcionalmente filtrando producto
    PROCEDURE do_calcula_posicion_neta_rango_all (
        p_fecha_desde   IN     VARCHAR2,
        p_fecha_hasta   IN     VARCHAR2,
        p_producto      IN     NUMBER,
        p_cursor           OUT SYS_REFCURSOR)
    IS
        v_desde             DATE := TO_DATE (p_fecha_desde, 'YYYYMMDD');
        v_hasta             DATE := TO_DATE (p_fecha_hasta, 'YYYYMMDD');

        -- LINKSER
        v_linkser_bs_dom    NUMBER := 0;
        v_linkser_usd_dom   NUMBER := 0;
        v_linkser_bs_nac    NUMBER := 0;
        v_linkser_usd_nac   NUMBER := 0;
        v_linkser_bs_int    NUMBER := 0;
        v_linkser_usd_int   NUMBER := 0;

        v_producto_fun      NUMBER;
    BEGIN
        v_producto_fun := NVL (p_producto, 3);

        -- ================= LINKSER (NO TOCAR) =================
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            1,
            68,
            v_linkser_bs_dom);
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            1,
            840,
            v_linkser_usd_dom);
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            2,
            68,
            v_linkser_bs_nac);
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            2,
            840,
            v_linkser_usd_nac);
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            4,
            68,
            v_linkser_bs_int);
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            4,
            840,
            v_linkser_usd_int);

        OPEN p_cursor FOR
            WITH
                bancos_activos
                AS
                    (SELECT adquirente AS entidad_id, descripcion
                       FROM sial.comu_adquirentes
                      WHERE activo = 1),
                /* ======================= ADQ ======================= */
                adq
                AS
                    (  SELECT coad.adquirente                              AS entidad_id,
                              coad.descripcion,
                              liad.sis_tipo_local                          AS tipo_local,
                              CASE
                                  WHEN liad.sis_tipo_local = 4 THEN 840
                                  ELSE liad.moneda
                              END                                          AS moneda_uni,
                              SUM (fn_calcula_temp ('ADQ',
                                                    liad.tc,
                                                    liad.sis_tipo_local,
                                                    'S',
                                                    liad.monto_destino,
                                                    liad.comision_adq,
                                                    liad.comision_emi,
                                                    liad.comision_pro))    AS total
                         FROM sial.vi_liquidaciones_adq liad
                              JOIN sial.comu_adquirentes coad
                                  ON coad.adquirente = liad.sis_banco_adq
                        WHERE     liad.sis_fecha_liquidada BETWEEN v_desde
                                                               AND v_hasta
                              -- AND liad.tipo_tx_liq_adq = 1
                              AND liad.sis_marca = 1
                              AND (   p_producto IS NULL
                                   OR liad.sis_producto = p_producto)
                     GROUP BY coad.adquirente,
                              coad.descripcion,
                              liad.sis_tipo_local,
                              CASE
                                  WHEN liad.sis_tipo_local = 4 THEN 840
                                  ELSE liad.moneda
                              END
                     UNION ALL
                     SELECT 99, 'LINKSER', 1, 68, v_linkser_bs_dom FROM DUAL
                     UNION ALL
                     SELECT 99,
                            'LINKSER',
                            1,
                            840,
                            v_linkser_usd_dom
                       FROM DUAL
                     UNION ALL
                     SELECT 99, 'LINKSER', 2, 68, v_linkser_bs_nac FROM DUAL
                     UNION ALL
                     SELECT 99,
                            'LINKSER',
                            2,
                            840,
                            v_linkser_usd_nac
                       FROM DUAL
                     UNION ALL
                     SELECT 99, 'LINKSER', 4, 68, v_linkser_bs_int FROM DUAL
                     UNION ALL
                     SELECT 99,
                            'LINKSER',
                            4,
                            840,
                            v_linkser_usd_int
                       FROM DUAL),
                /* ======================= EMI ======================= */
                emi
                AS
                    (  SELECT COALESCE (tjb.adquirente_id, liem.sis_banco_emi)
                                  AS entidad_id,
                              COALESCE (tjb.descripcion,
                                        TO_CHAR (liem.sis_banco_emi))
                                  AS descripcion,
                              liem.sis_tipo_local
                                  AS tipo_local,
                              CASE
                                  WHEN liem.sis_tipo_local = 4 THEN 840
                                  ELSE liem.moneda
                              END
                                  AS moneda_uni,
                              SUM (fn_calcula_temp ('EMI',
                                                    liem.tc,
                                                    liem.sis_tipo_local,
                                                    'N',
                                                    liem.monto,
                                                    0,
                                                    liem.comision_emi,
                                                    0))
                                  AS total
                         FROM sial.vi_liquidaciones_emi liem
                              LEFT JOIN sial.tj_bancos_emisores tjb
                                  ON tjb.banco = liem.sis_banco_emi
                        WHERE     liem.sis_fecha_liquidada BETWEEN v_desde
                                                               AND v_hasta
                              --AND liem.tipo_tx_liq_adq = 1
                              AND liem.sis_marca = 1
                              AND (   p_producto IS NULL
                                   OR liem.sis_producto = p_producto)
                     GROUP BY COALESCE (tjb.adquirente_id,
                                        liem.sis_banco_emi),
                              COALESCE (tjb.descripcion,
                                        TO_CHAR (liem.sis_banco_emi)),
                              liem.sis_tipo_local,
                              CASE
                                  WHEN liem.sis_tipo_local = 4 THEN 840
                                  ELSE liem.moneda
                              END),
                /* ===== COMISIONES DE COMPRA (SIN TRANSFORMAR) ===== */
                comisiones_compra_adq
                AS
                    (  SELECT liad.sis_banco_adq     AS entidad_id,
                              liad.sis_tipo_local    AS tipo_local,
                              liad.moneda_destino    AS moneda_uni,
                              SUM (
                                  CASE
                                      WHEN liad.sis_tipo_local = 1
                                      THEN
                                          liad.comision_adq
                                      ELSE
                                          liad.sis_retencion_comercio
                                  END)               AS comision
                         FROM sial.vi_liquidaciones_adq liad
                        WHERE     liad.tc = '05'
                              AND liad.sis_marca = 1
                              AND liad.sis_fecha_liquidada BETWEEN v_desde
                                                               AND v_hasta
                              AND (   p_producto IS NULL
                                   OR liad.sis_producto = p_producto)
                     GROUP BY liad.sis_banco_adq,
                              liad.sis_tipo_local,
                              liad.moneda_destino),
                /* ======================= NETOS ======================= */
                netos
                AS
                    (SELECT NVL (a.tipo_local, e.tipo_local)
                                AS tipo_local,
                            NVL (a.entidad_id, e.entidad_id)
                                AS entidad_id,
                            NVL (a.descripcion, e.descripcion)
                                AS descripcion,
                            NVL (a.moneda_uni, e.moneda_uni)
                                AS moneda_uni,
                              NVL (e.total, 0)
                            - NVL (a.total, 0)
                            + NVL (cc.comision, 0)
                                AS neto
                       FROM adq  a
                            FULL JOIN emi e
                                ON     a.entidad_id = e.entidad_id
                                   AND a.tipo_local = e.tipo_local
                                   AND a.moneda_uni = e.moneda_uni
                            LEFT JOIN comisiones_compra_adq cc
                                ON     cc.entidad_id = a.entidad_id
                                   AND cc.tipo_local = a.tipo_local
                                   AND cc.moneda_uni = a.moneda_uni),
                total_bancos
                AS
                    (SELECT entidad_id, descripcion FROM bancos_activos
                     UNION
                     SELECT entidad_id, descripcion FROM adq
                     UNION
                     SELECT entidad_id, descripcion FROM emi
                     UNION
                     SELECT 99, 'LINKSER' FROM DUAL),
                tipos_locales
                AS
                    (SELECT 1 tipo_local FROM DUAL
                     UNION ALL
                     SELECT 2 FROM DUAL
                     UNION ALL
                     SELECT 4 FROM DUAL)
              SELECT tl.tipo_local,
                     CASE tl.tipo_local
                         WHEN 1 THEN 'DOM¿STICA'
                         WHEN 2 THEN 'NACIONAL'
                         WHEN 4 THEN 'INTERNACIONAL'
                     END
                         AS tipo_liquidacion,
                     tb.entidad_id
                         AS adquirente,
                     tb.descripcion,
                     SUM (CASE WHEN n.moneda_uni = 68 THEN n.neto ELSE 0 END)
                         AS neto_bs,
                     SUM (CASE WHEN n.moneda_uni = 840 THEN n.neto ELSE 0 END)
                         AS neto_usd
                FROM total_bancos tb
                     CROSS JOIN tipos_locales tl
                     LEFT JOIN netos n
                         ON     n.entidad_id = tb.entidad_id
                            AND n.tipo_local = tl.tipo_local
            GROUP BY tl.tipo_local, tb.entidad_id, tb.descripcion
            ORDER BY tl.tipo_local, tb.entidad_id;
    END do_calcula_posicion_neta_rango_all;



    --------------
    PROCEDURE do_calcula_posicion_neta_rango_all_2 (
        p_fecha_desde   IN     VARCHAR2,
        p_fecha_hasta   IN     VARCHAR2,
        p_producto      IN     NUMBER,
        p_cursor           OUT SYS_REFCURSOR)
    IS
        v_desde             DATE := TO_DATE (p_fecha_desde, 'YYYYMMDD');
        v_hasta             DATE := TO_DATE (p_fecha_hasta, 'YYYYMMDD');

        v_linkser_bs_dom    NUMBER := 0;
        v_linkser_usd_dom   NUMBER := 0;
        v_linkser_bs_nac    NUMBER := 0;
        v_linkser_usd_nac   NUMBER := 0;
        v_linkser_bs_int    NUMBER := 0;
        v_linkser_usd_int   NUMBER := 0;

        v_producto_fun      NUMBER;
    BEGIN
        v_producto_fun := NVL (p_producto, 3);

        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            1,
            68,
            v_linkser_bs_dom);
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            1,
            840,
            v_linkser_usd_dom);
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            2,
            68,
            v_linkser_bs_nac);
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            2,
            840,
            v_linkser_usd_nac);
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            4,
            68,
            v_linkser_bs_int);
        SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
            p_fecha_desde,
            p_fecha_hasta,
            v_producto_fun,
            4,
            840,
            v_linkser_usd_int);

        OPEN p_cursor FOR
            WITH
                bancos
                AS
                    (SELECT ca.adquirente      bank_id,
                            ca.descripcion     banco_descripcion,
                            ca.emisor_id
                       FROM sial.comu_adquirentes ca
                      WHERE     ca.activo = 1
                            AND UPPER (ca.descripcion) <> 'CIDRE IFD'
                     UNION ALL
                     SELECT te.banco, te.descripcion, te.banco
                       FROM sial.tj_bancos_emisores te
                      WHERE     te.banco NOT IN
                                    (SELECT emisor_id
                                       FROM sial.comu_adquirentes
                                      WHERE emisor_id IS NOT NULL)
                            AND UPPER (te.descripcion) <> 'CIDRE IFD'),
                adq
                AS
                    (  SELECT b.bank_id,
                              b.banco_descripcion,
                              liad.sis_tipo_local            AS tipo_local,
                              liad.moneda_destino            AS moneda,
                              SUM (
                                  fn_calcula_temp_pos_neta (
                                      'ADQ',
                                      liad.tc,
                                      liad.sis_tipo_local,
                                      liad.monto_destino,
                                      liad.sis_retencion_comercio,
                                      liad.comision_emi))    AS total_adq
                         FROM sial.vi_liquidaciones_adq liad
                              JOIN bancos b ON b.bank_id = liad.sis_banco_adq
                        WHERE     liad.sis_marca = 1
                              --AND liad.tipo_tx_liq_adq = 1
                              AND TRUNC (liad.sis_fecha_liquidada) BETWEEN v_desde
                                                                       AND v_hasta
                              AND (   v_producto_fun = 3
                                   OR liad.sis_producto = v_producto_fun)
                     GROUP BY b.bank_id,
                              b.banco_descripcion,
                              liad.sis_tipo_local,
                              liad.moneda_destino),
                emi
                AS
                    (  SELECT b.bank_id,
                              b.banco_descripcion,
                              liem.sis_tipo_local            AS tipo_local,
                              liem.moneda_destino            AS moneda,
                              SUM (
                                  fn_calcula_temp_pos_neta (
                                      'EMI',
                                      liem.tc,
                                      liem.sis_tipo_local,
                                      liem.monto_destino,
                                      0,
                                      liem.comision_emi))    AS total_emi
                         FROM sial.vi_liquidaciones_emi liem
                              JOIN bancos b ON b.emisor_id = liem.sis_banco_emi
                        WHERE     liem.sis_marca = 1
                              --AND liem.tipo_tx_liq_adq = 1
                              AND TRUNC (liem.sis_fecha_liquidada) BETWEEN v_desde
                                                                       AND v_hasta
                              AND (   v_producto_fun = 3
                                   OR liem.sis_producto = v_producto_fun)
                     GROUP BY b.bank_id,
                              b.banco_descripcion,
                              liem.sis_tipo_local,
                              liem.moneda_destino),
                netos_bancos
                AS
                    (SELECT COALESCE (e.bank_id, a.bank_id)
                                AS entidad_id,
                            COALESCE (e.banco_descripcion,
                                      a.banco_descripcion)
                                AS descripcion,
                            COALESCE (e.tipo_local, a.tipo_local)
                                AS tipo_local,
                            COALESCE (e.moneda, a.moneda)
                                AS moneda,
                            NVL (e.total_emi, 0) - NVL (a.total_adq, 0)
                                AS neto
                       FROM adq  a
                            FULL JOIN emi e
                                ON     a.bank_id = e.bank_id
                                   AND a.tipo_local = e.tipo_local
                                   AND a.moneda = e.moneda),
                netos
                AS
                    (SELECT entidad_id,
                            descripcion,
                            tipo_local,
                            moneda,
                            neto
                       FROM netos_bancos
                     UNION ALL
                     SELECT 99, 'LINKSER', 1, 68, -v_linkser_bs_dom FROM DUAL
                     UNION ALL
                     SELECT 99,
                            'LINKSER',
                            1,
                            840,
                            -v_linkser_usd_dom
                       FROM DUAL
                     UNION ALL
                     SELECT 99, 'LINKSER', 2, 68, -v_linkser_bs_nac FROM DUAL
                     UNION ALL
                     SELECT 99,
                            'LINKSER',
                            2,
                            840,
                            -v_linkser_usd_nac
                       FROM DUAL
                     UNION ALL
                     SELECT 99, 'LINKSER', 4, 68, -v_linkser_bs_int FROM DUAL
                     UNION ALL
                     SELECT 99,
                            'LINKSER',
                            4,
                            840,
                            -v_linkser_usd_int
                       FROM DUAL),
                total_bancos
                AS
                    (SELECT bank_id               AS entidad_id,
                            banco_descripcion     AS descripcion
                       FROM bancos
                     UNION ALL
                     SELECT 99, 'LINKSER' FROM DUAL),
                tipos_locales
                AS
                    (SELECT 1 tipo_local FROM DUAL
                     UNION ALL
                     SELECT 2 FROM DUAL
                     UNION ALL
                     SELECT 4 FROM DUAL)
              SELECT tl.tipo_local,
                     CASE tl.tipo_local
                         WHEN 1 THEN 'DOM¿STICA'
                         WHEN 2 THEN 'NACIONAL'
                         WHEN 4 THEN 'INTERNACIONAL'
                     END
                         AS tipo_liquidacion,
                     tb.entidad_id
                         AS adquirente,
                     tb.descripcion,
                     SUM (CASE WHEN n.moneda = 68 THEN n.neto ELSE 0 END)
                         AS neto_bs,
                     SUM (CASE WHEN n.moneda = 840 THEN n.neto ELSE 0 END)
                         AS neto_usd
                FROM total_bancos tb
                     CROSS JOIN tipos_locales tl
                     LEFT JOIN netos n
                         ON     n.entidad_id = tb.entidad_id
                            AND n.tipo_local = tl.tipo_local
            GROUP BY tl.tipo_local, tb.entidad_id, tb.descripcion
            ORDER BY tl.tipo_local, tb.entidad_id;
    END do_calcula_posicion_neta_rango_all_2;

    ----------------------


    -- Wrappers p¿blicos (todos los bancos)
    PROCEDURE proc_calcula_posicion_neta_rango_all (
        p_fecha_desde   IN     VARCHAR2,
        p_fecha_hasta   IN     VARCHAR2,
        p_cursor           OUT SYS_REFCURSOR)
    IS
    BEGIN
        do_calcula_posicion_neta_rango_all_2 (p_fecha_desde,
                                              p_fecha_hasta,
                                              NULL,
                                              p_cursor);
    END proc_calcula_posicion_neta_rango_all;

    PROCEDURE proc_calcula_posicion_neta_credito_rango_all (
        p_fecha_desde   IN     VARCHAR2,
        p_fecha_hasta   IN     VARCHAR2,
        p_cursor           OUT SYS_REFCURSOR)
    IS
    BEGIN
        do_calcula_posicion_neta_rango_all_2 (p_fecha_desde,
                                              p_fecha_hasta,
                                              2,
                                              p_cursor);
    END proc_calcula_posicion_neta_credito_rango_all;

    PROCEDURE proc_calcula_posicion_neta_debito_rango_all (
        p_fecha_desde   IN     VARCHAR2,
        p_fecha_hasta   IN     VARCHAR2,
        p_cursor           OUT SYS_REFCURSOR)
    IS
    BEGIN
        do_calcula_posicion_neta_rango_all_2 (p_fecha_desde,
                                              p_fecha_hasta,
                                              1,
                                              p_cursor);
    END proc_calcula_posicion_neta_debito_rango_all;


    PROCEDURE proc_posicion_neta_general_resumen (
        p_periodo            IN     VARCHAR2,
        p_tipo_liquidacion   IN     NUMBER,
        p_tipo_producto      IN     NUMBER,
        p_cursor                OUT SYS_REFCURSOR)
    IS
        v_producto_fun   NUMBER;
    BEGIN
        v_producto_fun := NVL (p_tipo_producto, 3);

        OPEN p_cursor FOR
            WITH
                bancos
                AS
                    (SELECT ca.adquirente      AS bank_id,
                            ca.descripcion     AS banco_descripcion,
                            ca.emisor_id       AS emisor_id
                       FROM sial.comu_adquirentes ca
                      WHERE     ca.activo = 1
                            AND UPPER (ca.descripcion) <> 'CIDRE IFD'
                     UNION                           -- ¿¿ CAMBIO AQUÍ
                     SELECT te.banco           AS bank_id,
                            te.descripcion     AS banco_descripcion,
                            te.banco           AS emisor_id
                       FROM sial.tj_bancos_emisores te
                      WHERE     te.banco NOT IN
                                    (SELECT emisor_id
                                       FROM sial.comu_adquirentes
                                      WHERE emisor_id IS NOT NULL)
                            AND UPPER (te.descripcion) <> 'CIDRE IFD'),
                adq
                AS
                    (  SELECT b.bank_id,
                              b.banco_descripcion,
                              liad.MONEDA_DESTINO    AS moneda,
                              liad.TC                AS tc,
                              SUM (
                                  CASE
                                      WHEN liad.TC IN ('06', '25', '27')
                                      THEN
                                          -ABS (NVL (liad.MONTO_DESTINO, 0))
                                      ELSE
                                          NVL (liad.MONTO_DESTINO, 0)
                                  END)               AS monto_saliente,
                              SUM (
                                  CASE
                                      WHEN liad.TC = '07' THEN NVL (liad.COMISION_ADQ, 0)
                                      WHEN     p_tipo_liquidacion IN (1, 2, 4)
                                           AND liad.TC IN ('05', '06', '25')
                                      THEN
                                          CASE
                                              WHEN liad.TC IN ('06', '25')
                                              THEN
                                                  -ABS (
                                                       NVL (
                                                           liad.SIS_RETENCION_COMERCIO,
                                                           0))
                                              ELSE
                                                  NVL (
                                                      liad.SIS_RETENCION_COMERCIO,
                                                      0)
                                          END
                                      ELSE
                                          CASE
                                              WHEN liad.TC IN
                                                       ('06', '25', '27')
                                              THEN
                                                  -ABS (
                                                         NVL (
                                                             liad.COMISION_ADQ,
                                                             0)
                                                       + NVL (
                                                             liad.COMISION_EMI,
                                                             0))
                                              ELSE
                                                    NVL (liad.COMISION_ADQ, 0)
                                                 + NVL (liad.COMISION_EMI, 0)
                                          END
                                  END)               AS comision_saliente,
                              SUM (
                                  CASE
                                      WHEN liad.TC = '07'
                                      THEN 0
                                      WHEN p_tipo_liquidacion = 1
                                      THEN NVL (liad.COMISION_ADQ, 0)
                                      WHEN     p_tipo_liquidacion IN (2, 4)
                                           AND liad.TC IN ('05', '06', '25')
                                      THEN
                                          NVL (liad.SIS_RETENCION_COMERCIO, 0)
                                      ELSE
                                          NVL (liad.SIS_RETENCION_COMERCIO, 0)
                                  END)               AS retencion_linkser,
                              SUM (
                                  CASE
                                      WHEN liad.TC IN ('06', '25', '27')
                                      THEN
                                            -1
                                          * fn_calcula_temp_pos_neta (
                                                'ADQ',
                                                liad.TC,
                                                liad.SIS_TIPO_LOCAL,
                                                liad.MONTO_DESTINO,
                                                liad.SIS_RETENCION_COMERCIO,
                                                liad.COMISION_EMI)
                                      ELSE
                                          fn_calcula_temp_pos_neta (
                                              'ADQ',
                                              liad.TC,
                                              liad.SIS_TIPO_LOCAL,
                                              liad.MONTO_DESTINO,
                                              liad.SIS_RETENCION_COMERCIO,
                                              liad.COMISION_EMI)
                                  END)               AS total_adq,
                              COUNT (*)              AS cantidad_transacciones_saliente
                         FROM sial.vi_liquidaciones_adq liad
                              JOIN bancos b ON b.bank_id = liad.SIS_BANCO_ADQ
                        WHERE     liad.SIS_MARCA = 1
                              AND TRUNC (liad.SIS_FECHA_LIQUIDADA) =
                                  TO_DATE (p_periodo, 'YYYYMMDD')
                              AND liad.SIS_TIPO_LOCAL = p_tipo_liquidacion
                              AND (   v_producto_fun = 3
                                   OR liad.SIS_PRODUCTO = v_producto_fun)
                     GROUP BY b.bank_id,
                              b.banco_descripcion,
                              liad.MONEDA_DESTINO,
                              liad.TC),
                emi
                AS
                    (  SELECT b.bank_id,
                              b.banco_descripcion,
                              liem.MONEDA_DESTINO    AS moneda,
                              liem.TC                AS tc,
                              SUM (
                                  CASE
                                      WHEN liem.TC IN ('06', '25', '27')
                                      THEN
                                          -ABS (NVL (liem.MONTO_DESTINO, 0))
                                      ELSE
                                          NVL (liem.MONTO_DESTINO, 0)
                                  END)               AS monto_entrante,
                              SUM (
                                  CASE
                                      WHEN liem.TC IN ('06', '25', '27')
                                      THEN
                                          -ABS (NVL (liem.COMISION_EMI, 0))
                                      ELSE
                                          NVL (liem.COMISION_EMI, 0)
                                  END)               AS comision_entrante,
                              SUM (
                                  CASE
                                      WHEN liem.TC IN ('06', '25', '27')
                                      THEN
                                            -1
                                          * fn_calcula_temp_pos_neta (
                                                'EMI',
                                                liem.TC,
                                                liem.SIS_TIPO_LOCAL,
                                                liem.MONTO_DESTINO,
                                                0,
                                                liem.COMISION_EMI)
                                      ELSE
                                          fn_calcula_temp_pos_neta (
                                              'EMI',
                                              liem.TC,
                                              liem.SIS_TIPO_LOCAL,
                                              liem.MONTO_DESTINO,
                                              0,
                                              liem.COMISION_EMI)
                                  END)               AS total_emi,
                              COUNT (*)              AS cantidad_transacciones_entrante
                         FROM sial.vi_liquidaciones_emi liem
                              JOIN bancos b ON b.emisor_id = liem.SIS_BANCO_EMI
                        WHERE     liem.SIS_MARCA = 1
                              AND TRUNC (liem.SIS_FECHA_LIQUIDADA) =
                                  TO_DATE (p_periodo, 'YYYYMMDD')
                              AND liem.SIS_TIPO_LOCAL = p_tipo_liquidacion
                              AND (   v_producto_fun = 3
                                   OR liem.SIS_PRODUCTO = v_producto_fun)
                     GROUP BY b.bank_id,
                              b.banco_descripcion,
                              liem.MONEDA_DESTINO,
                              liem.TC)
              SELECT COALESCE (e.bank_id, a.bank_id)
                         AS bank_id,
                     COALESCE (e.banco_descripcion, a.banco_descripcion)
                         AS banco,
                     COALESCE (e.moneda, a.moneda)
                         AS moneda,
                     CASE COALESCE (e.moneda, a.moneda)
                         WHEN 68 THEN 'Bolivianos'
                         WHEN 840 THEN 'Dolares'
                         ELSE 'OTRA'
                     END
                         AS moneda_liq,
                     COALESCE (e.tc, a.tc)
                         AS tc,
                     NVL (a.cantidad_transacciones_saliente, 0)
                         AS cantidad_transacciones_saliente,
                     NVL (a.monto_saliente, 0)
                         AS monto_saliente,
                     NVL (a.comision_saliente, 0)
                         AS comision_saliente,
                     NVL (a.retencion_linkser, 0)
                         AS retencion_linkser,
                     NVL (e.cantidad_transacciones_entrante, 0)
                         AS cantidad_transacciones_entrante,
                     NVL (e.monto_entrante, 0)
                         AS monto_entrante,
                     NVL (e.comision_entrante, 0)
                         AS comision_entrante,
                     CASE
                         WHEN COALESCE (e.tc, a.tc) = '07'
                         THEN
                             NVL (a.monto_saliente, 0) + NVL (a.comision_saliente, 0)
                         WHEN COALESCE (e.tc, a.tc) IN ('06',
                                                        '25',
                                                        '27',
                                                        '26')
                         THEN
                             -1 * (NVL (a.total_adq, 0) - NVL (e.total_emi, 0))
                         ELSE
                             (NVL (a.total_adq, 0) - NVL (e.total_emi, 0))
                     END
                         AS neto,
                       NVL (a.cantidad_transacciones_saliente, 0)
                     + NVL (e.cantidad_transacciones_entrante, 0)
                         AS cantidad_transacciones_totales
                FROM adq a
                     FULL OUTER JOIN emi e
                         ON     a.bank_id = e.bank_id
                            AND a.moneda = e.moneda
                            AND a.tc = e.tc
            ORDER BY COALESCE (e.bank_id, a.bank_id),
                     COALESCE (e.tc, a.tc),
                     COALESCE (e.moneda, a.moneda);
    END proc_posicion_neta_general_resumen;


    PROCEDURE proc_calcula_posicion_neta_adquirentes_rango_all (
        p_fecha_desde   IN     VARCHAR2,
        p_fecha_hasta   IN     VARCHAR2,
        p_producto      IN     NUMBER,
        p_cursor           OUT SYS_REFCURSOR)
    IS
        v_desde          DATE := TO_DATE (p_fecha_desde, 'YYYYMMDD');
        v_hasta          DATE := TO_DATE (p_fecha_hasta, 'YYYYMMDD');

        -- LINKSER
        v_dom_bs         NUMBER := 0;
        v_dom_usd        NUMBER := 0;
        v_nac_bs         NUMBER := 0;
        v_nac_usd        NUMBER := 0;
        v_int_bs         NUMBER := 0;
        v_int_usd        NUMBER := 0;
        v_producto_fun   NUMBER;

        PROCEDURE ejecutar_sumatoria (p_tipo_local   IN     NUMBER,
                                      p_moneda       IN     NUMBER,
                                      p_total        IN OUT NUMBER)
        IS
            v_tmp   NUMBER := 0;
        BEGIN
            IF p_producto IS NULL
            THEN
                -- Producto 1
                SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
                    p_fecha_desde,
                    p_fecha_hasta,
                    1,
                    p_tipo_local,
                    p_moneda,
                    v_tmp);
                p_total := p_total + v_tmp;

                -- Producto 2
                v_tmp := 0;
                SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
                    p_fecha_desde,
                    p_fecha_hasta,
                    2,
                    p_tipo_local,
                    p_moneda,
                    v_tmp);
                p_total := p_total + v_tmp;
            ELSE
                -- Producto espec¿fico (1 o 2)
                SIAL.PACK_VI_RESUMEN_COMISIONES.proc_resumen_comisiones_adq_base_sum (
                    p_fecha_desde,
                    p_fecha_hasta,
                    p_producto,
                    p_tipo_local,
                    p_moneda,
                    p_total);
            END IF;
        END ejecutar_sumatoria;
    BEGIN
        v_producto_fun := NVL (p_producto, 3);

        -- LINKSER (99)
        ejecutar_sumatoria (1, 68, v_dom_bs);
        ejecutar_sumatoria (1, 840, v_dom_usd);
        ejecutar_sumatoria (2, 68, v_nac_bs);
        ejecutar_sumatoria (2, 840, v_nac_usd);
        ejecutar_sumatoria (4, 68, v_int_bs);
        ejecutar_sumatoria (4, 840, v_int_usd);

        -- CURSOR FINAL
        OPEN p_cursor FOR
            WITH
                /* ===================== CAT¿LOGO BANCOS ===================== */
                bancos
                AS
                    (SELECT ca.adquirente      AS bank_id,
                            ca.descripcion     AS banco_descripcion,
                            ca.emisor_id       AS emisor_id
                       FROM sial.comu_adquirentes ca
                      WHERE     ca.activo = 1
                            AND UPPER (ca.descripcion) <> 'CIDRE IFD'
                     UNION ALL
                     -- emisores "hu¿rfanos"
                     SELECT te.banco           AS bank_id,
                            te.descripcion     AS banco_descripcion,
                            te.banco           AS emisor_id
                       FROM sial.tj_bancos_emisores te
                      WHERE     te.banco NOT IN
                                    (SELECT emisor_id
                                       FROM sial.comu_adquirentes
                                      WHERE emisor_id IS NOT NULL)
                            AND UPPER (te.descripcion) <> 'CIDRE IFD'),
                /* ===================== ADQ ===================== */
                adq
                AS
                    (  SELECT b.bank_id,
                              b.banco_descripcion,
                              liad.sis_tipo_local            AS tipo_local,
                              liad.moneda_destino            AS moneda,
                              SUM (
                                  fn_calcula_temp_pos_neta (
                                      'ADQ',
                                      liad.tc,
                                      liad.sis_tipo_local,
                                      liad.monto_destino,
                                      liad.sis_retencion_comercio,
                                      liad.comision_emi))    AS total_adq
                         FROM sial.vi_liquidaciones_adq liad
                              JOIN bancos b ON b.bank_id = liad.sis_banco_adq
                        WHERE     liad.sis_marca = 1
                              -- AND liad.tipo_tx_liq_adq = 1
                              AND TRUNC (liad.sis_fecha_liquidada) BETWEEN v_desde
                                                                       AND v_hasta
                              AND (   v_producto_fun = 3
                                   OR liad.sis_producto = v_producto_fun)
                     GROUP BY b.bank_id,
                              b.banco_descripcion,
                              liad.sis_tipo_local,
                              liad.moneda_destino),
                /* ===================== EMI ===================== */
                emi
                AS
                    (  SELECT b.bank_id,
                              b.banco_descripcion,
                              liem.sis_tipo_local            AS tipo_local,
                              liem.moneda_destino            AS moneda,
                              SUM (
                                  fn_calcula_temp_pos_neta (
                                      'EMI',
                                      liem.tc,
                                      liem.sis_tipo_local,
                                      liem.monto_destino,
                                      0,
                                      liem.comision_emi))    AS total_emi
                         FROM sial.vi_liquidaciones_emi liem
                              JOIN bancos b ON b.emisor_id = liem.sis_banco_emi
                        WHERE     liem.sis_marca = 1
                              --AND liem.tipo_tx_liq_adq = 1
                              AND TRUNC (liem.sis_fecha_liquidada) BETWEEN v_desde
                                                                       AND v_hasta
                              AND (   v_producto_fun = 3
                                   OR liem.sis_producto = v_producto_fun)
                     GROUP BY b.bank_id,
                              b.banco_descripcion,
                              liem.sis_tipo_local,
                              liem.moneda_destino),
                /* ===================== FEES ===================== */
                fees
                AS
                    (  SELECT b.bank_id,
                              f.sis_tipo_local    AS tipo_local,
                              f.moneda            AS moneda,
                              SUM (
                                  CASE f.sis_producto
                                      WHEN 1 THEN NVL (f.monto, 0)
                                      WHEN 2 THEN -NVL (f.monto, 0)
                                      ELSE 0
                                  END)            AS total_fee
                         FROM sial.vi_fee_aplicados f
                              JOIN bancos b
                                  ON (   b.bank_id = f.banco_id
                                      OR b.emisor_id = f.banco_id)
                        WHERE     f.activo = 1
                              AND TRUNC (f.fecha) BETWEEN v_desde AND v_hasta
                              AND (   v_producto_fun = 3
                                   OR f.sis_producto = v_producto_fun)
                     GROUP BY b.bank_id, f.sis_tipo_local, f.moneda),
                /* ===================== NETOS (con JOINs similares al antiguo) ===================== */
                netos
                AS
                    (-- BANCOS NORMALES
                     SELECT NVL (a.tipo_local, e.tipo_local)
                                AS tipo_local,
                            NVL (a.bank_id, e.bank_id)
                                AS entidad_id,
                            NVL (a.banco_descripcion, e.banco_descripcion)
                                AS descripcion,
                            NVL (a.moneda, e.moneda)
                                AS moneda_uni,
                            NVL (a.total_adq, 0)
                                AS total_adq,
                            NVL (e.total_emi, 0)
                                AS total_emi,
                            NVL (f.total_fee, 0)
                                AS total_fee,
                              NVL (e.total_emi, 0)
                            - NVL (a.total_adq, 0)
                            + NVL (f.total_fee, 0)
                                AS neto
                       FROM adq  a
                            FULL OUTER JOIN emi e
                                ON     a.bank_id = e.bank_id
                                   AND a.tipo_local = e.tipo_local
                                   AND a.moneda = e.moneda
                            LEFT JOIN fees f
                                ON     f.bank_id = NVL (a.bank_id, e.bank_id)
                                   AND f.tipo_local =
                                       NVL (a.tipo_local, e.tipo_local)
                                   AND f.moneda = NVL (a.moneda, e.moneda)
                     UNION ALL
                     -- LINKSER (99) - REGISTRO MANUAL
                     SELECT pn.tipo_local,
                            99                AS entidad_id,
                            'LINKSER'         AS descripcion,
                            pn.moneda         AS moneda_uni,
                            pn.total_adq      AS total_adq,
                            0                 AS total_emi,
                            0                 AS total_fee,
                            -pn.total_adq     AS neto
                       FROM (SELECT 1            AS tipo_local,
                                    68           AS moneda,
                                    v_dom_bs     AS total_adq
                               FROM DUAL
                             UNION ALL
                             SELECT 1, 840, v_dom_usd FROM DUAL
                             UNION ALL
                             SELECT 2, 68, v_nac_bs FROM DUAL
                             UNION ALL
                             SELECT 2, 840, v_nac_usd FROM DUAL
                             UNION ALL
                             SELECT 4, 68, v_int_bs FROM DUAL
                             UNION ALL
                             SELECT 4, 840, v_int_usd FROM DUAL) pn)
              /* ===================== SELECT FINAL (MISMA ESTRUCTURA ANTIGUA) ===================== */
              SELECT entidad_id         AS adquirente,
                     descripcion,
                     tipo_local,
                     CASE tipo_local
                         WHEN 1 THEN 'DOM¿STICA'
                         WHEN 2 THEN 'NACIONAL'
                         WHEN 4 THEN 'INTERNACIONAL'
                         ELSE 'Desconocido'
                     END                AS tipo_liquidacion,
                     moneda_uni         AS moneda,
                     CASE moneda_uni
                         WHEN 68 THEN 'BS.'
                         WHEN 840 THEN 'USD.'
                         ELSE 'OTRA'
                     END                AS moneda_liq,
                     SUM (total_adq)    AS total_adq,
                     SUM (total_emi)    AS total_emi,
                     SUM (total_fee)    AS total_fee,
                     SUM (neto)         AS neto,
                     CASE
                         WHEN SUM (neto) > 0 THEN 'A PAGAR'
                         WHEN SUM (neto) < 0 THEN 'A COBRAR'
                         ELSE NULL
                     END                AS estado
                FROM netos
            GROUP BY entidad_id,
                     descripcion,
                     tipo_local,
                     moneda_uni
            ORDER BY CASE
                         WHEN entidad_id = 99 THEN 999999
                         ELSE entidad_id
                     END,
                     tipo_local,
                     moneda_uni;
    END proc_calcula_posicion_neta_adquirentes_rango_all;
END PACK_VI_POSICION_NETA;