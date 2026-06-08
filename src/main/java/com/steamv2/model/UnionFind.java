package com.steamv2.model;

import java.util.HashMap;
import java.util.Map;

/**
 * Estructura de Datos: Union-Find (Conjuntos Disjuntos / Disjoint Set Union - DSU)
 */
public class UnionFind<T> {

    private final Map<T, T> parent = new HashMap<>();
    private final Map<T, Integer> rank = new HashMap<>();

    public void makeSet(T element) {
        if (!parent.containsKey(element)) {
            parent.put(element, element);
            rank.put(element, 0);
        }
    }

    public T find(T element) {
        if (!parent.containsKey(element)) {
            return null;
        }

        T p = parent.get(element);
        if (p.equals(element)) {
            return element;
        }
   
        T root = find(p);
        parent.put(element, root);
        return root;
    }

    public boolean union(T element1, T element2) {
        T root1 = find(element1);
        T root2 = find(element2);

        if (root1 == null || root2 == null || root1.equals(root2)) {
            return false;
        }

        int rank1 = rank.get(root1);
        int rank2 = rank.get(root2);

        if (rank1 < rank2) {
            parent.put(root1, root2);
        } else if (rank1 > rank2) {
            parent.put(root2, root1);
        } else {
            parent.put(root2, root1);
            rank.put(root1, rank1 + 1);
        }

        return true;
    }

    public boolean connected(T element1, T element2) {
        T root1 = find(element1);
        T root2 = find(element2);
        return root1 != null && root1.equals(root2);
    }

    public Map<T, T> getParentMap() {
        return parent;
    }
}