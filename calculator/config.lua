-- Calculator Phone App Configuration
Config = {}

-- App settings
Config.AppName = "Calculator"
Config.AppIcon = "fas fa-calculator"
Config.AppColor = "#20c997"

-- Phone Integration
Config.PhoneApp = {
  identifier = "calculator",
  name = "Calculator",
  description = "Advanced calculator with history",
  icon = "https://cdn-icons-png.flaticon.com/512/1021/1021103.png",
  category = "utilities",
  size = 256
}

-- Calculator settings
Config.MaxDigits = 12           -- Maximum number of digits
Config.EnableScientific = false -- Enable scientific calculator functions
Config.EnableHistory = true     -- Enable calculation history
Config.MaxHistory = 50          -- Maximum history entries

-- Sound settings
Config.EnableSounds = true -- Enable button click sounds
Config.SoundVolume = 0.5   -- Sound volume (0.0 to 1.0)
