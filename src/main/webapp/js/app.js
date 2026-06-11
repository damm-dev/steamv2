// STEAM BERDE - CLIENT SIDE SCRIPTS & INTERACTION LOGIC

// --- APPLICATION STATE INTERACTION ---

// Send an asynchronous POST request to the servlet and update the UI
async function sendAction(params) {
    const searchParams = new URLSearchParams(params);
    searchParams.set('format', 'json');
    try {
        const response = await fetch(`${window.contextPath}/recommendations`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json'
            },
            body: searchParams.toString()
        });
        if (!response.ok) throw new Error('Response error');
        const data = await response.json();
        updateStateAndRender(data);
    } catch (error) {
        console.error('Error executing action:', error);
    }
}

// Update local state and trigger dynamic updates of all components
function updateStateAndRender(data) {
    window.steamState.username = data.username;
    window.steamState.library = data.library || [];
    window.steamState.recommendations = data.recommendations || [];
    window.steamState.unionFindGroups = data.unionFindGroups || {};
    window.steamState.unionFindParents = data.unionFindParents || {};

    if (data.allUsers) window.steamState.allUsers = data.allUsers;
    if (data.allGames) window.steamState.allGames = data.allGames;

    renderVisibility();
    if (window.steamState.username) {
        renderNavbarUser();
        renderLibrary();
        renderSuggestions();
        renderGroups();
        renderCarousel();
        updateSearchSuggestions();
    }
}

// Control visible sections (Welcome/Login vs Main Dashboard)
function renderVisibility() {
    const welcome = document.getElementById('welcomeContainer');
    const dashboard = document.getElementById('dashboardContainer');
    const navSearch = document.getElementById('navSearchContainer');
    const navUser = document.getElementById('navUserWidgetWrapper');

    if (window.steamState.username) {
        if (welcome) welcome.style.display = 'none';
        if (dashboard) {
            dashboard.style.opacity = '0';
            dashboard.style.display = 'block';
            setTimeout(() => {
                dashboard.style.transition = 'opacity 0.4s ease';
                dashboard.style.opacity = '1';
            }, 10);
        }
        if (navSearch) navSearch.style.display = 'block';
        if (navUser) navUser.style.display = 'block';
    } else {
        if (welcome) {
            welcome.style.opacity = '0';
            welcome.style.display = 'block';
            setTimeout(() => {
                welcome.style.transition = 'opacity 0.4s ease';
                welcome.style.opacity = '1';
            }, 10);
        }
        if (dashboard) dashboard.style.display = 'none';
        if (navSearch) navSearch.style.display = 'none';
        if (navUser) navUser.style.display = 'none';
        
        // Reset search input on logout
        const searchInput = document.getElementById('searchInput');
        if (searchInput) searchInput.value = '';
    }
}

// Render the navbar user widget and dropdown list
function renderNavbarUser() {
    const username = window.steamState.username;
    const allUsers = window.steamState.allUsers || [];
    
    const nameText = document.getElementById('navUsernameText');
    if (nameText && username) {
        nameText.textContent = username;
    }

    const usersList = document.getElementById('dropdownUsersList');
    if (usersList) {
        usersList.innerHTML = '';
        allUsers.forEach(u => {
            const item = document.createElement('div');
            item.className = `dropdown-user-item ${u.username === username ? 'active-user' : ''}`;
            const userLikedGamesCount = u.likedGames ? u.likedGames.length : 0;
            item.innerHTML = `
                <div class="dropdown-user-info">
                    <div class="dropdown-username">${u.username}</div>
                    <div class="dropdown-user-games">${userLikedGamesCount} juegos</div>
                </div>
            `;
            item.onclick = () => switchProfile(u.username);
            usersList.appendChild(item);
        });
    }
}

