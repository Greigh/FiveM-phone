-- Gallery Phone App - Client Side (Universal Framework & Phone Compatible)
local PhoneApps = require 'shared.phone_framework'

-- Local variables
local isNuiOpen = false
local playerData = {}

-- Initialize framework and phone integration
CreateThread(function()
  Wait(2000) -- Wait for resources to load

  -- Register app with phone system
  PhoneApps.RegisterApp(Config.PhoneApp)

  -- Register framework and phone events
  PhoneApps.RegisterEvents('gallery')

  print('[Gallery] App initialized and registered')
end)

-- Event handlers
RegisterNetEvent('gallery:client:playerLoaded', function()
  playerData = PhoneApps.GetPlayerData()
end)

RegisterNetEvent('gallery:client:playerUnloaded', function()
  playerData = {}
end)

RegisterNetEvent('gallery:client:jobUpdated', function(jobInfo)
  if playerData then
    playerData.job = jobInfo
  end
end)

-- Open gallery app
RegisterNetEvent('gallery:client:openApp', function()
  if isNuiOpen then return end

  -- Get fresh player data
  playerData = PhoneApps.GetPlayerData()

  isNuiOpen = true
  SetNuiFocus(true, true)

  SendNUIMessage({
    action = "openApp",
    playerData = PhoneApps.FormatPlayerData(playerData),
    config = Config
  })
end)

-- Close app
RegisterNUICallback('closeApp', function(data, cb)
  isNuiOpen = false
  SetNuiFocus(false, false)
  cb('ok')
end)

-- Upload photo
RegisterNUICallback('uploadPhoto', function(data, cb)
  TriggerServerEvent('gallery:server:uploadPhoto', data)
  cb('ok')
end)

-- Get photos
RegisterNUICallback('getPhotos', function(data, cb)
  PhoneApps.TriggerCallback('gallery:server:getPhotos', function(photos)
    cb(photos)
  end)
end)

-- Delete photo
RegisterNUICallback('deletePhoto', function(data, cb)
  TriggerServerEvent('gallery:server:deletePhoto', data.photoId)
  cb('ok')
end)

-- Share photo
RegisterNUICallback('sharePhoto', function(data, cb)
  TriggerServerEvent('gallery:server:sharePhoto', data)
  cb('ok')
end)

-- Create album
RegisterNUICallback('createAlbum', function(data, cb)
  TriggerServerEvent('gallery:server:createAlbum', data)
  cb('ok')
end)

-- Handle photo upload response
RegisterNetEvent('gallery:client:photoUploaded', function(success, message)
  if success then
    PhoneApps.ShowNotification(message, "success", 3000)
  else
    PhoneApps.ShowNotification(message, "error", 3000)
  end
end)

-- Handle photo sharing
RegisterNetEvent('gallery:client:photoShared', function(photo)
  PhoneApps.ShowNotification("You received a shared photo!", "primary", 5000)
  PhoneApps.SendPhoneNotification("gallery", "Gallery", "New shared photo", 5000)
end)

-- Export for phone integration
exports('openGalleryApp', function()
  TriggerEvent('gallery:client:openApp')
end)
