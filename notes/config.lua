-- Notes App Configuration
Config = {}

-- App settings
Config.AppName = "Notes"
Config.AppIcon = "fas fa-sticky-note"
Config.AppColor = "#f39c12"

-- Phone Integration
Config.PhoneApp = {
  identifier = "notes",
  name = "Notes",
  description = "Personal note-taking application",
  icon = "https://cdn-icons-png.flaticon.com/512/3176/3176369.png",
  category = "productivity",
  size = 512
}

-- Notes settings
Config.MaxNotes = 50        -- Maximum notes per player
Config.MaxNoteLength = 2000 -- Maximum characters per note
Config.MaxTitleLength = 100 -- Maximum title length
Config.AutoSave = true      -- Auto-save notes while typing
Config.AutoSaveDelay = 2000 -- Auto-save delay in milliseconds

-- Categories
Config.Categories = {
  "Personal",
  "Work",
  "Shopping",
  "Ideas",
  "Reminders",
  "Important"
}

Config.DefaultCategory = "Personal"

-- Features
Config.Features = {
  search = true,       -- Enable search functionality
  categories = true,   -- Enable note categories
  timestamps = true,   -- Show created/modified timestamps
  export = false,      -- Allow exporting notes (future feature)
  sharing = false      -- Allow sharing notes with other players (future feature)
}

-- UI Settings
Config.UI = {
  theme = "modern",
  notesPerPage = 20,
  showPreview = true,
  previewLength = 100   -- Characters to show in preview
}

-- Notification settings
Config.Notifications = {
  success = "Note saved successfully!",
  error = "Failed to save note.",
  deleted = "Note deleted successfully!",
  maxReached = "Maximum number of notes reached."
}

-- Database table name
Config.TableName = "player_notes"
