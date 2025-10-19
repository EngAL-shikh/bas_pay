// BAS Payment Integration Guide - JavaScript Functions

// Global Variables
let currentStep = 1;
const totalSteps = 5;

// Initialize the guide
document.addEventListener('DOMContentLoaded', function() {
    updateProgress();
    initializeEventListeners();
});

// Update progress bar and text
function updateProgress() {
    const progress = (currentStep / totalSteps) * 100;
    const progressFill = document.getElementById('progressFill');
    const progressText = document.getElementById('progressText');
    
    if (progressFill) {
        progressFill.style.width = progress + '%';
    }
    
    if (progressText) {
        if (currentStep <= totalSteps) {
            progressText.textContent = `الخطوة ${currentStep} من ${totalSteps}`;
        } else {
            progressText.textContent = 'تم إكمال الدليل!';
        }
    }
}

// Complete a step and move to next
function completeStep(stepNumber) {
    // Mark current step as completed
    const currentStepElement = document.getElementById(`step${stepNumber}`);
    const stepNumberElement = document.getElementById(`step${stepNumber}Number`);
    
    if (stepNumberElement) {
        stepNumberElement.classList.remove('step-active');
        stepNumberElement.classList.add('step-completed');
        stepNumberElement.textContent = '✓';
    }
    
    // Hide current step with animation
    if (currentStepElement) {
        currentStepElement.style.opacity = '0';
        currentStepElement.style.transform = 'translateY(-20px)';
        
        setTimeout(() => {
            currentStepElement.classList.add('hidden');
            
            // Show next step
            currentStep++;
            if (currentStep <= totalSteps) {
                showStep(currentStep);
            } else {
                showCompletion();
            }
            
            updateProgress();
        }, 300);
    }
}

// Show a specific step
function showStep(stepNumber) {
    const stepElement = document.getElementById(`step${stepNumber}`);
    const stepNumberElement = document.getElementById(`step${stepNumber}Number`);
    
    if (stepElement && stepNumberElement) {
        stepElement.classList.remove('hidden');
        stepElement.style.opacity = '0';
        stepElement.style.transform = 'translateY(20px)';
        
        stepNumberElement.classList.add('step-active');
        
        // Animate in
        setTimeout(() => {
            stepElement.style.opacity = '1';
            stepElement.style.transform = 'translateY(0)';
            stepElement.classList.add('fade-in');
            
            // Scroll to top of the page
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }, 50);
    }
}

// Show completion screen
function showCompletion() {
    const completionElement = document.getElementById('completion');
    if (completionElement) {
        completionElement.classList.remove('hidden');
        completionElement.style.opacity = '0';
        completionElement.style.transform = 'translateY(20px)';
        
        setTimeout(() => {
            completionElement.style.opacity = '1';
            completionElement.style.transform = 'translateY(0)';
            completionElement.classList.add('fade-in');
            
            // Scroll to top of the page
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }, 50);
    }
    
    // Update progress to 100%
    const progressFill = document.getElementById('progressFill');
    if (progressFill) {
        progressFill.style.width = '100%';
    }
}

// Copy code to clipboard
function copyCode(elementId) {
    const codeElement = document.getElementById(elementId);
    if (!codeElement) return;
    
    const text = codeElement.textContent;
    
    navigator.clipboard.writeText(text).then(() => {
        showCopySuccess(elementId);
    }).catch(err => {
        console.error('Failed to copy text: ', err);
        showCopyError(elementId);
    });
}

// Show copy success feedback
function showCopySuccess(elementId) {
    const codeElement = document.getElementById(elementId);
    const button = codeElement.parentElement.querySelector('.copy-btn');
    
    if (button) {
        const originalText = button.textContent;
        const originalBg = button.style.background;
        
        button.textContent = 'تم النسخ!';
        button.style.background = '#22c55e';
        
        setTimeout(() => {
            button.textContent = originalText;
            button.style.background = originalBg;
        }, 2000);
    }
}

// Show copy error feedback
function showCopyError(elementId) {
    const codeElement = document.getElementById(elementId);
    const button = codeElement.parentElement.querySelector('.copy-btn');
    
    if (button) {
        const originalText = button.textContent;
        const originalBg = button.style.background;
        
        button.textContent = 'فشل النسخ';
        button.style.background = '#ef4444';
        
        setTimeout(() => {
            button.textContent = originalText;
            button.style.background = originalBg;
        }, 2000);
    }
}

