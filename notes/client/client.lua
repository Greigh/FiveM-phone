-- Notes App - Client Side (Universal Framework & Phone Compatible)
local PhoneApps = require 'shared.phone_framework'

-- Local variables
local isNuiOpen = false
local playerData = {}
local currentNotes = {}

-- Initialize framework and phone integration
CreateThread(function()
    Wait(2000) -- Wait for resources to load

    -- Register app with phone system
    PhoneApps.RegisterApp(Config.PhoneApp)

    -- Register framework and phone events
    PhoneApps.RegisterEvents('notes')

    print('[Notes] App initialized and registered')
end)

-- Event handlers
RegisterNetEvent('notes:client:playerLoaded', function()
    playerData = PhoneApps.GetPlayerData()
end)

RegisterNetEvent('notes:client:playerUnloaded', function()
    playerData = {}
end)

RegisterNetEvent('notes:client:jobUpdated', function(jobInfo)
    -- Handle job updates if needed
end)

-- Open notes app
RegisterNetEvent('notes:client:openApp', function()
    if isNuiOpen then return end

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

-- Get all notes
RegisterNUICallback('getNotes', function(data, cb)
    PhoneApps.TriggerCallback('notes:server:getNotes', function(notes)
        currentNotes = notes
        cb(notes)
    end)
end)

-- Save note
RegisterNUICallback('saveNote', function(data, cb)
    TriggerServerEvent('notes:server:saveNote', data)
    cb('ok')
end)

-- Delete note
RegisterNUICallback('deleteNote', function(data, cb)
    TriggerServerEvent('notes:server:deleteNote', data.noteId)
    cb('ok')
end)

-- Search notes
RegisterNUICallback('searchNotes', function(data, cb)
    PhoneApps.TriggerCallback('notes:server:searchNotes', function(notes)
        cb(notes)
    end, data.query)
end)

-- Handle note saved response
RegisterNetEvent('notes:client:noteSaved', function(success, message, note)
    if success then
        PhoneApps.ShowNotification(Config.Notifications.success, "success", 3000)

        -- Update local notes
        if note.id then
            -- Update existing note
            for i, existingNote in ipairs(currentNotes) do
                if existingNote.id == note.id then
                    currentNotes[i] = note
                    break
                end
            end
        else
            -- Add new note
            table.insert(currentNotes, 1, note)
        end

        -- Update UI
        SendNUIMessage({
            action = "updateNotes",
            notes = currentNotes
        })
    else
        PhoneApps.ShowNotification(message or Config.Notifications.error, "error", 3000)
    end
end)

-- Handle note deleted response
RegisterNetEvent('notes:client:noteDeleted', function(success, message, noteId)
    if success then
        PhoneApps.ShowNotification(Config.Notifications.deleted, "success", 3000)

        -- Remove from local notes
        for i, note in ipairs(currentNotes) do
            if note.id == noteId then
                table.remove(currentNotes, i)
                break
            end
        end

        -- Update UI
        SendNUIMessage({
            action = "updateNotes",
            notes = currentNotes
        })
    else
        PhoneApps.ShowNotification(message or Config.Notifications.error, "error", 3000)
    end
end)

-- Command to open notes (for testing)
RegisterCommand('notes', function()
    TriggerEvent('notes:client:openApp')
end, false)

-- Export for phone integration
exports('openNotesApp', function()
    TriggerEvent('notes:client:openApp')
end)

exports('isAppOpen', function()
    return isNuiOpen
end)
