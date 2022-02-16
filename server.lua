local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface("vrp_mdt",src)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PREPARE
-----------------------------------------------------------------------------------------------------------------------------------------
vRP._prepare("mdt/get_user_inssues","SELECT * FROM vrp_mdt WHERE user_id = @user_id")
vRP._prepare("mdt/get_user_arrest","SELECT * FROM vrp_mdt WHERE user_id = @user_id AND type = @type")
vRP._prepare("mdt/add_user_inssues","INSERT INTO vrp_mdt(user_id,type,value,data,info,officer) VALUES(@user_id,@type,@value,@data,@info,@officer,@warning,@arrest,@ticket); SELECT LAST_INSERT_ID() AS slot")

-----------------------------------------------------------------------------------------------------------------------------------------
-- WEBHOOK
-----------------------------------------------------------------------------------------------------------------------------------------
local webhookarsenal = "#"
local webhookprender = "#"
local webhookmultas = "#"
local webhookocorrencias = "#"
local webhookdetido = "#"
local webhookre = "#"
local webhookpoliciaapreendidos = "#"
local webhookpolicia = "#"
local webhookparamedico = "#"
local webhookmecanico = "#"
local webhookbombeiro = "#"

function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- SEARCH INFO
-----------------------------------------------------------------------------------------------------------------------------------------
function src.infoUser(user)
	local source = source 
	if user then
		local value = vRP.getUData(parseInt(user),"vRP:multas")
		local multas = json.decode(value) or 0
		local identity = vRP.getUserIdentity(parseInt(user))
		local arrests = vRP.query("mdt/get_user_arrest",{ user_id = parseInt(user), type = "arrest" })
		local tickets = vRP.query("mdt/get_user_arrest",{ user_id = parseInt(user), type = "ticket" })
		local warnings = vRP.query("mdt/get_user_arrest",{ user_id = parseInt(user), type = "warning" })
		if identity then
			return multas,identity.name,identity.firstname,identity.registration,parseInt(identity.age),#arrests,#warnings
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEARCH ARRESTS
-----------------------------------------------------------------------------------------------------------------------------------------
function src.arrestsUser(user)
	local source = source
	if user then
		local data = vRP.query("mdt/get_user_arrest",{ user_id = user, type = "arrest" })
		local arrest = {}
		if data then
			for k,v in pairs(data) do
				table.insert(arrest,{ data = v.data, value = v.value, info = v.info, officer = v.officer })
			end
			return arrest
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEARCH TICKETS
-----------------------------------------------------------------------------------------------------------------------------------------
function src.ticketsUser(user)
	local source = source
	if user then
		local data = vRP.query("mdt/get_user_arrest",{ user_id = user, type = "ticket" })
		local arrest = {}
		if data then
			for k,v in pairs(data) do
				table.insert(arrest,{ data = v.data, value = v.value, info = v.info, officer = v.officer })
			end
			return arrest
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- USER DATA
-----------------------------------------------------------------------------------------------------------------------------------------
function src.userData()
	local source = source
	local user_id = vRP.getUserId(source)
	local identity = vRP.getUserIdentity(user_id)
	if user_id then
		return user_id, identity.name .. " " .. identity.firstname
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEARCH WARNINGS
-----------------------------------------------------------------------------------------------------------------------------------------
function src.warningsUser(user)
	local source = source
	if user then
		local data = vRP.query("mdt/get_user_arrest",{ user_id = user, type = "warning" })
		local arrest = {}
		if data then
			for k,v in pairs(data) do
				table.insert(arrest,{ data = v.data, value = v.value, info = v.info, officer = v.officer })
			end
			return arrest
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WARNING
-----------------------------------------------------------------------------------------------------------------------------------------
function src.warningUser(user,date,info,officer)
	local source = source
	if user then
		local user_id = vRP.getUserId(source)
		vRP.execute("mdt/add_user_inssues",{ user_id = user, type = "warning", value = 0, data = date, info = info, officer = user_id })
		TriggerClientEvent("Notify",source,"sucesso","Aviso aplicado com sucesso.",8000)
		vRPclient.playSound(source,"Hack_Success","DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS")
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function src.ticketUser(user,value,date,info)
	local source = source
	local user_id = vRP.getUserId(source)
	if user then
		local valor = vRP.getUData(parseInt(user),"vRP:multas")
		local multas = json.decode(valor) or 0
		local oficialid = vRP.getUserIdentity(user_id)
		local identity = vRP.getUserIdentity(parseInt(user))
		local nplayer = vRP.getUserSource(parseInt(user))
		randmoney = math.random(90,150)
		vRP.giveMoney(user_id,parseInt(randmoney))
		vRP.setUData(parseInt(user),"vRP:multas",json.encode(parseInt(multas)+parseInt(value)))
		SendWebhookMessage(webhookmultas,"```prolog\n[OFICIAL]: "..user_id.." "..oficialid.name.." "..oficialid.firstname.." \n[==============MULTOU==============] \n[PASSAPORTE]: "..user.." "..identity.name.." "..identity.firstname.." \n[VALOR]: R$"..vRP.format(parseInt(value)).." \n[MOTIVO]: "..info.." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
		vRP.execute("mdt/add_user_inssues",{ user_id = user, type = "ticket", value = parseInt(value), data = date, info = info, officer = user_id.." "..oficialid.name.." "..oficialid.firstname })
		TriggerClientEvent("Notify",source,"sucesso","Multa aplicada com sucesso.",8000)
		TriggerClientEvent("Notify",source,"importante","Você recebeu <b>R$"..vRP.format(parseInt(randmoney)).." reais</b> de bonificação.")
		TriggerClientEvent("Notify",nplayer,"importante","Você foi multado em <b>R$"..vRP.format(parseInt(value)).." reais</b>.<br><b>Motivo:</b> "..info..".")
		vRPclient.playSound(source,"Hack_Success","DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS")
	end
end

function prison_lock(target_id)
	local player = vRP.getUserSource(parseInt(target_id))
	if player then
		SetTimeout(60000,function()
			local value = vRP.getUData(parseInt(target_id),"vRP:prisao")
			local tempo = json.decode(value) or 0
			if parseInt(tempo) >= 1 then
				TriggerClientEvent("Notify",player,"importante","Ainda vai passar <b>"..parseInt(tempo).." meses</b> preso.")
				vRP.setUData(parseInt(target_id),"vRP:prisao",json.encode(parseInt(tempo)-1))
				prison_lock(parseInt(target_id))
			elseif parseInt(tempo) == 0 then
				TriggerClientEvent('prisioneiro',player,false)
				vRPclient.teleport(player,1850.5,2604.0,45.5)
				vRP.setUData(parseInt(target_id),"vRP:prisao",json.encode(-1))
				TriggerClientEvent("Notify",player,"importante","Sua sentença terminou, esperamos não ve-lo novamente.")
			end
			vRPclient.PrisionGod(player)
		end)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function src.arrestUser(user,value,date,info,officer)
	local source = source
	local user_id = vRP.getUserId(source)
	if user then
		local player = vRP.getUserSource(parseInt(user))
		if player then
			vRP.setUData(user, "vRP:prisao", json.encode(parseInt(tempo)))
			vRPclient.setHandcuffed(player,false)
			TriggerClientEvent('prisioneiro',player,true)

			vRPclient.teleport(player,1680.1,2513.0,45.5)
			prison_lock(parseInt(user))
			TriggerClientEvent('removealgemas',player)
			TriggerClientEvent("vrp_sound:source",player,'jaildoor',0.7)
			TriggerClientEvent("vrp_sound:source",source,'jaildoor',0.7)

			-- APLICAR ROUPA DE PRISIONEIRO
			local old_custom = vRPclient.getCustomization(player)
			local custom = {
				[1885233650] = {
					[1] = { -1,0 }, -- máscara
		            [3] = { 0,0 }, -- maos
		            [4] = { 5,7 }, -- calça
		            [5] = { -1,0 }, -- mochila
		            [6] = { 5,2 }, -- sapato
		            [7] = { -1,0 },  -- acessorios
		            [8] = { -1,0 }, -- blusa
		            [9] = { -1,0 }, -- colete
		            [10] = { -1,0 }, -- adesivo
		            [11] = { 22,0 }, -- jaqueta	
					["p0"] = { -1,0 }, -- chapeu
					["p1"] = { -1,0 },
					["p2"] = { -1,0 },
					["p6"] = { -1,0 },
					["p7"] = { -1,0 }
				},
				[-1667301416] = {
					[1] = { -1,0 },
		            [3] = { 14,0 },
		            [4] = { 66,6 },
		            [5] = { -1,0 },
		            [6] = { 5,0 },
		            [7] = { -1,0 },
		            [8] = { 6,0 },
		            [9] = { -1,0 },
		            [10] = { -1,0 },
		            [11] = { 73,0 },
					["p0"] = { -1,0 },
					["p1"] = { -1,0 },
					["p2"] = { -1,0 },
					["p6"] = { -1,0 },
					["p7"] = { -1,0 }
				}
			}

			local idle_copy = {}
			idle_copy.modelhash = nil
			for l,w in pairs(custom[old_custom.modelhash]) do
				idle_copy[l] = w
			end
			vRPclient._setCustomization(player, idle_copy)

			local oficialid = vRP.getUserIdentity(user_id)
			local identity = vRP.getUserIdentity(parseInt(user))
			local nplayer = vRP.getUserSource(parseInt(user))
			SendWebhookMessage(webhookprender,"```prolog\n[OFICIAL]: "..user_id.." "..oficialid.name.." "..oficialid.firstname.." \n[==============PRENDEU==============] \n[PASSAPORTE]: "..user.." "..identity.name.." "..identity.firstname.." \n[TEMPO]: "..vRP.format(value).." Meses \n[CRIMES]: "..info.." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").."\n[PROTOCOLO]: "..os.time(os.date("!*t")).." \r```")
			
			randmoney = math.random(parseInt(tempo), parseInt(tempo) * 2)
			vRP.giveMoney(user_id,parseInt(randmoney))
			vRP.execute("mdt/add_user_inssues",{ user_id = user, type = "arrest", value = parseInt(value), data = date, info = info, officer = user_id })
			TriggerClientEvent("Notify",source,"sucesso","Você prendeu o passaporte <b>"..user.."</b> por <b>"..value.." meses</b> efetuada com sucesso.")
			TriggerClientEvent("Notify",source,"importante","Você recebeu <b>R$"..vRP.format(parseInt(randmoney)).." reais</b> de bonificação.")
			TriggerClientEvent("Notify",nplayer,"importante","Você foi preso por <b>"..vRP.format(parseInt(value)).." meses</b>.<br><b>Motivo:</b> "..info..".")
			vRPclient.playSound(source,"Hack_Success","DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS")
			vRPclient.playSound(nplayer,"Hack_Success","DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS")

		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function src.checkPermission()
	local source = source
	local user_id = vRP.getUserId(source)
	return vRP.hasPermission(user_id,"policia.permissao")
end