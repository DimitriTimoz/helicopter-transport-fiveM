local RCCar = {['towed'] = false}

RegisterCommand("rc", function()
	RCCar.Start() -- spawn le charriot
end)

RegisterCommand("stop", function()
	RCCar.Attach("pick") -- Supprime le charriot 
end)

RegisterNetEvent('helicopter:spawn-cart')
AddEventHandler('helicopter:spawn-cart', function ()
	RCCar.Start()
end)

RegisterNetEvent('helicopter:stop-cart')
AddEventHandler('helicopter:stop-cart', function ()
	RCCar.Tablet(false)
	RCCar.Attach("pick")
end)

local collision = true

RCCar.Start = function()
	if DoesEntityExist(RCCar.Entity) then return end

	RCCar.Spawn()

	RCCar.Tablet(true)

	while DoesEntityExist(RCCar.Entity) and DoesEntityExist(RCCar.Driver) do
		Citizen.Wait(5)

		local distanceCheck = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()),  GetEntityCoords(RCCar.Entity), true)

		RCCar.DrawInstructions(distanceCheck)
		RCCar.HandleKeys(distanceCheck)

		if distanceCheck <= Config.LoseConnectionDistance then
			if not NetworkHasControlOfEntity(RCCar.Driver) then
				NetworkRequestControlOfEntity(RCCar.Driver)
			elseif not NetworkHasControlOfEntity(RCCar.Entity) then
				NetworkRequestControlOfEntity(RCCar.Entity)
			end
		else
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 6, 2500)
		end
	end
end

RCCar.HandleKeys = function(distanceCheck)
	if distanceCheck < Config.LoseConnectionDistance then
		if IsControlPressed(0, 172) then
			if GetEntitySpeed(RCCar.Entity) > 1.5 then
        		SetVehicleForwardSpeed(RCCar.Entity, 1.5)
       	    end 
		end

		if IsControlPressed(0, 173) then
			if GetEntitySpeed(RCCar.Entity) > 1.5 then
        		SetVehicleForwardSpeed(RCCar.Entity, -1.5)
       	    end 
		end

		if IsControlPressed(0, 172) and not IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 9, 1)
		end
		
		if IsControlJustReleased(0, 172) or IsControlJustReleased(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 6, 2500)
		end

		if IsControlPressed(0, 173) and not IsControlPressed(0, 172) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 22, 1)
		end

		if IsControlPressed(0, 174) and IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 13, 1)
		end

		if IsControlPressed(0, 175) and IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 14, 1)
		end

		if IsControlPressed(0, 172) and IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 30, 100)
		end

		if IsControlPressed(0, 174) and IsControlPressed(0, 172) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 7, 1)
		end

		if IsControlPressed(0, 175) and IsControlPressed(0, 172) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 8, 1)
		end

		if IsControlPressed(0, 174) and not IsControlPressed(0, 172) and not IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 4, 1)
		end

		if IsControlPressed(0, 175) and not IsControlPressed(0, 172) and not IsControlPressed(0, 173) then
			TaskVehicleTempAction(RCCar.Driver, RCCar.Entity, 5, 1)
		end

		if IsControlJustPressed(0, 38)then
			RCCar.Tow()
		end
	end
end

