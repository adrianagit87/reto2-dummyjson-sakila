# Reto 2 - Postman (DummyJSON) + SQL (Sakila)

**Autora:** Adriana Troche Robles
**Máster Profesional en QA y Automatización de Pruebas**
**Fecha:** 23 de abril de 2026

---

## Estructura del entregable

```
reto2-dummyjson-sakila/
├── README.md                                       <- este archivo
├── postman/
│   ├── reto2-dummyjson.postman_collection.json     <- coleccion (5 requests)
│   └── reto2-dummyjson.postman_environment.json    <- environment
└── sql/
    ├── reto2-sakila.sql                            <- 5 queries comentadas
    └── sakila.db                                   <- base SQLite portada desde Sakila oficial
```

---

## Sección 1 - Postman (DummyJSON)

### Como ejecutar

1. Abrir Postman.
2. Importar `postman/reto2-dummyjson.postman_collection.json`.
3. Importar `postman/reto2-dummyjson.postman_environment.json` y seleccionarlo como environment activo.
4. Correr con **Collection Runner** en orden natural (Ej 1 -> Ej 5).

### Nota importante sobre las credenciales

El enunciado indica usar `kminchelle / 0lelplR`. **Esas credenciales ya no son válidas** en la API actual de DummyJSON (devuelven `400 Invalid credentials`). Se verificó contra el servicio en vivo:

```bash
# Credenciales del enunciado -> 400
curl -s -X POST 'https://dummyjson.com/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{"username":"kminchelle","password":"0lelplR"}'
# -> {"message":"Invalid credentials"}

# Credenciales vigentes -> 200
curl -s -X POST 'https://dummyjson.com/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{"username":"emilys","password":"emilyspass"}'
# -> {"accessToken":"eyJ...","username":"emilys", ...}
```

Se usaron las credenciales vigentes (`emilys / emilyspass`, documentadas en la pagina oficial de DummyJSON). La lógica evaluada (tests, condicionales, retry) es idéntica.

### Mapa de ejercicios a requests

| Ej | Request en la coleccion               | Endpoint          | Lo que valida                                                                                     |
|----|---------------------------------------|-------------------|---------------------------------------------------------------------------------------------------|
| 1  | Ej 1 - Login (básico)                 | POST /auth/login  | Status 200, parseo JSON, existe `accessToken`, `username` correcto.                               |
| 2  | Ej 2 - Auth Me (validación de sesión) | GET /auth/me      | Bearer token, status 200, existe `email`, `username` coincide, condicional `session_valid`.      |
| 3  | Ej 3 - Login (manejo de token)        | POST /auth/login  | Guarda `accessToken` en variable `token` y valida que no sea null/undefined/vacio.                |
| 4  | Ej 4 - Products (lista con logica)    | GET /products     | Itera productos: `price > 0`, `stock >= 0`, si `price > 100` debe existir `discountPercentage`. Cuenta `expensive_count` (price > 50). |
| 5  | Ej 5 - Auth Me (retry)                | GET /auth/me      | Flujo automatico: si 401 -> `expired_token=true` + `setNextRequest('Ej 1 - Login')`. Si 200 -> flujo normal. |

### Variables del environment

| Variable          | Propósito                                                |
|-------------------|----------------------------------------------------------|
| `base_url`        | `https://dummyjson.com`                                  |
| `username`        | Usuario del login (reutilizado en asserts)               |
| `password`        | Contrasenia del login                                    |
| `token`           | `accessToken` devuelto por el login                      |
| `session_valid`   | `true`/`false` segun resultado de `/auth/me`             |
| `expired_token`   | Bandera de retry (`true` cuando /auth/me respondio 401)  |
| `expensive_count` | Cantidad de productos con `price > 50`                   |

### Como probar el retry (Ej 5) manualmente

1. Correr la colección completa una vez -> todo verde, token válido.
2. En el environment, editar `token` y poner un valor inválido (ej `invalid`).
3. Correr solo el **Ej 5** -> recibira 401 -> el script marca `expired_token = true` y hace `setNextRequest('Ej 1 - Login (básico)')`.
4. Ej 1 detecta que `expired_token === 'true'`, refresca el token y ejecuta `setNextRequest(null)` para detener el runner y evitar bucles.
5. Volver a correr el Ej 5 -> ahora devuelve 200 y el flujo continua normal.

