package com.steamv2.controller;

import com.google.gson.Gson;
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
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Controlador para la recomendación de juegos.
 */
@WebServlet(name = "RecommendationServlet", urlPatterns = {"/recommendations"})
public class RecommendationServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        DataService dataService = DataService.getInstance();
        
        HttpSession session = request.getSession();
        String loggedUser = (String) session.getAttribute("loggedUser");
        
        request.setAttribute("allUsers", dataService.getUsers());
        request.setAttribute("allGames", dataService.getGames());
        
        Map<String, List<String>> groups = dataService.getGroups();
        request.setAttribute("unionFindGroups", groups);
        request.setAttribute("unionFindParents", dataService.getUnionFind().getParentMap());

        List<Game> library = null;
        List<Game> recommendations = null;

        if (loggedUser != null && !loggedUser.trim().isEmpty()) {
            library = dataService.getUserLibrary(loggedUser);
            recommendations = dataService.getRecommendations(loggedUser);
            
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
            request.setAttribute("username", null);
            request.setAttribute("javaStatus", "Servidor listo. Esperando inicio de sesión.");
        }

        // Respuesta en formato JSON para AJAX
        if ("json".equals(request.getParameter("format")) || (request.getHeader("Accept") != null && request.getHeader("Accept").contains("application/json"))) {
            response.setContentType("application/json;charset=UTF-8");
            Map<String, Object> data = new HashMap<>();
            data.put("username", loggedUser);
            data.put("allUsers", dataService.getUsers());
            data.put("allGames", dataService.getGames());
            data.put("unionFindGroups", groups);
            data.put("unionFindParents", dataService.getUnionFind().getParentMap());
            
            if (loggedUser != null && !loggedUser.trim().isEmpty()) {
                data.put("library", library);
                data.put("recommendations", recommendations);
                
                String searchQuery = request.getParameter("searchQuery");
                if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                    data.put("searchResults", dataService.searchGames(searchQuery));
                    data.put("searchQuery", searchQuery);
                } else {
                    data.put("searchResults", Collections.emptyList());
                    data.put("searchQuery", "");
                }
            } else {
                data.put("library", Collections.emptyList());
                data.put("recommendations", Collections.emptyList());
                data.put("searchResults", Collections.emptyList());
                data.put("searchQuery", "");
            }
            
            response.getWriter().write(new Gson().toJson(data));
            return;
        }

        request.getRequestDispatcher("/index.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        HttpSession session = request.getSession();

        if ("logout".equals(action)) {
            session.removeAttribute("loggedUser");
        } else if ("addGame".equals(action)) {
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
            String user = request.getParameter("username");
            if (user != null && !user.trim().isEmpty()) {
                session.setAttribute("loggedUser", user);
            }
        }
        
        // Respuesta en formato JSON para AJAX
        if ("json".equals(request.getParameter("format")) || (request.getHeader("Accept") != null && request.getHeader("Accept").contains("application/json"))) {
            response.setContentType("application/json;charset=UTF-8");
            DataService dataService = DataService.getInstance();
            String loggedUser = (String) session.getAttribute("loggedUser");
            
            Map<String, Object> data = new HashMap<>();
            data.put("username", loggedUser);
            data.put("allUsers", dataService.getUsers());
            data.put("allGames", dataService.getGames());
            data.put("unionFindGroups", dataService.getGroups());
            data.put("unionFindParents", dataService.getUnionFind().getParentMap());
            
            if (loggedUser != null && !loggedUser.trim().isEmpty()) {
                data.put("library", dataService.getUserLibrary(loggedUser));
                data.put("recommendations", dataService.getRecommendations(loggedUser));
            } else {
                data.put("library", Collections.emptyList());
                data.put("recommendations", Collections.emptyList());
            }
            
            response.getWriter().write(new Gson().toJson(data));
            return;
        }
        
        response.sendRedirect(request.getContextPath() + "/recommendations");
    }
}
