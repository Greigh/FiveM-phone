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

-- Get player businesses
CreateCallback('invoicing:server:getBusinesses', function(source, cb)
  local Player = GetPlayer(source)
  if not Player then return cb({}) end

  local identifier = GetPlayerIdentifier(Player)

  local businesses = MySQL.query.await(
    'SELECT * FROM ' .. Config.BusinessTableName .. ' WHERE owner_citizenid = ? AND status = "active"', {
      identifier
    })

  cb(businesses or {})
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
  local maxAmount = invoiceData.sender_business_id and Config.MaxBusinessInvoiceAmount or Config.MaxInvoiceAmount
  if amount <= 0 or amount > maxAmount then
    TriggerClientEvent('QBCore:Notify', src, "Invalid invoice amount", "error")
    return
  end

  -- Calculate commission and tax amounts
  local commissionAmount = 0
  local taxAmount = 0
  local taxRate = invoiceData.tax_rate or Config.DefaultTaxRate

  if invoiceData.commission_rate and invoiceData.commission_rate > 0 then
    if invoiceData.commission_type == 'flat' then
      commissionAmount = invoiceData.commission_rate
    else
      commissionAmount = amount * invoiceData.commission_rate
    end
  end

  taxAmount = amount * taxRate
  local totalAmount = amount + taxAmount
  local netAmount = amount - commissionAmount

  -- Get receiver data
  local receiverData = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?',
    { invoiceData.receiver_citizenid })
  if not receiverData then
    TriggerClientEvent('QBCore:Notify', src, "Receiver not found", "error")
    return
  end

  local receiverCharinfo = json.decode(receiverData.charinfo)
  local senderCharinfo = GetPlayerCharinfo(Player)

  -- Get business info if applicable
  local senderBusinessName = nil
  if invoiceData.sender_business_id then
    local businessData = MySQL.single.await('SELECT name FROM ' .. Config.BusinessTableName .. ' WHERE id = ?',
      { invoiceData.sender_business_id })
    if businessData then
      senderBusinessName = businessData.name
    end
  end

  -- Generate invoice number if enabled
  local invoiceNumber = nil
  if Config.GenerateInvoiceNumbers then
    local dateStr = os.date("%Y%m%d")
    local format = invoiceData.sender_business_id and Config.BusinessInvoiceNumberFormat or Config.InvoiceNumberFormat
    invoiceNumber = string.format(format, dateStr, os.time())
  end

  -- Set expiry date
  local expiryDays = invoiceData.sender_business_id and Config.BusinessInvoiceExpiry or Config.InvoiceExpiry

  -- Create invoice
  local invoiceId = MySQL.insert.await(
    'INSERT INTO ' .. Config.TableName ..
    ' (sender_citizenid, sender_name, sender_type, sender_business_id, sender_business_name, receiver_citizenid, receiver_name, amount, description, tax_rate, tax_amount, commission_rate, commission_amount, commission_recipient_id, commission_recipient_name, commission_type, total_amount, net_amount, invoice_number, created_at, expires_at, auto_pay_taxes, auto_pay_commission) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? DAY), ?, ?)',
    {
      GetPlayerIdentifier(Player),
      senderCharinfo.firstname .. ' ' .. senderCharinfo.lastname,
      invoiceData.sender_business_id and 'business' or 'player',
      invoiceData.sender_business_id,
      senderBusinessName,
      invoiceData.receiver_citizenid,
      receiverCharinfo.firstname .. ' ' .. receiverCharinfo.lastname,
      amount,
      invoiceData.description,
      taxRate,
      taxAmount,
      invoiceData.commission_rate,
      commissionAmount,
      invoiceData.commission_recipient_id,
      invoiceData.commission_recipient_name,
      invoiceData.commission_type or 'percentage',
      totalAmount,
      netAmount,
      invoiceNumber,
      expiryDays,
      invoiceData.auto_pay_taxes or false,
      invoiceData.auto_pay_commission or true
    })

  if invoiceId then
    -- Create commission record if applicable
    if commissionAmount > 0 and invoiceData.commission_recipient_id then
      MySQL.insert.await(
        'INSERT INTO ' ..
        Config.CommissionTableName ..
        ' (invoice_id, recipient_citizenid, recipient_name, recipient_type, commission_type, commission_rate, commission_amount) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
          invoiceId,
          invoiceData.commission_recipient_id,
          invoiceData.commission_recipient_name or 'Unknown',
          'player',
          invoiceData.commission_type or 'percentage',
          invoiceData.commission_rate,
          commissionAmount
        })
    end

    -- Create tax record if applicable
    if taxAmount > 0 then
      MySQL.insert.await(
        'INSERT INTO ' ..
        Config.TaxPaymentTableName .. ' (invoice_id, tax_type, tax_rate, tax_amount, paid_to) VALUES (?, ?, ?, ?, ?)',
        {
          invoiceId,
          'sales_tax',
          taxRate,
          taxAmount,
          Config.GovernmentTaxAccount or 'government'
        })
    end

    TriggerClientEvent('QBCore:Notify', src, Config.Notifications.success, "success")

    -- Notify receiver if online
    local receiverPlayer = GetPlayerByCitizenId(invoiceData.receiver_citizenid)
    if receiverPlayer then
      local receiverSource = GetPlayerSource(receiverPlayer)
      local notifMsg = invoiceData.sender_business_id and Config.Notifications.businessInvoice or "New invoice received!"
      TriggerClientEvent('invoicing:client:receiveInvoice', receiverSource, {
        id = invoiceId,
        sender_name = senderCharinfo.firstname .. ' ' .. senderCharinfo.lastname,
        sender_business_name = senderBusinessName,
        amount = amount,
        total_amount = totalAmount,
        description = invoiceData.description,
        invoice_number = invoiceNumber
      })
      TriggerClientEvent('QBCore:Notify', receiverSource, notifMsg, "info")
    end
  else
    TriggerClientEvent('QBCore:Notify', src, Config.Notifications.error, "error")
  end
