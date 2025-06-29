-- Invoice Phone App - Client Side (Universal Framework & Phone Compatible)
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
  PhoneApps.RegisterEvents('invoicing')

  print('[Invoicing] App initialized and registered')
end)

-- Event handlers
RegisterNetEvent('invoicing:client:playerLoaded', function()
  playerData = PhoneApps.GetPlayerData()
end)

RegisterNetEvent('invoicing:client:playerUnloaded', function()
  playerData = {}
end)

RegisterNetEvent('invoicing:client:jobUpdated', function(jobInfo)
  if playerData then
    playerData.job = jobInfo
  end
end)

-- Open invoice app
RegisterNetEvent('invoicing:client:openApp', function()
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

-- Send invoice
RegisterNUICallback('sendInvoice', function(data, cb)
  TriggerServerEvent('invoicing:server:sendInvoice', data)
  cb('ok')
end)

-- Get invoices
RegisterNUICallback('getInvoices', function(data, cb)
  PhoneApps.TriggerCallback('invoicing:server:getInvoices', function(invoices)
    cb(invoices)
  end)
end)

-- Pay invoice
RegisterNUICallback('payInvoice', function(data, cb)
  TriggerServerEvent('invoicing:server:payInvoice', data.invoiceId)
  cb('ok')
end)

-- Delete invoice
RegisterNUICallback('deleteInvoice', function(data, cb)
  TriggerServerEvent('invoicing:server:deleteInvoice', data.invoiceId)
  cb('ok')
end)

-- Search players
RegisterNUICallback('searchPlayers', function(data, cb)
  PhoneApps.TriggerCallback('invoicing:server:searchPlayers', function(players)
    cb(players)
  end, data.query)
end)

-- Get player businesses
RegisterNUICallback('getBusinesses', function(data, cb)
  PhoneApps.TriggerCallback('invoicing:server:getBusinesses', function(businesses)
    cb(businesses)
  end)
end)

-- Create business
RegisterNUICallback('createBusiness', function(data, cb)
  TriggerServerEvent('invoicing:server:createBusiness', data)
  cb('ok')
end)

-- Delete business
RegisterNUICallback('deleteBusiness', function(data, cb)
  TriggerServerEvent('invoicing:server:deleteBusiness', data.businessId)
  cb('ok')
end)

-- Handle business creation response
RegisterNetEvent('invoicing:client:businessCreated', function(success, message)
  if success then
    PhoneApps.ShowNotification(Config.Notifications.businessCreated, "success")
    -- Send NUI message to refresh businesses list
    SendNUIMessage({
      action = "refreshBusinesses"
    })
  else
    PhoneApps.ShowNotification(message or "Failed to create business", "error")
  end
end)

-- Handle invoice notifications
RegisterNetEvent('invoicing:client:receiveInvoice', function(invoice)
  PhoneApps.ShowNotification("You received an invoice for $" .. invoice.amount .. " from " .. invoice.sender_name,
    "primary", 5000)

  -- Send phone notification
  PhoneApps.SendPhoneNotification("invoicing", "New Invoice", "Invoice from " .. invoice.sender_name, 5000)
end)

-- Handle payment notifications
RegisterNetEvent('invoicing:client:invoicePaid', function(invoice)
  PhoneApps.ShowNotification("Invoice #" .. invoice.id .. " has been paid! +$" .. invoice.amount, "success", 5000)
end)

-- Handle business invoice notifications
RegisterNetEvent('invoicing:client:receiveBusinessInvoice', function(invoice)
  local message = string.format("Business invoice for $%s from %s",
    invoice.amount, invoice.sender_business_name or invoice.sender_name)

  PhoneApps.ShowNotification(message, "primary", 5000)
  PhoneApps.SendPhoneNotification("invoicing", "Business Invoice", message, 5000)
end)

-- Export for phone integration
exports('openInvoiceApp', function()
  TriggerEvent('invoicing:client:openApp')
end)
