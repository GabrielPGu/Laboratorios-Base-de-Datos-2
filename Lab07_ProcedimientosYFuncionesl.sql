--DESAROLLO DE LABORATORIO DE PROCEDIMIENTOS Y FUNCIONES
--POMA GUTIERREZ GABRIEL 23200110
SET SERVEROUTPUT ON

--4.1.1
CREATE OR REPLACE PROCEDURE listar_partes_no_paris(p_peso_minimo IN NUMBER DEFAULT 10) IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.1 COLOR | CIUDAD (peso > '||p_peso_minimo||', ciudad <> Paris)');
  FOR fila IN (
    SELECT DISTINCT color, city AS ciudad
    FROM P
    WHERE UPPER(city) <> 'PARIS'
      AND weight > p_peso_minimo
    ORDER BY color, ciudad
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.color||' | '||fila.ciudad);
  END LOOP;
END;
/

--4.1.2
CREATE OR REPLACE FUNCTION libras_a_gramos(p_libras IN NUMBER) RETURN NUMBER IS
BEGIN
  RETURN ROUND(p_libras * 453.59237, 2);
END;
/

CREATE OR REPLACE PROCEDURE listar_pesos_en_gramos IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.2 PARTE | PESO(lb) -> PESO(g)');
  FOR fila IN (
    SELECT p# AS parte, weight AS peso_lb, libras_a_gramos(weight) AS peso_g
    FROM P
    ORDER BY parte
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.parte||' | '||fila.peso_lb||' -> '||fila.peso_g);
  END LOOP;
END;
/

--4.1.3
CREATE OR REPLACE PROCEDURE listar_proveedores IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.3 PROV | NOMBRE | ESTADO | CIUDAD');
  FOR fila IN (
    SELECT s# AS proveedor, sname AS nombre, status AS estado, city AS ciudad
    FROM S
    ORDER BY proveedor
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.proveedor||' | '||fila.nombre||' | '||fila.estado||' | '||fila.ciudad);
  END LOOP;
END;
/

--4.1.4
CREATE OR REPLACE PROCEDURE listar_proveedor_parte_misma_ciudad IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.4 (PROV, PARTE) co-localizados (misma ciudad)');
  FOR fila IN (
    SELECT s.s# AS proveedor, p.p# AS parte
    FROM S s
    JOIN P p ON UPPER(s.city) = UPPER(p.city)
    ORDER BY proveedor, parte
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.proveedor||' , '||fila.parte);
  END LOOP;
END;
/