// Render user's library side list
function renderLibrary() {
    const library = window.steamState.library || [];
    const list = document.getElementById('libraryList');
    const title = document.getElementById('libraryTitle');
    
    if (title) {
        title.textContent = `Mi Biblioteca (${library.length})`;
    }
    
    if (list) {
        list.innerHTML = '';
        if (library.length === 0) {
            list.innerHTML = '<li style="padding: 15px; color: var(--text-secondary); text-align: center; font-style: italic;">Sin juegos agregados.</li>';
            return;
        }
        library.forEach(game => {
            const img = game.image || 'default_game.jpg';
            const li = document.createElement('li');
            li.className = 'sidebar-item-library';
            li.innerHTML = `
                <div class="sidebar-mini-img-wrap">
                    <img src="${window.contextPath}/images/${img}" alt="${game.name}" class="sidebar-mini-img" onerror="this.onerror=null; this.src='https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=150&auto=format&fit=crop';">
                </div>
                <span class="sidebar-item-title" title="${game.name}">${game.name}</span>
                <button class="remove-btn-mini" onclick="removeGameFromLibrary(${game.id})" title="Eliminar de la biblioteca">
                    <svg viewBox="0 0 24 24" width="10" height="10"><path fill="currentColor" d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z"/></svg>
                </button>
            `;
            list.appendChild(li);
        });
    }
}

// Render sidebar suggestions list
function renderSuggestions() {
    const recommendations = window.steamState.recommendations || [];
    const list = document.getElementById('suggestionsListSide');
    if (list) {
        list.innerHTML = '';
        if (recommendations.length === 0) {
            list.innerHTML = '<li style="padding: 15px; color: var(--text-secondary); text-align: center; font-style: italic;">Sin sugerencias disponibles.</li>';
            return;
        }
        recommendations.forEach(game => {
            const li = document.createElement('li');
            li.className = 'sidebar-item-suggestion';
            li.innerHTML = `
                <span class="sidebar-item-title" title="${game.name}" style="max-width: 140px;">${game.name}</span>
                <button class="add-btn-mini" onclick="addGameToLibrary(${game.id})">+ Añadir</button>
            `;
            list.appendChild(li);
        });
    }
}

// View state for visualizer
let visualizerView = 'cards';
let currentPositions = {};
let animationFrameId = null;
const transitionDuration = 600; // ms

function switchVisualizerView(view) {
    visualizerView = view;
    
    // Toggle active classes on buttons
    const btnCards = document.getElementById('btnViewCards');
    const btnTree = document.getElementById('btnViewTree');
    if (btnCards) {
        if (view === 'cards') btnCards.classList.add('active');
        else btnCards.classList.remove('active');
    }
    if (btnTree) {
        if (view === 'tree') btnTree.classList.add('active');
        else btnTree.classList.remove('active');
    }
    
    renderGroups();
}

// Render horizontal groups cluster or DSU trees
function renderGroups() {
    const groups = window.steamState.unionFindGroups || {};
    const parents = window.steamState.unionFindParents || {};
    const username = window.steamState.username;
    
    const cardsContainer = document.getElementById('groupsContainer');
    const treeContainer = document.getElementById('groupsTreeContainer');
    
    if (!cardsContainer || !treeContainer) return;
    
    if (visualizerView === 'cards') {
        cardsContainer.style.display = 'grid';
        treeContainer.style.display = 'none';
        
        cardsContainer.innerHTML = '';
        const entries = Object.entries(groups);
        if (entries.length === 0) {
            cardsContainer.innerHTML = '<div style="padding: 15px; color: var(--text-secondary); text-align: center; font-style: italic; width: 100%;">No hay grupos formados.</div>';
            return;
        }
        
        entries.forEach(([representative, members]) => {
            const isUserInGroup = members.includes(username);
            const card = document.createElement('div');
            card.className = `cluster-card ${isUserInGroup ? 'active-group' : ''}`;
            
            let badgesHtml = '';
            members.forEach(member => {
                badgesHtml += `
                    <span class="badge ${member === username ? 'badge-me' : 'badge-other'}">
                        ${member}
                    </span>
                `;
            });
            
            card.innerHTML = `
                <h5 class="cluster-group-title">
                    GRUPO ${representative} ${isUserInGroup ? '(Tu Grupo)' : ''}
                </h5>
                <p class="cluster-representative">
                    Representante raíz: <strong>${representative}</strong>
                </p>
                <div class="cluster-members">
                    ${badgesHtml}
                </div>
            `;
            cardsContainer.appendChild(card);
        });
    } else {
        cardsContainer.style.display = 'none';
        treeContainer.style.display = 'block';
        
        renderGroupsTree(treeContainer, groups, parents, username);
    }
}

