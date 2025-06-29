-- Invoice Phone App Configuration
Config = {}

-- App settings
Config.AppName = "Invoicing"
Config.AppIcon = "fas fa-file-invoice-dollar"
Config.AppColor = "#2ecc71"

-- Phone Integration
Config.PhoneApp = {
  identifier = "invoicing",
  name = "Invoicing",
  description = "Create and manage professional invoices for players and businesses",
  icon = "https://cdn-icons-png.flaticon.com/512/1611/1611179.png",
  category = "business",
  size = 1024
}

-- Tax settings
Config.DefaultTaxRate = 0.10 -- 10% default tax
Config.MaxTaxRate = 0.25     -- 25% maximum tax
Config.BusinessTaxRate = 0.08 -- 8% business tax rate

-- Invoice settings
Config.MaxInvoiceAmount = 50000 -- Maximum invoice amount
Config.MaxBusinessInvoiceAmount = 100000 -- Maximum business invoice amount
Config.InvoiceExpiry = 7        -- Days until invoice expires
Config.BusinessInvoiceExpiry = 14 -- Days until business invoice expires
Config.AutoReminders = true     -- Send automatic reminders
Config.GenerateInvoiceNumbers = true -- Auto-generate invoice numbers

-- Business settings
Config.EnableBusinessInvoicing = true -- Enable business invoicing features
Config.RequireBusinessLicense = false -- Require business license to create businesses
Config.MaxBusinessesPerPlayer = 3 -- Maximum businesses per player
Config.BusinessNameMinLength = 3 -- Minimum business name length
Config.BusinessNameMaxLength = 50 -- Maximum business name length

-- Payment methods
Config.PaymentMethods = {
  player = { "cash", "bank" },
  business = { "bank", "business" }
}

-- Job restrictions (empty table means all jobs can use)
Config.AllowedJobs = {
  -- 'mechanic',
  -- 'lawyer',
  -- 'doctor',
  -- 'business',
  -- Add job names here to restrict access
}

-- Business creation restrictions (empty table means all jobs can create businesses)
Config.BusinessCreationJobs = {
  -- 'ceo',
  -- 'business',
  -- 'entrepreneur',
  -- Add job names here to restrict business creation
}

-- Notification settings
Config.Notifications = {
  success = "Invoice sent successfully!",
  error = "Failed to send invoice.",
  paid = "Invoice has been paid!",
  expired = "Invoice has expired.",
  businessCreated = "Business created successfully!",
  businessInvoice = "Business invoice received!"
}

-- Database table names
Config.TableName = "invoices"
Config.BusinessTableName = "businesses"

-- Invoice number format (for auto-generation)
Config.InvoiceNumberFormat = "INV-%s-%d" -- Format: INV-YYYYMMDD-ID
Config.BusinessInvoiceNumberFormat = "BIZ-%s-%d" -- Format: BIZ-YYYYMMDD-ID
