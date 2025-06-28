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
  description = "Create and manage professional invoices",
  icon = "https://cdn-icons-png.flaticon.com/512/1611/1611179.png",
  category = "business",
  size = 1024
}

-- Tax settings
Config.DefaultTaxRate = 0.10 -- 10% default tax
Config.MaxTaxRate = 0.25     -- 25% maximum tax

-- Invoice settings
Config.MaxInvoiceAmount = 50000 -- Maximum invoice amount
Config.InvoiceExpiry = 7        -- Days until invoice expires
Config.AutoReminders = true     -- Send automatic reminders

-- Job restrictions (empty table means all jobs can use)
Config.AllowedJobs = {
  -- 'mechanic',
  -- 'lawyer',
  -- 'doctor',
  -- Add job names here to restrict access
}

-- Notification settings
Config.Notifications = {
  success = "Invoice sent successfully!",
  error = "Failed to send invoice.",
  paid = "Invoice has been paid!",
  expired = "Invoice has expired."
}

-- Database table name
Config.TableName = "invoices"
