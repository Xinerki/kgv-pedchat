_DEBUG = false
pedConvoLevel = 0
lastPed = 0

function DebugPrint(...)
	if _DEBUG == true then
		return print(...)
	end
end

function prc(percentage)
	local rand = math.random(0,100)
	if rand > percentage then
		return false
	elseif rand <= percentage then
		return true
	end
end

convos = {
    
    -- default
    {
        name = "default",
        speech = {
            "GENERIC_HI",
            "GENERIC_HOWS_IT_GOING",
            "CHAT_RESP",
            "GENERIC_WHATEVER",
        },
    },
    
    -- calm
    {
        name = "calm",
        speech = {
            "GENERIC_HOWS_IT_GOING",
            "GENERIC_THANKS",
            "GENERIC_BYE",
        },
    },

    -- scared
    {
        name = "scared",
        speech = {
            --"GENERIC_BYE",
            "GENERIC_CURSE_MED",
            "GENERIC_CURSE_HIGH",
            "GENERIC_FRIGHTENED_HIGH"
        },
        flee = true,
    },

    -- aggressive
    {
        name = "aggressive",
        speech = {
            "GENERIC_HI",
            "GENERIC_WHATEVER",
            --"CHAT_RESP",
            --"GENERIC_FUCK_YOU",
            "GENERIC_INSULT_MED",
            "GENERIC_INSULT_HIGH"
        },
        attack = true,
    },
}

pedConvo = convos[1]

CreateThread(function()
    while true do 
        Wait(0)

        repeat Wait(0) until MumbleIsPlayerTalking(PlayerId()) 
        local startTime = GetGameTimer()
        DebugPrint("started talking")
        repeat Wait(0) until not MumbleIsPlayerTalking(PlayerId())
        local endTime = GetGameTimer()
        DebugPrint("no more talking")

        local duration = endTime - startTime
        DebugPrint("talk duration = "..duration)

        if duration < 500 then
            DebugPrint("duration too short")
        else
            Wait(math.random(200, 800))

            local pool = GetGamePool("CPed")
            for i,v in pairs(pool) do
                if #(GetEntityCoords(v) - GetEntityCoords(PlayerPedId())) < 4.3 and v ~= PlayerPedId() and not IsPedAPlayer(v) then
                    if not IsPedDeadOrDying(v, 1) and not IsPedFleeing(v) and not IsPedInCurrentConversation(v) then
                        if not IsAnySpeechPlaying(v) then
                            if v == lastPed then
                                pedConvoLevel = math.min(pedConvoLevel + 1, #pedConvo.speech)
                            else
                                pedConvoLevel = 1
                                pedConvo = convos[math.random(1,#convos)]
                                DebugPrint(v, "chose convo", pedConvo.name)
                            end
                            
                                -- local speech = "APOLOGY_NO_TROUBLE"
							local speech = pedConvo.speech[pedConvoLevel]
							
                            if IsPedInCombat(v, PlayerPedId()) then
                                -- PlayPedAmbientSpeechNative(v, "GENERIC_INSULT_HIGH", "SPEECH_PARAMS_FORCE_NORMAL")
								local speech = "GENERIC_INSULT_HIGH"
                            else
                                TaskLookAtEntity(v, PlayerPedId(), 3000, 2048, 3)
                                if pedConvoLevel == #pedConvo.speech then
                                    DebugPrint("reached end of convo")
                                    if pedConvo.attack then
                                        -- couldn't figure out how to make random ped attack instead of flee
                                        --DebugPrint("attacking")
                                        --SetPedCombatAbility(v, 2)
                                        --TaskCombatPed(v, PlayerPedId(), 0, 16)
                                    elseif pedConvo.flee then
                                        DebugPrint("fleeing")
                                        TaskReactAndFleePed(v, PlayerPedId())
                                    end
                                else
                                    if prc(15) then
                                        DebugPrint("15% chance passed, turning ped")
                                        TaskTurnPedToFaceEntity(v, PlayerPedId(), 1000)
                                    end
                                end
                            end
							DebugPrint(v, "saying", speech)
							PlayPedAmbientSpeechNative(v, speech, "SPEECH_PARAMS_FORCE_NORMAL")
							TriggerServerEvent("pedchat:receiveSpeech", PedToNet(v), speech)
                            lastPed = v
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("pedchat:sendSpeech")
AddEventHandler("pedchat:sendSpeech", function(player, ped, speech)
	if player ~= GetPlayerServerId(PlayerId()) then
		DebugPrint("Received", ped, speech)
		local ped = NetToPed(ped)
		if DoesEntityExist(ped) then
			PlayPedAmbientSpeechNative(ped, speech, "SPEECH_PARAMS_FORCE_NORMAL")
		end
	end
end)