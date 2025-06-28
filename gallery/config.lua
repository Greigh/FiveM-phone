-- Gallery Phone App Configuration
Config = {}

-- App settings
Config.AppName = "Gallery"
Config.AppIcon = "fas fa-images"
Config.AppColor = "#9b59b6"

-- Phone Integration
Config.PhoneApp = {
  identifier = "gallery",
  name = "Gallery",
  description = "Photo storage and management",
  icon = "https://cdn-icons-png.flaticon.com/512/1375/1375106.png",
  category = "entertainment",
  size = 1536
}

-- Gallery settings
Config.MaxPhotos = 500        -- Maximum photos per player
Config.MaxPhotoSize = 5242880 -- 5MB in bytes
Config.AllowedFormats = {     -- Allowed image formats
  "jpg", "jpeg", "png", "gif", "webp"
}

-- Album settings
Config.MaxAlbums = 50          -- Maximum albums per player
Config.MaxAlbumName = 50       -- Maximum album name length
Config.MaxPhotosPerAlbum = 100 -- Maximum photos per album

-- Sharing settings
Config.EnableSharing = true   -- Allow photo sharing
Config.SharingDistance = 10.0 -- Distance for nearby sharing (meters)
Config.MaxSharedPhotos = 10   -- Maximum shared photos at once

-- Privacy settings
Config.DefaultPrivacy = "private" -- Default photo privacy (public/private)
Config.EnablePublicGallery = true -- Allow public photo browsing

-- Storage settings
Config.EnableCloud = true             -- Enable cloud storage simulation
Config.CloudStorageLimit = 1073741824 -- 1GB in bytes

-- Notification settings
Config.Notifications = {
  photoUploaded = "Photo uploaded successfully!",
  photoDeleted = "Photo deleted successfully!",
  albumCreated = "Album created successfully!",
  photoShared = "Photo shared successfully!",
  error = "Failed to process request."
}

-- Database table name
Config.TableName = "gallery_photos"
Config.AlbumsTableName = "gallery_albums"
