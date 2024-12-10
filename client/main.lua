function GetCoords()
	if NetworkIsInSpectatorMode() then
		return GetFinalRenderedCamCoord()
	else
		return GetEntityCoords(PlayerPedId())
	end
end

Citizen.CreateThread(function()
	AddTextEntry("PLAYER_CRASHED", "Gecrashte speler")
end)

local msgTypes = {
	[1] = "is gecrasht!",
	[2] = "is de connectie verloren!",
	[3] = "is gecombatlogged!"
}

function AddCrashBlip(coords)
	local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
	SetBlipSprite (blip, 303)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, 1.0)
	SetBlipColour(blip, 1)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("PLAYER_CRASHED")
	EndTextCommandSetBlipName(blip)
	return blip
end

function IsAdmin()
	local staff = false
	local discordperms = exports['discordperms']
	if discordperms:hasstaffgroup() then
		staff = true
	end
	return staff
end

RegisterNetEvent("chat:crashMessage")
AddEventHandler("chat:crashMessage", function(msgType, data)
	local pedCoords = GetCoords()
	local coords = data.coords
	local name = data.name
	local id = data.source
	local distance = #(pedCoords - coords)
	if IsAdmin() then
		if distance < 432.0 then
			TriggerEvent('chat:addMessage', {
				template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(255, 41, 41, 0.6); border-radius: 3px;"><i class="fas fa-globe"></i> <b><font color=grey></b></font> <b>{0}</b> {1}</div>',
				args = { IsAdmin() and name or id, msgTypes[msgType] }
			})
		else
			TriggerEvent('chat:addMessage', {
				template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(255, 41, 41, 0.6); border-radius: 3px;"><i class="fas fa-globe"></i> <b><font color=grey></b></font> <b>{0}</b> {1}</div>',
				args = { IsAdmin() and name or id, msgTypes[msgType] }
			})
		end
		local blip = AddCrashBlip(coords)
		Citizen.SetTimeout(900000, function()
			RemoveBlip(blip)
		end)
	else
		if #(pedCoords - coords) < 50 then
			TriggerEvent('chat:addMessage', {
				template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(255, 41, 41, 0.6); border-radius: 3px;"><i class="fas fa-globe"></i> <b><font color=grey></b></font> <b>{0}</b> {1}</div>',
				args = { IsAdmin() and name or id, msgTypes[msgType] }
			})
		elseif #(pedCoords - coords) < 200 then
			TriggerEvent('chat:addMessage', {
				template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(41, 41, 41, 0.6); border-radius: 3px;"><i class="fas fa-globe"></i> <b><font color=grey></b></font> <b>{0}</b> {1}</div>',
				args = { IsAdmin() and name or id, msgTypes[msgType] }
			})
		elseif #(pedCoords - coords) < 300 then
			TriggerEvent('chat:addMessage', {
				template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(41, 41, 41, 0.6); border-radius: 3px;"><i class="fas fa-globe"></i> <b><font color=grey></b></font> <b>{0}</b> {1}</div>',
				args = { IsAdmin() and name or id, msgTypes[msgType] }
			})
		end
	end

end)

function GetCrashesWithinRadius(crashes, coords, radius)
	local result = {}
	local coordsSum = vector3(0, 0, 0)
	for i=#crashes, 1, -1 do
		local v = crashes[i]
		if #(coords - v) <= radius then
			table.insert(result, v)
			coordsSum = coordsSum + v
		end
	end

	local avgCoords = coordsSum / #result

	for i=#crashes, 1, -1 do
		local v = crashes[i]
		if #(avgCoords - v) <= radius then
			table.insert(result, v)
			table.remove(crashes, i)
		end
	end

	return result, avgCoords
end