RCCar.DrawInstructions = function(distanceCheck)
	local steeringButtons = {
		{
			["label"] = "Droite",
			["button"] = "~INPUT_CELLPHONE_RIGHT~"
		},
		{
			["label"] = "Avancer",
			["button"] = "~INPUT_CELLPHONE_UP~"
		},
		{
			["label"] = "Reculer",
			["button"] = "~INPUT_CELLPHONE_DOWN~"
		},
		{
			["label"] = "Gauche",
			["button"] = "~INPUT_CELLPHONE_LEFT~"
		},
	}

	local buttonsToDraw = {
		{
			["label"] = "Attacher/Detacher",
			["button"] = "~INPUT_CONTEXT~"
		}
	}

	if distanceCheck <= Config.LoseConnectionDistance then
		for buttonIndex = 1, #steeringButtons do
			local steeringButton = steeringButtons[buttonIndex]

			table.insert(buttonsToDraw, steeringButton)
		end
	end

    Citizen.CreateThread(function()
        local instructionScaleform = RequestScaleformMovie("instructional_buttons")

        while not HasScaleformMovieLoaded(instructionScaleform) do
            Wait(0)
        end

        PushScaleformMovieFunction(instructionScaleform, "CLEAR_ALL")
        PushScaleformMovieFunction(instructionScaleform, "TOGGLE_MOUSE_BUTTONS")
        PushScaleformMovieFunctionParameterBool(0)
        PopScaleformMovieFunctionVoid()

        for buttonIndex, buttonValues in ipairs(buttonsToDraw) do
            PushScaleformMovieFunction(instructionScaleform, "SET_DATA_SLOT")
            PushScaleformMovieFunctionParameterInt(buttonIndex - 1)

            PushScaleformMovieMethodParameterButtonName(buttonValues["button"])
            PushScaleformMovieFunctionParameterString(buttonValues["label"])
            PopScaleformMovieFunctionVoid()
        end

        PushScaleformMovieFunction(instructionScaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
        PushScaleformMovieFunctionParameterInt(-1)
        PopScaleformMovieFunctionVoid()
        DrawScaleformMovieFullscreen(instructionScaleform, 255, 255, 255, 255)
	end)
end

RCCar.Spawn = function()
	RCCar.LoadModels({ GetHashKey("airtug"), 68070371 })

	local spawnCoords, spawnHeading = GetEntityCoords(PlayerPedId()) + GetEntityForwardVector(PlayerPedId()) * 2.0, GetEntityHeading(PlayerPedId())
	RCCar.Entity = CreateVehicle(GetHashKey("airtug"), spawnCoords , spawnHeading, true)
	RCCar.Cart = CreateObject(GetHashKey("prop_air_trailer_4b"), 0, 0, 0, true, true, true)
	while not DoesEntityExist(RCCar.Entity) do
		Citizen.Wait(5)
	end

	SetEntityInvincible(RCCar.Entity, true)
	SetEntityVisible(RCCar.Entity, false)
	AttachEntityToEntity(RCCar.Cart, RCCar.Entity, GetPedBoneIndex(PlayerPedId(), 28422), 0.0, 0.0, -0.44, 0.0, 0.0, 90.0, true, true, true, true, 1, true)	
	RCCar.Driver = CreatePed(5, 68070371, spawnCoords, spawnHeading, true)
	SetEntityCollision(RCCar.Driver, false)
	SetEntityInvincible(RCCar.Driver, true)
	SetEntityVisible(RCCar.Driver, false)
	FreezeEntityPosition(RCCar.Driver, true)
	SetPedAlertness(RCCar.Driver, 0.0)

	TaskWarpPedIntoVehicle(RCCar.Driver, RCCar.Entity, -1)

	while not IsPedInVehicle(RCCar.Driver, RCCar.Entity) do
		Citizen.Wait(0)
	end

end

RCCar.Attach = function(param)
	if not RCCar.towed then
		if not DoesEntityExist(RCCar.Entity) then
			return
		end

		if param == "pick" then
			RCCar.Tablet(false)

			Citizen.Wait(900)
		
			DetachEntity(RCCar.Entity)

			DeleteVehicle(RCCar.Entity)
			DeleteEntity(RCCar.Driver)

			RCCar.UnloadModels()
		end
	else
		ShowNotification("~r~ Vous devez d'abord détacher l'hélicoptère avant de ranger le charriot")
	end			
end


RCCar.Tablet = function(boolean)
	if boolean then
		RCCar.LoadModels({ GetHashKey("prop_cs_tablet") })

		RCCar.TabletEntity = CreateObject(GetHashKey("prop_cs_tablet"), GetEntityCoords(PlayerPedId()), true)

		AttachEntityToEntity(RCCar.TabletEntity, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), -0.03, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
	
		RCCar.LoadModels({ "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a" })
	
		TaskPlayAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 3.0, -8, -1, 63, 0, 0, 0, 0 )
	
		Citizen.CreateThread(function()
			while DoesEntityExist(RCCar.TabletEntity) do
				Citizen.Wait(5)
	
				if not IsEntityPlayingAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 3) then
					TaskPlayAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 3.0, -8, -1, 63, 0, 0, 0, 0 )
				end
			end

			ClearPedTasks(PlayerPedId())
		end)
	else
		DeleteEntity(RCCar.TabletEntity)
	end
end


