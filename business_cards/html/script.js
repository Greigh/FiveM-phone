// Business Cards App JavaScript
let playerData = {};
let config = {};
let selectedCardForSharing = null;
let myCards = [];

// DOM Elements
const app = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const tabBtns = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');

// Form elements
const cardTitle = document.getElementById('cardTitle');
const jobTitle = document.getElementById('jobTitle');
const cardDescription = document.getElementById('cardDescription');
const cardPhone = document.getElementById('cardPhone');
const cardEmail = document.getElementById('cardEmail');
const cardTemplate = document.getElementById('cardTemplate');
const createCardBtn = document.getElementById('createCard');
const refreshNearbyBtn = document.getElementById('refreshNearby');

// Lists
const cardsList = document.getElementById('cardsList');
const shareCardsList = document.getElementById('shareCardsList');
const nearbyPlayersList = document.getElementById('nearbyPlayersList');

// Initialize app
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openApp') {
        playerData = data.playerData;
        config = data.config;
        openApp();
    }
});

function openApp() {
    app.classList.remove('hidden');
    loadCards();
    setupEventListeners();
    updatePreview();
    
    // Pre-fill form with player data
    if (playerData.phone) {
        cardPhone.value = playerData.phone;
    }
    if (playerData.job) {
        jobTitle.value = playerData.job;
    }
}

function closeApp() {
    app.classList.add('hidden');
    clearForm();
    
    fetch(`https://${GetParentResourceName()}/closeApp`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

function setupEventListeners() {
    // Close button
    closeBtn.addEventListener('click', closeApp);
    
    // Tab switching
    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const tabName = btn.getAttribute('data-tab');
            switchTab(tabName);
        });
    });
    
    // Form inputs
    cardTitle.addEventListener('input', () => {
        updateCharCount(cardTitle, 50);
        updatePreview();
        updateCreateButton();
    });
    
    cardDescription.addEventListener('input', () => {
        updateCharCount(cardDescription, 200);
        updatePreview();
        updateCreateButton();
    });
    
    jobTitle.addEventListener('input', updatePreview);
    cardPhone.addEventListener('input', updatePreview);
    cardEmail.addEventListener('input', updatePreview);
    cardTemplate.addEventListener('change', updatePreview);
    
    // Create card
    createCardBtn.addEventListener('click', createCard);
    
    // Refresh nearby players
    refreshNearbyBtn.addEventListener('click', loadNearbyPlayers);
}

function switchTab(tabName) {
    // Update tab buttons
    tabBtns.forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    
    // Update tab content
    tabContents.forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(`${tabName}-tab`).classList.add('active');
    
    // Load data based on tab
    if (tabName === 'share') {
        loadCardsForSharing();
        loadNearbyPlayers();
    }
}

function updateCharCount(element, maxLength) {
    const parent = element.parentElement;
    const counter = parent.querySelector('.char-count');
    const currentLength = element.value.length;
    counter.textContent = `${currentLength}/${maxLength}`;
    
    if (currentLength > maxLength * 0.9) {
        counter.style.color = '#dc3545';
    } else {
        counter.style.color = '#999';
    }
}

function updatePreview() {
    const preview = document.getElementById('cardPreview');
    const title = cardTitle.value || playerData.name || 'Your Name';
    const job = jobTitle.value || playerData.job || 'Your Job Title';
    const description = cardDescription.value || 'Your description will appear here...';
    const phone = cardPhone.value || playerData.phone || 'Your Phone';
    const email = cardEmail.value || 'Your Email';
    const template = cardTemplate.value || 'professional';
    
    // Update template class
    preview.className = `business-card ${template.toLowerCase()}`;
    
    // Update content
    preview.querySelector('.card-title').textContent = title;
    preview.querySelector('.card-job').textContent = job;
    preview.querySelector('.card-description').textContent = description;
    preview.querySelector('.phone').textContent = phone;
    preview.querySelector('.email').textContent = email;
}

function updateCreateButton() {
    const hasTitle = cardTitle.value.trim().length > 0;
    const hasDescription = cardDescription.value.trim().length > 0;
    const titleValid = cardTitle.value.length <= 50;
    const descriptionValid = cardDescription.value.length <= 200;
    
    createCardBtn.disabled = !(hasTitle && hasDescription && titleValid && descriptionValid);
}

function createCard() {
    const cardData = {
        title: cardTitle.value.trim(),
        description: cardDescription.value.trim(),
        job_title: jobTitle.value.trim(),
        phone: cardPhone.value.trim(),
        email: cardEmail.value.trim(),
        template: cardTemplate.value
    };
    
    fetch(`https://${GetParentResourceName()}/createCard`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(cardData)
    }).then(() => {
        clearForm();
        loadCards();
        switchTab('cards');
    });
}

