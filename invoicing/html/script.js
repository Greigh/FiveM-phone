// Invoicing App JavaScript
let playerData = {};
let config = {};
let selectedRecipient = null;
let playerBusinesses = [];

// DOM Elements
const app = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const tabBtns = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');

// Form elements
const senderTypeSelect = document.getElementById('senderType');
const businessSenderGroup = document.getElementById('businessSenderGroup');
const senderBusinessSelect = document.getElementById('senderBusiness');
const recipientInput = document.getElementById('recipient');
const recipientTypeSelect = document.getElementById('recipientType');
const searchResults = document.getElementById('searchResults');
const amountInput = document.getElementById('amount');
const descriptionInput = document.getElementById('description');
const taxRateInput = document.getElementById('taxRate');
const taxExemptInput = document.getElementById('taxExempt');
const dueDateInput = document.getElementById('dueDate');
const notesInput = document.getElementById('notes');
const sendInvoiceBtn = document.getElementById('sendInvoice');

// Commission elements
const enableCommissionInput = document.getElementById('enableCommission');
const commissionOptions = document.getElementById('commissionOptions');
const commissionTypeSelect = document.getElementById('commissionType');
const commissionValueInput = document.getElementById('commissionValue');
const commissionRecipientSelect = document.getElementById('commissionRecipient');
const customRecipientSearch = document.getElementById('customRecipientSearch');
const customCommissionRecipientInput = document.getElementById('customCommissionRecipient');
const commissionSearchResults = document.getElementById('commissionSearchResults');

// Business elements
const createBusinessBtn = document.getElementById('createBusinessBtn');
const businessModal = document.getElementById('businessModal');
const businessesList = document.getElementById('businessesList');

// Preview elements
const subtotalSpan = document.getElementById('subtotal');
const taxAmountSpan = document.getElementById('taxAmount');
const taxRateDisplay = document.getElementById('taxRateDisplay');
const taxPreviewRow = document.getElementById('taxPreviewRow');
const commissionAmountSpan = document.getElementById('commissionAmount');
const commissionDisplay = document.getElementById('commissionDisplay');
const commissionUnit = document.getElementById('commissionUnit');
const commissionPreviewRow = document.getElementById('commissionPreviewRow');
const totalSpan = document.getElementById('total');
const netAmountSpan = document.getElementById('netAmount');

