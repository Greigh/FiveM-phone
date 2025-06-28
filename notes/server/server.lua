-- Notes App - Server Side
local QBX = exports.qbx_core

-- Get player notes
QBX.Functions.CreateCallback('notes:server:getNotes', function(source, cb)
    local Player = QBX.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    
    local citizenid = Player.PlayerData.citizenid
    
    local notes = MySQL.query.await('SELECT * FROM ' .. Config.TableName .. ' WHERE citizenid = ? ORDER BY updated_at DESC', {
        citizenid
    })
    
    cb(notes or {})
end)

-- Search notes
QBX.Functions.CreateCallback('notes:server:searchNotes', function(source, cb, query)
    local Player = QBX.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    
    if not query or #query < 2 then return cb({}) end
    
    local citizenid = Player.PlayerData.citizenid
    
    local notes = MySQL.query.await('SELECT * FROM ' .. Config.TableName .. ' WHERE citizenid = ? AND (title LIKE ? OR content LIKE ?) ORDER BY updated_at DESC', {
        citizenid,
        '%' .. query .. '%',
        '%' .. query .. '%'
    })
    
    cb(notes or {})
end)

-- Save note
RegisterNetEvent('notes:server:saveNote', function(noteData)
    local src = source
    local Player = QBX.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Validate data
    if not noteData.title or not noteData.content then
        TriggerClientEvent('notes:client:noteSaved', src, false, "Invalid note data")
        return
    end
    
    -- Check length limits
    if #noteData.title > Config.MaxTitleLength then
        TriggerClientEvent('notes:client:noteSaved', src, false, "Title too long")
        return
    end
    
    if #noteData.content > Config.MaxNoteLength then
        TriggerClientEvent('notes:client:noteSaved', src, false, "Note content too long")
        return
    end
    
    local category = noteData.category or Config.DefaultCategory
    
    if noteData.id then
        -- Update existing note
        local result = MySQL.update.await('UPDATE ' .. Config.TableName .. ' SET title = ?, content = ?, category = ?, updated_at = NOW() WHERE id = ? AND citizenid = ?', {
            noteData.title,
            noteData.content,
            category,
            noteData.id,
            citizenid
        })
        
        if result > 0 then
            -- Get updated note
            local note = MySQL.single.await('SELECT * FROM ' .. Config.TableName .. ' WHERE id = ? AND citizenid = ?', {
                noteData.id, citizenid
            })
            TriggerClientEvent('notes:client:noteSaved', src, true, nil, note)
        else
            TriggerClientEvent('notes:client:noteSaved', src, false, "Failed to update note")
        end
    else
        -- Check note count limit
        local noteCount = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. Config.TableName .. ' WHERE citizenid = ?', {
            citizenid
        })
        
        if noteCount >= Config.MaxNotes then
            TriggerClientEvent('notes:client:noteSaved', src, false, Config.Notifications.maxReached)
            return
        end
        
        -- Create new note
        local noteId = MySQL.insert.await('INSERT INTO ' .. Config.TableName .. ' (citizenid, title, content, category, created_at, updated_at) VALUES (?, ?, ?, ?, NOW(), NOW())', {
            citizenid,
            noteData.title,
            noteData.content,
            category
        })
        
        if noteId then
            -- Get created note
            local note = MySQL.single.await('SELECT * FROM ' .. Config.TableName .. ' WHERE id = ?', {
                noteId
            })
            TriggerClientEvent('notes:client:noteSaved', src, true, nil, note)
        else
            TriggerClientEvent('notes:client:noteSaved', src, false, "Failed to create note")
        end
    end
end)

-- Delete note
RegisterNetEvent('notes:server:deleteNote', function(noteId)
    local src = source
    local Player = QBX.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    local result = MySQL.update.await('DELETE FROM ' .. Config.TableName .. ' WHERE id = ? AND citizenid = ?', {
        noteId, citizenid
    })
    
    if result > 0 then
        TriggerClientEvent('notes:client:noteDeleted', src, true, nil, noteId)
    else
        TriggerClientEvent('notes:client:noteDeleted', src, false, "Failed to delete note")
    end
end)

-- Clean up old notes (optional - run periodically)
CreateThread(function()
    while true do
        Wait(3600000) -- Check every hour
        
        -- You could add cleanup logic here for very old notes if needed
        -- For example, delete notes older than 1 year
        -- MySQL.update('DELETE FROM ' .. Config.TableName .. ' WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR)')
        
        Wait(3600000) -- Wait another hour
    end
end)
