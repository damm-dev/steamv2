<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.steamv2.model.Game" %>
<%@ page import="com.steamv2.model.User" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.google.gson.Gson" %>
<%
    // Obtener los datos enviados desde el servlet RecommendationServlet
    String username = (String) request.getAttribute("username");
    List<Game> library = (List<Game>) request.getAttribute("library");
    List<Game> recommendations = (List<Game>) request.getAttribute("recommendations");
    List<User> allUsers = (List<User>) request.getAttribute("allUsers");
    List<Game> allGames = (List<Game>) request.getAttribute("allGames");
    Map<String, List<String>> unionFindGroups = (Map<String, List<String>>) request.getAttribute("unionFindGroups");
    Map<String, String> unionFindParents = (Map<String, String>) request.getAttribute("unionFindParents");

    // Si accedemos directamente al JSP sin pasar por el servlet, redirigir al controlador
    if (allUsers == null) {
        response.sendRedirect(request.getContextPath() + "/recommendations");
        return;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Steam Berde - Sugerencias con Union-Find</title>
    <!-- Favicon -->
    <link rel="shortcut icon" href="${pageContext.request.contextPath}/images/logo.png" type="image/png">
    <!-- Fuente premium Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
    <!-- Estilos del proyecto con cache-busting -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css?v=<%= System.currentTimeMillis() %>">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/carousel.css?v=<%= System.currentTimeMillis() %>">
    <!-- Inyección de estado inicial de la aplicación -->
    <script id="steamStateData" type="application/json">
        {
            "username": <%= username != null ? new Gson().toJson(username) : "null" %>,
            "library": <%= library != null ? new Gson().toJson(library) : "[]" %>,
            "recommendations": <%= recommendations != null ? new Gson().toJson(recommendations) : "[]" %>,
            "unionFindGroups": <%= unionFindGroups != null ? new Gson().toJson(unionFindGroups) : "{}" %>,
            "unionFindParents": <%= unionFindParents != null ? new Gson().toJson(unionFindParents) : "{}" %>,
            "allUsers": <%= allUsers != null ? new Gson().toJson(allUsers) : "[]" %>,
            "allGames": <%= allGames != null ? new Gson().toJson(allGames) : "[]" %>
        }
    </script>
    <script>
        window.steamState = JSON.parse(document.getElementById('steamStateData').textContent);
        window.contextPath = "${pageContext.request.contextPath}";
    </script>
</head>
<body>    <!-- Encabezado de SteamV2 -->
    <header class="steam-header">
        <div class="container header-content">
            <div class="logo" style="display: flex; align-items: center; gap: 12px;">
                <img src="${pageContext.request.contextPath}/images/logo.png" alt="SteamBerde Logo" style="height: 32px; width: 32px; object-fit: contain;">
                <div style="display: flex; align-items: center;">
                    <span class="highlight-cyan">STEAM</span><span class="highlight-blue">BERDE</span>
                </div>
            </div>
            
            <!-- Buscador dinámico con sugerencias flotantes -->
            <div class="search-container" id="navSearchContainer" style="display: <%= username != null ? "block" : "none" %>;">
                <div class="search-input-wrapper">
                    <span class="search-icon">
                        <svg class="search-icon-svg" viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="M9.5,3A6.5,6.5 0 0,1 16,9.5C16,11.11 15.41,12.59 14.44,13.73L14.71,14H15.5L20.5,19L19,20.5L14,15.5V14.71L13.73,14.44C12.59,15.41 11.11,16 9.5,16A6.5,6.5 0 0,1 3,9.5A6.5,6.5 0 0,1 9.5,3M9.5,5C7,5 5,7 5,9.5C5,12 7,14 9.5,14C12,14 14,12 14,9.5C14,7 12,5 9.5,5Z"/></svg>
                    </span>
                    <input type="text" id="searchInput" placeholder="Buscar juego en el catálogo..." autocomplete="off">
                    <button type="button" class="search-clear-btn" id="searchClearBtn" style="display: none;">
                        <svg viewBox="0 0 24 24" width="10" height="10"><path fill="currentColor" d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z"/></svg>
                    </button>
                </div>
                <div class="search-suggestions-dropdown" id="searchSuggestionsDropdown" style="display: none;">
                    <div class="suggestions-list" id="suggestionsList"></div>
                </div>
            </div>
            
            <nav class="nav-links">
                <!-- Dropdown de usuario premium (muestra solo el nombre en el botón trigger) -->
                <div class="nav-user-widget-wrapper" id="navUserWidgetWrapper" style="display: <%= username != null ? "block" : "none" %>;">
                    <div class="custom-dropdown" id="navUserDropdown">
                        <button class="dropdown-trigger btn-user-profile" onclick="toggleUserDropdown(event)">
                            <span class="nav-username-text" id="navUsernameText"><%= username != null ? username : "" %></span>
                            <svg class="dropdown-arrow-svg" viewBox="0 0 24 24" width="10" height="10" style="margin-left: 6px;"><path fill="currentColor" d="M7.41,8.58L12,13.17L16.59,8.58L18,10L12,16L6,10L7.41,8.58Z"/></svg>
                        </button>
                        <div class="dropdown-menu" id="navUserDropdownMenu">
                            <div class="dropdown-header">Cambiar de Perfil</div>
                            <div class="dropdown-users-list" id="dropdownUsersList">
                                <% if (allUsers != null) {
                                    for (User u : allUsers) { %>
                                        <div class="dropdown-user-item <%= username != null && u.getUsername().equals(username) ? "active-user" : "" %>" onclick="switchProfile('<%= u.getUsername() %>')">
                                            <div class="dropdown-user-info">
                                                <div class="dropdown-username"><%= u.getUsername() %></div>
                                                <div class="dropdown-user-games"><%= u.getLikedGames() != null ? u.getLikedGames().size() : 0 %> juegos</div>
                                            </div>
                                        </div>
                                <%  }
                                } %>
                            </div>
                            <div class="dropdown-divider"></div>
                            <button onclick="performLogout()" class="dropdown-logout-btn">
                                <svg viewBox="0 0 24 24" width="14" height="14" style="margin-right: 6px;"><path fill="currentColor" d="M19,3H5C3.89,3 3,3.89 3,5V9H5V5H19V19H5V15H3V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5C21,3.89 20.1,3 19,3M10.08,15.58L11.5,17L16.5,12L11.5,7L10.08,8.41L12.67,11H3V13H12.67L10.08,15.58Z"/></svg>
                                Cerrar Sesión
                            </button>
                        </div>
                    </div>
                </div>
            </nav>
        </div>
    </header>

    <main class="main-content" style="padding-top: 0; padding-bottom: 60px;">
        <!-- PANTALLA INICIAL (Simulación de Login) -->
        <div id="welcomeContainer" style="display: <%= username == null ? "block" : "none" %>; padding-top: 40px !important;">
            <div class="container">
                <div class="welcome-card card">
                    <div class="welcome-header">
                        <h2>Bienvenido a <span class="highlight-cyan">Steam</span><span class="highlight-blue">Berde</span></h2>
                    </div>
                    
                    <div class="login-form-container" style="max-width: 500px; margin: 0 auto; text-align: left;">
                        <form id="welcomeLoginForm" onsubmit="handleInitialLogin(event)">
                            <div style="margin-bottom: 20px;">
                                <label for="userSelect" style="display: block; margin-bottom: 8px; font-weight: 600; color: #a3a3a3;">
                                    Selecciona un perfil de usuario:
                                </label>
                                <select id="userSelect" name="username" style="width: 100%; padding: 12px; border-radius: 8px; background-color: #0a120d; border: 1px solid #2a4c35; color: #fff; font-size: 16px; outline: none; font-family: 'Outfit', sans-serif;">
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
                                Iniciar Sesión
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <!-- PANEL PRINCIPAL (Simulación Cargada) -->
        <div id="dashboardContainer" style="display: <%= username != null ? "block" : "none" %>;">
            
            <!-- ROW 1: 3-COLUMN DASHBOARD LAYOUT (Library, Groups Visualizer, Suggestions) (MOVIDO ARRIBA) -->
            <div class="container" style="margin-top: 35px;">
                <div class="steam-dashboard-layout">
                    <!-- Columna Izquierda: Mi Biblioteca -->
                    <div class="sidebar-card">
                        <h3 id="libraryTitle">Mi Biblioteca (<%= library != null ? library.size() : 0 %>)</h3>
                        <ul class="sidebar-list" id="libraryList">
                            <% if (library != null && !library.isEmpty()) {
                                for (Game bg : library) {
                                    String bgImg = bg.getImage();
                                    if (bgImg == null || bgImg.isEmpty()) bgImg = "default_game.jpg";
                            %>
                                <li class="sidebar-item-library">
                                    <div class="sidebar-mini-img-wrap">
                                        <img src="${pageContext.request.contextPath}/images/<%= bgImg %>" alt="<%= bg.getName() %>" class="sidebar-mini-img" onerror="this.onerror=null; this.src='https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=150&auto=format&fit=crop';">
                                    </div>
                                    <span class="sidebar-item-title" title="<%= bg.getName() %>"><%= bg.getName() %></span>
                                    <button class="remove-btn-mini" onclick="removeGameFromLibrary(<%= bg.getId() %>)" title="Eliminar de la biblioteca">
                                        <svg viewBox="0 0 24 24" width="10" height="10"><path fill="currentColor" d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z"/></svg>
                                    </button>
                                </li>
                            <% } } else { %>
                                <li style="padding: 15px; color: var(--text-secondary); text-align: center; font-style: italic;">Sin juegos agregados.</li>
                            <% } %>
                        </ul>
                    </div>

                    <!-- Columna Central: Visualizador de Grupos (Union-Find) (CAMBIADO A HORIZONTAL) -->
                    <div class="sidebar-card">
                        <div class="column-header" style="margin-bottom: 6px; display: flex; align-items: center; width: 100%; justify-content: space-between;">
                            <div style="display: flex; align-items: center;">
                                <svg class="icon" fill="currentColor" viewBox="0 0 24 24" style="color: #42f58e;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.53c-.26-.81-1-1.4-1.9-1.4h-1v-3c0-.55-.45-1-1-1h-6v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/></svg>
                                <h3 style="margin: 0 0 0 6px;">Visualizador de Grupos</h3>
                            </div>
                            <div class="view-toggles" style="display: flex; gap: 8px;">
                                <button id="btnViewCards" class="btn-toggle active" onclick="switchVisualizerView('cards')">Tarjetas</button>
                                <button id="btnViewTree" class="btn-toggle" onclick="switchVisualizerView('tree')">Árboles (DSU)</button>
                            </div>
                        </div>
                        <p class="section-desc" style="font-size: 12px; margin-bottom: 10px; padding-bottom: 8px;">Conjuntos disjuntos (DSU) en memoria agrupados por coincidencia.</p>
                        
                        <div class="clusters-container-horizontal" id="groupsContainer">
                            <% if (unionFindGroups != null) {
                                for (Map.Entry<String, List<String>> entry : unionFindGroups.entrySet()) { 
                                    String representative = entry.getKey();
                                    List<String> members = entry.getValue();
                                    boolean isUserInGroup = (username != null && members.contains(username));
                            %>
                                    <div class="cluster-card <%= isUserInGroup ? "active-group" : "" %>">
                                        <h5 class="cluster-group-title">
                                            GRUPO <%= representative %> <%= isUserInGroup ? "(Tu Grupo)" : "" %>
                                        </h5>
                                        <p class="cluster-representative">
                                            Representante raíz: <strong><%= representative %></strong>
                                        </p>
                                        <div class="cluster-members">
                                            <% for (String member : members) { %>
                                                <span class="badge <%= member.equals(username) ? "badge-me" : "badge-other" %>">
                                                    <%= member %>
                                                </span>
                                            <% } %>
                                        </div>
                                    </div>
                            <%  }
                               } %>
                        </div>
                        <div class="clusters-tree-container" id="groupsTreeContainer" style="display: none; flex: 1; min-height: 0; overflow: auto; position: relative;"></div>
                    </div>

                    <!-- Columna Derecha: Sugerencias para Ti -->
                    <div class="sidebar-card">
                        <h3>Sugerencias para Ti</h3>
                        <ul class="sidebar-list" id="suggestionsListSide">
                            <% if (recommendations != null && !recommendations.isEmpty()) { 
                                for (Game game : recommendations) { %>
                                     <li class="sidebar-item-suggestion">
                                         <span class="sidebar-item-title" title="<%= game.getName() %>" style="max-width: 140px;"><%= game.getName() %></span>
                                         <button class="add-btn-mini" onclick="addGameToLibrary(<%= game.getId() %>)">+ Añadir</button>
                                     </li>
                            <%  } 
                               } else { %>
                                    <li style="padding: 15px; color: var(--text-secondary); text-align: center; font-style: italic;">Sin sugerencias disponibles.</li>
                            <% } %>
                        </ul>
                    </div>
                </div>
            </div>

            <!-- ROW 2: CARRUSEL DE RECOMENDADOS (ANCHO COMPLETO DE LA PÁGINA) (MOVIDO ABAJO) -->
            <div class="carousel-fullwidth-wrapper" style="width: 100%; background-color: #0a120d; border-top: 2px solid #2a4c35; border-bottom: 2px solid #2a4c35; padding: 25px 0; margin-top: 35px;">
                <div class="container" style="margin-bottom: 15px !important;">
                    <div class="column-header" style="margin-bottom: 8px;">
                        <svg class="icon" fill="currentColor" viewBox="0 0 24 24" style="color: #42f58e;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 17h-2v-2h2v2zm2.07-7.75l-.9.92C13.45 12.9 13 13.5 13 15h-2v-.5c0-1.1.45-2.1 1.17-2.83l1.24-1.26c.37-.36.59-.86.59-1.41 0-1.1-.9-2-2-2v2H7c0-2.76 2.24-5 5-5s5 2.24 5 5c0 1.04-.42 1.99-1.07 2.75z"/></svg>
                        <h3 style="font-size: 20px; text-transform: uppercase; letter-spacing: 1px; color: #fff; margin: 0;">Destacados y Recomendados</h3>
                    </div>
                    <p class="section-desc" style="margin-bottom: 0; border-bottom: none; padding-bottom: 0;">Videojuegos sugeridos basados en tu grupo de Union-Find. Desliza para explorar.</p>
                </div>
                
                <div id="carouselWrapper">
                    <% if (recommendations != null && !recommendations.isEmpty()) { %>
                        <div class="steam-carousel" id="recommendationsCarousel" style="margin: 0; width: 100%; border-radius: 0; border-left: none; border-right: none;">
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
                                                    
                                                    <p style="font-size: 13px; color: #8da294; line-height: 1.5; margin-top: 5px;">
                                                        Este título es popular dentro de tu grupo de Union-Find.
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
                                                <span class="carousel-price" style="color: #a3cf06;">Gratuito / Incluido</span>
                                                <button class="carousel-btn-add" onclick="addGameToLibrary(<%= game.getId() %>)">Instalar ahora</button>
                                            </div>
                                        </div>
                                    </div>
                                <% } %>
                                
                                <!-- Flechas de navegación -->
                                <button class="carousel-arrow carousel-arrow-left" onclick="moveCarousel(-1)">
                                    <svg viewBox="0 0 24 24" width="24" height="24"><path fill="currentColor" d="M15.41,16.58L10.83,12L15.41,7.41L14,6L8,12L14,18L15.41,16.58Z"/></svg>
                                </button>
                                <button class="carousel-arrow carousel-arrow-right" onclick="moveCarousel(1)">
                                    <svg viewBox="0 0 24 24" width="24" height="24"><path fill="currentColor" d="M8.59,16.58L13.17,12L8.59,7.41L10,6L16,12L10,18L8.59,16.58Z"/></svg>
                                </button>
                            </div>
                            
                            <!-- Paginación de puntos -->
                            <div class="carousel-dots">
                                <% for (int i = 0; i < recommendations.size(); i++) { %>
                                    <span class="carousel-dot <%= i == 0 ? "active" : "" %>" onclick="setCarouselSlide(<%= i %>)"></span>
                                <% } %>
                            </div>
                        </div>
                    <% } else { %>
                        <div class="container">
                            <div style="padding: 30px; color: var(--text-secondary); text-align: center; font-style: italic; background-color: var(--bg-card); border-radius: 8px; border: 1px dashed var(--border-color); margin-top: 15px;">
                                No hay sugerencias recomendadas actualmente.
                            </div>
                        </div>
                    <% } %>
                </div>
            </div>

            <!-- Formularios ocultos para acciones -->
            <form id="addGameForm" action="${pageContext.request.contextPath}/recommendations" method="POST" style="display: none;">
                <input type="hidden" name="action" value="addGame">
                <input type="hidden" id="addGameId" name="gameId" value="">
            </form>
            <form id="removeGameForm" action="${pageContext.request.contextPath}/recommendations" method="POST" style="display: none;">
                <input type="hidden" name="action" value="removeGame">
                <input type="hidden" id="removeGameId" name="gameId" value="">
            </form>
            <form id="profileActionForm" action="${pageContext.request.contextPath}/recommendations" method="POST" style="display: none;">
                <input type="hidden" name="action" id="profileFormAction" value="">
                <input type="hidden" name="username" id="profileFormUsername" value="">
            </form>
        </div>
    </main>

    <footer class="steam-footer">
        <div class="container footer-content">
            <p>© 2026 Steam Berde. #freeJogoooos</p>
            <p class="footer-links"><a href="#">Privacidad</a> | <a href="#">Términos Legales</a> | <a href="#">Acuerdo de Suscriptor</a></p>
        </div>
    </footer>

    <!-- Cargar scripts del proyecto con cache-busting -->
    <script src="${pageContext.request.contextPath}/js/app.js?v=<%= System.currentTimeMillis() %>"></script>
</body>
</html>
