-- ============================================================================
-- Reto 2 - Seccion 2: SQL sobre Sakila
-- Autora: Adriana Troche Robles
-- Motor: SQLite 3 (schema compatible con MySQL Sakila)
-- Archivo base: sakila.db (dump oficial Sakila portado a SQLite)
--
-- Como correr:
--   sqlite3 sakila.db < reto2-sakila.sql
-- o abrir interactivamente:
--   sqlite3 sakila.db
--   > .read reto2-sakila.sql
-- ============================================================================


-- ----------------------------------------------------------------------------
-- Ejercicio 1 (BASICO): Nombre y apellido de actores
-- ----------------------------------------------------------------------------
-- Proyeccion simple sobre la tabla actor.
SELECT
    first_name,
    last_name
FROM actor
ORDER BY last_name, first_name;


-- ----------------------------------------------------------------------------
-- Ejercicio 2 (INTERMEDIO): Titulo y duracion de peliculas con duracion > 100
-- ----------------------------------------------------------------------------
-- Filtro por length (duracion en minutos) mayor a 100.
SELECT
    title,
    length AS duracion_min
FROM film
WHERE length > 100
ORDER BY length DESC;


-- ----------------------------------------------------------------------------
-- Ejercicio 3 (INTERMEDIO): Titulo de pelicula + categoria (JOIN)
-- ----------------------------------------------------------------------------
-- La relacion film <-> category es muchos-a-muchos a traves de film_category.
SELECT
    f.title        AS pelicula,
    c.name         AS categoria
FROM film f
INNER JOIN film_category fc ON f.film_id     = fc.film_id
INNER JOIN category      c  ON fc.category_id = c.category_id
ORDER BY f.title;


-- ----------------------------------------------------------------------------
-- Ejercicio 4 (DIFICIL): Numero de peliculas por categoria (GROUP BY)
-- ----------------------------------------------------------------------------
-- Se agrupa por categoria y se cuenta cuantas peliculas tiene cada una.
SELECT
    c.name                  AS categoria,
    COUNT(fc.film_id)       AS total_peliculas
FROM category c
INNER JOIN film_category fc ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY total_peliculas DESC, c.name;


-- ----------------------------------------------------------------------------
-- Ejercicio 5 (DIFICIL): Por cliente, total de rentas y total pagado
-- ----------------------------------------------------------------------------
-- Cruza customer con rental (para contar rentas) y payment (para sumar lo pagado).
-- COUNT(DISTINCT r.rental_id) evita inflar el conteo cuando un rental tiene
-- mas de un pago registrado.
-- ORDER BY total_pagado DESC para ver primero a los mejores clientes.
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name   AS cliente,
    COUNT(DISTINCT r.rental_id)          AS total_rentas,
    ROUND(SUM(p.amount), 2)              AS total_pagado
FROM customer c
INNER JOIN rental  r ON c.customer_id = r.customer_id
INNER JOIN payment p ON r.rental_id   = p.rental_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_pagado DESC, total_rentas DESC;
