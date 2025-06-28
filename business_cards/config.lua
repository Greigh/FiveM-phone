-- Business Cards Phone App Configuration
Config = {}

-- App settings
Config.AppName = "Business Cards"
Config.AppIcon = "fas fa-address-card"
Config.AppColor = "#6c63ff"

-- Phone Integration
Config.PhoneApp = {
  identifier = "business_cards",
  name = "Business Cards",
  description = "Create and share professional business cards",
  icon = "https://cdn-icons-png.flaticon.com/512/2821/2821786.png",
  category = "business",
  size = 768
}

-- Business card settings
Config.MaxCardTitle = 50        -- Maximum title length
Config.MaxCardDescription = 200 -- Maximum description length
Config.MaxCards = 100           -- Maximum cards per player
Config.AllowCustomImages = true -- Allow custom card images

-- Sharing settings
Config.EnableNearbySharing = true -- Share cards with nearby players
Config.SharingDistance = 5.0      -- Distance for nearby sharing (meters)
Config.EnableQRCode = true        -- Generate QR codes for cards

-- Job restrictions (empty table means all jobs can use)
Config.AllowedJobs = {
  -- 'business',
  -- 'lawyer',
  -- 'realestate',
  -- Add job names here to restrict access
}

-- Default card templates
Config.DefaultTemplates = {
  "Professional",
  "Modern",
  "Creative",
  "Minimal",
  "Corporate"
}

-- Notification settings
Config.Notifications = {
  cardCreated = "Business card created successfully!",
  cardShared = "Business card shared!",
  cardReceived = "You received a business card!",
  error = "Failed to process request."
}

-- Database table name
Config.TableName = "business_cards"
