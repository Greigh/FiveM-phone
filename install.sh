#!/bin/bash

# FiveM Phone Apps - Installation Script
# Installs phone apps from this repository to your FiveM server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║           FiveM Phone Apps - Installation Script              ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📱 Installing phone apps for Enhanced Notebook Item Resource${NC}"
echo ""

# Available apps
apps=("invoicing" "notes" "business_cards" "calculator")

echo -e "${BLUE}📋 Available Phone Apps:${NC}"
for i in "${!apps[@]}"; do
    echo -e "  $((i+1)). ${apps[$i]}"
done
echo ""

# Get server path
while true; do
    read -p "Enter your FiveM server resources path: " server_path
    if [ -d "$server_path" ]; then
        echo -e "${GREEN}✅ Path exists: $server_path${NC}"
        break
    else
        echo -e "${RED}❌ Path does not exist. Please enter a valid path.${NC}"
    fi
done

echo ""

# Install apps
for app in "${apps[@]}"; do
    if [ -d "$app" ]; then
        echo -e "${BLUE}📱 Installing $app...${NC}"
        
        target_path="$server_path/$app"
        
        if [ -d "$target_path" ]; then
            echo -e "${YELLOW}⚠️  $app already exists at $target_path${NC}"
            read -p "Overwrite existing installation? (y/N): " overwrite
            if [[ ! $overwrite =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Skipping $app${NC}"
                continue
            fi
            rm -rf "$target_path"
        fi
        
        cp -r "$app" "$target_path"
        echo -e "${GREEN}✅ $app installed to $target_path${NC}"
        
        # Check for SQL file
        if [ -f "$app/sql.sql" ]; then
            echo -e "${CYAN}ℹ️  SQL file found: $app/sql.sql${NC}"
            echo -e "${YELLOW}⚠️  Please import this SQL file to your database${NC}"
        fi
    else
        echo -e "${RED}❌ $app directory not found${NC}"
    fi
done

echo ""
echo -e "${BLUE}⚙️  Server Configuration${NC}"
echo ""
echo -e "${CYAN}Add these lines to your server.cfg:${NC}"
for app in "${apps[@]}"; do
    if [ -d "$app" ]; then
        echo -e "${GREEN}ensure $app${NC}"
    fi
done

echo ""
echo -e "${BLUE}📋 Database Setup${NC}"
echo ""
echo -e "${CYAN}Import the following SQL files to your database:${NC}"
for app in "${apps[@]}"; do
    if [ -f "$app/sql.sql" ]; then
        echo -e "- $app/sql.sql"
    fi
done

echo ""
echo -e "${GREEN}🎉 Phone Apps Installation Complete!${NC}"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo -e "1. Import SQL files to your database"
echo -e "2. Add resources to server.cfg"
echo -e "3. Configure apps by editing their config.lua files"
echo -e "4. Restart your FiveM server"
echo -e "5. Test the apps through your phone system"
echo ""
echo -e "${BLUE}📱 Make sure you have the Enhanced Notebook Item Resource installed first!${NC}"
echo -e "${BLUE}Core Repository: https://github.com/Greigh/FiveM-notebook${NC}"
echo ""
echo -e "${GREEN}Happy roleplaying! 📱✨${NC}"