function clearForm() {
    cardTitle.value = '';
    cardDescription.value = '';
    jobTitle.value = playerData.job || '';
    cardPhone.value = playerData.phone || '';
    cardEmail.value = '';
    cardTemplate.value = 'Professional';
    
    // Reset char counters
    updateCharCount(cardTitle, 50);
    updateCharCount(cardDescription, 200);
    updatePreview();
    updateCreateButton();
}

function loadCards() {
    cardsList.innerHTML = '<div class="loading"><i class="fas fa-spinner fa-spin"></i>Loading cards...</div>';
    
    fetch(`https://${GetParentResourceName()}/getCards`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    }).then(response => response.json())
    .then(cards => {
        myCards = cards;
        displayCards(cards);
    });
}

function displayCards(cards) {
    if (cards.length === 0) {
        cardsList.innerHTML = createEmptyState('No business cards yet', 'fas fa-address-card');
        return;
    }
    
    cardsList.innerHTML = '';
    
    cards.forEach(card => {
        const cardElement = createCardElement(card);
        cardsList.appendChild(cardElement);
    });
}

function createCardElement(card) {
    const cardDiv = document.createElement('div');
    cardDiv.className = 'card-item';
    cardDiv.innerHTML = `
        <div class="card-item-header">
            <div class="card-item-info">
                <div class="card-item-title">${card.title}</div>
                <div class="card-item-job">${card.job_title || ''}</div>
            </div>
            <div class="card-item-actions">
                <button class="btn-danger" onclick="deleteCard(${card.id})">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        </div>
        <div class="card-item-description">${card.description}</div>
        <div class="card-item-meta">
            <span><i class="fas fa-phone"></i> ${card.phone || 'No phone'}</span>
            <span>Template: ${card.template}</span>
        </div>
    `;
    
    return cardDiv;
}

function deleteCard(cardId) {
    if (confirm('Are you sure you want to delete this business card?')) {
        fetch(`https://${GetParentResourceName()}/deleteCard`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ cardId: cardId })
        }).then(() => {
            loadCards();
        });
    }
}

function loadCardsForSharing() {
    shareCardsList.innerHTML = '';
    
    if (myCards.length === 0) {
        shareCardsList.innerHTML = '<div class="empty-state">No cards available to share</div>';
        return;
    }
    
    myCards.forEach(card => {
        const cardDiv = document.createElement('div');
        cardDiv.className = 'share-card-item';
        cardDiv.innerHTML = `
            <div class="card-item-title">${card.title}</div>
            <div class="card-item-description">${card.description}</div>
        `;
        
        cardDiv.addEventListener('click', () => {
            // Remove previous selection
            document.querySelectorAll('.share-card-item').forEach(item => {
                item.classList.remove('selected');
            });
            
            // Select this card
            cardDiv.classList.add('selected');
            selectedCardForSharing = card.id;
        });
        
        shareCardsList.appendChild(cardDiv);
    });
}

function loadNearbyPlayers() {
    nearbyPlayersList.innerHTML = '<div class="loading"><i class="fas fa-spinner fa-spin"></i>Finding nearby players...</div>';
    
    fetch(`https://${GetParentResourceName()}/getNearbyPlayers`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    }).then(response => response.json())
    .then(players => {
        displayNearbyPlayers(players);
    });
}

function displayNearbyPlayers(players) {
    if (players.length === 0) {
        nearbyPlayersList.innerHTML = '<div class="empty-state">No players nearby</div>';
        return;
    }
    
    nearbyPlayersList.innerHTML = '';
    
    players.forEach(player => {
        const playerDiv = document.createElement('div');
        playerDiv.className = 'nearby-player';
        playerDiv.innerHTML = `
            <div class="player-info">
                <div class="player-name">${player.name}</div>
                <div class="player-distance">${player.distance}m away</div>
            </div>
            <button class="btn-primary" onclick="shareWithPlayer(${player.id})" ${!selectedCardForSharing ? 'disabled' : ''}>
                Share
            </button>
        `;
        
        nearbyPlayersList.appendChild(playerDiv);
    });
}

function shareWithPlayer(playerId) {
    if (!selectedCardForSharing) {
        alert('Please select a card to share first');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/shareCard`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ cardId: selectedCardForSharing })
    }).then(() => {
        loadNearbyPlayers();
    });
}

function createEmptyState(message, icon) {
    return `
        <div class="empty-state">
            <i class="${icon}"></i>
            <h4>${message}</h4>
            <p>Get started by creating your first business card!</p>
        </div>
    `;
}

// Handle ESC key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeApp();
    }
});

// Utility function for resource name
function GetParentResourceName() {
    return 'business_cards';
}
