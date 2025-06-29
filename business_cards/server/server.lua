-- Business Cards Phone App - Server Side
local QBX = exports.qbx_core

-- Get player business cards
QBX.Functions.CreateCallback('business_cards:server:getCards', function(source, cb)
    local Player = QBX.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    
    local citizenid = Player.PlayerData.citizenid
    
    local cards = MySQL.query.await('SELECT * FROM ' .. Config.TableName .. ' WHERE owner_citizenid = ? ORDER BY created_at DESC', {
        citizenid
    })
    
    cb(cards or {})
end)

-- Get nearby players for sharing
QBX.Functions.CreateCallback('business_cards:server:getNearbyPlayers', function(source, cb)
    local src = source
    local Player = QBX.Functions.GetPlayer(src)
    if not Player then return cb({}) end
    
    local coords = GetEntityCoords(GetPlayerPed(src))
    local players = {}
    
    for _, playerId in pairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        if targetId ~= src then
            local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
            local distance = #(coords - targetCoords)
            
            if distance <= Config.SharingDistance then
                local TargetPlayer = QBX.Functions.GetPlayer(targetId)
                if TargetPlayer then
                    table.insert(players, {
                        id = targetId,
                        name = TargetPlayer.PlayerData.charinfo.firstname .. " " .. TargetPlayer.PlayerData.charinfo.lastname,
                        distance = math.floor(distance * 100) / 100
                    })
                end
            end
        end
    end
    
    cb(players)
end)

-- Create business card
RegisterNetEvent('business_cards:server:createCard', function(cardData)
    local src = source
    local Player = QBX.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Validate data
    if not cardData.title or not cardData.description then
        TriggerClientEvent('business_cards:client:cardCreated', src, false, "Missing required information")
        return
    end
    
    -- Check length limits
    if #cardData.title > Config.MaxCardTitle or #cardData.description > Config.MaxCardDescription then
        TriggerClientEvent('business_cards:client:cardCreated', src, false, "Text too long")
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    
    -- Check if player has reached maximum cards
    local existingCards = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. Config.TableName .. ' WHERE owner_citizenid = ?', {citizenid})
    if existingCards >= Config.MaxCards then
        TriggerClientEvent('business_cards:client:cardCreated', src, false, "Maximum cards limit reached")
        return
    end
    
    -- Create card
    local cardId = MySQL.insert.await('INSERT INTO ' .. Config.TableName .. ' (owner_citizenid, owner_name, title, description, job_title, phone, email, template, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())', {
        citizenid,
        playerName,
        cardData.title,
        cardData.description,
        cardData.job_title or Player.PlayerData.job.label,
        cardData.phone or Player.PlayerData.charinfo.phone,
        cardData.email or "",
        cardData.template or "Professional"
    })
    
    if cardId then
        TriggerClientEvent('business_cards:client:cardCreated', src, true, Config.Notifications.cardCreated)
    else
        TriggerClientEvent('business_cards:client:cardCreated', src, false, Config.Notifications.error)
    end
end)

-- Share business card
RegisterNetEvent('business_cards:server:shareCard', function(cardId)
    local src = source
    local Player = QBX.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Get card data
    local card = MySQL.single.await('SELECT * FROM ' .. Config.TableName .. ' WHERE id = ? AND owner_citizenid = ?', {
        cardId, Player.PlayerData.citizenid
    })
    
    if not card then
        TriggerClientEvent('QBCore:Notify', src, "Card not found", "error")
        return
    end
    
    -- Get nearby players and share with them
    local coords = GetEntityCoords(GetPlayerPed(src))
    local sharedCount = 0
    
    for _, playerId in pairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        if targetId ~= src then
            local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
            local distance = #(coords - targetCoords)
            
            if distance <= Config.SharingDistance then
                TriggerClientEvent('business_cards:client:receiveCard', targetId, card)
                sharedCount = sharedCount + 1
            end
        end
    end
    
    if sharedCount > 0 then
        TriggerClientEvent('QBCore:Notify', src, string.format("Card shared with %d people nearby", sharedCount), "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "No one nearby to share with", "error")
    end
end)

-- Delete business card
RegisterNetEvent('business_cards:server:deleteCard', function(cardId)
    local src = source
    local Player = QBX.Functions.GetPlayer(src)
    if not Player then return end
    
    local deleted = MySQL.query.await('DELETE FROM ' .. Config.TableName .. ' WHERE id = ? AND owner_citizenid = ?', {
        cardId, Player.PlayerData.citizenid
    })
    
    if deleted.affectedRows > 0 then
        TriggerClientEvent('QBCore:Notify', src, "Business card deleted", "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Failed to delete card", "error")
    end
end)
