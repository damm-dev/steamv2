package com.steamv2.model;

import java.util.List;

public class Game {
    private int id;
    private String name;
    private List<String> genres;
    private String image;

    public Game() {
    }

    public Game(int id, String name, List<String> genres, String image) {
        this.id = id;
        this.name = name;
        this.genres = genres;
        this.image = image;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<String> getGenres() {
        return genres;
    }

    public void setGenres(List<String> genres) {
        this.genres = genres;
    }

    public String getImage() {
        return image;
    }

    public void setImage(String image) {
        this.image = image;
    }

    @Override
    public String toString() {
        return name;
    }
}
