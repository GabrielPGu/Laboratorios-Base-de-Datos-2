-- Poma Gutierrez Gabriel 23200110

--EJERCICIO 1
SET SERVEROUTPUT ON;

DECLARE
  v_rows90 PLS_INTEGER := 0;
  v_rows60 PLS_INTEGER := 0;
BEGIN
  UPDATE employees
     SET salary = ROUND(salary * 1.10, 2)
   WHERE department_id = 90;
  v_rows90 := SQL%ROWCOUNT;

  SAVEPOINT punto1;

  UPDATE employees
     SET salary = ROUND(salary * 1.05, 2)
   WHERE department_id = 60;
  v_rows60 := SQL%ROWCOUNT;

  ROLLBACK TO SAVEPOINT punto1;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Aumentos persistidos dpto 90: '||v_rows90);
  DBMS_OUTPUT.PUT_LINE('Aumentos revertidos dpto 60 (rollback parcial): '||v_rows60);
END;
/

/*
a) ¿Qué departamento mantuvo los cambios?
El departamento 90 mantiene el +10% 

b) ¿Qué efecto tuvo el ROLLBACK parcial?
El ROLLBACK TO SAVEPOINT punto1 deshizo únicamente lo ejecutado después del savepoint, dejando intacto lo anterior.

c) ¿Qué ocurriría si se ejecutara ROLLBACK sin especificar SAVEPOINT?
Un ROLLBACK total revierte toda la transacción hasta el último COMMIT/inicio de transacción: se perderían tanto el +5% del dpto 60 como el +10% del dpto 90.
*/


--EJERCICIO 2

SELECT sid, serial#, username, status, blocking_session, event
FROM   v$session
WHERE  username IS NOT NULL
AND    (blocking_session IS NOT NULL OR event LIKE 'enq: TX%')
ORDER BY sid;

SELECT lo.session_id     AS sid,
       s.serial#,
       s.username,
       ao.owner||'.'||ao.object_name AS objeto,
       lo.locked_mode
FROM   v$locked_object lo
JOIN   all_objects ao ON ao.object_id = lo.object_id
JOIN   v$session s    ON s.sid = lo.session_id
ORDER BY lo.session_id;

SELECT * FROM dba_blockers;

SELECT * FROM dba_waiters;

SELECT inst_id, sid, type, id1, id2, lmode, request, block
FROM   gv$lock
WHERE  type IN ('TX','TM')
ORDER  BY block DESC, sid;


/*
a) ¿Por qué la segunda sesión quedó bloqueada?
Porque la primera sesión actualizó una fila y no hizo COMMIT, reteniendo un bloqueo exclusivo de fila (enq: TX – row lock) sobre employees.employee_id = 103. Cuando la segunda sesión intenta actualizar la misma fila, necesita ese mismo bloqueo exclusivo y queda en espera hasta que la primera confirme o revierta la transacción.

b) ¿Qué comando libera los bloqueos?
COMMIT; o ROLLBACK; en la sesión que bloquea (la primera). Cualquiera de los dos finaliza la transacción y libera el bloqueo. (Matar la sesión también los libera indirectamente cuando PMON hace rollback, pero lo correcto es COMMIT/ROLLBACK).

c) ¿Qué vistas permiten verificar sesiones bloqueadas?
V$SESSION (columnas BLOCKING_SESSION, FINAL_BLOCKING_SESSION, EVENT).
V$LOCK 
V$LOCKED_OBJECT
DBA_BLOCKERS y DBA_WAITERS 
*/


--EJERCICIO 3

DECLARE
  v_emp_id        CONSTANT employees.employee_id%TYPE := 104;
  v_new_dept_id   CONSTANT departments.department_id%TYPE := 110;

  v_old_dept_id   employees.department_id%TYPE;
  v_job_id        employees.job_id%TYPE;
  v_start_date    employees.hire_date%TYPE;

  e_dept_not_found EXCEPTION;
  PRAGMA EXCEPTION_RESTRICT_xcptns(e_dept_not_found);

  v_dummy NUMBER;
BEGIN
  SELECT 1 INTO v_dummy
  FROM departments
  WHERE department_id = v_new_dept_id;

  SELECT department_id, job_id, hire_date
  INTO   v_old_dept_id, v_job_id, v_start_date
  FROM   employees
  WHERE  employee_id = v_emp_id
  FOR UPDATE;

  INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
  VALUES (v_emp_id, v_start_date, SYSDATE, v_job_id, v_old_dept_id);

  UPDATE employees
  SET    department_id = v_new_dept_id
  WHERE  employee_id = v_emp_id;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Transferencia exitosa: empleado '||v_emp_id||
                        ' de '||v_old_dept_id||' a '||v_new_dept_id||
                        ' y JOB_HISTORY registrado.');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error: departamento '||v_new_dept_id||
                         ' o empleado '||v_emp_id||' no existe(n).');
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error en la transacción: '||SQLERRM);
END;
/


/*
a) Atomicidad: porque ambas acciones forman una sola operación; si una falla, se deshacen las dos.
b) Error antes del COMMIT: se ejecuta ROLLBACK, anulando todos los cambios.
c) Integridad: se garantiza con la clave foránea entre ambas tablas, la transacción única y el uso de FOR UPDATE para evitar conflictos.
*/


--EJERCICIO 4

SET SERVEROUTPUT ON;

DECLARE
  v_upd_100  PLS_INTEGER := 0;
  v_upd_80   PLS_INTEGER := 0;
  v_del_50   PLS_INTEGER := 0;
BEGIN
  UPDATE employees
     SET salary = ROUND(salary * 1.08, 2)
   WHERE department_id = 100;
  v_upd_100 := SQL%ROWCOUNT;
  SAVEPOINT A;

  UPDATE employees
     SET salary = ROUND(salary * 1.05, 2)
   WHERE department_id = 80;
  v_upd_80 := SQL%ROWCOUNT;
  SAVEPOINT B;

  DELETE FROM employees
   WHERE department_id = 50;
  v_del_50 := SQL%ROWCOUNT;

  ROLLBACK TO SAVEPOINT B;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('+8% dpto 100 (persistente): '||v_upd_100||' filas');
  DBMS_OUTPUT.PUT_LINE('+5% dpto 80  (persistente): '||v_upd_80||' filas');
  DBMS_OUTPUT.PUT_LINE('DELETE dpto 50 (revertido): '||v_del_50||' filas');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT B; 
    COMMIT;      
    DBMS_OUTPUT.PUT_LINE('Aviso: ocurrió un error y se revirtió hasta B. '||SQLERRM);
END;
/


/*
a) Persisten los aumentos: +8% en dpto 100 y +5% en dpto 80 (se ejecutaron antes del ROLLBACK TO B y luego se confirmaron).
b) Las filas eliminadas del dpto 50 se recuperan: el ROLLBACK TO B deshace esa eliminación.
c) Se puede verificar a traves:

SELECT department_id, COUNT(*) empleados, SUM(salary) suma_salarios
FROM employees
WHERE department_id IN (80,100,50)
GROUP BY department_id
ORDER BY department_id;

SELECT COUNT(*) FROM employees WHERE department_id = 50;

*/