// Render disjoint-set forest (DSU trees) using dynamic SVG with smooth transitions
function renderGroupsTree(container, groups, parents, username) {
    const allNodes = new Set();
    
    // Build adjacency list and node list
    Object.keys(parents).forEach(child => {
        allNodes.add(child);
        allNodes.add(parents[child]);
    });
    
    const usersCount = allNodes.size;
    const svgWidth = Math.max(container.clientWidth - 10, usersCount * 80);
    const svgHeight = 250;
    
    // Check if the SVG already exists, otherwise create it
    let svg = document.getElementById('dsuSvg');
    if (!svg) {
        container.innerHTML = '';
        svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('id', 'dsuSvg');
        svg.setAttribute('width', svgWidth);
        svg.setAttribute('height', svgHeight);
        svg.style.background = '#0a120d';
        svg.style.borderRadius = '8px';
        svg.style.border = '1px solid var(--border-color)';
        svg.style.display = 'block';
        container.appendChild(svg);
    } else {
        svg.setAttribute('width', svgWidth);
    }
    
    const childrenMap = {};
    Object.keys(parents).forEach(child => {
        const p = parents[child];
        if (p !== child) {
            if (!childrenMap[p]) childrenMap[p] = [];
            childrenMap[p].push(child);
        }
    });
    
    const roots = [];
    allNodes.forEach(node => {
        if (parents[node] === node) {
            roots.push(node);
        }
    });
    
    if (roots.length === 0) {
        container.innerHTML = '<div style="padding: 20px; color: var(--text-secondary); text-align: center; font-style: italic;">No hay árboles DSU disponibles.</div>';
        currentPositions = {};
        return;
    }
    
    // Calculate new target coordinates
    const targetCoords = {};
    const sortedRoots = [...roots].sort((a, b) => {
        const aIsActive = (groups[a] || []).includes(username);
        const bIsActive = (groups[b] || []).includes(username);
        if (aIsActive && !bIsActive) return -1;
        if (!aIsActive && bIsActive) return 1;
        return a.localeCompare(b);
    });
    
    let currentLeft = 0;
    sortedRoots.forEach(root => {
        const members = groups[root] || [root];
        const groupWidth = (members.length / usersCount) * (svgWidth - 40);
        const leftBound = currentLeft + 20;
        const rightBound = currentLeft + 20 + groupWidth;
        
        layoutTree(root, leftBound, rightBound, 0);
        currentLeft += groupWidth;
    });
    
    function layoutTree(node, left, right, depth) {
        const x = (left + right) / 2;
        const y = 40 + depth * 65;
        targetCoords[node] = { x, y, depth };
        
        const children = childrenMap[node] || [];
        if (children.length > 0) {
            const segmentWidth = (right - left) / children.length;
            children.forEach((child, i) => {
                layoutTree(child, left + i * segmentWidth, left + (i + 1) * segmentWidth, depth + 1);
            });
        }
    }
    
    // Animate transition to new coordinates
    animateTransition(targetCoords, parents, username);
}