function AddCrashMetricsBlip(crashes, coords, radius)
	local numCrashes, avgCoords = GetCrashesWithinRadius(crashes, coords, radius)
	local blip = AddBlipForCoord(avgCoords.x, avgCoords.y, avgCoords.z)
	SetBlipSprite (blip, 685 + math.min(#numCrashes, 36))
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, 1.0)
	SetBlipColour(blip, #numCrashes > 36 and 1 or 0)
	SetBlipPriority(blip, #numCrashes)
	SetBlipAsShortRange(blip, true)
	AddTextEntry("PLAYER_CRASHED" .. #numCrashes, ("%s Gecrashte spelers"):format(#numCrashes))
	BeginTextCommandSetBlipName("PLAYER_CRASHED" .. #numCrashes)
	EndTextCommandSetBlipName(blip)
	return blip
end

local activeCrashBlips = {}
RegisterNetEvent("esx_rpchat:receiveCrashBlips", function(coords, radius)
	if #activeCrashBlips > 0 then
		for k,v in pairs(activeCrashBlips) do
			RemoveBlip(v)
		end
		table.clear(activeCrashBlips)
	end

	print(("Totaal aantal crashes gevonden: %s"):format(#coords))

	for i=1, #coords do
		local v = coords[i]
		coords[i] = vector3(v.x, v.y, v.z)
	end

	while #coords > 0 do
		table.insert(activeCrashBlips, AddCrashMetricsBlip(coords, coords[1], radius))
		Citizen.Wait(0)
	end

	Citizen.SetTimeout(900000, function()
		if #activeCrashBlips > 0 then
			for k,v in pairs(activeCrashBlips) do
				RemoveBlip(v)
			end
			table.clear(activeCrashBlips)
		end
	end)
end)

RegisterNetEvent('sendProximityMessage')
AddEventHandler('sendProximityMessage', function(id, name, message)
	local myId = PlayerId()
	local pid = GetPlayerFromServerId(id)
	local coords = GetCoords()

	if pid == myId then
		TriggerEvent('chatMessage', "^4" .. name .. "", {0, 153, 204}, "^7 " .. message)
	elseif pid ~= -1 and #(coords - GetEntityCoords(GetPlayerPed(pid))) < 19.999 then
		TriggerEvent('chatMessage', "^4" .. name .. "", {0, 153, 204}, "^7 " .. message)
	end
end)

local mumbleVoip = exports["mumble-voip"]
function IsLocal(pid, myId, range)
	range = range or 15.4
	local coords = GetCoords()
	if pid == myId then
		return true
	end
	if pid == -1 then
		return false
	end

	if #(coords - GetEntityCoords(GetPlayerPed(pid))) < range then
		return true
	end
end

local function getPlayerFromChange(bagName)
	local player = bagName:gsub("player:", "")
	player = tonumber(player)

	return player
end

local displayTime = 7000
local nbrDisplaying = {}
function DisplayMessageAboveHead(serverId, text, range)
	local player = GetPlayerFromServerId(serverId)

	if serverId == -1 then
		return
	end

    range = range or mumbleVoip:GetVoiceRange(serverId) or 15.4

	local offset = vector3(0, 0, 1 + ((nbrDisplaying[player] or 1) * 0.14))

    local ped = GetPlayerPed(player)
    local coordsMe = GetEntityCoords(ped, false)
    local coords = GetEntityCoords(PlayerPedId(), false)
    local dist = #(coordsMe - coords)

    if dist < 100 then
        Citizen.CreateThread(function()
            nbrDisplaying[player] = (nbrDisplaying[player] or 1) + 1
			local start = GetGameTimer()
            while GetGameTimer() - start < displayTime do
                Citizen.Wait(0)
                coordsMe = GetEntityCoords(ped, false)
                coords = GetEntityCoords(PlayerPedId(), false)
                dist = #(coordsMe - coords)
                if dist < range then
                    if HasEntityClearLosToEntity(PlayerPedId(), ped, 17) then
                        DrawText3D(coordsMe + offset, text)
                    end
                end
            end
            nbrDisplaying[player] = nbrDisplaying[player] - 1
			if nbrDisplaying[player] == 0 then
				nbrDisplaying[player] = nil
			end
        end)
    end
end

function MessageMe(player, message)
	local pid = GetPlayerFromServerId(player)
	print(player, pid, message)
	if pid == -1 then
		return
	end

	local myId = PlayerId()
	local voiceRange = mumbleVoip:GetVoiceRange(player) or 15.4
	if IsLocal(pid, myId, voiceRange) then
		TriggerEvent('chat:addMessage', {
			template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(255, 41, 41, 0.6); border-radius: 3px;"><i class="fas fa-user-circle"></i> <b>{0}:</b> {1}</div>',
			args = { player, message }
		})

		DisplayMessageAboveHead(player, message, voiceRange)
	end
end

function MessageDo(player, message)
	local pid = GetPlayerFromServerId(player)

	if pid == -1 then
		return
	end

	local myId = PlayerId()

	local voiceRange = mumbleVoip:GetVoiceRange(player) or 15.4
	if IsLocal(pid, myId, voiceRange) then
		TriggerEvent('chat:addMessage', {
			template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(81, 245, 66, 0.6); border-radius: 3px;"><i class="fas fa-user-circle"></i> <b>{0}:</b> {1}</div>',
			args = { player, message }
		})

		DisplayMessageAboveHead(player, message, voiceRange)
	end
end

function MessageLooc(player, message)
	local pid = GetPlayerFromServerId(player)

	if pid == -1 then
		return
	end

	local myId = PlayerId()

	if IsLocal(pid, myId, 50.0) then
		TriggerEvent('chat:addMessage', {
			template = '<div style="padding: 0.8vh; margin: 0.8vh; background-color: rgba(41, 41, 41, 0.6); border-radius: 3px;"><i class="fas fa-globe"></i> <b><font color=grey>LOOC</b></font> <b>{0}:</b> {1}</div>',
			args = { player, message }
		})

		DisplayMessageAboveHead(player, message, 50.0)
	end
end

AddStateBagChangeHandler("message", nil, function (bagName, key, value, reserved, replicated)
	if not value then
		return
	end

	local player = getPlayerFromChange(bagName)

	local messageType = value[1]
	local message = value[2]

	if messageType == MESSAGE_TYPES.DO then
		MessageDo(player, message)
	elseif messageType == MESSAGE_TYPES.ME then
		MessageMe(player, message)
	elseif messageType == MESSAGE_TYPES.LOOC then
		MessageLooc(player, message)
	end
end)

RegisterNetEvent('esx-qalle-chat:looc', function(id, message)
	MessageLooc(id, message)
end)

if false then
	---@class Formatting
	---@field type? "success"|"error"|"warning"|"info"
	---@field r? number
	---@field g? number
	---@field b? number
	---@field a? number
	---@field important? boolean
	local formatting = {}
end

exports('printToChat', PrintToChat)
exports('PrintToChat', PrintToChat)

exports("SendReply", SendReply)

RegisterNetEvent("staff:bannedPlayer", function(source, time, prefix, banReason)
	if type(source) == "number" then
		source = ("[%s]"):format(source)
	else
		source = "Een speler"
	end
	PrintToChat(prefix, ('^3%s^0 is %s^0 op vakantie gestuurd voor ^3%s^0!'):format(source, time, banReason))
end)