RCCar.LoadModels = function(models)
	for modelIndex = 1, #models do
		local model = models[modelIndex]

		if not RCCar.CachedModels then
			RCCar.CachedModels = {}
		end

		table.insert(RCCar.CachedModels, model)

		if IsModelValid(model) then
			while not HasModelLoaded(model) do
				RequestModel(model)
	
				Citizen.Wait(10)
			end
		else
			while not HasAnimDictLoaded(model) do
				RequestAnimDict(model)
	
				Citizen.Wait(10)
			end    
		end
	end
end

RCCar.UnloadModels = function()
	for modelIndex = 1, #RCCar.CachedModels do
		local model = RCCar.CachedModels[modelIndex]

		if IsModelValid(model) then
			SetModelAsNoLongerNeeded(model)
		else
			RemoveAnimDict(model)   
		end
	end
end

function ShowNotification(text)
	SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, true)
end

local backY = -5.0
RCCar.Tow = function()	
	local coords = GetEntityCoords(GetPlayerPed(-1))
	local targetVehicle = GetPlayersLastVehicle(GetPlayerPed(-1))  -- Vehicule à déplacer
	local x,y,z  = 0.0, 0.0, 0.0
	if not RCCar.towed then	
		if targetVehicle ~= 0 then
			if GetVehicleClass(targetVehicle) == 15 then
				if targetVehicle ~= RCCar.Entity then
					if GetDistanceBetweenCoords(GetEntityCoords(RCCar.Entity, true)['x'], GetEntityCoords(RCCar.Entity, true)['y'], GetEntityCoords(RCCar.Entity, true)['z'], coords['x'], coords['y'], coords['z'], false) <= 10 then
						RCCar.targetVehicle = targetVehicle -- Helicopter

						local targetVehicleHash = GetHashKey(targetVehicle)
							
						--DEFAUT--
						x = 0.0
						y = 0.0
						z = 1.7
						backY = -5.0	
						--CUSTOM--
						-- Pour ajouter une position custom dupliquez une condition puis dans la condition 
						--'IsVehicleModel(.., GetHashKey(-ici-))' inserez le nom de votre helicoptère
						-- Ensuite régles x,y et z. 
						--'z' est la hauteur
						--'y' est de l'avant à l'arrière
						--'x' est de gauche à droite
						--'backY' est la position y du vehicule lorsqu il sera d'étaché
						-- Les coordonnés doivent toujours avoir un chiffre après la virgule il peut être '0' ex: 0.0
						if IsVehicleModel(targetVehicle, GetHashKey('polmav')) or IsVehicleModel(targetVehicle, GetHashKey('maverick')) then
							y = -0.5
							z = 1.37
						elseif IsVehicleModel(targetVehicle, GetHashKey('swift2')) or IsVehicleModel(targetVehicle, GetHashKey('swift')) then
							y = -1.3
							z = 0.45
							backY = -6.0
						elseif IsVehicleModel(targetVehicle, GetHashKey('volatus'))then
							y = -1.8
							z = 1.25
							backY = -8.0
						elseif IsVehicleModel(targetVehicle, GetHashKey('frogger')) or IsVehicleModel(targetVehicle, GetHashKey('frogger2')) then
							y = -0.8
							z = 0.7
						elseif IsVehicleModel(targetVehicle, GetHashKey('buzzard')) or IsVehicleModel(targetVehicle, GetHashKey('buzzard2')) then
							y = -0.7
							z = 0.85
						elseif IsVehicleModel(targetVehicle, GetHashKey('cargobob')) or IsVehicleModel(targetVehicle, GetHashKey('cargobob2')) or IsVehicleModel(targetVehicle, GetHashKey('cargobob3')) then
							y = 0.0	
							z = 0.9	
							backY = -10.0
						elseif IsVehicleModel(targetVehicle, GetHashKey('savage'))then
							y = -1.5
							z = 1.0	
							backY = -8.0
						elseif IsVehicleModel(targetVehicle, GetHashKey('annihilator'))then
							y = 0.0
							z = 0.5
							backY = -8.0				
						end	
						
						-- Attache l'hélicoptère au charriot
						AttachEntityToEntity(targetVehicle, RCCar.Entity, GetObjectIndexFromEntityIndex(RCCar.Entity), x, y, z, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
						RCCar.towed = true
					end
				end	
			end	
		end
	else
		
		AttachEntityToEntity(targetVehicle, RCCar.Entity, GetObjectIndexFromEntityIndex(RCCar.Entity), 0.0, backY, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
		DetachEntity(RCCar.targetVehicle, true, true)			
		RCCar.towed = false
	end
		Citizen.Wait(500)				
end

