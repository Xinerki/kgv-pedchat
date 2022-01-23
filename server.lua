RegisterServerEvent("pedchat:receiveSpeech")
AddEventHandler('pedchat:receiveSpeech', function(ped, speech)
	local str = string.format("PEDSPEECH: %s triggered %d: \"%s\"", GetPlayerName(source), ped, speech)
	print(str)
	
	TriggerClientEvent("pedchat:sendSpeech", -1, source, ped, speech)
end)