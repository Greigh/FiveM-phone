-- Business Cards Phone App - Client Side (Universal Framework & Phone Compatible)
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
  PhoneApps.RegisterEvents('business_cards')

  print('[Business Cards] App initialized and registered')
end)

-- Event handlers
RegisterNetEvent('business_cards:client:playerLoaded', function()
  playerData = PhoneApps.GetPlayerData()
end)

RegisterNetEvent('business_cards:client:playerUnloaded', function()
  playerData = {}
end)

RegisterNetEvent('business_cards:client:jobUpdated', function(jobInfo)
  if playerData then
    playerData.job = jobInfo
  end
end)

-- Open business cards app
RegisterNetEvent('business_cards:client:openApp', function()
  if isNuiOpen then return end

  -- Get fresh player data
  playerData = PhoneApps.GetPlayerData()

  -- Check if player has permission (if job restrictions are enabled)
  if #Config.AllowedJobs > 0 then
    local hasPermission = false
    local playerJob = playerData.job and playerData.job.name

    for _, job in pairs(Config.AllowedJobs) do
      if playerJob == job then
        hasPermission = true
        break
      end
    end

    if not hasPermission then
      PhoneApps.ShowNotification("You don't have permission to use this app", "error")
      return
    end
  end

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

-- Create business card
RegisterNUICallback('createCard', function(data, cb)
  TriggerServerEvent('business_cards:server:createCard', data)
  cb('ok')
end)

-- Get business cards
RegisterNUICallback('getCards', function(data, cb)
  PhoneApps.TriggerCallback('business_cards:server:getCards', function(cards)
    cb(cards)
  end)
end)

-- Delete business card
RegisterNUICallback('deleteCard', function(data, cb)
  TriggerServerEvent('business_cards:server:deleteCard', data.cardId)
  cb('ok')
end)

-- Share business card with nearby players
RegisterNUICallback('shareCard', function(data, cb)
  TriggerServerEvent('business_cards:server:shareCard', data.cardId)
  cb('ok')
end)

-- Search nearby players for sharing
RegisterNUICallback('getNearbyPlayers', function(data, cb)
  PhoneApps.TriggerCallback('business_cards:server:getNearbyPlayers', function(players)
    cb(players)
  end)
end)

-- Handle receiving business card
RegisterNetEvent('business_cards:client:receiveCard', function(card)
  PhoneApps.ShowNotification("You received a business card from " .. card.owner_name, "primary", 5000)

  -- Send phone notification
  PhoneApps.SendPhoneNotification("business_cards", "Business Cards", "New card from " .. card.owner_name, 5000)
end)

-- Handle card creation response
RegisterNetEvent('business_cards:client:cardCreated', function(success, message)
  if success then
    PhoneApps.ShowNotification(message, "success", 3000)
  else
    PhoneApps.ShowNotification(message, "error", 3000)
  end
end)

-- Export for phone integration
exports('openBusinessCardsApp', function()
  TriggerEvent('business_cards:client:openApp')
end)
