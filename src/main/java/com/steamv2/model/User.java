package com.steamv2.model;

import java.util.List;

public class User {
    private String username;
    private String password;
    private List<Integer> likedGames;

    public User() {
    }

    public User(String username, String password, List<Integer> likedGames) {
        this.username = username;
        this.password = password;
        this.likedGames = likedGames;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public List<Integer> getLikedGames() {
        return likedGames;
    }

    public void setLikedGames(List<Integer> likedGames) {
        this.likedGames = likedGames;
    }

    @Override
    public String toString() {
        return username;
    }
}
