package com.steamv2.controller;

import com.steamv2.model.Game;
import com.steamv2.model.User;
import com.steamv2.service.DataService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * Servlet de Recomendación de Videojuegos.
 * 
 * Actúa como el Controlador (C de MVC). Procesa las peticiones, se comunica con
 * el DataService (que a su vez utiliza UnionFind) y redirige a la vista JSP.
 */
@WebServlet(name = "RecommendationServlet", urlPatterns = {"/recommendations"})
public class RecommendationServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        DataService dataService = DataService.getInstance();
        
        // 1. Obtener la sesión y ver si hay un usuario logueado
        HttpSession session = request.getSession();
        String loggedUser = (String) session.getAttribute("loggedUser");
        
        // 2. Pasar la lista de todos los usuarios para el formulario de login/interfaz
        request.setAttribute("allUsers", dataService.getUsers());
        
        // 3. Pasar los grupos/clusters actuales del Union-Find para visualizarlos en pantalla
        Map<String, List<String>> groups = dataService.getGroups();
        request.setAttribute("unionFindGroups", groups);

        if (loggedUser != null && !loggedUser.trim().isEmpty()) {
            // Usuario está logueado, cargar sus datos reales
            List<Game> library = dataService.getUserLibrary(loggedUser);
            List<Game> recommendations = dataService.getRecommendations(loggedUser);
            
            // Buscar si se ingresó un término de búsqueda en la Navbar
            String searchQuery = request.getParameter("searchQuery");
            if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                List<Game> searchResults = dataService.searchGames(searchQuery);
                request.setAttribute("searchResults", searchResults);
                request.setAttribute("searchQuery", searchQuery);
            }

            request.setAttribute("username", loggedUser);
            request.setAttribute("library", library);
            request.setAttribute("recommendations", recommendations);
            request.setAttribute("javaStatus", "Simulación activa. Datos procesados dinámicamente con Union-Find.");
        } else {
            // No hay usuario logueado
            request.setAttribute("username", null);
            request.setAttribute("javaStatus", "Servidor listo. Esperando inicio de sesión.");
        }

        // 4. Redirigir (forward) la petición a la página JSP para mostrar la interfaz
        request.getRequestDispatcher("/index.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        HttpSession session = request.getSession();

        if ("logout".equals(action)) {
            // Cerrar sesión
            session.removeAttribute("loggedUser");
        } else if ("addGame".equals(action)) {
            // Agregar juego a la biblioteca del usuario
            String loggedUser = (String) session.getAttribute("loggedUser");
            String gameIdStr = request.getParameter("gameId");
            if (loggedUser != null && gameIdStr != null) {
                try {
                    int gameId = Integer.parseInt(gameIdStr);
                    DataService.getInstance().addLikedGameToUser(loggedUser, gameId);
                } catch (NumberFormatException e) {
                    e.printStackTrace();
                }
            }
        } else if ("removeGame".equals(action)) {
            // Eliminar juego de la biblioteca del usuario
            String loggedUser = (String) session.getAttribute("loggedUser");
            String gameIdStr = request.getParameter("gameId");
            if (loggedUser != null && gameIdStr != null) {
                try {
                    int gameId = Integer.parseInt(gameIdStr);
                    DataService.getInstance().removeLikedGameFromUser(loggedUser, gameId);
                } catch (NumberFormatException e) {
                    e.printStackTrace();
                }
            }
        } else {
            // Intentar iniciar sesión
            String user = request.getParameter("username");
            if (user != null && !user.trim().isEmpty()) {
                session.setAttribute("loggedUser", user);
            }
        }
        
        response.sendRedirect(request.getContextPath() + "/recommendations");
    }
}
