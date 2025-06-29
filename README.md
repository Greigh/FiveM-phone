# 📱 FiveM Phone Apps Collection

A collection of universal phone apps for FiveM servers, compatible with multiple frameworks (ESX, QBCore, QBX) and phone systems (LB Phone, QB Phone, QS Smartphone).

> **⚠️ Development Status Notice**  
> These phone apps are currently in **development/testing phase** and have not been fully tested in production environments. While they pass all validation checks and are designed for universal compatibility, **we recommend using them primarily with LB Phone** as it has received the most testing attention. Use in production servers at your own discretion and please report any issues you encounter.
> Additionally this is only my second FiveM project, so please be patient with me as I learn the ropes of this FiveM.

## 📋 Apps Included

| App | Description | Size | Database Required |
|-----|-------------|------|-------------------|
| 📧 **Invoicing** | Create and manage professional invoices | 1024 KB | ✅ Yes |
| 📝 **Notes** | Personal note-taking with categories | 512 KB | ❌ No |
| 💼 **Business Cards** | Design and share professional cards | 768 KB | ✅ Yes |
| 🧮 **Calculator** | Advanced calculator with history | 256 KB | ❌ No |
| 📸 **Gallery** | Photo storage and management | 1536 KB | ✅ Yes |

## 🚀 Quick Start

> **📱 Recommended Setup**: For the best experience, we recommend using **LB Phone** as it has received the most comprehensive testing with these apps.

### 1. Download & Extract

```bash
# Download the latest release
# Extract to your server's resources directory
```

### 2. Install Dependencies

```lua
# Add to server.cfg BEFORE the phone apps
ensure ox_lib
ensure es_extended  # OR qb-core OR qbx_core
ensure lb-phone     # OR qb-phone OR qs-smartphone
```

### 3. Install Phone Apps

```bash
# Run the installation script
cd phone_apps
chmod +x install.sh
./install.sh
```

### 4. Add to server.cfg

```lua
# Phone Apps (add after dependencies)
ensure invoicing
ensure notes
ensure business_cards
ensure calculator
ensure gallery
```

### 5. Restart Server

```bash
# Restart your FiveM server
restart ox_lib
restart [your-framework]
restart [your-phone-system]
start invoicing
start notes
start business_cards
start calculator
start gallery
```

## 🔧 Compatibility

### ✅ Supported Frameworks

- **ESX** (es_extended)
- **QBCore** (qb-core)
- **QBX** (qbx_core)

### ✅ Supported Phone Systems

- **LB Phone** (lb-phone) - **🌟 Recommended & Best Tested**
- **QB Phone** (qb-phone) - Limited testing
- **QS Smartphone** (qs-smartphone) - Limited testing

### ✅ Dependencies

- **ox_lib** (required)
- **MySQL Async/oxmysql** (for database apps)

## 📱 App Details

### 📧 Invoicing App

Professional invoice management system.

**Features:**

- Create and send invoices to players
- Automatic tax calculations
- Payment processing
- Invoice history and tracking
- Expiration handling

**Database:** `invoices` table (auto-created)

### 📝 Notes App  

Personal note-taking application.

**Features:**

- Create and edit personal notes
- Category organization
- Search functionality
- Auto-save feature
- Rich text support

**Database:** Not required (uses local storage)

### 💼 Business Cards App

Professional business card creator.

**Features:**

- Design custom business cards
- Multiple professional templates
- Share with nearby players
- Contact management
- QR code generation

**Database:** `business_cards` table (auto-created)

### 🧮 Calculator App

Advanced calculator with memory.

**Features:**

- Basic and advanced operations
- Calculation history
- Keyboard shortcuts
- Memory functions
- Responsive design

**Database:** Not required

### 📸 Gallery App

Photo storage and management.

**Features:**

- Photo upload and storage
- Album organization
- Image viewing and sharing
- Privacy controls
- Slideshow mode

**Database:** `gallery_photos` and `gallery_albums` tables (auto-created)

## 🛠️ Configuration

Each app includes a `config.lua` file for customization:

```lua
-- Example: Invoicing App Configuration
Config.MaxInvoiceAmount = 50000
Config.DefaultTaxRate = 0.10
Config.AllowedJobs = {} -- Empty = all jobs can use

-- Example: Business Cards Configuration
Config.MaxCards = 100
Config.SharingDistance = 5.0
Config.AllowCustomImages = true
```

## 📱 Phone Integration

Apps automatically register with your phone system:

```lua
-- LB Phone Integration
Config.PhoneApp = {
    identifier = "invoicing",
    name = "Invoicing",
    description = "Create and manage professional invoices",
    icon = "https://cdn-icons-png.flaticon.com/512/1611/1611179.png",
    category = "business",
    size = 1024
}
```

## 🔍 Validation

Validate your installation:

```bash
# Run the validation script
./validate_phone_apps.sh
```

The validation script checks:

- ✅ App structure and files
- ✅ Framework compatibility
- ✅ Phone system integration
- ✅ Configuration validity
- ✅ Code quality standards

## 🧪 Testing Status & Recommendations