---

## Seccion 2 - SQL (Sakila)

### Base utilizada

Sakila en **SQLite** (port oficial del dump original de MySQL). La eleccion de SQLite se debe a que:

- Es el motor que ya viene preinstalado en macOS (`sqlite3`), no requiere servicio separado.
- El schema relevante (`actor`, `film`, `category`, `film_category`, `customer`, `rental`, `payment`) es idêntico al de Sakila oficial.
- Las queries del reto usan solo SQL estandar (`SELECT`, `JOIN`, `GROUP BY`, `COUNT`, `SUM`, `ORDER BY`), compatibles con ambos motores.

### Como ejecutar

**Opción A - DBeaver (cliente grafico, recomendada)**

1. `Database -> New Database Connection` -> elegir **SQLite** -> `Next`.
2. En **Path**, seleccionar `sql/sakila.db` (si DBeaver pide descargar los drivers, aceptar).
3. `Test Connection -> Finish`. La conexion queda lista en el Database Navigator.
4. Abrir el archivo `sql/reto2-sakila.sql` en un SQL Editor de DBeaver con la conexion activa.
5. Ejecutar:
   - `Cmd + Enter` -> corre la query donde esta el cursor (util para ver cada ejercicio por separado).
   - `Cmd + Alt + Enter` -> corre el script completo (abre una pestania de resultados por cada `SELECT`).
6. Para exportar resultados: click derecho sobre la grilla -> `Export data...` (CSV, Excel, HTML, Markdown).

**Opción B - Terminal (sin instalar nada, `sqlite3` ya viene con macOS)**

```bash
cd sql/
# Ejecutar todas las queries de una vez:
sqlite3 sakila.db < reto2-sakila.sql

# O entrar en modo interactivo:
sqlite3 sakila.db
sqlite> .headers on
sqlite> .mode column
sqlite> .read reto2-sakila.sql
```

### Resumen de las 5 queries

| Ej | Objetivo                                                         | Tecnica                               |
|----|------------------------------------------------------------------|---------------------------------------|
| 1  | Nombre y apellido de actores                                     | `SELECT` simple                       |
| 2  | Titulo y duracion de peliculas con duracion > 100                | `SELECT` + `WHERE`                    |
| 3  | Titulo de pelicula + categoria                                   | `JOIN` via `film_category`            |
| 4  | Numero de peliculas por categoria                                | `JOIN` + `GROUP BY` + `COUNT`         |
| 5  | Por cliente: total de rentas y total pagado                      | `JOIN x3` + `GROUP BY` + `ORDER DESC` |

### Muestra de resultados (primeros registros)

```
Ej 1 - Actores (200 en total):
  PENELOPE GUINESS, NICK WAHLBERG, ED CHASE, ...

Ej 2 - Peliculas > 100 min (610 en total):
  AFFAIR PREJUDICE (117), AFRICAN EGG (130), AGENT TRUMAN (169), ...

Ej 4 - Top categorias:
  Sports (74), Foreign (73), Family (69), Documentary (68), Animation (66)

Ej 5 - Top clientes por total pagado:
  KARL SEAL        -> 45 rentas - $221.55
  ELEANOR HUNT     -> 46 rentas - $216.54
  CLARA SHAW       -> 42 rentas - $195.58
```

---

## Decisiones de diseno

- **Cobertura 1:1 con el enunciado**: cada ejercicio se implementa como un request/query independiente para facilitar la evaluacion.
- **Variables dinamicas**: nada hardcodeado reutilizable. `base_url`, credenciales, `token` y contadores estan en el environment.
- **Condicionales**: Ej 2 (`if status === 200`), Ej 4 (`if price > 100`), Ej 5 (`if status === 401 / 200`).
- **Retry sin bucles**: el Ej 5 setea `expired_token = true` antes de saltar al Login; el Login lee la bandera y llama `setNextRequest(null)` al terminar el refresh para detener el runner.
- **SQLite**: evita requerir servicios externos. Las queries son SQL estandar, portables a MySQL Sakila sin cambios.
