# Guía de Inicio: Proyecto SteamV2 (JSP + Servlets + Union-Find)

¡Hola equipo! Este repositorio contiene la estructura base (esqueleto) para nuestro proyecto de **Estructura de Datos 2**. Hemos decidido implementar una aplicación web para el sistema de recomendaciones tipo Steam utilizando la estructura de datos **Union-Find**.

Esta guía explica qué archivos se han creado, los conceptos teóricos básicos de la tecnología web empleada (JSP y Servlets), y cómo correr el proyecto localmente sin necesidad de instalar configuraciones complejas.

---

## 📚 Conceptos Básicos Web (¿Qué es JSP y Servlets?)

Para este proyecto web estamos utilizando una arquitectura **MVC (Modelo-Vista-Controlador)** clásica de Java:

```
[Cliente (Navegador)] ──(Petición HTTP)──> [ Servlet (Controlador) ]
                                                   │ (Lógica Java & Union-Find)
                                                   ▼
[Cliente (Navegador)] <──(HTML Renderizado)─ [ JSP (Vista) ]
```

### 1. ¿Qué es un Servlet? (El Controlador / Backend)
Un **Servlet** es una clase Java que se ejecuta en el servidor y se encarga de recibir, procesar y responder a las peticiones del navegador web (HTTP Requests). 
* **Para qué sirve:** Es el "cerebro" del backend. Aquí recuperamos los datos del usuario, leemos archivos (como el JSON), instanciamos nuestra estructura de datos **Union-Find** y ejecutamos la lógica de negocio (agrupación y cálculo de recomendaciones).
* **Ubicación en el proyecto:** `src/main/java/com/steamv2/controller/RecommendationServlet.java`.
* **Cómo funciona:** Usa la anotación `@WebServlet("/recommendations")` para que, cuando entres a esa ruta en el navegador, se ejecute su método `doGet()` o `doPost()`.

### 2. ¿Qué es JSP (JavaServer Pages)? (La Vista / Frontend)
Un archivo **JSP** (`.jsp`) es esencialmente una página HTML que nos permite incrustar código Java dinámico.
* **Para qué sirve:** Sirve para renderizar la interfaz gráfica del usuario (botones, tablas, tarjetas de videojuegos). En lugar de tener HTML estático, podemos usar etiquetas especiales o expresiones de Java para pintar la lista de recomendaciones generada por el Servlet.
* **Ubicación en el proyecto:** `src/main/webapp/index.jsp`.
* **Cómo se conecta con el Servlet:** 
  1. El Servlet procesa la lógica en Java y guarda los resultados en el "objeto de petición" usando `request.setAttribute("nombreVariable", objetoJava)`.
  2. Luego, el Servlet hace un *forward* (reenvío) a `index.jsp`.
  3. El JSP lee esa variable usando expresiones de Java y genera dinámicamente el HTML que el usuario verá en pantalla.

---

## 🛠️ Estructura del Proyecto

El proyecto está organizado bajo el estándar de **Maven**:

* **`pom.xml`**: Archivo de configuración de dependencias de Maven. Aquí se definen las librerías necesarias (como `jakarta.servlet` y la librería `gson` para leer JSON) y el plugin de **Jetty** para levantar el servidor localmente.
* **`mvnw` y `mvnw.cmd` (Maven Wrapper)**: Son scripts especiales. **No necesitas tener Maven instalado en tu computadora**. Cuando ejecutas estos scripts, el sistema descarga automáticamente la versión correcta de Maven y ejecuta el proyecto.
* **`src/main/java`**: Contiene nuestro código fuente Java.
  * **`com.steamv2.model.UnionFind`**: Contiene la definición genérica de nuestra estructura de datos.
  * **`com.steamv2.controller.RecommendationServlet`**: Controlador que gestiona la comunicación entre el algoritmo en Java y la página web.
* **`src/main/webapp`**: Contiene los archivos web.
  * **`index.jsp`**: La página de inicio y el panel de control estilizado como la tienda oscura de Steam.
  * **`css/styles.css`**: Hoja de estilos con variables de color premium, diseño responsive y micro-animaciones.
  * **`WEB-INF/web.xml`**: Descriptor de despliegue web básico.

---

## 🚀 Cómo Ejecutar el Proyecto Localmente

Para compilar y correr el proyecto en tu máquina local, sigue estos pasos:

### 1. Requisitos Previos
* Tener instalado **Java JDK 21** o superior.
* *Nota para Windows:* El script `mvnw.cmd` ha sido mejorado para **detectar automáticamente** tu instalación de JDK en `C:\Program Files\Java\jdk-*` si no tienes la variable de entorno `JAVA_HOME` configurada. ¡Por lo tanto, no necesitas hacer configuraciones manuales en el sistema!

### 2. Levantar el Servidor Web
Abre una terminal (PowerShell, CMD o la terminal de tu IDE) en la carpeta raíz del proyecto y escribe el siguiente comando:

**En Windows (PowerShell / CMD):**
```powershell
.\mvnw jetty:run
```

**En macOS o Linux:**
```bash
./mvnw jetty:run
```

*Nota: La primera vez que lo ejecutes, Maven descargará automáticamente el servidor Jetty y las dependencias necesarias. Esto puede tomar unos minutos según tu conexión a internet.*

### 3. Acceder a la Aplicación
Una vez que veas en la consola el mensaje indicando que el servidor ha iniciado (por ejemplo: `Started ServerConnector@... {0.0.0.0:8080}`), abre tu navegador e ingresa a:
```
http://localhost:8080/
```
Verás la interfaz oscura simulada de Steam. Al hacer clic en **"Cargar Simulación"**, la petición irá al Servlet de Java, procesará la prueba y te mostrará los datos dinámicos.

---

## ✍️ Tareas Pendientes para el Equipo

Para completar el proyecto, debemos trabajar en los siguientes puntos:

1. **Implementar Union-Find (`UnionFind.java`)**:
   Completar el algoritmo en los métodos `makeSet`, `find` (usando compresión de caminos), `union` (usando unión por rango) y `connected`.
   
2. **Base de Datos Simulada (`users.json` / `games.json`)**:
   Crear archivos JSON para simular nuestra base de datos.
   * `games.json`: Con campos como `id`, `name`, `genres`.
   * `users.json`: Con `username`, `password`, `likedGames` (lista de IDs de juegos).
   
3. **Servicio y Carga de Datos**:
   Desarrollar la lógica en Java para leer los JSONs usando la librería `gson` (incluida en el `pom.xml`) y agrupar usuarios en el `UnionFind` en base a coincidencias en sus juegos adquiridos.
   
4. **Actualizar el Servlet e Interfaz**:
   Modificar el `RecommendationServlet` para procesar el inicio de sesión real (buscando las credenciales en el JSON) y generar sugerencias auténticas utilizando los clusters creados por el `UnionFind`.
