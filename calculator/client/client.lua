-- Calculator Phone App - Client Side (Universal Framework & Phone Compatible)
local PhoneApps = require 'shared.phone_framework'

-- Local variables
local isNuiOpen = false

-- Initialize framework and phone integration
CreateThread(function()
  Wait(2000) -- Wait for resources to load

  -- Register app with phone system
  PhoneApps.RegisterApp(Config.PhoneApp)

  -- Register framework and phone events
  PhoneApps.RegisterEvents('calculator')

  print('[Calculator] App initialized and registered')
end)

-- Open calculator app
RegisterNetEvent('calculator:client:openApp', function()
  if isNuiOpen then return end

  isNuiOpen = true
  SetNuiFocus(true, true)

  SendNUIMessage({
    action = "openApp",
    config = Config
  })
end)

-- Close app
RegisterNUICallback('closeApp', function(data, cb)
  isNuiOpen = false
  SetNuiFocus(false, false)
  cb('ok')
end)

-- Export for phone integration
exports('openCalculatorApp', function()
  TriggerEvent('calculator:client:openApp')
end)