--4.1.5
CREATE OR REPLACE PROCEDURE listar_pares_ciudades_abastecimiento IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.5 (ciudadProveedor, ciudadParte) con abastecimiento');
  FOR fila IN (
    SELECT DISTINCT s.city AS ciudad_proveedor, p.city AS ciudad_parte
    FROM SP sp
    JOIN S  s ON s.s# = sp.s#
    JOIN P  p ON p.p# = sp.p#
    ORDER BY ciudad_proveedor, ciudad_parte
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- ('||fila.ciudad_proveedor||', '||fila.ciudad_parte||')');
  END LOOP;
END;
/

--4.1.6
CREATE OR REPLACE PROCEDURE listar_pares_proveedores_misma_ciudad IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.6 (PROV1, PROV2) co-localizados (misma ciudad, sin duplicar)');
  FOR fila IN (
    SELECT s1.s# AS prov1, s2.s# AS prov2, s1.city AS ciudad
    FROM S s1
    JOIN S s2 ON UPPER(s1.city) = UPPER(s2.city)
             AND s1.s# < s2.s#
    ORDER BY ciudad, prov1, prov2
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.prov1||' , '||fila.prov2||' | '||fila.ciudad);
  END LOOP;
END;
/

--4.1.7
CREATE OR REPLACE FUNCTION contar_proveedores RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM S;
  RETURN v_total;
END;
/

CREATE OR REPLACE PROCEDURE mostrar_total_proveedores IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.7 Total de proveedores: '||contar_proveedores);
END;
/

--4.1.8
CREATE OR REPLACE PROCEDURE mostrar_min_max_por_parte(p_parte IN P.p#%TYPE DEFAULT 'P2') IS
  v_cantidad_minima NUMBER;
  v_cantidad_maxima NUMBER;
BEGIN
  SELECT MIN(qty), MAX(qty)
  INTO   v_cantidad_minima, v_cantidad_maxima
  FROM   SP
  WHERE  p# = p_parte;

  IF v_cantidad_minima IS NULL AND v_cantidad_maxima IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('4.1.8 '||p_parte||': sin envíos.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('4.1.8 '||p_parte||' -> MIN='||v_cantidad_minima||', MAX='||v_cantidad_maxima);
  END IF;
END;
/

--4.1.9
CREATE OR REPLACE PROCEDURE listar_totales_por_parte IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.9 PARTE | SUM(QTY)');
  FOR fila IN (
    SELECT p# AS parte, SUM(qty) AS total_cantidad
    FROM SP
    GROUP BY p#
    ORDER BY parte
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.parte||' | '||fila.total_cantidad);
  END LOOP;
END;
/

--4.1.10
CREATE OR REPLACE PROCEDURE listar_partes_con_varios_proveedores IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.10 Partes con más de un proveedor');
  FOR fila IN (
    SELECT p# AS parte
    FROM SP
    GROUP BY p#
    HAVING COUNT(DISTINCT s#) > 1
    ORDER BY parte
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.parte);
  END LOOP;
END;
/

--4.1.11
CREATE OR REPLACE PROCEDURE listar_proveedores_de_p2 IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.11 Proveedores que abastecen P2');
  FOR fila IN (
    SELECT DISTINCT s.sname AS nombre_proveedor
    FROM SP sp
    JOIN S  s ON s.s# = sp.s#
    WHERE sp.p# = 'P2'
    ORDER BY nombre_proveedor
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.nombre_proveedor);
  END LOOP;
END;
/

--4.1.12
CREATE OR REPLACE PROCEDURE listar_proveedores_con_algun_abastecimiento IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.12 Proveedores con al menos una parte abastecida');
  FOR fila IN (
    SELECT DISTINCT s.sname AS nombre_proveedor
    FROM S s
    WHERE EXISTS (SELECT 1 FROM SP sp WHERE sp.s# = s.s#)
    ORDER BY nombre_proveedor
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.nombre_proveedor);
  END LOOP;
END;
/

--4.1.13
CREATE OR REPLACE PROCEDURE listar_proveedores_estado_menor_al_maximo IS
  v_estado_maximo S.status%TYPE;
BEGIN
  SELECT MAX(status) INTO v_estado_maximo FROM S;
  DBMS_OUTPUT.PUT_LINE('4.1.13 Proveedores con estado < '||v_estado_maximo);
  FOR fila IN (
    SELECT s# AS proveedor
    FROM S
    WHERE status < v_estado_maximo
    ORDER BY proveedor
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.proveedor);
  END LOOP;
END;
/

--4.1.14
CREATE OR REPLACE PROCEDURE listar_proveedores_de_p2_usando_exists IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.14 Proveedores que abastecen P2 (EXISTS)');
  FOR fila IN (
    SELECT s.sname AS nombre_proveedor
    FROM S s
    WHERE EXISTS (
      SELECT 1
      FROM SP sp
      WHERE sp.s# = s.s#
        AND sp.p# = 'P2'
    )
    ORDER BY nombre_proveedor
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.nombre_proveedor);
  END LOOP;
END;
/

--4.1.15
CREATE OR REPLACE PROCEDURE listar_proveedores_que_no_abastecen_p2 IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.15 Proveedores que NO abastecen P2');
  FOR fila IN (
    SELECT s.sname AS nombre_proveedor
    FROM S s
    WHERE NOT EXISTS (
      SELECT 1
      FROM SP sp
      WHERE sp.s# = s.s#
        AND sp.p# = 'P2'
    )
    ORDER BY nombre_proveedor
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.nombre_proveedor);
  END LOOP;
END;
/

--4.1.16
CREATE OR REPLACE PROCEDURE listar_proveedores_que_abastecen_todas_las_partes IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.16 Proveedores que abastecen TODAS las partes');
  FOR fila IN (
    SELECT s.sname AS nombre_proveedor
    FROM S s
    WHERE NOT EXISTS (        -- No existe parte p
      SELECT 1
      FROM P p
      WHERE NOT EXISTS (      -- ...para la cual NO exista envío de s
        SELECT 1
        FROM SP sp
        WHERE sp.s# = s.s#
          AND sp.p# = p.p#
      )
    )
    ORDER BY nombre_proveedor
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.nombre_proveedor);
  END LOOP;
END;
/

--4.1.17
CREATE OR REPLACE PROCEDURE listar_partes_pesadas_o_de_s2 IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('4.1.17 Partes con peso > 16 lb O abastecidas por S2');
  FOR fila IN (
    SELECT DISTINCT p.p# AS parte
    FROM P p
    WHERE p.weight > 16
       OR EXISTS (SELECT 1 FROM SP sp WHERE sp.p# = p.p# AND sp.s# = 'S2')
    ORDER BY parte
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('- '||fila.parte);
  END LOOP;
END;
/


--EJECUCION DE TODOS LOS PROCEDIMIENTOS Y FUNCIONES

BEGIN
  listar_partes_no_paris;                          
  listar_pesos_en_gramos;                          
  listar_proveedores;                              
  listar_proveedor_parte_misma_ciudad;             
  listar_pares_ciudades_abastecimiento;            
  listar_pares_proveedores_misma_ciudad;           
  mostrar_total_proveedores;                       
  mostrar_min_max_por_parte;                       
  listar_totales_por_parte;                        
  listar_partes_con_varios_proveedores;            
  listar_proveedores_de_p2;                        
  listar_proveedores_con_algun_abastecimiento;     
  listar_proveedores_estado_menor_al_maximo;       
  listar_proveedores_de_p2_usando_exists;          
  listar_proveedores_que_no_abastecen_p2;          
  listar_proveedores_que_abastecen_todas_las_partes;
  listar_partes_pesadas_o_de_s2;                   
END;
/






















