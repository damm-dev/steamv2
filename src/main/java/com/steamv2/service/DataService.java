package com.steamv2.service;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;
import com.steamv2.model.Game;
import com.steamv2.model.UnionFind;
import com.steamv2.model.User;

import java.io.File;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class DataService {

    private static DataService instance;

    private List<Game> games = new ArrayList<>();
    private List<User> users = new ArrayList<>();
    private Map<Integer, Game> gameMap = new HashMap<>();
    private Map<String, User> userMap = new HashMap<>();
    private UnionFind<String> unionFind = new UnionFind<>();

    private DataService() {
        loadData();
        buildClusters();
    }

    public static synchronized DataService getInstance() {
        if (instance == null) {
            instance = new DataService();
        }
        return instance;
    }

    private void loadData() {
        try {
            Gson gson = new Gson();

            // Cargar juegos
            InputStream gamesStream = getClass().getClassLoader().getResourceAsStream("games.json");
            if (gamesStream != null) {
                Reader reader = new InputStreamReader(gamesStream, StandardCharsets.UTF_8);
                games = gson.fromJson(reader, new TypeToken<List<Game>>() {}.getType());
                for (Game g : games) {
                    gameMap.put(g.getId(), g);
                }
            } else {
                System.err.println("No se pudo encontrar games.json en los recursos.");
            }

            // Cargar usuarios
            InputStream usersStream = getClass().getClassLoader().getResourceAsStream("users.json");
            if (usersStream != null) {
                Reader reader = new InputStreamReader(usersStream, StandardCharsets.UTF_8);
                users = gson.fromJson(reader, new TypeToken<List<User>>() {}.getType());
                for (User u : users) {
                    userMap.put(u.getUsername(), u);
                }
            } else {
                System.err.println("No se pudo encontrar users.json en los recursos.");
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void buildClusters() {
        unionFind = new UnionFind<>();

        // Inicializar conjuntos disjuntos para cada usuario
        for (User u : users) {
            unionFind.makeSet(u.getUsername());
        }

        // Agrupar usuarios por gustos en común
        Map<Integer, List<String>> gameToUsers = new HashMap<>();
        for (User u : users) {
            if (u.getLikedGames() != null) {
                for (Integer gameId : u.getLikedGames()) {
                    gameToUsers.computeIfAbsent(gameId, k -> new ArrayList<>()).add(u.getUsername());
                }
            }
        }

        // Unir usuarios que comparten al menos un juego
        for (Map.Entry<Integer, List<String>> entry : gameToUsers.entrySet()) {
            List<String> usersWhoLiked = entry.getValue();
            if (usersWhoLiked.size() > 1) {
                String firstUser = usersWhoLiked.get(0);
                for (int i = 1; i < usersWhoLiked.size(); i++) {
                    unionFind.union(firstUser, usersWhoLiked.get(i));
                }
            }
        }
    }

    public List<Game> getGames() {
        return games;
    }

    public List<User> getUsers() {
        return users;
    }

    public Game getGameById(int id) {
        return gameMap.get(id);
    }

    public User getUserByUsername(String username) {
        return userMap.get(username);
    }

    public UnionFind<String> getUnionFind() {
        return unionFind;
    }

    // Obtener biblioteca de juegos del usuario
    public List<Game> getUserLibrary(String username) {
        User user = getUserByUsername(username);
        if (user == null || user.getLikedGames() == null) {
            return Collections.emptyList();
        }
        List<Game> library = new ArrayList<>();
        for (Integer gameId : user.getLikedGames()) {
            Game game = getGameById(gameId);
            if (game != null) {
                library.add(game);
            }
        }
        return library;
    }

    // Obtener recomendaciones basadas en Union-Find
    public List<Game> getRecommendations(String username) {
        User targetUser = getUserByUsername(username);
        if (targetUser == null) {
            return Collections.emptyList();
        }

        String targetRoot = unionFind.find(username);
        if (targetRoot == null) {
            return Collections.emptyList();
        }

        Set<Integer> ownedGameIds = new HashSet<>(targetUser.getLikedGames());
        Map<Integer, Integer> recommendedGameFreq = new HashMap<>();

        for (User u : users) {
            if (u.getUsername().equals(username)) {
                continue;
            }

            // Agrupar recomendaciones de usuarios en el mismo conjunto
            if (targetRoot.equals(unionFind.find(u.getUsername()))) {
                if (u.getLikedGames() != null) {
                    for (Integer gameId : u.getLikedGames()) {
                        if (!ownedGameIds.contains(gameId)) {
                            recommendedGameFreq.put(gameId, recommendedGameFreq.getOrDefault(gameId, 0) + 1);
                        }
                    }
                }
            }
        }

        // Ordenar recomendaciones por popularidad en el grupo
        List<Map.Entry<Integer, Integer>> sortedRecs = new ArrayList<>(recommendedGameFreq.entrySet());
        sortedRecs.sort((a, b) -> b.getValue().compareTo(a.getValue()));

        List<Game> recommendations = new ArrayList<>();
        for (Map.Entry<Integer, Integer> entry : sortedRecs) {
            Game g = getGameById(entry.getKey());
            if (g != null) {
                recommendations.add(g);
            }
        }

        return recommendations;
    }

    // Obtener los grupos de usuarios agrupados por su representante
    public Map<String, List<String>> getGroups() {
        Map<String, List<String>> groups = new HashMap<>();
        for (User u : users) {
            String root = unionFind.find(u.getUsername());
            if (root != null) {
                groups.computeIfAbsent(root, k -> new ArrayList<>()).add(u.getUsername());
            }
        }
        return groups;
    }

    // Agregar un juego favorito a un usuario y actualizar clusters
    public synchronized boolean addLikedGameToUser(String username, int gameId) {
        User user = getUserByUsername(username);
        if (user == null) {
            return false;
        }
        
        List<Integer> liked = user.getLikedGames();
        if (liked == null) {
            liked = new ArrayList<>();
            user.setLikedGames(liked);
        } else {
            liked = new ArrayList<>(liked);
            user.setLikedGames(liked);
        }
        
        if (!liked.contains(gameId)) {
            liked.add(gameId);
            buildClusters();
            saveUsersData();
            return true;
        }
        return false;
    }

    // Buscar juegos por coincidencia en el nombre
    public List<Game> searchGames(String query) {
        if (query == null || query.trim().isEmpty()) {
            return Collections.emptyList();
        }
        String lowerQuery = query.toLowerCase().trim();
        List<Game> results = new ArrayList<>();
        for (Game g : games) {
            if (g.getName().toLowerCase().contains(lowerQuery)) {
                results.add(g);
            }
        }
        return results;
    }

    // Eliminar un juego favorito de un usuario y actualizar clusters
    public synchronized boolean removeLikedGameFromUser(String username, int gameId) {
        User user = getUserByUsername(username);
        if (user == null || user.getLikedGames() == null) {
            return false;
        }
        
        List<Integer> liked = new ArrayList<>(user.getLikedGames());
        if (liked.contains(gameId)) {
            liked.remove(Integer.valueOf(gameId));
            user.setLikedGames(liked);
            buildClusters();
            saveUsersData();
            return true;
        }
        return false;
    }

    // Guardar cambios de usuarios en los archivos users.json
    private synchronized void saveUsersData() {
        try {
            Gson gson = new GsonBuilder().setPrettyPrinting().create();
            String jsonString = gson.toJson(users);
            
            // Guardar en la carpeta de compilacion (target/classes)
            URL resourceUrl = getClass().getClassLoader().getResource("users.json");
            if (resourceUrl != null) {
                File targetFile = new File(resourceUrl.toURI());
                try (FileWriter writer = new FileWriter(targetFile, StandardCharsets.UTF_8)) {
                    writer.write(jsonString);
                }
            }
            
            // Guardar en la carpeta de fuentes (src/main/resources)
            if (resourceUrl != null) {
                File targetFile = new File(resourceUrl.toURI());
                File projectRoot = targetFile.getParentFile().getParentFile().getParentFile();
                File sourceFile = new File(projectRoot, "src/main/resources/users.json");
                if (sourceFile.exists()) {
                    try (FileWriter writer = new FileWriter(sourceFile, StandardCharsets.UTF_8)) {
                        writer.write(jsonString);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