// Commission variables
let selectedCommissionRecipient = null;

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
    loadBusinesses();
    setupEventListeners();
    setupCommissionEventListeners();
    updatePreview();
    updateTaxRate();
    updateMaxAmount();
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
    senderTypeSelect.addEventListener('change', handleSenderTypeChange);
    recipientInput.addEventListener('input', handleRecipientSearch);
    recipientTypeSelect.addEventListener('change', updateRecipientSearch);
    amountInput.addEventListener('input', updatePreview);
    taxRateInput.addEventListener('input', updatePreview);
    
    // Send invoice
    sendInvoiceBtn.addEventListener('click', sendInvoice);
    
    // Business creation
    createBusinessBtn.addEventListener('click', openBusinessModal);
    
    // Commission and tax event listeners
    setupCommissionEventListeners();
    
    // Click outside search results
    document.addEventListener('click', (e) => {
        if (!e.target.closest('.search-container')) {
            hideSearchResults();
            hideCommissionSearchResults();
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
    } else if (tabName === 'businesses') {
        loadBusinesses();
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
    const taxRate = taxExemptInput.checked ? 0 : (parseFloat(taxRateInput.value) / 100 || 0);
    const taxAmount = amount * taxRate;
    
    // Commission calculation
    let commissionAmount = 0;
    if (enableCommissionInput.checked && commissionValueInput.value) {
        const commissionValue = parseFloat(commissionValueInput.value) || 0;
        const commissionType = commissionTypeSelect.value;
        
        if (commissionType === 'percentage') {
            commissionAmount = amount * (commissionValue / 100);
        } else {
            commissionAmount = commissionValue;
        }
        
        // Update commission display
        commissionDisplay.textContent = commissionValue;
        commissionAmountSpan.textContent = `$${commissionAmount.toFixed(2)}`;
        commissionPreviewRow.classList.remove('hidden');
    } else {
        commissionPreviewRow.classList.add('hidden');
    }
    
    const totalAmount = amount + taxAmount;
    const netAmount = amount - commissionAmount; // Amount recipient gets after commission
    
    // Update displays
    subtotalSpan.textContent = `$${amount.toFixed(2)}`;
    taxRateDisplay.textContent = (taxRate * 100).toFixed(1);
    taxAmountSpan.textContent = `$${taxAmount.toFixed(2)}`;
    totalSpan.textContent = `$${totalAmount.toFixed(2)}`;
    netAmountSpan.textContent = `$${netAmount.toFixed(2)}`;
    
    // Handle tax exempt styling
    if (taxExemptInput.checked) {
        taxPreviewRow.classList.add('tax-exempt');
    } else {
        taxPreviewRow.classList.remove('tax-exempt');
    }
    
    updateSendButton();
}

function updateSendButton() {
    const hasRecipient = selectedRecipient !== null;
    const hasAmount = parseFloat(amountInput.value) > 0;
    const hasDescription = descriptionInput.value.trim().length > 0;
    
    sendInvoiceBtn.disabled = !(hasRecipient && hasAmount && hasDescription);
}

function sendInvoice() {
    const senderType = senderTypeSelect.value;
    const recipientType = recipientTypeSelect.value;
    const amount = parseFloat(amountInput.value);
    const description = descriptionInput.value.trim();
    const taxRate = taxExemptInput.checked ? 0 : (parseFloat(taxRateInput.value) / 100);
    const dueDate = dueDateInput.value;
    const notes = notesInput.value.trim();
    
    if (!selectedRecipient || amount <= 0 || !description) {
        alert('Please fill in all required fields');
        return;
    }

    let invoiceData = {
        receiver_citizenid: selectedRecipient.citizenid,
        amount: amount,
        description: description,
        tax_rate: taxRate,
        tax_exempt: taxExemptInput.checked,
        sender_type: senderType,
        receiver_type: recipientType
    };

    // Add business information if sending from business
    if (senderType === 'business') {
        const businessId = senderBusinessSelect.value;
        if (!businessId) {
            alert('Please select a business to send from');
            return;
        }
        invoiceData.sender_business_id = parseInt(businessId);
    }

    // Add commission information if enabled
    if (enableCommissionInput.checked && commissionValueInput.value) {
        const commissionValue = parseFloat(commissionValueInput.value);
        const commissionType = commissionTypeSelect.value;
        
        if (!selectedCommissionRecipient) {
            alert('Please select a commission recipient');
            return;
        }
        
        invoiceData.commission_enabled = true;
        invoiceData.commission_type = commissionType;
        invoiceData.commission_value = commissionValue;
        invoiceData.commission_recipient_id = selectedCommissionRecipient.citizenid;
        invoiceData.commission_recipient_name = selectedCommissionRecipient.name;
        invoiceData.commission_recipient_type = selectedCommissionRecipient.type || 'player';
    }

    // Add optional fields
    if (dueDate) {
        invoiceData.due_date = dueDate;
    }
    if (notes) {
        invoiceData.notes = notes;
    }
    
    fetch(`https://${GetParentResourceName()}/sendInvoice`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(invoiceData)
    }).then(response => response.json())
    .then(result => {
        if (result.success) {
            clearForm();
            switchTab('sent');
        } else {
            alert(result.message || 'Failed to send invoice');
        }
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

// Business functions
function openBusinessModal() {
    businessModal.classList.remove('hidden');
}

function closeBusinessModal() {
    businessModal.classList.add('hidden');
    clearBusinessForm();
}

function clearBusinessForm() {
    document.getElementById('businessName').value = '';
    document.getElementById('businessType').value = 'retail';
    document.getElementById('businessPhone').value = '';
    document.getElementById('businessEmail').value = '';
    document.getElementById('businessAddress').value = '';
}

function createBusiness() {
    const businessData = {
        name: document.getElementById('businessName').value.trim(),
        business_type: document.getElementById('businessType').value,
        phone: document.getElementById('businessPhone').value.trim(),
        email: document.getElementById('businessEmail').value.trim(),
        address: document.getElementById('businessAddress').value.trim(),
        default_commission_rate: parseFloat(document.getElementById('defaultCommissionRate').value) / 100,
        auto_tax_payment: document.getElementById('autoTaxPayment').checked,
        tax_exempt: document.getElementById('taxExemptBusiness').checked
    };

    if (!businessData.name || businessData.name.length < 3) {
        alert('Business name must be at least 3 characters long');
        return;
    }

    fetch(`https://${GetParentResourceName()}/createBusiness`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(businessData)
    }).then(response => response.json())
    .then(result => {
        if (result.success) {
            closeBusinessModal();
            loadBusinesses();
        } else {
            alert(result.message || 'Failed to create business');
        }
    });
}

function loadBusinesses() {
    fetch(`https://${GetParentResourceName()}/getBusinesses`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(businesses => {
        playerBusinesses = businesses;
        displayBusinesses(businesses);
        updateBusinessDropdown(businesses);
    });
}

function displayBusinesses(businesses) {
    if (businesses.length === 0) {
        businessesList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-building"></i>
                <h4>No Businesses Yet</h4>
                <p>Create your first business to start sending business invoices</p>
            </div>
        `;
        return;
    }

    businessesList.innerHTML = '';
    businesses.forEach(business => {
        const businessElement = createBusinessElement(business);
        businessesList.appendChild(businessElement);
    });
}

function createBusinessElement(business) {
    const div = document.createElement('div');
    div.className = 'business-item';
    
    let badges = '';
    if (business.tax_exempt) {
        badges += '<span class="tax-exempt-badge">Tax Exempt</span> ';
    }
    if (business.default_commission_rate > 0) {
        badges += `<span class="commission-badge">${(business.default_commission_rate * 100).toFixed(1)}% Commission</span>`;
    }
    
    div.innerHTML = `
        <div class="business-header">
            <div class="business-info">
                <h4>${business.name} ${badges}</h4>
                <p><i class="fas fa-tag"></i> ${business.business_type}</p>
                <p><i class="fas fa-calendar"></i> Created ${formatDate(business.created_at)}</p>
            </div>
            <div class="business-status">
                <span class="status ${business.status}">${business.status}</span>
            </div>
        </div>
        <div class="business-details">
            ${business.phone ? `<p><i class="fas fa-phone"></i> ${business.phone}</p>` : ''}
            ${business.email ? `<p><i class="fas fa-envelope"></i> ${business.email}</p>` : ''}
            ${business.address ? `<p><i class="fas fa-map-marker-alt"></i> ${business.address}</p>` : ''}
        </div>
        <div class="commission-info">
            <p><i class="fas fa-percentage"></i> Default Commission: ${(business.default_commission_rate * 100).toFixed(1)}%</p>
            <p><i class="fas fa-coins"></i> Auto Tax Payment: ${business.auto_tax_payment ? 'Yes' : 'No'}</p>
            ${business.tax_exempt ? '<p><i class="fas fa-shield-alt"></i> Tax Exempt Status</p>' : ''}
        </div>
        <div class="business-actions">
            <button class="btn-secondary" onclick="editBusiness(${business.id})">
                <i class="fas fa-edit"></i> Edit
            </button>
            <button class="btn-danger" onclick="deleteBusiness(${business.id})">
                <i class="fas fa-trash"></i> Delete
            </button>
        </div>
    `;
    
    return div;
}

function updateBusinessDropdown(businesses) {
    senderBusinessSelect.innerHTML = '<option value="">Select a business...</option>';
    businesses.forEach(business => {
        const option = document.createElement('option');
        option.value = business.id;
        option.textContent = business.name;
        senderBusinessSelect.appendChild(option);
    });
}

function editBusiness(businessId) {
    // TODO: Implement business editing
    console.log('Edit business:', businessId);
}

function deleteBusiness(businessId) {
    if (!confirm('Are you sure you want to delete this business?')) {
        return;
    }

    fetch(`https://${GetParentResourceName()}/deleteBusiness`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ businessId: businessId })
    }).then(response => response.json())
    .then(result => {
        if (result.success) {
            loadBusinesses();
        } else {
            alert(result.message || 'Failed to delete business');
        }
    });
}

// Update sender type change handler
function handleSenderTypeChange() {
    const senderType = senderTypeSelect.value;
    if (senderType === 'business') {
        businessSenderGroup.style.display = 'block';
        if (playerBusinesses.length === 0) {
            loadBusinesses();
        }
    } else {
        businessSenderGroup.style.display = 'none';
    }
    updateTaxRate();
    updateMaxAmount();
}

function updateTaxRate() {
    const senderType = senderTypeSelect.value;
    if (senderType === 'business' && config.BusinessTaxRate) {
        taxRateInput.value = (config.BusinessTaxRate * 100).toFixed(1);
    } else {
        taxRateInput.value = (config.DefaultTaxRate * 100).toFixed(1);
    }
    updatePreview();
}

function updateMaxAmount() {
    const senderType = senderTypeSelect.value;
    const maxAmount = senderType === 'business' ? 
        (config.MaxBusinessInvoiceAmount || 100000) : 
        (config.MaxInvoiceAmount || 50000);
    
    amountInput.max = maxAmount;
}

// Commission and Tax Functions
function setupCommissionEventListeners() {
    enableCommissionInput.addEventListener('change', toggleCommissionOptions);
    commissionTypeSelect.addEventListener('change', updateCommissionDisplay);
    commissionValueInput.addEventListener('input', updatePreview);
    commissionRecipientSelect.addEventListener('change', handleCommissionRecipientChange);
    taxExemptInput.addEventListener('change', updatePreview);
    customCommissionRecipientInput.addEventListener('input', handleCommissionRecipientSearch);
}

function toggleCommissionOptions() {
    if (enableCommissionInput.checked) {
        commissionOptions.classList.remove('hidden');
        // Set default commission value if empty
        if (!commissionValueInput.value) {
            commissionValueInput.value = config.DefaultCommissionRate * 100 || 5;
        }
    } else {
        commissionOptions.classList.add('hidden');
        selectedCommissionRecipient = null;
    }
    updatePreview();
}

function updateCommissionDisplay() {
    const type = commissionTypeSelect.value;
    commissionUnit.textContent = type === 'percentage' ? '%' : '';
    updatePreview();
}

function handleCommissionRecipientChange() {
    const selected = commissionRecipientSelect.value;
    
    if (selected === 'custom') {
        customRecipientSearch.classList.remove('hidden');
        selectedCommissionRecipient = null;
    } else {
        customRecipientSearch.classList.add('hidden');
        
        if (selected === 'government') {
            selectedCommissionRecipient = {
                citizenid: 'GOV001',
                name: 'Government Tax Authority',
                type: 'government'
            };
            commissionValueInput.value = 3;
        } else if (selected === 'broker') {
            selectedCommissionRecipient = {
                citizenid: 'BROKER001',
                name: 'Business Broker',
                type: 'business'
            };
            commissionValueInput.value = 2;
        } else {
            selectedCommissionRecipient = null;
        }
    }
    updatePreview();
}

function handleCommissionRecipientSearch() {
    const query = customCommissionRecipientInput.value.trim();
    
    if (query.length < 2) {
        hideCommissionSearchResults();
        selectedCommissionRecipient = null;
        return;
    }
    
    // Search for players/businesses for commission
    fetch(`https://${GetParentResourceName()}/searchCommissionRecipients`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query: query })
    })
    .then(response => response.json())
    .then(recipients => {
        displayCommissionSearchResults(recipients);
    });
}

function displayCommissionSearchResults(recipients) {
    if (recipients.length === 0) {
        commissionSearchResults.innerHTML = '<div class="search-result">No recipients found</div>';
        commissionSearchResults.classList.remove('hidden');
        return;
    }
    
    commissionSearchResults.innerHTML = '';
    commissionSearchResults.classList.remove('hidden');
    
    recipients.forEach(recipient => {
        const div = document.createElement('div');
        div.className = 'search-result';
        div.innerHTML = `<strong>${recipient.name}</strong><br><small>${recipient.type}</small>`;
        div.onclick = () => selectCommissionRecipient(recipient);
        commissionSearchResults.appendChild(div);
    });
}

function selectCommissionRecipient(recipient) {
    selectedCommissionRecipient = recipient;
    customCommissionRecipientInput.value = recipient.name;
    hideCommissionSearchResults();
}

function hideCommissionSearchResults() {
    commissionSearchResults.classList.add('hidden');
}
