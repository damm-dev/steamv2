<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SteamV2 - Sugerencias con Union-Find</title>
    <!-- Fuente premium Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
    <!-- Estilos del proyecto -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
</head>
<body>

    <!-- Encabezado de SteamV2 -->
    <header class="steam-header">
        <div class="container header-content">
            <div class="logo">
                <span class="highlight-cyan">STEAM</span><span class="highlight-blue">V2</span>
            </div>
            <nav class="nav-links">
                <a href="#" class="active">Tienda</a>
                <a href="#">Comunidad</a>
                <a href="#">Sobre Nosotros</a>
                <a href="#">Soporte</a>
            </nav>
        </div>
    </header>

    <%
        // Obtener los datos enviados desde el servlet RecommendationServlet
        String username = (String) request.getAttribute("username");
        List<String> library = (List<String>) request.getAttribute("library");
        List<String> recommendations = (List<String>) request.getAttribute("recommendations");
        String javaStatus = (String) request.getAttribute("javaStatus");
    %>

    <main class="container main-content">
        <% if (username == null) { %>
            <!-- PANTALLA INICIAL (Simulación de Login) -->
            <div class="welcome-card card">
                <div class="welcome-header">
                    <h2>Bienvenido a <span class="highlight-cyan">Steam</span><span class="highlight-blue">V2</span></h2>
                    <p class="subtitle">Simulador de Recomendaciones de Videojuegos usando la Estructura de Datos <strong>Union-Find</strong></p>
                </div>
                
                <div class="login-form-container">
                    <p>Para inicializar el flujo y cargar la base de datos simulada en Java, haz clic en el botón inferior. Esto invocará al <code>RecommendationServlet</code>, que instanciará tu clase <code>UnionFind</code>.</p>
                    
                    <form action="${pageContext.request.contextPath}/recommendations" method="GET">
                        <button type="submit" class="btn btn-primary btn-glow">
                            Cargar Simulación (Servlet / Java)
                        </button>
                    </form>
                </div>
            </div>
        <% } else { %>
            <!-- PANEL PRINCIPAL (Simulación Cargada) -->
            <div class="status-banner">
                <span class="status-dot"></span>
                <strong>Estado de Java:</strong> <%= javaStatus %>
            </div>

            <div class="profile-summary card">
                <div class="profile-info">
                    <div class="avatar-placeholder">P1</div>
                    <div>
                        <h3>Usuario Actual: <span class="highlight-cyan"><%= username %></span></h3>
                        <p class="subtitle">Perfil simulado activo - Conectado mediante sesión</p>
                    </div>
                </div>
                <a href="${pageContext.request.contextPath}/" class="btn btn-secondary">Salir / Reiniciar</a>
            </div>

            <!-- Contenedor de dos columnas -->
            <div class="dashboard-grid">
                <!-- Columna 1: Biblioteca del Usuario -->
                <div class="column card">
                    <div class="column-header">
                        <svg class="icon" fill="currentColor" viewBox="0 0 24 24"><path d="M4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm16-4H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H8V4h12v12z"/></svg>
                        <h3>Tus Videojuegos (<%= library != null ? library.size() : 0 %>)</h3>
                    </div>
                    <p class="section-desc">Juegos que ya posees y definen tus gustos iniciales.</p>
                    <ul class="game-list">
                        <% if (library != null) { 
                            for (String game : library) { %>
                                <li class="game-item owned">
                                    <div class="game-indicator"></div>
                                    <span class="game-title"><%= game %></span>
                                    <span class="badge badge-owned">Adquirido</span>
                                </li>
                        <%  } 
                           } %>
                    </ul>
                </div>

                <!-- Columna 2: Recomendaciones (Union-Find) -->
                <div class="column card">
                    <div class="column-header">
                        <svg class="icon" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 17h-2v-2h2v2zm2.07-7.75l-.9.92C13.45 12.9 13 13.5 13 15h-2v-.5c0-1.1.45-2.1 1.17-2.83l1.24-1.26c.37-.36.59-.86.59-1.41 0-1.1-.9-2-2-2s-2 .9-2 2H7c0-2.76 2.24-5 5-5s5 2.24 5 5c0 1.04-.42 1.99-1.07 2.75z"/></svg>
                        <h3>Sugerencias para Ti</h3>
                    </div>
                    <p class="section-desc">Recomendados basados en usuarios de tu mismo conjunto disjunto (Union-Find).</p>
                    <ul class="game-list">
                        <% if (recommendations != null) { 
                            for (String game : recommendations) { %>
                                <li class="game-item recommended">
                                    <div class="game-indicator recommended-ind"></div>
                                    <span class="game-title"><%= game %></span>
                                    <span class="badge badge-rec">Sugerido</span>
                                </li>
                        <%  } 
                           } %>
                    </ul>
                </div>
            </div>
            
            <div class="info-alert card">
                <h4>💡 Lógica a Implementar en el Proyecto:</h4>
                <p>En el backend de Java deberás asociar los usuarios según la intersección de sus bibliotecas de juegos. Al agruparlos mediante <code>UnionFind.union()</code>, podrás iterar sobre los miembros del grupo del usuario actual, identificar qué juegos tienen ellos que tú no tengas, y mostrarlos en la sección de sugerencias.</p>
            </div>
        <% } %>
    </main>

    <footer class="steam-footer">
        <div class="container footer-content">
            <p>© 2026 SteamV2. Desarrollado como proyecto de Estructura de Datos 2.</p>
            <p class="footer-links"><a href="#">Privacidad</a> | <a href="#">Términos Legales</a> | <a href="#">Acuerdo de Suscriptor</a></p>
        </div>
    </footer>

</body>
</html>