end)

-- Pay invoice
RegisterNetEvent('invoicing:server:payInvoice', function(invoiceId)
  local src = source
  local Player = GetPlayer(src)
  if not Player then return end

  -- Get invoice with all details
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

  local totalAmount = invoice.total_amount or (invoice.amount + invoice.tax_amount)

  -- Check if player has enough money
  if GetPlayerMoney(Player, 'bank') < totalAmount then
    TriggerClientEvent('QBCore:Notify', src, "Insufficient funds", "error")
    return
  end

  -- Process payment
  RemovePlayerMoney(Player, 'bank', totalAmount, 'invoice-payment')

  -- Pay the sender (net amount after commission)
  local senderPayment = invoice.net_amount or invoice.amount
  local senderPlayer = GetPlayerByCitizenId(invoice.sender_citizenid)
  if senderPlayer then
    AddPlayerMoney(senderPlayer, 'bank', senderPayment, 'invoice-received')
    local senderSource = GetPlayerSource(senderPlayer)
    TriggerClientEvent('invoicing:client:invoicePaid', senderSource, invoice)
  else
    -- Add money offline
    MySQL.update(
      'UPDATE players SET money = JSON_SET(money, "$.bank", JSON_EXTRACT(money, "$.bank") + ?) WHERE citizenid = ?', {
        senderPayment, invoice.sender_citizenid
      })
  end

  -- Process commission payment if applicable
  if invoice.auto_pay_commission and invoice.commission_amount and invoice.commission_amount > 0 and invoice.commission_recipient_id then
    local commissionPlayer = GetPlayerByCitizenId(invoice.commission_recipient_id)
    if commissionPlayer then
      AddPlayerMoney(commissionPlayer, 'bank', invoice.commission_amount, 'commission-received')
      local commissionSource = GetPlayerSource(commissionPlayer)
      TriggerClientEvent('QBCore:Notify', commissionSource, Config.Notifications.commissionPaid, "success")
    else
      -- Add commission offline
      MySQL.update(
        'UPDATE players SET money = JSON_SET(money, "$.bank", JSON_EXTRACT(money, "$.bank") + ?) WHERE citizenid = ?', {
          invoice.commission_amount, invoice.commission_recipient_id
        })
    end

    -- Update commission status
    MySQL.update(
      'UPDATE ' .. Config.CommissionTableName .. ' SET status = "paid", paid_at = NOW() WHERE invoice_id = ?',
      { invoiceId })
  end

  -- Process tax payment if applicable
  if invoice.auto_pay_taxes and invoice.tax_amount and invoice.tax_amount > 0 then
    -- In a real server, you might want to add this to a government account
    -- For now, we'll just mark it as paid
    MySQL.update(
      'UPDATE ' .. Config.TaxPaymentTableName .. ' SET status = "paid", paid_at = NOW() WHERE invoice_id = ?',
      { invoiceId })

    -- Optional: Add to government account if it's a player account
    if Config.GovernmentTaxAccount and Config.GovernmentTaxAccount ~= 'government' then
      local govPlayer = GetPlayerByCitizenId(Config.GovernmentTaxAccount)
      if govPlayer then
        AddPlayerMoney(govPlayer, 'bank', invoice.tax_amount, 'tax-received')
        local govSource = GetPlayerSource(govPlayer)
        TriggerClientEvent('QBCore:Notify', govSource, Config.Notifications.taxPaid, "info")
      end
    end
  end

  -- Update invoice status
  MySQL.update('UPDATE ' .. Config.TableName .. ' SET status = "paid", paid_at = NOW() WHERE id = ?', { invoiceId })

  TriggerClientEvent('QBCore:Notify', src, Config.Notifications.paid, "success")
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

-- Create business
RegisterNetEvent('invoicing:server:createBusiness', function(businessData)
  local src = source
  local Player = GetPlayer(src)
  if not Player then return end

  -- Validate business data
  if not businessData.name or #businessData.name < Config.BusinessNameMinLength then
    TriggerClientEvent('QBCore:Notify', src, "Business name too short", "error")
    return
  end

  if #businessData.name > Config.BusinessNameMaxLength then
    TriggerClientEvent('QBCore:Notify', src, "Business name too long", "error")
    return
  end

  local identifier = GetPlayerIdentifier(Player)

  -- Check if player already has max businesses
  local existingBusinesses = MySQL.scalar.await(
    'SELECT COUNT(*) FROM ' .. Config.BusinessTableName .. ' WHERE owner_citizenid = ? AND status = "active"',
    { identifier })

  if existingBusinesses >= Config.MaxBusinessesPerPlayer then
    TriggerClientEvent('QBCore:Notify', src, "Maximum businesses limit reached", "error")
    return
  end

  -- Check if business name already exists
  local nameExists = MySQL.scalar.await(
    'SELECT COUNT(*) FROM ' .. Config.BusinessTableName .. ' WHERE name = ?',
    { businessData.name })

  if nameExists > 0 then
    TriggerClientEvent('QBCore:Notify', src, "Business name already exists", "error")
    return
  end

  -- Create business
  local businessId = MySQL.insert.await(
    'INSERT INTO ' .. Config.BusinessTableName ..
    ' (name, owner_citizenid, business_type, phone, email, address, default_commission_rate, auto_tax_payment, tax_exempt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    {
      businessData.name,
      identifier,
      businessData.business_type or 'general',
      businessData.phone or '',
      businessData.email or '',
      businessData.address or '',
      businessData.commission_rate or Config.DefaultCommissionRate,
      businessData.auto_tax_payment or true,
      businessData.tax_exempt or false
    })

  if businessId then
    TriggerClientEvent('QBCore:Notify', src, Config.Notifications.businessCreated, "success")
    TriggerClientEvent('invoicing:client:businessCreated', src, {
      id = businessId,
      name = businessData.name
    })
  else
    TriggerClientEvent('QBCore:Notify', src, "Failed to create business", "error")
  end
end)

