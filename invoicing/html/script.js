// Invoicing App JavaScript
let playerData = {};
let config = {};
let selectedRecipient = null;

// DOM Elements
const app = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const tabBtns = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');

// Form elements
const recipientInput = document.getElementById('recipient');
const searchResults = document.getElementById('searchResults');
const amountInput = document.getElementById('amount');
const descriptionInput = document.getElementById('description');
const taxRateInput = document.getElementById('taxRate');
const sendInvoiceBtn = document.getElementById('sendInvoice');

// Preview elements
const subtotalSpan = document.getElementById('subtotal');
const taxAmountSpan = document.getElementById('taxAmount');
const totalSpan = document.getElementById('total');

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
    loadInvoices();
    setupEventListeners();
    updatePreview();
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
            const tabName = btn.dataset.tab;
            switchTab(tabName);
        });
    });
    
    // Form inputs
    recipientInput.addEventListener('input', handleRecipientSearch);
    amountInput.addEventListener('input', updatePreview);
    taxRateInput.addEventListener('input', updatePreview);
    
    // Send invoice
    sendInvoiceBtn.addEventListener('click', sendInvoice);
    
    // Click outside search results
    document.addEventListener('click', (e) => {
        if (!e.target.closest('.search-container')) {
            hideSearchResults();
        }
    });
}

function switchTab(tabName) {
    // Update tab buttons
    tabBtns.forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.tab === tabName) {
            btn.classList.add('active');
        }
    });
    
    // Update tab content
    tabContents.forEach(content => {
        content.classList.remove('active');
        if (content.id === `${tabName}-tab`) {
            content.classList.add('active');
        }
    });
    
    // Load data for specific tabs
    if (tabName === 'received' || tabName === 'sent') {
        loadInvoices();
    }
}

function handleRecipientSearch() {
    const query = recipientInput.value.trim();
    
    if (query.length < 2) {
        hideSearchResults();
        selectedRecipient = null;
        updateSendButton();
        return;
    }
    
    // Search for players
    fetch(`https://${GetParentResourceName()}/searchPlayers`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query: query })
    })
    .then(response => response.json())
    .then(players => {
        displaySearchResults(players);
    });
}

function displaySearchResults(players) {
    if (players.length === 0) {
        hideSearchResults();
        return;
    }
    
    searchResults.innerHTML = '';
    searchResults.classList.remove('hidden');
    
    players.forEach(player => {
        const resultDiv = document.createElement('div');
        resultDiv.className = 'search-result';
        resultDiv.innerHTML = `
            <div><strong>${player.name}</strong></div>
            <div style="font-size: 12px; color: #666;">${player.phone}</div>
        `;
        
        resultDiv.addEventListener('click', () => {
            selectRecipient(player);
        });
        
        searchResults.appendChild(resultDiv);
    });
}

function selectRecipient(player) {
    selectedRecipient = player;
    recipientInput.value = player.name;
    hideSearchResults();
    updateSendButton();
}

function hideSearchResults() {
    searchResults.classList.add('hidden');
}

function updatePreview() {
    const amount = parseFloat(amountInput.value) || 0;
    const taxRate = parseFloat(taxRateInput.value) / 100 || 0;
    const taxAmount = amount * taxRate;
    const total = amount + taxAmount;
    
    subtotalSpan.textContent = `$${amount.toFixed(2)}`;
    taxAmountSpan.textContent = `$${taxAmount.toFixed(2)}`;
    totalSpan.textContent = `$${total.toFixed(2)}`;
    
    updateSendButton();
}

function updateSendButton() {
    const hasRecipient = selectedRecipient !== null;
    const hasAmount = parseFloat(amountInput.value) > 0;
    const hasDescription = descriptionInput.value.trim().length > 0;
    
    sendInvoiceBtn.disabled = !(hasRecipient && hasAmount && hasDescription);
}

function sendInvoice() {
    const amount = parseFloat(amountInput.value);
    const description = descriptionInput.value.trim();
    const taxRate = parseFloat(taxRateInput.value) / 100;
    
    if (!selectedRecipient || amount <= 0 || !description) {
        return;
    }
    
    const invoiceData = {
        receiver_citizenid: selectedRecipient.citizenid,
        amount: amount,
        description: description,
        tax_rate: taxRate
    };
    
    fetch(`https://${GetParentResourceName()}/sendInvoice`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(invoiceData)
    }).then(() => {
        clearForm();
        // Switch to sent tab to see the new invoice
        switchTab('sent');
    });
}

