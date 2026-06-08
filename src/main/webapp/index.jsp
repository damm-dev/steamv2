<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.steamv2.model.Game" %>
<%@ page import="com.steamv2.model.User" %>
<%@ page import="java.util.Map" %>
<%
    // Obtener los datos enviados desde el servlet RecommendationServlet
    String username = (String) request.getAttribute("username");
    List<Game> library = (List<Game>) request.getAttribute("library");
    List<Game> recommendations = (List<Game>) request.getAttribute("recommendations");
    String javaStatus = (String) request.getAttribute("javaStatus");
    List<User> allUsers = (List<User>) request.getAttribute("allUsers");
    Map<String, List<String>> unionFindGroups = (Map<String, List<String>>) request.getAttribute("unionFindGroups");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Steam Berde - Sugerencias con Union-Find</title>
    <!-- Fuente premium Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
    <!-- Estilos del proyecto -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/carousel.css">
</head>
<body>

    <!-- Encabezado de SteamV2 -->
    <header class="steam-header">
        <div class="container header-content">
            <div class="logo" style="display: flex; align-items: center; gap: 20px;">
                <div>
                    <span class="highlight-cyan">STEAM</span><span class="highlight-blue">BERDE</span>
                </div>
                <% if (username != null) { %>
                    <form action="${pageContext.request.contextPath}/recommendations" method="GET" style="display: flex; align-items: center; margin: 0 15px;">
                        <input type="text" name="searchQuery" placeholder="Buscar juego en el catálogo..." value="<%= request.getAttribute("searchQuery") != null ? request.getAttribute("searchQuery") : "" %>" style="background-color: #0b120d; border: 1px solid #1a2a1f; color: #fff; padding: 8px 15px; border-radius: 4px 0 0 4px; outline: none; font-size: 14px; width: 230px; font-family: 'Outfit', sans-serif;">
                        <button type="submit" style="background-color: #3df27b; border: none; color: #060a07; padding: 8px 15px; border-radius: 0 4px 4px 0; cursor: pointer; font-size: 14px; font-weight: bold; font-family: 'Outfit', sans-serif;">Buscar</button>
                        <% if (request.getAttribute("searchResults") != null) { %>
                            <a href="${pageContext.request.contextPath}/recommendations" style="color: #eb5e55; text-decoration: none; margin-left: 12px; font-size: 13px; font-weight: bold; font-family: 'Outfit', sans-serif;">Limpiar</a>
                        <% } %>
                    </form>
                <% } %>
            </div>
            <nav class="nav-links">
                <a href="#" class="active">Tienda</a>
                <a href="#">Comunidad</a>
                <a href="#">Sobre Nosotros</a>
                <a href="#">Soporte</a>
            </nav>
        </div>
    </header>

    <main class="container main-content">
        <% if (username == null) { %>
            <!-- PANTALLA INICIAL (Simulación de Login) -->
            <div class="welcome-card card">
                <div class="welcome-header">
                    <h2>Bienvenido a <span class="highlight-cyan">Steam</span><span class="highlight-blue">Berde</span></h2>
                    <p class="subtitle">Simulador de Recomendaciones de Videojuegos usando la Estructura de Datos <strong>Union-Find</strong></p>
                </div>
                
                <div class="login-form-container" style="max-width: 500px; margin: 0 auto; text-align: left;">
                    <p style="margin-bottom: 20px; line-height: 1.6; color: #c7d5e0;">
                        Para simular la recomendación de juegos en Java mediante <strong>Union-Find</strong>, selecciona uno de los perfiles disponibles en nuestra base de datos simulada y pulsa el botón para iniciar sesión.
                    </p>
                    
                    <form action="${pageContext.request.contextPath}/recommendations" method="POST">
                        <div style="margin-bottom: 20px;">
                            <label for="userSelect" style="display: block; margin-bottom: 8px; font-weight: 600; color: #a3a3a3;">
                                Selecciona un perfil de usuario:
                            </label>
                            <select id="userSelect" name="username" style="width: 100%; padding: 12px; border-radius: 8px; background-color: #0b120d; border: 1px solid #1a2a1f; color: #fff; font-size: 16px; outline: none; font-family: 'Outfit', sans-serif;">
                                <% if (allUsers != null) {
                                    for (User u : allUsers) { %>
                                        <option value="<%= u.getUsername() %>">
                                            <%= u.getUsername() %> (<%= u.getLikedGames() != null ? u.getLikedGames().size() : 0 %> juegos favoritos)
                                        </option>
                                <%  }
                                   } %>
                            </select>
                        </div>
                        <button type="submit" class="btn btn-primary btn-glow" style="width: 100%; padding: 14px; font-size: 16px; font-weight: bold; cursor: pointer;">
                            Iniciar Sesión y Cargar Simulación
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

            <div class="profile-summary card" style="display: flex; align-items: center; justify-content: space-between;">
                <div class="profile-info" style="display: flex; align-items: center; gap: 15px;">
                    <div class="avatar-placeholder" style="width: 50px; height: 50px; border-radius: 50%; background: linear-gradient(135deg, #0f9b58, #3df27b); color: #060a07; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 20px;">
                        <%= username.substring(0, Math.min(username.length(), 2)).toUpperCase() %>
                    </div>
                    <div>
                        <h3>Usuario Actual: <span class="highlight-cyan"><%= username %></span></h3>
                        <p class="subtitle" style="margin: 0; font-size: 13px; color: #8899a6;">Perfil simulado activo - Conectado mediante sesión</p>
                    </div>
                </div>
                <form action="${pageContext.request.contextPath}/recommendations" method="POST" style="margin: 0;">
                    <input type="hidden" name="action" value="logout" />
                    <button type="submit" class="btn btn-secondary" style="padding: 10px 20px; font-size: 14px; font-weight: bold; cursor: pointer; border-radius: 5px;">
                        Salir / Cambiar de Usuario
                    </button>
                </form>
            </div>

            <% 
                List<Game> searchResults = (List<Game>) request.getAttribute("searchResults");
                String searchQuery = (String) request.getAttribute("searchQuery");
                if (searchResults != null) { 
            %>
                <div class="card" style="margin-bottom: 30px; border: 1px solid #3df27b; background: linear-gradient(180deg, #0f1c13 0%, #060a07 100%); border-radius: 16px;">
                    <div class="column-header">
                        <span style="font-size: 24px; margin-right: 12px;">🔍</span>
                        <h3 style="color: #fff;">Resultados para: <span class="highlight-cyan">"<%= searchQuery %>"</span></h3>
                    </div>
                    <p class="section-desc" style="border-bottom: 1px solid #1a2a1f; padding-bottom: 10px; margin-bottom: 15px;">Juegos encontrados en todo el catálogo de Steam Berde.</p>
                    <ul class="game-list" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 15px; list-style: none;">
                        <% if (!searchResults.isEmpty()) {
                            for (Game game : searchResults) { 
                                boolean alreadyOwned = false;
                                if (library != null) {
                                    for (Game owned : library) {
                                        if (owned.getId() == game.getId()) {
                                            alreadyOwned = true;
                                            break;
                                        }
                                    }
                                }
                        %>
                                <li class="game-item" style="display: flex; align-items: center; justify-content: space-between; padding: 12px 15px; background-color: #0b120d; border-radius: 6px; border: 1px solid #1a2a1f; border-left: 4px solid <%= alreadyOwned ? "#0f9b58" : "#3df27b" %>; margin: 0;">
                                    <div style="display: flex; flex-direction: column; flex-grow: 1;">
                                        <span class="game-title" style="font-weight: 600; color: #fff; font-size: 14px;"><%= game.getName() %></span>
                                        <span class="game-genres" style="font-size: 11px; color: #8899a6; margin-top: 4px;">
                                            <%= String.join(", ", game.getGenres()) %>
                                        </span>
                                    </div>
                                    <% if (alreadyOwned) { %>
                                        <span class="badge badge-owned">Adquirido</span>
                                    <% } else { %>
                                        <button class="carousel-btn-add" style="padding: 6px 12px; font-size: 11px; border-radius: 4px; border: none; background: #3df27b; color: #060a07; cursor: pointer; font-weight: bold;" onclick="addGameToLibrary(<%= game.getId() %>)">Añadir</button>
                                    <% } %>
                                </li>
                        <%  }
                           } else { %>
                                <li style="padding: 15px; color: #8899a6; font-style: italic; list-style: none; grid-column: 1 / -1; text-align: center;">No se encontraron juegos con ese nombre en la tienda.</li>
                        <% } %>
                    </ul>
                </div>
            <% } %>

            <!-- CARRUSEL DE RECOMENDADOS (ESTILO STEAM) -->
            <div class="card" style="padding: 24px; margin-bottom: 30px; background: linear-gradient(180deg, #0f1c13 0%, #060a07 100%); border: 1px solid #1a2a1f;">
                <div class="column-header">
                    <svg class="icon" fill="currentColor" viewBox="0 0 24 24" style="color: #3df27b;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 17h-2v-2h2v2zm2.07-7.75l-.9.92C13.45 12.9 13 13.5 13 15h-2v-.5c0-1.1.45-2.1 1.17-2.83l1.24-1.26c.37-.36.59-.86.59-1.41 0-1.1-.9-2-2-2s-2 .9-2 2H7c0-2.76 2.24-5 5-5s5 2.24 5 5c0 1.04-.42 1.99-1.07 2.75z"/></svg>
                    <h3 style="font-size: 20px; text-transform: uppercase; letter-spacing: 1px; color: #fff;">Destacados y Recomendados</h3>
                </div>
                <p class="section-desc" style="margin-bottom: 15px; border-bottom: 1px solid #1a2a1f; padding-bottom: 10px;">Videojuegos sugeridos basados en tu grupo de Union-Find. Desliza para explorar.</p>
                
                <% if (recommendations != null && !recommendations.isEmpty()) { %>
                    <div class="steam-carousel" id="recommendationsCarousel">
                        <div class="carousel-viewport">
                            <% 
                            for (int i = 0; i < recommendations.size(); i++) {
                                Game game = recommendations.get(i);
                                String imgName = game.getImage();
                                if (imgName == null || imgName.isEmpty()) {
                                    imgName = "default_game.jpg";
                                }
                            %>
                                <div class="carousel-slide <%= i == 0 ? "active" : "" %>" data-slide-index="<%= i %>">
                                    <!-- Lado Izquierdo: Imagen Principal -->
                                    <div class="carousel-image-panel">
                                        <img src="${pageContext.request.contextPath}/images/<%= imgName %>" alt="<%= game.getName() %>" class="carousel-main-image" onerror="this.onerror=null; this.src='https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=600&auto=format&fit=crop';">
                                    </div>
                                    
                                    <!-- Lado Derecho: Detalles -->
                                    <div class="carousel-info-panel">
                                        <div>
                                            <div class="carousel-info-title" style="margin-bottom: 8px;"><%= game.getName() %></div>
                                            <span class="carousel-recommendation-tag">Recomendado por tu grupo</span>
                                            
                                            <div class="carousel-info-details">
                                                <div class="carousel-info-genres">
                                                    <% for (String genre : game.getGenres()) { %>
                                                        <span class="carousel-genre-tag"><%= genre %></span>
                                                    <% } %>
                                                </div>
                                                
                                                <p style="font-size: 13px; color: #8899a6; line-height: 1.5; margin-top: 5px;">
                                                    Este título es popular entre los usuarios de tu conjunto disjunto. Es un juego que aún no tienes en tu biblioteca.
                                                </p>
                                                
                                                <!-- Capturas miniatura simuladas al estilo Steam -->
                                                <div class="carousel-mini-grid">
                                                    <img src="${pageContext.request.contextPath}/images/<%= imgName %>" class="carousel-mini-img" onerror="this.onerror=null; this.src='https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=150&auto=format&fit=crop';">
                                                    <img src="https://images.unsplash.com/photo-1552820728-8b83bb6b773f?q=80&w=150&auto=format&fit=crop" class="carousel-mini-img">
                                                    <img src="https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=150&auto=format&fit=crop" class="carousel-mini-img">
                                                    <img src="https://images.unsplash.com/photo-1538481199705-c710c4e965fc?q=80&w=150&auto=format&fit=crop" class="carousel-mini-img">
                                                </div>
                                            </div>
                                        </div>
                                        
                                        <!-- Compra Widget -->
                                        <div class="carousel-purchase-widget">
                                            <span class="carousel-price">Gratuito / Incluido</span>
                                            <button class="carousel-btn-add" onclick="addGameToLibrary(<%= game.getId() %>)">Instalar ahora</button>
                                        </div>
                                    </div>
                                </div>
                            <% } %>
                            
                            <!-- Flechas de navegación -->
                            <button class="carousel-arrow carousel-arrow-left" onclick="moveCarousel(-1)">&#10094;</button>
                            <button class="carousel-arrow carousel-arrow-right" onclick="moveCarousel(1)">&#10095;</button>
                        </div>
                        
                        <!-- Paginación de puntos -->
                        <div class="carousel-dots">
                            <% for (int i = 0; i < recommendations.size(); i++) { %>
                                <span class="carousel-dot <%= i == 0 ? "active" : "" %>" onclick="setCarouselSlide(<%= i %>)"></span>
                            <% } %>
                        </div>
                    </div>
                <% } else { %>
                    <div style="padding: 30px; color: #8899a6; text-align: center; font-style: italic; background-color: #171a21; border-radius: 6px; border: 1px dashed #2a475e;">
                        No hay sugerencias recomendadas. Esto ocurre si ya tienes todos los juegos que les gustan a tus compañeros de grupo, o si eres el único en tu conjunto disjunto.
                    </div>
                <% } %>
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
                        <% if (library != null && !library.isEmpty()) { 
                            for (Game game : library) { %>
                                <li class="game-item owned" style="display: flex; align-items: center; justify-content: space-between; padding: 12px 15px; margin-bottom: 8px; border-radius: 6px; background-color: #0b120d; border-left: 4px solid #0f9b58;">
                                    <div style="display: flex; flex-direction: column; flex-grow: 1;">
                                        <span class="game-title" style="font-weight: 600; color: #fff;"><%= game.getName() %></span>
                                        <span class="game-genres" style="font-size: 12px; color: #8899a6; margin-top: 4px;">
                                            <%= String.join(", ", game.getGenres()) %>
                                        </span>
                                    </div>
                                    <button class="btn-delete" style="background-color: rgba(235, 94, 85, 0.1); border: 1px solid rgba(235, 94, 85, 0.3); color: #eb5e55; padding: 6px 12px; font-size: 11px; margin-right: 12px; border-radius: 4px; cursor: pointer; font-weight: 600; font-family: 'Outfit', sans-serif; transition: all 0.2s ease;" onclick="removeGameFromLibrary(<%= game.getId() %>)">Eliminar</button>
                                    <span class="badge badge-owned">Adquirido</span>
                                </li>
                        <%  } 
                           } else { %>
                                <li style="padding: 15px; color: #8899a6; text-align: center; font-style: italic; list-style: none;">
                                    No tienes juegos en tu biblioteca.
                                </li>
                        <% } %>
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
                        <% if (recommendations != null && !recommendations.isEmpty()) { 
                            for (Game game : recommendations) { %>
                                 <li class="game-item recommended" style="display: flex; align-items: center; justify-content: space-between; padding: 12px 15px; margin-bottom: 8px; border-radius: 6px; background-color: #0b120d; border-left: 4px solid #3df27b;">
                                     <div style="display: flex; flex-direction: column; flex-grow: 1;">
                                         <span class="game-title" style="font-weight: 600; color: #fff;"><%= game.getName() %></span>
                                         <span class="game-genres" style="font-size: 12px; color: #8899a6; margin-top: 4px;">
                                             <%= String.join(", ", game.getGenres()) %>
                                         </span>
                                     </div>
                                     <button class="carousel-btn-add" style="padding: 6px 12px; font-size: 11px; margin-right: 12px; border-radius: 4px;" onclick="addGameToLibrary(<%= game.getId() %>)">Añadir</button>
                                     <span class="badge badge-rec">Sugerido</span>
                                 </li>
                        <%  } 
                           } else if (recommendations != null) { %>
                                <li style="padding: 20px; color: #8899a6; text-align: center; font-style: italic; list-style: none; background-color: #171a21; border-radius: 6px; border: 1px dashed #2a475e;">
                                    No hay sugerencias recomendadas. Esto ocurre si ya tienes todos los juegos que les gustan a tus compañeros de grupo, o si eres el único en tu conjunto disjunto.
                                </li>
                        <% } %>
                    </ul>
                </div>
            </div>

            <!-- Visualización de Conjuntos Disjuntos (Union-Find Groups) -->
            <div class="card" style="margin-top: 25px;">
                <div class="column-header">
                    <svg class="icon" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.53c-.26-.81-1-1.4-1.9-1.4h-1v-3c0-.55-.45-1-1-1h-6v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/></svg>
                    <h3>Visualizador de Clusters (Union-Find)</h3>
                </div>
                <p class="section-desc">Estructura real de los conjuntos disjuntos (DSU) en memoria. Se agrupan usuarios según la coincidencia de sus juegos comprados.</p>
                
                <div class="clusters-container" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; margin-top: 15px;">
                    <% if (unionFindGroups != null) {
                        int groupNum = 1;
                        for (Map.Entry<String, List<String>> entry : unionFindGroups.entrySet()) { 
                            String representative = entry.getKey();
                            List<String> members = entry.getValue();
                            boolean isUserInGroup = (username != null && members.contains(username));
                    %>
                            <div class="cluster-card" style="padding: 15px; border-radius: 8px; background: <%= isUserInGroup ? "linear-gradient(135deg, #0f1c13, #0b120d)" : "#0b120d" %>; border: 1px solid <%= isUserInGroup ? "#3df27b" : "#1a2a1f" %>; box-shadow: <%= isUserInGroup ? "0 0 10px rgba(61,242,123,0.2)" : "none" %>;">
                                <h5 style="margin: 0 0 10px 0; color: <%= isUserInGroup ? "#3df27b" : "#c7d5e0" %>; font-size: 14px; font-weight: 600; text-transform: uppercase;">
                                    GRUPO <%= representative %> <%= isUserInGroup ? "★ (Tu Grupo)" : "" %>
                                </h5>
                                <p style="font-size: 12px; margin: 0 0 8px 0; color: #8899a6;">
                                    Representante raíz: <strong style="color: #fff;"><%= representative %></strong>
                                </p>
                                <div style="display: flex; flex-wrap: wrap; gap: 6px;">
                                    <% for (String member : members) { %>
                                        <span class="badge" style="background-color: <%= member.equals(username) ? "#3df27b" : "#1a2a1f" %>; color: <%= member.equals(username) ? "#060a07" : "#fff" %>; padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: 600;">
                                            <%= member %>
                                        </span>
                                    <% } %>
                                </div>
                            </div>
                    <%  }
                       } %>
                </div>
            </div>
            
            <div class="info-alert card" style="margin-top: 25px;">
                                <h4>💡 Lógica implementada en este simulador:</h4>
                                <p style="line-height: 1.6; color: #c7d5e0;">
                                    El backend Java lee los archivos JSON y mapea la relación entre usuarios. Cada vez que dos o más usuarios comparten un gusto por el mismo juego, se invoca a <code>UnionFind.union()</code>. 
                                    Al iniciar sesión con un usuario, el sistema busca su representante (llamando a <code>UnionFind.find()</code>), identifica a los usuarios en su mismo cluster, combina sus juegos preferidos, filtra los que ya tienes, y te muestra la recomendación ordenada por frecuencia de popularidad dentro de tu grupo.
                                </p>
                            </div>
                
                            <!-- Formulario oculto para agregar juegos a la biblioteca -->
                            <form id="addGameForm" action="${pageContext.request.contextPath}/recommendations" method="POST" style="display: none;">
                                <input type="hidden" name="action" value="addGame">
                                <input type="hidden" id="addGameId" name="gameId" value="">
                            </form>

                            <!-- Formulario oculto para eliminar juegos de la biblioteca -->
                            <form id="removeGameForm" action="${pageContext.request.contextPath}/recommendations" method="POST" style="display: none;">
                                <input type="hidden" name="action" value="removeGame">
                                <input type="hidden" id="removeGameId" name="gameId" value="">
                            </form>
                        <% } %>
                    </main>

    <footer class="steam-footer">
        <div class="container footer-content">
            <p>© 2026 Steam Berde. Desarrollado como proyecto de Estructura de Datos 2.</p>
            <p class="footer-links"><a href="#">Privacidad</a> | <a href="#">Términos Legales</a> | <a href="#">Acuerdo de Suscriptor</a></p>
        </div>
    </footer>

    <!-- Script para controlar el Carrusel -->
    <script>
        function addGameToLibrary(gameId) {
            document.getElementById('addGameId').value = gameId;
            document.getElementById('addGameForm').submit();
        }

        function removeGameFromLibrary(gameId) {
            if (confirm("¿Estás seguro de que deseas eliminar este juego de tu biblioteca?")) {
                document.getElementById('removeGameId').value = gameId;
                document.getElementById('removeGameForm').submit();
            }
        }

        let currentSlide = 0;
        const slides = document.querySelectorAll('.carousel-slide');
        const dots = document.querySelectorAll('.carousel-dot');
        let carouselInterval = null;

        function showSlide(index) {
            if (slides.length === 0) return;
            
            if (index >= slides.length) {
                currentSlide = 0;
            } else if (index < 0) {
                currentSlide = slides.length - 1;
            } else {
                currentSlide = index;
            }

            slides.forEach(slide => slide.classList.remove('active'));
            dots.forEach(dot => dot.classList.remove('active'));

            slides[currentSlide].classList.add('active');
            if (dots[currentSlide]) {
                dots[currentSlide].classList.add('active');
            }
        }

        function moveCarousel(direction) {
            showSlide(currentSlide + direction);
            resetAutoplay();
        }

        function setCarouselSlide(index) {
            showSlide(index);
            resetAutoplay();
        }

        function startAutoplay() {
            if (slides.length <= 1) return;
            carouselInterval = setInterval(() => {
                showSlide(currentSlide + 1);
            }, 5500); // Cambiar automáticamente cada 5.5 segundos
        }

        function resetAutoplay() {
            if (carouselInterval) {
                clearInterval(carouselInterval);
                startAutoplay();
            }
        }

        document.addEventListener('DOMContentLoaded', () => {
            startAutoplay();
            
            const carouselElement = document.getElementById('recommendationsCarousel');
            if (carouselElement) {
                carouselElement.addEventListener('mouseenter', () => {
                    if (carouselInterval) clearInterval(carouselInterval);
                });
                carouselElement.addEventListener('mouseleave', () => {
                    startAutoplay();
                });
            }
        });
    </script>
</body>
</html>