// Test API endpoint
async function testInitiateAPI() {
    const baseUrl = document.getElementById('apiBaseUrl')?.value;
    const authToken = document.getElementById('authToken')?.value;
    const responseArea = document.getElementById('apiResponse');
    
    if (!responseArea) return;
    
    // Validate inputs
    if (!baseUrl || !authToken) {
        responseArea.textContent = 'يرجى إدخال Base URL و Auth Token';
        responseArea.className = 'response-area error-response';
        return;
    }
    
    // Show loading state
    responseArea.textContent = 'جاري إرسال الطلب...';
    responseArea.className = 'response-area';
    
    try {
        const response = await axios.post(`${baseUrl}/api/payment/initiate`, {
            amount: 1000,
            order_id: `test_${Date.now()}`,
            customer_id: 'test_customer',
            customer_name: 'عميل تجريبي',
            customer_phone: '777777777'
        }, {
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': `Bearer ${authToken}`
            },
            timeout: 10000 // 10 seconds timeout
        });
        
        // Show success response
        responseArea.textContent = JSON.stringify(response.data, null, 2);
        responseArea.className = 'response-area success-response';
        
        // Log success
        console.log('API Test Success:', response.data);
        
    } catch (error) {
        // Show error response
        let errorMessage = 'خطأ غير معروف';
        
        if (error.response) {
            // Server responded with error status
            errorMessage = `خطأ ${error.response.status}: ${error.response.data?.message || error.response.statusText}`;
        } else if (error.request) {
            // Request was made but no response received
            errorMessage = 'لا يمكن الوصول للخادم. تأكد من صحة URL';
        } else {
            // Something else happened
            errorMessage = error.message;
        }
        
        responseArea.textContent = errorMessage;
        responseArea.className = 'response-area error-response';
        
        // Log error
        console.error('API Test Error:', error);
    }
}

// Reset the entire guide
function resetGuide() {
    // Reset all steps
    for (let i = 1; i <= totalSteps; i++) {
        const stepElement = document.getElementById(`step${i}`);
        const stepNumberElement = document.getElementById(`step${i}Number`);
        
        if (stepElement) {
            stepElement.classList.add('hidden');
            stepElement.classList.remove('fade-in');
            stepElement.style.opacity = '';
            stepElement.style.transform = '';
        }
        
        if (stepNumberElement) {
            stepNumberElement.classList.remove('step-completed', 'step-active');
            stepNumberElement.textContent = i;
        }
    }
    
    // Hide completion
    const completionElement = document.getElementById('completion');
    if (completionElement) {
        completionElement.classList.add('hidden');
        completionElement.style.opacity = '';
        completionElement.style.transform = '';
    }
    
    // Reset to step 1
    currentStep = 1;
    showStep(1);
    updateProgress();
    
    // Scroll to top
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Initialize event listeners
function initializeEventListeners() {
    // Add keyboard navigation
    document.addEventListener('keydown', function(e) {
        if (e.key === 'ArrowRight' && currentStep < totalSteps) {
            completeStep(currentStep);
        } else if (e.key === 'ArrowLeft' && currentStep > 1) {
            // Go back to previous step
            goToStep(currentStep - 1);
        }
    });
    
    // Add smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
    
    // Add form validation
    const inputs = document.querySelectorAll('input[required]');
    inputs.forEach(input => {
        input.addEventListener('blur', validateInput);
        input.addEventListener('input', clearValidation);
    });
}

// Go to specific step
function goToStep(stepNumber) {
    if (stepNumber < 1 || stepNumber > totalSteps) return;
    
    // Hide current step
    const currentStepElement = document.getElementById(`step${currentStep}`);
    if (currentStepElement) {
        currentStepElement.classList.add('hidden');
    }
    
    // Update current step
    currentStep = stepNumber;
    
    // Show target step
    showStep(stepNumber);
    updateProgress();
}

// Go to previous step
function goToPreviousStep() {
    if (currentStep > 1) {
        goToStep(currentStep - 1);
        // Scroll to top of the page
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
}

// Validate input field
function validateInput(e) {
    const input = e.target;
    const value = input.value.trim();
    
    if (!value) {
        input.classList.add('border-red-500');
        showInputError(input, 'هذا الحقل مطلوب');
    } else {
        input.classList.remove('border-red-500');
        clearInputError(input);
    }
}

// Clear validation error
function clearValidation(e) {
    const input = e.target;
    input.classList.remove('border-red-500');
    clearInputError(input);
}

// Show input error
function showInputError(input, message) {
    clearInputError(input);
    
    const errorDiv = document.createElement('div');
    errorDiv.className = 'text-red-500 text-sm mt-1 input-error';
    errorDiv.textContent = message;
    
    input.parentNode.appendChild(errorDiv);
}

// Clear input error
function clearInputError(input) {
    const errorDiv = input.parentNode.querySelector('.input-error');
    if (errorDiv) {
        errorDiv.remove();
    }
}

// Utility function to format JSON
function formatJSON(obj) {
    return JSON.stringify(obj, null, 2);
}

// Utility function to debounce function calls
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Export functions for global access
window.completeStep = completeStep;
window.copyCode = copyCode;
window.testInitiateAPI = testInitiateAPI;
window.resetGuide = resetGuide;
window.goToPreviousStep = goToPreviousStep;