// Coordinate transition animator
function animateTransition(targetCoords, targetParents, username) {
    const startTime = performance.now();
    
    // Map initial coords
    const startCoords = {};
    Object.keys(targetCoords).forEach(node => {
        if (currentPositions[node]) {
            startCoords[node] = { ...currentPositions[node] };
        } else {
            // New node: start at parent's current position if available, else at its target position
            const parent = targetParents[node];
            if (parent && currentPositions[parent]) {
                startCoords[node] = { ...currentPositions[parent] };
            } else {
                startCoords[node] = { ...targetCoords[node] };
            }
        }
    });
    
    // If it's the very first rendering, set directly without animation
    if (Object.keys(currentPositions).length === 0) {
        Object.keys(targetCoords).forEach(node => {
            currentPositions[node] = { ...targetCoords[node] };
        });
        drawSvgFrame(targetParents, username);
        return;
    }
    
    function step(now) {
        const elapsed = now - startTime;
        const progress = Math.min(elapsed / transitionDuration, 1);
        
        // ease-out cubic
        const ease = 1 - Math.pow(1 - progress, 3);
        
        Object.keys(targetCoords).forEach(node => {
            const start = startCoords[node];
            const end = targetCoords[node];
            currentPositions[node] = {
                x: start.x + (end.x - start.x) * ease,
                y: start.y + (end.y - start.y) * ease
            };
        });
        
        drawSvgFrame(targetParents, username);
        
        if (progress < 1) {
            animationFrameId = requestAnimationFrame(step);
        } else {
            // Set exact final positions
            currentPositions = { ...targetCoords };
            drawSvgFrame(targetParents, username);
            animationFrameId = null;
        }
    }
    
    if (animationFrameId) cancelAnimationFrame(animationFrameId);
    animationFrameId = requestAnimationFrame(step);
}

// Draws the current positions frame onto the SVG element
function drawSvgFrame(targetParents, username) {
    const svg = document.getElementById('dsuSvg');
    if (!svg) return;
    
    let elementsHtml = `
        <defs>
            <marker id="arrow" viewBox="0 0 10 10" refX="21" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                <path d="M 0 0 L 10 5 L 0 10 z" fill="#2a4c35" />
            </marker>
            <marker id="arrow-active" viewBox="0 0 10 10" refX="21" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                <path d="M 0 0 L 10 5 L 0 10 z" fill="#42f58e" />
            </marker>
        </defs>
    `;
    
    const allNodes = Object.keys(currentPositions);
    
    // Trace the active search path to root
    const activePath = new Set();
    let curr = username;
    if (curr && targetParents[curr]) {
        while (curr) {
            activePath.add(curr);
            const next = targetParents[curr];
            if (next === curr || !next) break;
            curr = next;
        }
    }
    
    // 1. Draw Directed Edges (Arrows)
    allNodes.forEach(node => {
        const p = targetParents[node];
        if (p && p !== node && currentPositions[node] && currentPositions[p]) {
            const start = currentPositions[node];
            const end = currentPositions[p];
            const isEdgeActive = activePath.has(node) && activePath.has(p) && targetParents[node] === p;
            
            elementsHtml += `
                <line x1="${start.x}" y1="${start.y}" x2="${end.x}" y2="${end.y}"
                      stroke="${isEdgeActive ? '#42f58e' : '#2a4c35'}"
                      stroke-width="${isEdgeActive ? '3' : '2'}"
                      marker-end="url(${isEdgeActive ? '#arrow-active' : '#arrow'})" />
            `;
        }
    });
    
    // 2. Draw Nodes and text labels
    allNodes.forEach(node => {
        if (!currentPositions[node]) return;
        const { x, y } = currentPositions[node];
        
        let nodeColor = '#1a3022';
        let strokeColor = 'var(--border-color)';
        let strokeWidth = '2';
        let textColor = '#fff';
        let labelColor = '#8da294';
        
        if (node === username) {
            nodeColor = 'var(--accent-cyan)';
            strokeColor = '#fff';
            textColor = '#0a120d';
            labelColor = 'var(--accent-cyan)';
        } else if (targetParents[node] === node) {
            nodeColor = '#1ebd60';
            strokeColor = '#42f58e';
            labelColor = '#42f58e';
        }
        
        // Active search path dashed glow circle
        if (activePath.has(node)) {
            elementsHtml += `
                <circle cx="${x}" cy="${y}" r="19" fill="none"
                        stroke="${node === username ? 'var(--accent-cyan)' : '#42f58e'}"
                        stroke-width="1.5" stroke-dasharray="3,3" />
            `;
        }
        
        elementsHtml += `
            <circle cx="${x}" cy="${y}" r="15" fill="${nodeColor}" stroke="${strokeColor}" stroke-width="${strokeWidth}" />
            <text x="${x}" y="${y + 4}" text-anchor="middle" font-size="11" font-weight="800" fill="${textColor}">
                ${node.charAt(0).toUpperCase()}
            </text>
            <text x="${x}" y="${y + 26}" text-anchor="middle" font-size="10" font-weight="600" fill="${labelColor}">
                ${node}
            </text>
        `;
    });
    
    svg.innerHTML = elementsHtml;
}