### 🌟 Recommended Configuration

- **Framework**: Any (ESX, QBCore, QBX) - All tested and working
- **Phone System**: **LB Phone** - Most thoroughly tested
- **Environment**: Development/Testing servers initially

### ⚠️ Testing Status by Phone System

| Phone System | Testing Level | Status | Recommendation |
|--------------|---------------|--------|----------------|
| **LB Phone** | Comprehensive | ✅ Well Tested | **Recommended for production** |
| **QB Phone** | Basic | ⚠️ Limited Testing | Use with caution, test thoroughly |
| **QS Smartphone** | Basic | ⚠️ Limited Testing | Use with caution, test thoroughly |

### 🔬 What Has Been Tested

- ✅ Framework detection and compatibility (ESX/QB/QBX)
- ✅ App installation and registration
- ✅ Basic functionality of all 5 apps
- ✅ Database integration (where required)
- ✅ NUI interface loading and interaction
- ✅ LB Phone integration and app appearance

### ⚠️ What Needs More Testing

- 🔄 Extended production use in live servers
- 🔄 QB Phone and QS Smartphone integration edge cases
- 🔄 Performance under high player loads
- 🔄 Cross-framework data compatibility
- 🔄 Advanced features in complex server environments

### 💡 For Production Use

1. **Test in a development environment first**
2. **Start with LB Phone if possible**
3. **Monitor console for any errors**
4. **Test with a small group of users initially**
5. **Report any issues you encounter**

## 🐛 Troubleshooting

### Apps Not Appearing in Phone

1. Check console for registration messages
2. Verify dependencies are loaded first
3. Ensure framework is detected correctly
4. Check resource loading order
5. **For best results, use LB Phone** (most tested)

### Framework Detection Issues

```lua
-- Debug framework detection
print("Framework:", PhoneApps.GetFramework())
```

### Phone System Specific Issues

**LB Phone (Recommended):**

- Most stable and tested integration
- Apps should appear automatically in the app grid
- Check LB Phone configuration if apps don't show

**QB Phone / QS Smartphone:**

- Limited testing - may require additional configuration
- Monitor console for specific error messages
- Consider switching to LB Phone if issues persist

### Database Connection Problems

1. Verify MySQL resource is running
2. Check table creation in database
3. Validate Config.TableName settings

### Common Error Solutions

```bash
# Framework not detected
# Solution: Install ESX, QBCore, or QBX

# Phone system not found
# Solution: Install lb-phone, qb-phone, or qs-smartphone

# ox_lib not found
# Solution: Install ox_lib dependency
```

## 📚 Documentation

- 📖 **[LB Phone Setup Guide](LB_PHONE_SETUP.md)** - Detailed LB Phone integration
- 🔧 **[Framework Implementation](FRAMEWORK_IMPLEMENTATION.md)** - Technical details
- 🚀 **[Universal Implementation](UNIVERSAL_IMPLEMENTATION_COMPLETE.md)** - Compatibility guide

## 🔄 Migration

### From QB Phone to LB Phone

1. Backup existing app data
2. Update phone system references
3. Test all features
4. Import user data if needed

### Framework Migration

The apps automatically adapt to your framework:

- No code changes required
- Universal compatibility layer
- Automatic detection and configuration

## ✅ Testing Checklist

After installation:

- [ ] All apps appear in phone interface
- [ ] Apps open without errors
- [ ] Framework detection working
- [ ] Database tables created (if required)
- [ ] NUI interfaces load correctly
- [ ] Server callbacks function properly
- [ ] **Recommended**: Test with LB Phone first
- [ ] Test in development environment before production
- [ ] Monitor console for any warning messages

## 📞 Support

For issues or questions:

1. **Check Console**: Look for error messages in F8 console
2. **Run Validation**: Use `./validate_phone_apps.sh`
3. **Verify Setup**: Follow installation guide step by step
4. **Update Resources**: Ensure all dependencies are current
5. **Try LB Phone**: If using QB Phone/QS Smartphone, test with LB Phone
6. **Report Issues**: Help improve the apps by reporting bugs and feedback

> **🤝 Community Feedback Welcome**  
> Since these apps are in active development, your feedback is valuable! Please report any issues, suggestions, or successful implementations to help improve compatibility across different setups.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run validation script
5. Submit a pull request

## 🔄 Changelog

### v1.0.0-beta (Current)

- ✅ Universal framework compatibility (ESX/QB/QBX)
- ✅ Multi-phone system support (LB/QB/QS)
- ✅ 5 complete phone apps included
- ✅ Automatic validation and testing
- ✅ Comprehensive documentation
- ✅ Production-ready code quality
- 🌟 **Best tested with LB Phone**
- ⚠️ **Beta status**: Requires further testing in production environments

### Upcoming

- 🔄 Enhanced QB Phone and QS Smartphone compatibility
- 🔄 Extended production testing
- 🔄 Performance optimizations
- 🔄 Additional features based on community feedback

---

#### Made with ❤️ for the FiveM community

*Compatible with all major frameworks and phone systems - just install and go!*