-- Delete business
RegisterNetEvent('invoicing:server:deleteBusiness', function(businessId)
  local src = source
  local Player = GetPlayer(src)
  if not Player then return end

  local identifier = GetPlayerIdentifier(Player)

  -- Check if business exists and is owned by player
  local business = MySQL.single.await(
    'SELECT * FROM ' .. Config.BusinessTableName .. ' WHERE id = ? AND owner_citizenid = ?',
    { businessId, identifier })

  if not business then
    TriggerClientEvent('QBCore:Notify', src, "Business not found or not owned by you", "error")
    return
  end

  -- Check if business has pending invoices
  local pendingInvoices = MySQL.scalar.await(
    'SELECT COUNT(*) FROM ' .. Config.TableName .. ' WHERE sender_business_id = ? AND status = "pending"',
    { businessId })

  if pendingInvoices > 0 then
    TriggerClientEvent('QBCore:Notify', src, "Cannot delete business with pending invoices", "error")
    return
  end

  -- Soft delete (set status to inactive)
  local result = MySQL.update.await(
    'UPDATE ' .. Config.BusinessTableName .. ' SET status = "inactive" WHERE id = ? AND owner_citizenid = ?',
    { businessId, identifier })

  if result > 0 then
    TriggerClientEvent('QBCore:Notify', src, "Business deleted successfully", "success")
  else
    TriggerClientEvent('QBCore:Notify', src, "Failed to delete business", "error")
  end
end)