// Dynamic Carousel renderer
function renderCarousel() {
    const recommendations = window.steamState.recommendations || [];
    const container = document.getElementById('carouselWrapper');
    if (carouselInterval) clearInterval(carouselInterval);

    if (!container) return;

    if (recommendations.length === 0) {
        container.innerHTML = `
            <div class="container">
                <div style="padding: 30px; color: var(--text-secondary); text-align: center; font-style: italic; background-color: var(--bg-card); border-radius: 8px; border: 1px dashed var(--border-color); margin-top: 15px;">
                    No hay sugerencias recomendadas actualmente.
                </div>
            </div>
        `;
        return;
    }

    let slidesHtml = '';
    recommendations.forEach((game, i) => {
        let imgName = game.image || 'default_game.jpg';
        let genresHtml = '';
        if (game.genres) {
            game.genres.forEach(genre => {
                genresHtml += `<span class="carousel-genre-tag">${genre}</span>`;
            });
        }

        slidesHtml += `
            <div class="carousel-slide ${i === 0 ? 'active' : ''}" data-slide-index="${i}">
                <div class="carousel-image-panel">
                    <img src="${window.contextPath}/images/${imgName}" alt="${game.name}" class="carousel-main-image" onerror="this.onerror=null; this.src='https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=600&auto=format&fit=crop';">
                </div>
                <div class="carousel-info-panel">
                    <div>
                        <div class="carousel-info-title" style="margin-bottom: 8px;">${game.name}</div>
                        <span class="carousel-recommendation-tag">Recomendado por tu grupo</span>
                        <div class="carousel-info-details">
                            <div class="carousel-info-genres">
                                ${genresHtml}
                            </div>
                            <p style="font-size: 13px; color: #8da294; line-height: 1.5; margin-top: 5px;">
                                Este título es popular dentro de tu grupo de Union-Find.
                            </p>
                            <div class="carousel-mini-grid">
                                <img src="${window.contextPath}/images/${imgName}" class="carousel-mini-img" onerror="this.onerror=null; this.src='https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=150&auto=format&fit=crop';">
                                <img src="https://images.unsplash.com/photo-1552820728-8b83bb6b773f?q=80&w=150&auto=format&fit=crop" class="carousel-mini-img">
                                <img src="https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=150&auto=format&fit=crop" class="carousel-mini-img">
                                <img src="https://images.unsplash.com/photo-1538481199705-c710c4e965fc?q=80&w=150&auto=format&fit=crop" class="carousel-mini-img">
                            </div>
                        </div>
                    </div>
                    <div class="carousel-purchase-widget">
                        <span class="carousel-price" style="color: #a3cf06;">Gratuito / Incluido</span>
                        <button class="carousel-btn-add" onclick="addGameToLibrary(${game.id})">Instalar ahora</button>
                    </div>
                </div>
            </div>
        `;
    });

    let dotsHtml = '';
    recommendations.forEach((_, i) => {
        dotsHtml += `<span class="carousel-dot ${i === 0 ? 'active' : ''}" onclick="setCarouselSlide(${i})"></span>`;
    });

    container.innerHTML = `
        <div class="steam-carousel" id="recommendationsCarousel" style="margin: 0; width: 100%; border-radius: 0; border-left: none; border-right: none;">
            <div class="carousel-viewport">
                ${slidesHtml}
                <button class="carousel-arrow carousel-arrow-left" onclick="moveCarousel(-1)">
                    <svg viewBox="0 0 24 24" width="24" height="24"><path fill="currentColor" d="M15.41,16.58L10.83,12L15.41,7.41L14,6L8,12L14,18L15.41,16.58Z"/></svg>
                </button>
                <button class="carousel-arrow carousel-arrow-right" onclick="moveCarousel(1)">
                    <svg viewBox="0 0 24 24" width="24" height="24"><path fill="currentColor" d="M8.59,16.58L13.17,12L8.59,7.41L10,6L16,12L10,18L8.59,16.58Z"/></svg>
                </button>
            </div>
            <div class="carousel-dots">
                ${dotsHtml}
            </div>
        </div>
    `;

    currentSlide = 0;
    updateCarouselElements();
    startAutoplay();

    // Rebind mouse event listeners
    const carouselElement = document.getElementById('recommendationsCarousel');
    if (carouselElement) {
        carouselElement.addEventListener('mouseenter', () => {
            if (carouselInterval) clearInterval(carouselInterval);
        });
        carouselElement.addEventListener('mouseleave', () => {
            startAutoplay();
        });
    }
}


