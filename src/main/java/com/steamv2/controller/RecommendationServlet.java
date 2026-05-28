package com.steamv2.controller;

import com.steamv2.model.UnionFind;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * Servlet de Recomendación de Videojuegos.
 * 
 * Este actúa como el Controlador (C de MVC). Procesa las peticiones, ejecuta la lógica
 * en Java (como usar la clase UnionFind) y redirige a la vista JSP correspondientes.
 */
@WebServlet(name = "RecommendationServlet", urlPatterns = {"/recommendations"})
public class RecommendationServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // 1. Simular algunos datos de prueba para mostrar en la interfaz
        String mockUser = "PlayerOne";
        List<String> userLibrary = List.of("Counter-Strike 2", "Dota 2", "Cyberpunk 2077");
        
        // 2. Demostración básica de la instancia de Union-Find en Java
        UnionFind<String> uf = new UnionFind<>();
        uf.makeSet("PlayerOne");
        uf.makeSet("PlayerTwo");
        uf.makeSet("PlayerThree");
        
        // Simular unión (estos métodos están vacíos por ahora en UnionFind, pero no darán error al compilar)
        uf.union("PlayerOne", "PlayerTwo");
        
        // 3. Crear datos ficticios de recomendación para renderizar en JSP
        List<String> recommendedGames = new ArrayList<>();
        recommendedGames.add("Portal 2");
        recommendedGames.add("Witcher 3: Wild Hunt");
        recommendedGames.add("Hades");

        // 4. Guardar los datos en los atributos de la petición (request) para que JSP pueda leerlos
        request.setAttribute("username", mockUser);
        request.setAttribute("library", userLibrary);
        request.setAttribute("recommendations", recommendedGames);
        
        // Mensaje de estado indicando que Java está comunicándose con JSP
        request.setAttribute("javaStatus", "Conexión Servlet -> JSP establecida con éxito.");

        // 5. Redirigir (forward) la petición a la página JSP para mostrar la interfaz
        request.getRequestDispatcher("/index.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        // En caso de que se haga un POST (por ejemplo, simular un login rápido)
        String user = request.getParameter("username");
        if (user != null && !user.trim().isEmpty()) {
            request.getSession().setAttribute("loggedUser", user);
        }
        response.sendRedirect(request.getContextPath() + "/recommendations");
    }
}
