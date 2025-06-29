-- Invoice Phone App - Server Side (Universal Framework Compatible)

-- Framework Detection
local Framework = nil
local FrameworkType = nil

-- Detect which framework is running
CreateThread(function()
  if GetResourceState('es_extended') == 'started' then
    FrameworkType = 'ESX'
    Framework = exports['es_extended']:getSharedObject()
  elseif GetResourceState('qb-core') == 'started' then
    FrameworkType = 'QB'
    Framework = exports['qb-core']:GetCoreObject()
  elseif GetResourceState('qbx_core') == 'started' then
    FrameworkType = 'QBX'
    Framework = exports.qbx_core
  end
end)

-- Universal functions
local function GetPlayer(source)
  if FrameworkType == 'ESX' then
    return Framework.GetPlayerFromId(source)
  elseif FrameworkType == 'QB' then
    return Framework.Functions.GetPlayer(source)
  elseif FrameworkType == 'QBX' then
    return Framework.Functions.GetPlayer(source)
  end
end

local function GetPlayerIdentifier(player)
  if FrameworkType == 'ESX' then
    return player.identifier
  else -- QB/QBX
    return player.PlayerData.citizenid
  end
end

local function GetPlayerCharinfo(player)
  if FrameworkType == 'ESX' then
    return {
      firstname = player.getName(),
      lastname = '',
      phone = player.getPhone() or 'N/A'
    }
  else -- QB/QBX
    return player.PlayerData.charinfo
  end
end

local function GetPlayerByCitizenId(citizenid)
  if FrameworkType == 'ESX' then
    return Framework.GetPlayerFromIdentifier(citizenid)
  else -- QB/QBX
    return Framework.Functions.GetPlayerByCitizenId(citizenid)
  end
end

local function GetPlayerSource(player)
  if FrameworkType == 'ESX' then
    return player.source
  else -- QB/QBX
    return player.PlayerData.source
  end
end

local function GetPlayerMoney(player, account)
  if FrameworkType == 'ESX' then
    return player.getAccount(account or 'bank').money
  else -- QB/QBX
    return player.PlayerData.money[account or 'bank']
  end
end

local function RemovePlayerMoney(player, account, amount, reason)
  if FrameworkType == 'ESX' then
    player.removeAccountMoney(account or 'bank', amount)
  else -- QB/QBX
    player.Functions.RemoveMoney(account or 'bank', amount, reason or 'invoice-payment')
  end
end

local function AddPlayerMoney(player, account, amount, reason)
  if FrameworkType == 'ESX' then
    player.addAccountMoney(account or 'bank', amount)
  else -- QB/QBX
    player.Functions.AddMoney(account or 'bank', amount, reason or 'invoice-received')
  end
end

local function CreateCallback(name, cb)
  if FrameworkType == 'ESX' then
    Framework.RegisterServerCallback(name, cb)
  elseif FrameworkType == 'QB' then
    Framework.Functions.CreateCallback(name, cb)
  elseif FrameworkType == 'QBX' then
    Framework.Functions.CreateCallback(name, cb)
  end
end

-- Get player invoices
CreateCallback('invoicing:server:getInvoices', function(source, cb)
  local Player = GetPlayer(source)
  if not Player then return cb({}) end

  local identifier = GetPlayerIdentifier(Player)

  local invoices = MySQL.query.await(
    'SELECT * FROM ' ..
    Config.TableName .. ' WHERE sender_citizenid = ? OR receiver_citizenid = ? ORDER BY created_at DESC', {
      identifier, identifier
    })

  cb(invoices or {})
end)

-- Search players
CreateCallback('invoicing:server:searchPlayers', function(source, cb, query)
  if not query or #query < 2 then return cb({}) end

  local players = MySQL.query.await(
    'SELECT citizenid, charinfo FROM players WHERE JSON_EXTRACT(charinfo, "$.firstname") LIKE ? OR JSON_EXTRACT(charinfo, "$.lastname") LIKE ? LIMIT 10',
    {
      '%' .. query .. '%',
      '%' .. query .. '%'
    })

  local results = {}
  for _, player in pairs(players or {}) do
    local charinfo = json.decode(player.charinfo)
    table.insert(results, {
      citizenid = player.citizenid,
      name = charinfo.firstname .. ' ' .. charinfo.lastname,
      phone = charinfo.phone
    })
  end

  cb(results)
end)

