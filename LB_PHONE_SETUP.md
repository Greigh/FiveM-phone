# LB Phone Integration Setup Guide

This guide walks you through setting up the FiveM Phone Apps to work with **LB Phone** system.

## 📋 Prerequisites

- **Framework**: ESX, QBCore, or QBX
- **Phone System**: lb-phone (latest version)
- **Database**: MySQL/MariaDB
- **Dependencies**: ox_lib

## 🔧 Installation Steps

### 1. Framework Configuration

Each app automatically detects your framework. Make sure one of these is installed:

```lua
-- ESX
ensure es_extended

-- QBCore  
ensure qb-core

-- QBX (current default)
ensure qbx_core
```

### 2. Phone System Setup

Ensure LB Phone is properly installed and running:

```lua
ensure lb-phone
```

### 3. Install Phone Apps

1. **Copy Apps**: Place all phone app folders in your `resources` directory
2. **Add to server.cfg**:

```cfg
# Phone Apps
ensure invoicing
ensure notes  
ensure business_cards
ensure calculator
ensure gallery
```

### 4. Database Setup

Import the SQL files for apps that require database storage:

```sql
-- Invoicing App
source invoicing/sql.sql

-- Business Cards App  
source business_cards/sql.sql

-- Gallery App
source gallery/sql.sql
```

### 5. LB Phone App Registration

The apps will automatically register with LB Phone when both systems are running. You should see these messages in your console:

``` plaintext
[Invoicing] App initialized and registered
[Business Cards] App initialized and registered
[Notes] App initialized and registered
[Calculator] App initialized and registered
[Gallery] App initialized and registered
```

## 📱 LB Phone Configuration

### App Categories

The apps will appear in these categories in LB Phone:

| App | Category | Size | Price |
|-----|----------|------|-------|
| Invoicing | Business | 1024 KB | Free |
| Notes | Productivity | 512 KB | Free |
| Business Cards | Business | 768 KB | Free |
| Calculator | Utilities | 256 KB | Free |
| Gallery | Entertainment | 1536 KB | Free |

### Custom App Icons

The apps use these icon URLs (automatically configured):

- **Invoicing**: Professional invoice icon
- **Notes**: Sticky note icon  
- **Business Cards**: Business card icon
- **Calculator**: Calculator icon
- **Gallery**: Photo gallery icon

## 🔨 Framework Compatibility

### ESX Integration

For ESX servers, the apps automatically use:

- `ESX.GetPlayerData()` for player information
- `ESX.ShowNotification()` for notifications
- `ESX.TriggerServerCallback()` for server communication

### QBCore Integration  

For QBCore servers, the apps use:

- `QBCore.Functions.GetPlayerData()` for player information
- `QBCore.Functions.Notify()` for notifications
- `QBCore.Functions.TriggerCallback()` for server communication

### QBX Integration (Default)

For QBX servers, the apps use:

- `QBX:GetPlayerData()` for player information  
- `QBX:Notify()` for notifications
- `QBX.Functions.TriggerCallback()` for server communication

## 🎮 Usage

### Opening Apps

Apps can be opened through:

1. **LB Phone Interface**: Navigate to the app grid and tap the app icon
2. **Direct Commands**: Use exports to open apps programmatically
3. **Integration**: Other resources can trigger app opening

### App Features

#### Invoicing App

- Create and send invoices
- Receive and pay invoices  
- Tax calculations
- Invoice history
- Automatic reminders App

- Create and send invoices
- Receive and pay invoices  
- Tax calculations
- Invoice history
- Automatic reminders

#### Notes App

- Create personal notes
- Organize by categories
- Search functionality
- Auto-save feature
- Rich text support

#### Business Cards App

- Design professional cards
- Share with nearby players
- Multiple templates
- Contact management
- QR code generation

#### Calculator App

- Basic arithmetic operations
- Calculation history
- Keyboard shortcuts
- Memory functions
- Scientific mode (optional)

#### Gallery App

- Photo storage and management
- Album organization
- Image viewing and sharing
- Slideshow mode
- Privacy controls

## 🛠️ Customization

### App Configuration

Each app has a `config.lua` file for customization:

```lua
-- Example: Invoicing App
Config.MaxInvoiceAmount = 50000
Config.DefaultTaxRate = 0.10
Config.AllowedJobs = {} -- Empty = all jobs

-- Example: Business Cards App  
Config.MaxCards = 100
Config.SharingDistance = 5.0
Config.AllowCustomImages = true
```

### Phone System Settings

Modify app appearance in LB Phone by editing the `PhoneApp` configuration:

```lua
Config.PhoneApp = {
    identifier = "invoicing",
    name = "Invoicing", 
    description = "Create and manage professional invoices",
    icon = "custom-icon-url.png",
    category = "business",
    size = 1024
}
```

## 🐛 Troubleshooting

### Apps Not Appearing in LB Phone

1. **Check Console**: Look for registration messages
2. **Verify Dependencies**: Ensure ox_lib and framework are loaded
3. **Resource Order**: Make sure lb-phone starts before the apps
4. **Permissions**: Check if framework is detected correctly

### Framework Detection Issues

```lua
-- Debug framework detection
print("Framework Type:", PhoneApps.GetFramework())
```

### Database Connection Problems

1. **Check SQL Import**: Verify tables were created
2. **MySQL Async**: Ensure MySQL resource is running
3. **Table Names**: Verify Config.TableName matches your setup

### Common Errors

```bash
# Error: Framework not detected
# Solution: Install ESX, QBCore, or QBX

# Error: Phone system not found  
# Solution: Install and start lb-phone

# Error: ox_lib not found
# Solution: Install ox_lib dependency
```

## 📞 Support

For issues or questions:

1. **Check Logs**: Look for error messages in F8 console
2. **Verify Setup**: Follow this guide step by step
3. **Test Framework**: Ensure your framework is working
4. **Update Resources**: Make sure all dependencies are current

## 🔄 Migration from QB Phone

If migrating from QB Phone to LB Phone:

1. **Backup Data**: Export any existing app data
2. **Update Config**: Change phone system references
3. **Test Apps**: Verify all features work correctly
4. **Import Data**: Restore user data if needed

The apps are designed to work with both systems, so minimal changes should be required.

## ✅ Verification

After setup, verify everything works:

1. **Start Server**: Boot your FiveM server
2. **Join Game**: Connect as a player
3. **Open Phone**: Access LB Phone interface
4. **Test Apps**: Try opening each app
5. **Check Features**: Test core functionality

If all apps appear and function correctly, your setup is complete!

---

**Note**: This setup supports multiple frameworks and automatically adapts to your server configuration. The apps will detect your framework (ESX/QB/QBX) and phone system (LB Phone) automatically.
