// Calculator App JavaScript
let config = {};
let currentInput = '0';
let previousInput = '';
let operator = '';
let shouldResetDisplay = false;
let history = [];

// DOM Elements
const app = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const historyDisplay = document.getElementById('history');
const currentDisplay = document.getElementById('current');
const historyList = document.getElementById('historyList');

// Initialize app
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openApp') {
        config = data.config;
        openApp();
    }
});

function openApp() {
    app.classList.remove('hidden');
    setupEventListeners();
    loadHistory();
    updateDisplay();
}

function closeApp() {
    app.classList.add('hidden');
    
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
    
    // Keyboard support
    document.addEventListener('keydown', handleKeyboard);
}

function handleKeyboard(event) {
    const key = event.key;
    
    // Numbers
    if (key >= '0' && key <= '9') {
        inputNumber(key);
    }
    // Operators
    else if (key === '+') {
        setOperator('+');
    }
    else if (key === '-') {
        setOperator('-');
    }
    else if (key === '*') {
        setOperator('×');
    }
    else if (key === '/') {
        event.preventDefault();
        setOperator('÷');
    }
    // Actions
    else if (key === 'Enter' || key === '=') {
        event.preventDefault();
        calculate();
    }
    else if (key === 'Escape') {
        clearAll();
    }
    else if (key === 'Backspace') {
        backspace();
    }
    else if (key === '.') {
        inputDecimal();
    }
}

function inputNumber(num) {
    if (shouldResetDisplay) {
        currentInput = num;
        shouldResetDisplay = false;
    } else {
        if (currentInput === '0') {
            currentInput = num;
        } else {
            if (currentInput.length < config.MaxDigits) {
                currentInput += num;
            }
        }
    }
    updateDisplay();
}

function inputDecimal() {
    if (shouldResetDisplay) {
        currentInput = '0.';
        shouldResetDisplay = false;
    } else {
        if (!currentInput.includes('.')) {
            currentInput += '.';
        }
    }
    updateDisplay();
}

function setOperator(op) {
    if (operator && !shouldResetDisplay) {
        calculate();
    }
    
    previousInput = currentInput;
    operator = op;
    shouldResetDisplay = true;
    
    historyDisplay.textContent = `${previousInput} ${operator}`;
    
    // Update operator button states
    document.querySelectorAll('.btn-operator').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Find and highlight current operator
    const operatorSymbols = {'+': '+', '-': '−', '×': '×', '÷': '÷'};
    document.querySelectorAll('.btn-operator').forEach(btn => {
        if (btn.textContent === operatorSymbols[op]) {
            btn.classList.add('active');
        }
    });
}

function calculate() {
    if (!operator || shouldResetDisplay) return;
    
    const prev = parseFloat(previousInput);
    const current = parseFloat(currentInput);
    let result;
    
    switch (operator) {
        case '+':
            result = prev + current;
            break;
        case '-':
            result = prev - current;
            break;
        case '×':
            result = prev * current;
            break;
        case '÷':
            if (current === 0) {
                showError('Cannot divide by zero');
                return;
            }
            result = prev / current;
            break;
        default:
            return;
    }
    
    // Format result
    result = parseFloat(result.toPrecision(12));
    
    // Add to history
    const expression = `${previousInput} ${operator} ${currentInput}`;
    addToHistory(expression, result.toString());
    
    // Update display
    currentInput = result.toString();
    operator = '';
    previousInput = '';
    shouldResetDisplay = true;
    
    historyDisplay.textContent = '';
    updateDisplay();
    
    // Remove operator highlighting
    document.querySelectorAll('.btn-operator').forEach(btn => {
        btn.classList.remove('active');
    });
}

function clearAll() {
    currentInput = '0';
    previousInput = '';
    operator = '';
    shouldResetDisplay = false;
    historyDisplay.textContent = '';
    updateDisplay();
    
    // Remove operator highlighting
    document.querySelectorAll('.btn-operator').forEach(btn => {
        btn.classList.remove('active');
    });
}

function clearEntry() {
    currentInput = '0';
    shouldResetDisplay = false;
    updateDisplay();
}

function backspace() {
    if (currentInput.length > 1) {
        currentInput = currentInput.slice(0, -1);
    } else {
        currentInput = '0';
    }
    updateDisplay();
}

function toggleSign() {
    if (currentInput !== '0') {
        if (currentInput.startsWith('-')) {
            currentInput = currentInput.substring(1);
        } else {
            currentInput = '-' + currentInput;
        }
        updateDisplay();
    }
}

function updateDisplay() {
    currentDisplay.textContent = currentInput;
    
    // Remove error class if present
    document.querySelector('.display').classList.remove('error');
}

function showError(message) {
    currentDisplay.textContent = message;
    document.querySelector('.display').classList.add('error');
    
    setTimeout(() => {
        clearAll();
    }, 2000);
}

function addToHistory(expression, result) {
    if (!config.EnableHistory) return;
    
    const historyItem = {
        expression: expression,
        result: result,
        timestamp: new Date().toLocaleTimeString()
    };
    
    history.unshift(historyItem);
    
    // Limit history size
    if (history.length > config.MaxHistory) {
        history = history.slice(0, config.MaxHistory);
    }
    
    updateHistoryDisplay();
    saveHistory();
}

function updateHistoryDisplay() {
    if (history.length === 0) {
        historyList.innerHTML = '<div class="empty-history">No calculations yet</div>';
        return;
    }
    
    historyList.innerHTML = '';
    
    history.forEach((item, index) => {
        const historyItem = document.createElement('div');
        historyItem.className = 'history-item';
        historyItem.innerHTML = `
            <div class="history-expression">${item.expression}</div>
            <div class="history-result">${item.result}</div>
        `;
        
        historyItem.addEventListener('click', () => {
            currentInput = item.result;
            shouldResetDisplay = true;
            updateDisplay();
        });
        
        historyList.appendChild(historyItem);
    });
}

function clearHistory() {
    history = [];
    updateHistoryDisplay();
    saveHistory();
}

function saveHistory() {
    localStorage.setItem('calculator_history', JSON.stringify(history));
}

function loadHistory() {
    const saved = localStorage.getItem('calculator_history');
    if (saved) {
        history = JSON.parse(saved);
        updateHistoryDisplay();
    }
}

// Handle ESC key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && event.ctrlKey) {
        closeApp();
    }
});

// Utility function for resource name
function GetParentResourceName() {
    return 'calculator';
}
