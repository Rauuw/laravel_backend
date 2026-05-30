create or replace PACKAGE BODY      PACK_VI_POSICION_NETA_CREDITO
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
        v_temp   NUMBER := 0;
    BEGIN
        IF p_rol = 'ADQ'
        THEN
            IF p_tc = '07'
            THEN
                v_temp := p_importe + NVL (p_com_adq, 0);
            ELSIF p_tc = '27'
            THEN
                v_temp := -(p_importe + NVL (p_com_adq, 0));
            ELSIF p_tc = '05' AND p_tipo_local = 1
            THEN
                v_temp := p_importe - NVL (p_com_emi, 0) - NVL (p_com_pro, 0);
            ELSIF p_tc = '05' AND p_tipo_local IN (2, 4)
            THEN
                IF p_bisa_flag = 'S'
                THEN
                    v_temp :=
                        p_importe - NVL (p_com_emi, 0) - NVL (p_com_pro, 0);
                ELSE
                    v_temp :=
                          p_importe
                        - NVL (p_com_adq, 0)
                        - NVL (p_com_emi, 0)
                        - NVL (p_com_pro, 0);
                END IF;
            ELSIF p_tc = '06' AND p_tipo_local = 1
            THEN
                v_temp :=
                    -(p_importe - NVL (p_com_emi, 0) - NVL (p_com_pro, 0));
            ELSIF p_tc = '06' AND p_tipo_local IN (2, 4)
            THEN
                IF p_bisa_flag = 'S'
                THEN
                    v_temp :=
                        -(p_importe - NVL (p_com_emi, 0) - NVL (p_com_pro, 0));
                ELSE
                    v_temp :=
                        -(  p_importe
                          - NVL (p_com_adq, 0)
                          - NVL (p_com_emi, 0)
                          - NVL (p_com_pro, 0));
                END IF;
            ELSIF p_tc = '25' AND p_tipo_local = 1
            THEN
                v_temp :=
                    -(p_importe - NVL (p_com_emi, 0) - NVL (p_com_pro, 0));
            ELSIF p_tc = '25' AND p_tipo_local IN (2, 4)
            THEN
                IF p_bisa_flag = 'S'
                THEN
                    v_temp :=
                        -(p_importe - NVL (p_com_emi, 0) - NVL (p_com_pro, 0));
                ELSE
                    v_temp :=
                        -(  p_importe
                          - NVL (p_com_adq, 0)
                          - NVL (p_com_emi, 0)
                          - NVL (p_com_pro, 0));
                END IF;
            END IF;
        ELSIF p_rol = 'EMI'
        THEN
            IF p_tc = '07'
            THEN
                v_temp := p_importe + NVL (p_com_emi, 0);
            ELSIF p_tc = '27'
            THEN
                v_temp := -(p_importe + NVL (p_com_emi, 0));
            ELSIF p_tc = '05'
            THEN
                v_temp := p_importe - NVL (p_com_emi, 0);
            ELSIF p_tc = '06'
            THEN
                v_temp := -(p_importe - NVL (p_com_emi, 0));
            ELSIF p_tc = '25'
            THEN
                v_temp := -(p_importe - NVL (p_com_emi, 0));
            END IF;
        END IF;

        RETURN v_temp;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END fn_calcula_temp;

    PROCEDURE proc_calcula_posicion_neta (p_bank_id   IN     NUMBER,
                                          p_fecha     IN     VARCHAR2,
                                          p_cursor       OUT SYS_REFCURSOR)
    IS
    BEGIN
        OPEN p_cursor FOR
            WITH
                rate
                AS
                    (SELECT tasa
                       FROM SIAL.comu_tasas_cambio
                      WHERE     MONEDA_ORIGEN = 68
                            AND MONEDA_DESTINO = 840
                            AND fecha_vigencia =
                                (SELECT MAX (fecha_vigencia)
                                   FROM SIAL.comu_tasas_cambio
                                  WHERE     MONEDA_ORIGEN = 68
                                        AND MONEDA_DESTINO = 840)),
                adq
                AS
                    (  SELECT liad.SIS_TIPO_LOCAL    AS tipo_local,
                              -- convertir Bs a USD si internacional
                              CASE
                                  WHEN     liad.SIS_TIPO_LOCAL = 4
                                       AND liad.MONEDA = 68
                                  THEN
                                      840
                                  ELSE
                                      liad.MONEDA
                              END                    AS moneda,
                              SUM (
                                  CASE
                                      WHEN     liad.SIS_TIPO_LOCAL = 4
                                           AND liad.MONEDA = 68
                                      THEN
                                            fn_calcula_temp (
                                                'ADQ',
                                                liad.TC,
                                                liad.SIS_TIPO_LOCAL,
                                                CASE
                                                    WHEN coad.adquirente =
                                                         p_bank_id
                                                    THEN
                                                        'S'
                                                    ELSE
                                                        'N'
                                                END,
                                                liad.MONTO_DESTINO,
                                                liad.COMISION_ADQ,
                                                liad.COMISION_EMI,
                                                liad.COMISION_PRO)
                                          / rate.tasa
                                      ELSE
                                          fn_calcula_temp (
                                              'ADQ',
                                              liad.TC,
                                              liad.SIS_TIPO_LOCAL,
                                              CASE
                                                  WHEN coad.adquirente =
                                                       p_bank_id
                                                  THEN
                                                      'S'
                                                  ELSE
                                                      'N'
                                              END,
                                              liad.MONTO_DESTINO,
                                              liad.COMISION_ADQ,
                                              liad.COMISION_EMI,
                                              liad.COMISION_PRO)
                                  END)               AS total_adq
                         FROM SIAL.vi_liquidaciones_adq liad
                              JOIN SIAL.comu_adquirentes coad
                                  ON     coad.adquirente = liad.SIS_BANCO_ADQ
                                     AND coad.adquirente = p_bank_id
                              JOIN rate ON 1 = 1
                        WHERE     TRUNC (liad.SIS_FECHA_LIQUIDADA) =
                                  TO_DATE (p_fecha, 'YYYYMMDD')
                              AND liad.SIS_PRODUCTO = 2
                              AND liad.TIPO_TX_LIQ_ADQ = 1
                     GROUP BY liad.SIS_TIPO_LOCAL,
                              CASE
                                  WHEN     liad.SIS_TIPO_LOCAL = 4
                                       AND liad.MONEDA = 68
                                  THEN
                                      840
                                  ELSE
                                      liad.MONEDA
                              END),
                emi
                AS
                    (  SELECT liem.SIS_TIPO_LOCAL    AS tipo_local,
                              CASE
                                  WHEN     liem.SIS_TIPO_LOCAL = 4
                                       AND liem.MONEDA = 68
                                  THEN
                                      840
                                  ELSE
                                      liem.MONEDA
                              END                    AS moneda,
                              SUM (
                                  CASE
                                      WHEN     liem.SIS_TIPO_LOCAL = 4
                                           AND liem.MONEDA = 68
                                      THEN
                                            fn_calcula_temp (
                                                'EMI',
                                                liem.TC,
                                                liem.SIS_TIPO_LOCAL,
                                                'N',
                                                liem.MONTO,
                                                0,
                                                liem.COMISION_EMI,
                                                0)
                                          / rate.tasa
                                      ELSE
                                          fn_calcula_temp ('EMI',
                                                           liem.TC,
                                                           liem.SIS_TIPO_LOCAL,
                                                           'N',
                                                           liem.MONTO,
                                                           0,
                                                           liem.COMISION_EMI,
                                                           0)
                                  END)               AS total_emi
                         FROM SIAL.vi_liquidaciones_emi liem
                              JOIN SIAL.comu_adquirentes coad
                                  ON     coad.adquirente = p_bank_id
                                     AND liem.SIS_BANCO_EMI = coad.emisor_id
                              JOIN SIAL.tj_bancos_emisores baem
                                  ON baem.banco = coad.emisor_id
                              JOIN rate ON 1 = 1
                        WHERE     TRUNC (liem.SIS_FECHA_LIQUIDADA) =
                                  TO_DATE (p_fecha, 'YYYYMMDD')
                              AND liem.SIS_PRODUCTO = 2
                              AND liem.TIPO_TX_LIQ_ADQ = 1
                     GROUP BY liem.SIS_TIPO_LOCAL,
                              CASE
                                  WHEN     liem.SIS_TIPO_LOCAL = 4
                                       AND liem.MONEDA = 68
                                  THEN
                                      840
                                  ELSE
                                      liem.MONEDA
                              END)
            SELECT NVL (a.tipo_local, e.tipo_local)               AS tipo_local,
                   NVL (a.moneda, e.moneda)                       AS moneda,
                   CASE NVL (a.tipo_local, e.tipo_local)
                       WHEN 1 THEN 'Dom¿stica'
                       WHEN 2 THEN 'Nacional'
                       WHEN 4 THEN 'Internacional'
                       ELSE 'Desconocido'
                   END                                            AS tipo_liquidacion,
                   CASE NVL (a.moneda, e.moneda)
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
              FROM adq  a
                   FULL OUTER JOIN emi e
                       ON a.tipo_local = e.tipo_local AND a.moneda = e.moneda;
    END proc_calcula_posicion_neta;
END PACK_VI_POSICION_NETA_CREDITO;