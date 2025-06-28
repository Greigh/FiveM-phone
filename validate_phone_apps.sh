#!/bin/bash

# FiveM Phone Apps Validation Script
# Validates the structure and configuration of all phone apps
# Designed for standalone phone apps repository

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
SUCCESS=0

# Print functions
print_header() {
    echo -e "${CYAN}📱 FiveM Phone Apps Validation${NC}"
    echo "=================================="
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((SUCCESS++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_section() {
    echo -e "\n${PURPLE}📋 $1${NC}"
}

# Validation functions
check_file_exists() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        print_success "$description exists"
        return 0
    else
        print_error "$description missing: $file"
        return 1
    fi
}

check_dir_exists() {
    local dir="$1"
    local description="$2"
    
    if [[ -d "$dir" ]]; then
        print_success "$description directory exists"
        return 0
    else
        print_error "$description directory missing: $dir"
        return 1
    fi
}

validate_manifest() {
    local manifest="$1"
    local app_name="$2"
    
    if [[ ! -f "$manifest" ]]; then
        print_error "$app_name: fxmanifest.lua missing"
        return 1
    fi
    
    # Check required fields
    if grep -q "fx_version" "$manifest"; then
        print_success "$app_name: fxmanifest.lua has fx_version"
    else
        print_error "$app_name: fxmanifest.lua missing fx_version"
    fi
    
    if grep -q "game.*gta5" "$manifest"; then
        print_success "$app_name: fxmanifest.lua configured for GTA5"
    else
        print_error "$app_name: fxmanifest.lua not configured for GTA5"
    fi
    
    if grep -q "shared/phone_framework.lua" "$manifest"; then
        print_success "$app_name: fxmanifest.lua includes phone framework"
    else
        print_warning "$app_name: fxmanifest.lua missing phone framework reference"
    fi
    
    if grep -q "ox_lib" "$manifest"; then
        print_success "$app_name: fxmanifest.lua includes ox_lib dependency"
    else
        print_warning "$app_name: fxmanifest.lua missing ox_lib dependency"
    fi
}

validate_config() {
    local config="$1"
    local app_name="$2"
    
    if [[ ! -f "$config" ]]; then
        print_error "$app_name: config.lua missing"
        return 1
    fi
    
    # Check for required config sections
    if grep -q "Config\.PhoneApp" "$config"; then
        print_success "$app_name: config.lua has PhoneApp configuration"
    else
        print_error "$app_name: config.lua missing PhoneApp configuration"
    fi
    
    if grep -q "identifier.*=" "$config"; then
        print_success "$app_name: config.lua has app identifier"
    else
        print_error "$app_name: config.lua missing app identifier"
    fi
}

validate_client() {
    local client="$1"
    local app_name="$2"
    
    if [[ ! -f "$client" ]]; then
        print_error "$app_name: client script missing"
        return 1
    fi
    
    # Check for phone framework usage
    if grep -q "require.*phone_framework" "$client"; then
        print_success "$app_name: client uses phone framework"
    else
        print_error "$app_name: client missing phone framework require"
    fi
    
    # Check for NUI callbacks
    if grep -q "RegisterNUICallback" "$client"; then
        print_success "$app_name: client has NUI callbacks"
    else
        print_info "$app_name: client has no NUI callbacks (may be normal)"
    fi
}

validate_html_structure() {
    local html_dir="$1"
    local app_name="$2"
    
    if [[ ! -d "$html_dir" ]]; then
        print_warning "$app_name: html directory missing (calculator app is OK)"
        return 0
    fi
    
    check_file_exists "$html_dir/index.html" "$app_name: HTML main file"
    check_file_exists "$html_dir/style.css" "$app_name: CSS file"
    check_file_exists "$html_dir/script.js" "$app_name: JavaScript file"
    
    # Check for responsive design indicators
    if [[ -f "$html_dir/style.css" ]]; then
        if grep -q "@media" "$html_dir/style.css"; then
            print_success "$app_name: CSS includes responsive design"
        else
            print_info "$app_name: CSS may not be responsive"
        fi
    fi
}

validate_sql() {
    local sql="$1"
    local app_name="$2"
    
    if [[ -f "$sql" ]]; then
        print_success "$app_name: SQL file exists"
        
        # Check for proper table creation
        if grep -q "CREATE TABLE" "$sql"; then
            print_success "$app_name: SQL creates tables"
        else
            print_error "$app_name: SQL file missing table creation"
        fi
        
        # Check for IF NOT EXISTS
        if grep -q "IF NOT EXISTS" "$sql"; then
            print_success "$app_name: SQL uses IF NOT EXISTS"
        else
            print_warning "$app_name: SQL missing IF NOT EXISTS (may cause installation issues)"
        fi
    else
        print_info "$app_name: No SQL file (may not need database)"
    fi
}

validate_app() {
    local app_dir="$1"
    local app_name="$2"
    
    print_section "Validating $app_name App"
    
    # Check directory structure
    check_dir_exists "$app_dir" "$app_name"
    
    if [[ ! -d "$app_dir" ]]; then
        return 1
    fi
    
    # Check required files
    validate_manifest "$app_dir/fxmanifest.lua" "$app_name"
    validate_config "$app_dir/config.lua" "$app_name"
    
    # Check client directory
    if check_dir_exists "$app_dir/client" "$app_name client"; then
        validate_client "$app_dir/client/client.lua" "$app_name"
    fi
    
    # Check server directory (optional for some apps)
    if [[ -d "$app_dir/server" ]]; then
        check_file_exists "$app_dir/server/server.lua" "$app_name: server script"
    fi
    
    # Check HTML structure
    validate_html_structure "$app_dir/html" "$app_name"
    
    # Check SQL file
    validate_sql "$app_dir/sql.sql" "$app_name"
}

# Main validation
main() {
    print_header
    
    # Check if we're in the right directory
    if [[ ! -d "shared" ]]; then
        print_error "Please run this script from the phone_apps directory"
        exit 1
    fi
    
    print_section "Checking Core Components"
    
    # Validate shared framework
    check_file_exists "shared/phone_framework.lua" "Universal phone framework"
    
    # Check Lua diagnostics configuration
    check_file_exists ".luarc.json" "Lua diagnostics configuration"
    
    # Check documentation
    check_file_exists "README.md" "Main documentation"
    check_file_exists "LB_PHONE_SETUP.md" "LB Phone setup guide"
    
    # Check installation script
    check_file_exists "install.sh" "Installation script"
    
    print_section "Validating Individual Apps"
    
    # List of expected apps
    APPS=("invoicing" "notes" "business_cards" "calculator" "gallery")
    
    for app in "${APPS[@]}"; do
        validate_app "$app" "$app"
    done
    
    print_section "Framework Compatibility Check"
    
    # Check if shared framework supports all frameworks
    if [[ -f "shared/phone_framework.lua" ]]; then
        if grep -q "es_extended" "shared/phone_framework.lua"; then
            print_success "ESX framework support detected"
        else
            print_warning "ESX framework support missing"
        fi
        
        if grep -q "qb-core" "shared/phone_framework.lua"; then
            print_success "QBCore framework support detected"
        else
            print_warning "QBCore framework support missing"
        fi
        
        if grep -q "qbx_core" "shared/phone_framework.lua"; then
            print_success "QBX framework support detected"
        else
            print_warning "QBX framework support missing"
        fi
        
        # Check phone system support
        if grep -q "lb-phone" "shared/phone_framework.lua"; then
            print_success "LB Phone support detected"
        else
            print_warning "LB Phone support missing"
        fi
        
        if grep -q "qb-phone" "shared/phone_framework.lua"; then
            print_success "QB Phone support detected"
        else
            print_warning "QB Phone support missing"
        fi
    fi
    
    print_section "Code Quality Checks"
    
    # Check for common issues
    print_info "Checking for common coding issues..."
    
    # Check for hardcoded framework references
    if grep -r "QBCore\." --include="*.lua" . | grep -v "phone_framework.lua" | grep -q .; then
        print_warning "Found hardcoded QBCore references (should use PhoneApps functions)"
    else
        print_success "No hardcoded QBCore references found"
    fi
    
    if grep -r "ESX\." --include="*.lua" . | grep -v "phone_framework.lua" | grep -q .; then
        print_warning "Found hardcoded ESX references (should use PhoneApps functions)"
    else
        print_success "No hardcoded ESX references found"
    fi
    
    # Check for console.log in JavaScript (should use proper logging)
    if grep -r "console\.log" --include="*.js" . | grep -q .; then
        print_info "Found console.log statements in JavaScript (consider removing for production)"
    fi
    
    print_section "Validation Summary"
    echo "====================="
    
    if [[ $ERRORS -eq 0 ]]; then
        print_success "🎉 Perfect! No errors found."
        echo -e "${GREEN}The phone apps are ready for distribution!${NC}"
    else
        print_error "Found $ERRORS error(s) that need to be fixed."
    fi
    
    if [[ $WARNINGS -gt 0 ]]; then
        print_warning "Found $WARNINGS warning(s) - review recommended."
    fi
    
    echo -e "\n${CYAN}📊 Results Summary:${NC}"
    echo -e "✅ Successful checks: ${GREEN}$SUCCESS${NC}"
    echo -e "⚠️  Warnings: ${YELLOW}$WARNINGS${NC}"
    echo -e "❌ Errors: ${RED}$ERRORS${NC}"
    
    # App structure information
    echo -e "\n${PURPLE}📱 Phone Apps Structure:${NC}"
    echo "========================="
    
    for app in "${APPS[@]}"; do
        if [[ -d "$app" ]]; then
            echo -e "📱 ${CYAN}$app${NC}: Universal phone app"
            
            # Show size information
            if [[ -f "$app/config.lua" ]]; then
                local size=$(grep -o "size.*=.*[0-9]" "$app/config.lua" 2>/dev/null | grep -o "[0-9]*" | head -1)
                if [[ -n "$size" ]]; then
                    echo "   📏 Size: ${size} KB"
                fi
            fi
            
            # Show features
            if [[ -d "$app/html" ]]; then
                echo "   🎨 Has UI interface"
            fi
            if [[ -f "$app/sql.sql" ]]; then
                echo "   🗄️  Requires database"
            fi
            if [[ -d "$app/server" ]]; then
                echo "   🖥️  Has server-side logic"
            fi
        fi
    done
    
    echo -e "\n${BLUE}🚀 Next Steps:${NC}"
    echo "=============="
    
    if [[ $ERRORS -eq 0 ]]; then
        echo "1. 📦 Package the phone apps for distribution"
        echo "2. 📚 Update documentation if needed"
        echo "3. 🧪 Test apps in different frameworks (ESX/QB/QBX)"
        echo "4. 📱 Test with different phone systems (LB Phone/QB Phone)"
        echo "5. 🎉 Ready for release!"
    else
        echo "1. 🔧 Fix the reported errors"
        echo "2. 🔄 Run validation again"
        echo "3. 📝 Update code as needed"
    fi
    
    # Exit with error code if there are errors
    if [[ $ERRORS -gt 0 ]]; then
        exit 1
    fi
}

# Run main function
main "$@"