-- Get commission recipients (for dropdown in UI)
CreateCallback('invoicing:server:getCommissionRecipients', function(source, cb)
  local recipients = {}

  -- Add configured recipients from config
  for key, recipient in pairs(Config.CommissionRecipients) do
    table.insert(recipients, {
      id = recipient.citizenid,
      name = recipient.name,
      default_rate = recipient.default_rate,
      type = key
    })
  end

  -- You could also add dynamic recipients from active businesses here
  -- local businesses = MySQL.query.await('SELECT id, name, owner_citizenid FROM ' .. Config.BusinessTableName .. ' WHERE status = "active"')
  -- for _, business in pairs(businesses or {}) do
  --   table.insert(recipients, {
  --     id = business.owner_citizenid,
  --     name = business.name .. " (Business)",
  --     default_rate = Config.DefaultCommissionRate,
  --     type = 'business'
  --   })
  -- end

  cb(recipients)
end)

-- Get commission history for a player
CreateCallback('invoicing:server:getCommissionHistory', function(source, cb)
  local Player = GetPlayer(source)
  if not Player then return cb({}) end

  local identifier = GetPlayerIdentifier(Player)

  local commissions = MySQL.query.await(
    'SELECT c.*, i.amount as invoice_amount, i.description as invoice_description, i.sender_name, i.paid_at as invoice_paid_at FROM ' ..
    Config.CommissionTableName ..
    ' c JOIN ' ..
    Config.TableName .. ' i ON c.invoice_id = i.id WHERE c.recipient_citizenid = ? ORDER BY c.created_at DESC',
    { identifier })

  cb(commissions or {})
end)

-- Get tax payment history for a player/business
CreateCallback('invoicing:server:getTaxHistory', function(source, cb)
  local Player = GetPlayer(source)
  if not Player then return cb({}) end

  local identifier = GetPlayerIdentifier(Player)

  local taxPayments = MySQL.query.await(
    'SELECT t.*, i.amount as invoice_amount, i.description as invoice_description, i.sender_name, i.receiver_name FROM ' ..
    Config.TaxPaymentTableName ..
    ' t JOIN ' ..
    Config.TableName ..
    ' i ON t.invoice_id = i.id WHERE i.sender_citizenid = ? OR i.receiver_citizenid = ? ORDER BY t.created_at DESC',
    { identifier, identifier })

  cb(taxPayments or {})
end)

-- Clean up expired invoices (run periodically)
CreateThread(function()
  while true do
    Wait(3600000) -- Check every hour
    MySQL.update('UPDATE ' ..
      Config.TableName .. ' SET status = "expired" WHERE expires_at < NOW() AND status = "pending"')
  end
end)
