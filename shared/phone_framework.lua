-- Universal Framework Compatibility Layer
-- Supports ESX, QBCore, QBX, and multiple phone systems

local Framework = {}
local FrameworkType = nil
local PhoneType = nil

-- Framework Detection
CreateThread(function()
  if GetResourceState('es_extended') == 'started' then
    FrameworkType = 'ESX'
    Framework.ESX = exports['es_extended']:getSharedObject()
  elseif GetResourceState('qb-core') == 'started' then
    FrameworkType = 'QB'
    Framework.QBCore = exports['qb-core']:GetCoreObject()
  elseif GetResourceState('qbx_core') == 'started' then
    FrameworkType = 'QBX'
    Framework.QBX = exports.qbx_core
  end

  -- Phone System Detection
  if GetResourceState('lb-phone') == 'started' then
    PhoneType = 'LB'
  elseif GetResourceState('qb-phone') == 'started' then
    PhoneType = 'QB'
  elseif GetResourceState('qs-smartphone') == 'started' then
    PhoneType = 'QS'
  end
end)

-- Universal Functions
local PhoneApps = {}

PhoneApps.GetFramework = function()
  return FrameworkType, PhoneType
end

PhoneApps.GetPlayerData = function()
  if FrameworkType == 'ESX' then
    return Framework.ESX.GetPlayerData()
  elseif FrameworkType == 'QB' then
    return Framework.QBCore.Functions.GetPlayerData()
  elseif FrameworkType == 'QBX' then
    return Framework.QBX:GetPlayerData()
  end
  return {}
end

PhoneApps.ShowNotification = function(message, type, duration)
  if FrameworkType == 'ESX' then
    Framework.ESX.ShowNotification(message)
  elseif FrameworkType == 'QB' then
    Framework.QBCore.Functions.Notify(message, type or 'primary', duration or 5000)
  elseif FrameworkType == 'QBX' then
    Framework.QBX:Notify(message, type or 'primary', duration or 5000)
  end
end

PhoneApps.TriggerCallback = function(name, cb, ...)
  if FrameworkType == 'ESX' then
    Framework.ESX.TriggerServerCallback(name, cb, ...)
  elseif FrameworkType == 'QB' then
    Framework.QBCore.Functions.TriggerCallback(name, cb, ...)
  elseif FrameworkType == 'QBX' then
    Framework.QBX.Functions.TriggerCallback(name, cb, ...)
  end
end

PhoneApps.FormatPlayerData = function(playerData)
  local formatted = {}

  if FrameworkType == 'ESX' then
    formatted = {
      identifier = playerData.identifier,
      name = (playerData.get('firstName') or '') .. ' ' .. (playerData.get('lastName') or ''),
      job = playerData.job and playerData.job.label or 'Unemployed',
      phone = playerData.get('phoneNumber') or '',
      citizenid = playerData.identifier
    }
  else   -- QB/QBX
    local charinfo = playerData.charinfo or {}
    formatted = {
      identifier = playerData.citizenid,
      citizenid = playerData.citizenid,
      name = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''),
      job = playerData.job and playerData.job.label or 'Unemployed',
      phone = charinfo.phone or ''
    }
  end

  return formatted
end

PhoneApps.RegisterApp = function(appConfig)
  if PhoneType == 'LB' then
    -- LB Phone Registration
    exports['lb-phone']:AddCustomApp({
      identifier = appConfig.identifier,
      name = appConfig.name,
      description = appConfig.description,
      developer = appConfig.developer or "Greigh",
      version = appConfig.version or "1.0.0",
      ui = ("nui://%s/html/index.html"):format(appConfig.identifier),
      icon = appConfig.icon,
      iconBackground = appConfig.color,
      size = appConfig.size or 1024,
      price = 0,
      category = appConfig.category or "productivity"
    })
  elseif PhoneType == 'QB' then
    -- QB Phone - Apps are typically registered in the phone resource
    -- This is handled differently, usually through phone config
  end
end

PhoneApps.SendPhoneNotification = function(appName, title, message, duration)
  if PhoneType == 'LB' then
    exports['lb-phone']:SendNotification({
      app = appName,
      title = title,
      content = message,
      time = duration or 5000
    })
  elseif PhoneType == 'QB' then
    TriggerEvent('qb-phone:client:CustomNotification', title, message, "fas fa-bell", "#3498db", duration or 5000)
  end
end

PhoneApps.RegisterEvents = function(appName)
  -- Framework Events
  if FrameworkType == 'ESX' then
    RegisterNetEvent('esx:playerLoaded', function()
      TriggerEvent(appName .. ':client:playerLoaded')
    end)
    RegisterNetEvent('esx:onPlayerLogout', function()
      TriggerEvent(appName .. ':client:playerUnloaded')
    end)
  else   -- QB/QBX
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
      TriggerEvent(appName .. ':client:playerLoaded')
    end)
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
      TriggerEvent(appName .. ':client:playerUnloaded')
    end)
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
      TriggerEvent(appName .. ':client:jobUpdated', jobInfo)
    end)
  end

  -- Phone Events
  if PhoneType == 'LB' then
    RegisterNetEvent('lb-phone:apps:' .. appName, function()
      TriggerEvent(appName .. ':client:openApp')
    end)
  elseif PhoneType == 'QB' then
    RegisterNetEvent('qb-phone:client:RunApplication', function(app, data)
      if app == appName then
        TriggerEvent(appName .. ':client:openApp')
      end
    end)
  end
end

return PhoneApps