// --- REAL-TIME SEARCH LOGIC ---

function initSearch() {
    const searchInput = document.getElementById('searchInput');
    const searchClearBtn = document.getElementById('searchClearBtn');
    const searchDropdown = document.getElementById('searchSuggestionsDropdown');

    if (!searchInput) return;

    searchInput.addEventListener('input', () => {
        updateSearchSuggestions();
    });

    searchInput.addEventListener('focus', () => {
        updateSearchSuggestions();
    });

    if (searchClearBtn) {
        searchClearBtn.addEventListener('click', () => {
            searchInput.value = '';
            updateSearchSuggestions();
            searchInput.focus();
        });
    }

    // Close search suggestions and profile dropdown on click outside
    document.addEventListener('click', (e) => {
        const searchContainer = document.getElementById('navSearchContainer');
        if (searchContainer && !searchContainer.contains(e.target)) {
            if (searchDropdown) searchDropdown.style.display = 'none';
        }

        const dropdown = document.getElementById('navUserDropdown');
        const menu = document.getElementById('navUserDropdownMenu');
        if (dropdown && menu && !dropdown.contains(e.target)) {
            menu.classList.remove('active');
        }
    });
}

function updateSearchSuggestions() {
    const searchInput = document.getElementById('searchInput');
    const searchClearBtn = document.getElementById('searchClearBtn');
    const searchDropdown = document.getElementById('searchSuggestionsDropdown');
    const suggestionsList = document.getElementById('suggestionsList');

    if (!searchInput || !searchDropdown || !suggestionsList) return;

    const query = searchInput.value.toLowerCase().trim();

    if (searchClearBtn) {
        searchClearBtn.style.display = query.length > 0 ? 'block' : 'none';
    }

    if (query.length === 0) {
        searchDropdown.style.display = 'none';
        return;
    }

    // Search inside window.steamState.allGames
    const allGames = window.steamState.allGames || [];
    const library = window.steamState.library || [];
    const matches = allGames.filter(g => g.name.toLowerCase().includes(query));

    suggestionsList.innerHTML = '';
    
    if (matches.length === 0) {
        suggestionsList.innerHTML = '<div class="suggestion-no-results">No se encontraron juegos</div>';
        searchDropdown.style.display = 'block';
        return;
    }

    // Top 6 matches
    const topMatches = matches.slice(0, 6);
    topMatches.forEach(game => {
        const isOwned = library.some(bg => bg.id === game.id);
        const item = document.createElement('div');
        item.className = 'suggestion-item';
        
        let genresHtml = '';
        if (game.genres) {
            game.genres.slice(0, 2).forEach(g => {
                genresHtml += `<span class="suggestion-genre-tag">${g}</span>`;
            });
        }

        let actionHtml = '';
        if (isOwned) {
            actionHtml = `<span class="badge badge-owned">Adquirido</span>`;
        } else {
            actionHtml = `<button class="suggestion-add-btn" onclick="addGameToLibraryFromSearch(${game.id}, event)">Añadir</button>`;
        }

        const imgName = game.image || 'default_game.jpg';

        item.innerHTML = `
            <img src="${window.contextPath}/images/${imgName}" class="suggestion-thumb" onerror="this.onerror=null; this.src='https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=60&auto=format&fit=crop';">
            <div class="suggestion-info">
                <div class="suggestion-title">${game.name}</div>
                <div class="suggestion-genres">${genresHtml}</div>
            </div>
            <div class="suggestion-action">
                ${actionHtml}
            </div>
        `;
        suggestionsList.appendChild(item);
    });

    searchDropdown.style.display = 'block';
}