-- Send invoice
RegisterNetEvent('invoicing:server:sendInvoice', function(invoiceData)
  local src = source
  local Player = GetPlayer(src)
  if not Player then return end

  -- Validate data
  if not invoiceData.receiver_citizenid or not invoiceData.amount or not invoiceData.description then
    TriggerClientEvent('QBCore:Notify', src, "Invalid invoice data", "error")
    return
  end

  -- Check amount limits
  local amount = tonumber(invoiceData.amount)
  if amount <= 0 or amount > Config.MaxInvoiceAmount then
    TriggerClientEvent('QBCore:Notify', src, "Invalid invoice amount", "error")
    return
  end

  -- Get receiver data
  local receiverData = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?',
    { invoiceData.receiver_citizenid })
  if not receiverData then
    TriggerClientEvent('QBCore:Notify', src, "Receiver not found", "error")
    return
  end

  local receiverCharinfo = json.decode(receiverData.charinfo)
  local senderCharinfo = GetPlayerCharinfo(Player)

  -- Create invoice
  local invoiceId = MySQL.insert.await(
    'INSERT INTO ' ..
    Config.TableName ..
    ' (sender_citizenid, sender_name, receiver_citizenid, receiver_name, amount, description, tax_rate, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? DAY))',
    {
      GetPlayerIdentifier(Player),
      senderCharinfo.firstname .. ' ' .. senderCharinfo.lastname,
      invoiceData.receiver_citizenid,
      receiverCharinfo.firstname .. ' ' .. receiverCharinfo.lastname,
      amount,
      invoiceData.description,
      invoiceData.tax_rate or Config.DefaultTaxRate,
      Config.InvoiceExpiry
    })

  if invoiceId then
    TriggerClientEvent('QBCore:Notify', src, "Invoice sent successfully!", "success")

    -- Notify receiver if online
    local receiverPlayer = GetPlayerByCitizenId(invoiceData.receiver_citizenid)
    if receiverPlayer then
      local receiverSource = GetPlayerSource(receiverPlayer)
      TriggerClientEvent('invoicing:client:receiveInvoice', receiverSource, {
        id = invoiceId,
        sender_name = senderCharinfo.firstname .. ' ' .. senderCharinfo.lastname,
        amount = amount,
        description = invoiceData.description
      })
    end
  else
    TriggerClientEvent('QBCore:Notify', src, "Failed to send invoice", "error")
  end
end)

-- Pay invoice
RegisterNetEvent('invoicing:server:payInvoice', function(invoiceId)
  local src = source
  local Player = GetPlayer(src)
  if not Player then return end

  -- Get invoice
  local invoice = MySQL.single.await(
    'SELECT * FROM ' .. Config.TableName .. ' WHERE id = ? AND receiver_citizenid = ? AND status = "pending"', {
      invoiceId, GetPlayerIdentifier(Player)
    })

  if not invoice then
    TriggerClientEvent('QBCore:Notify', src, "Invoice not found or already paid", "error")
    return
  end

  -- Check if expired
  if invoice.expires_at and os.time() > os.time(invoice.expires_at) then
    TriggerClientEvent('QBCore:Notify', src, "Invoice has expired", "error")
    return
  end

  local totalAmount = invoice.amount + (invoice.amount * invoice.tax_rate)

  -- Check if player has enough money
  if GetPlayerMoney(Player, 'bank') < totalAmount then
    TriggerClientEvent('QBCore:Notify', src, "Insufficient funds", "error")
    return
  end

  -- Process payment
  RemovePlayerMoney(Player, 'bank', totalAmount, 'invoice-payment')

  -- Pay the sender
  local senderPlayer = GetPlayerByCitizenId(invoice.sender_citizenid)
  if senderPlayer then
    AddPlayerMoney(senderPlayer, 'bank', invoice.amount, 'invoice-received')
    local senderSource = GetPlayerSource(senderPlayer)
    TriggerClientEvent('invoicing:client:invoicePaid', senderSource, invoice)
  else
    -- Add money offline
    MySQL.update(
      'UPDATE players SET money = JSON_SET(money, "$.bank", JSON_EXTRACT(money, "$.bank") + ?) WHERE citizenid = ?', {
        invoice.amount, invoice.sender_citizenid
      })
  end

  -- Update invoice status
  MySQL.update('UPDATE ' .. Config.TableName .. ' SET status = "paid", paid_at = NOW() WHERE id = ?', { invoiceId })

  TriggerClientEvent('QBCore:Notify', src, "Invoice paid successfully!", "success")
end)

-- Delete invoice (sender only)
RegisterNetEvent('invoicing:server:deleteInvoice', function(invoiceId)
  local src = source
  local Player = GetPlayer(src)
  if not Player then return end

  local result = MySQL.update.await(
    'DELETE FROM ' .. Config.TableName .. ' WHERE id = ? AND sender_citizenid = ? AND status = "pending"', {
      invoiceId, GetPlayerIdentifier(Player)
    })

  if result > 0 then
    TriggerClientEvent('QBCore:Notify', src, "Invoice deleted successfully!", "success")
  else
    TriggerClientEvent('QBCore:Notify', src, "Cannot delete this invoice", "error")
  end
end)

-- Clean up expired invoices (run periodically)
CreateThread(function()
  while true do
    Wait(3600000) -- Check every hour
    MySQL.update('UPDATE ' ..
      Config.TableName .. ' SET status = "expired" WHERE expires_at < NOW() AND status = "pending"')
  end
end)