function clearForm() {
    recipientInput.value = '';
    amountInput.value = '';
    descriptionInput.value = '';
    taxRateInput.value = config.DefaultTaxRate * 100 || 10;
    selectedRecipient = null;
    hideSearchResults();
    updatePreview();
}

function loadInvoices() {
    fetch(`https://${GetParentResourceName()}/getInvoices`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(invoices => {
        displayInvoices(invoices);
    });
}

function displayInvoices(invoices) {
    const receivedContainer = document.getElementById('receivedInvoices');
    const sentContainer = document.getElementById('sentInvoices');
    
    // Clear containers
    receivedContainer.innerHTML = '';
    sentContainer.innerHTML = '';
    
    // Filter invoices
    const receivedInvoices = invoices.filter(inv => inv.receiver_citizenid === playerData.citizenid);
    const sentInvoices = invoices.filter(inv => inv.sender_citizenid === playerData.citizenid);
    
    // Display received invoices
    if (receivedInvoices.length === 0) {
        receivedContainer.innerHTML = createEmptyState('No received invoices', 'inbox');
    } else {
        receivedInvoices.forEach(invoice => {
            receivedContainer.appendChild(createInvoiceElement(invoice, 'received'));
        });
    }
    
    // Display sent invoices
    if (sentInvoices.length === 0) {
        sentContainer.innerHTML = createEmptyState('No sent invoices', 'paper-plane');
    } else {
        sentInvoices.forEach(invoice => {
            sentContainer.appendChild(createInvoiceElement(invoice, 'sent'));
        });
    }
}

function createInvoiceElement(invoice, type) {
    const div = document.createElement('div');
    div.className = `invoice-item ${invoice.status}`;
    
    const totalAmount = invoice.amount + (invoice.amount * invoice.tax_rate);
    const isReceived = type === 'received';
    const otherParty = isReceived ? invoice.sender_name : invoice.receiver_name;
    
    div.innerHTML = `
        <div class="invoice-header">
            <div class="invoice-info">
                <h4>${isReceived ? 'From' : 'To'}: ${otherParty}</h4>
                <p>${invoice.description}</p>
                <p>Created: ${formatDate(invoice.created_at)}</p>
                ${invoice.expires_at ? `<p>Expires: ${formatDate(invoice.expires_at)}</p>` : ''}
            </div>
            <div class="invoice-amount">
                <div class="amount">$${totalAmount.toFixed(2)}</div>
                <div class="status ${invoice.status}">${invoice.status}</div>
            </div>
        </div>
        <div class="invoice-actions">
            ${createInvoiceActions(invoice, type)}
        </div>
    `;
    
    return div;
}

function createInvoiceActions(invoice, type) {
    let actions = '';
    
    if (type === 'received' && invoice.status === 'pending') {
        actions += `<button class="btn-secondary" onclick="payInvoice(${invoice.id})">
            <i class="fas fa-credit-card"></i> Pay Invoice
        </button>`;
    }
    
    if (type === 'sent' && invoice.status === 'pending') {
        actions += `<button class="btn-danger" onclick="deleteInvoice(${invoice.id})">
            <i class="fas fa-trash"></i> Delete
        </button>`;
    }
    
    return actions;
}

function createEmptyState(message, icon) {
    return `
        <div class="empty-state">
            <i class="fas fa-${icon}"></i>
            <h4>${message}</h4>
            <p>Nothing to show here yet.</p>
        </div>
    `;
}

function payInvoice(invoiceId) {
    fetch(`https://${GetParentResourceName()}/payInvoice`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ invoiceId: invoiceId })
    }).then(() => {
        loadInvoices();
    });
}

function deleteInvoice(invoiceId) {
    fetch(`https://${GetParentResourceName()}/deleteInvoice`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ invoiceId: invoiceId })
    }).then(() => {
        loadInvoices();
    });
}

function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// Handle ESC key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeApp();
    }
});

// Initialize form values
document.addEventListener('DOMContentLoaded', function() {
    taxRateInput.value = 10; // Default 10%
    updatePreview();
});