function addGameToLibraryFromSearch(gameId, event) {
    if (event) event.stopPropagation(); // keep search dropdown open
    addGameToLibrary(gameId);
}


// --- NAVBAR DROPDOWN & ACTIONS SWITCHES ---

function toggleUserDropdown(event) {
    if (event) event.stopPropagation();
    const menu = document.getElementById('navUserDropdownMenu');
    if (menu) {
        menu.classList.toggle('active');
    }
}

function switchProfile(username) {
    const menu = document.getElementById('navUserDropdownMenu');
    if (menu) menu.classList.remove('active');
    sendAction({ action: '', username: username });
}

// Log out action call
function performLogout() {
    const menu = document.getElementById('navUserDropdownMenu');
    if (menu) menu.classList.remove('active');
    sendAction({ action: 'logout' });
}

// Initial login action call
function handleInitialLogin(event) {
    if (event) event.preventDefault();
    const select = document.getElementById('userSelect');
    if (select) {
        const username = select.value;
        sendAction({ action: '', username: username });
    }
}

// Actions wrappers
function addGameToLibrary(gameId) {
    sendAction({ action: 'addGame', gameId: gameId });
}

function removeGameFromLibrary(gameId) {
    sendAction({ action: 'removeGame', gameId: gameId });
}


// --- CAROUSEL ANIMATION & AUTOPLAY LOGIC ---

let currentSlide = 0;
let slides = [];
let dots = [];
let carouselInterval = null;

function updateCarouselElements() {
    slides = document.querySelectorAll('.carousel-slide');
    dots = document.querySelectorAll('.carousel-dot');
}

function showSlide(index) {
    updateCarouselElements();
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

    if (slides[currentSlide]) {
        slides[currentSlide].classList.add('active');
    }
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
    updateCarouselElements();
    if (slides.length <= 1) return;
    carouselInterval = setInterval(() => {
        showSlide(currentSlide + 1);
    }, 5500); // Change slide every 5.5s
}

function resetAutoplay() {
    if (carouselInterval) {
        clearInterval(carouselInterval);
        startAutoplay();
    }
}


// --- INITIALIZATION ---

document.addEventListener('DOMContentLoaded', () => {
    // Populate library/recommendations initially from window.steamState if they exist
    if (window.steamState.username) {
        if (!window.steamState.library) window.steamState.library = [];
        if (!window.steamState.recommendations) window.steamState.recommendations = [];
        if (!window.steamState.unionFindGroups) window.steamState.unionFindGroups = {};
    }

    updateCarouselElements();
    if (slides.length > 0) {
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
    }

    initSearch();
});
