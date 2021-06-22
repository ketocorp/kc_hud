local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 173,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 244, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

autopilotActive = false
seatbeltIsOn = false

local vehicleCruiser = 'off'
local seatbeltEjectSpeed = 45.0 
local seatbeltEjectAccel = 100.0
local beltWarningSet = false
local currSpeed = 0.0
local prevVelocity = {x = 0.0, y = 0.0, z = 0.0}
local speedBuffer  	  = {}
local velBuffer  	  = {}
local isBlackedOut = false
local seatbeltSpeedPedOut = 1.6
local MinSpeedBelt = 45
local lastVehCache
local PedVehIsHeli = false
local PedVehIsPlane = false
local PedVehIsBoat = false 
local PedVehIsBike = false 
local PedVehIsCar = false
local PedVehIsMotorcycle = false


WichVehicleItIs = function(veh)
	if(lastVehCache == nil or lastVehCache ~= veh) then
		lastVehCache = veh
		PedVehIsHeli = false
		PedVehIsPlane = false
		PedVehIsBoat = false 
		PedVehIsBike = false 
		PedVehIsCar = false
		PedVehIsMotorcycle = false
		local vc = GetVehicleClass(veh)
		if( (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)) then
			PedVehIsCar = true
		elseif(vc == 8) then
			PedVehIsMotorcycle = true
		elseif(vc == 13) then
			PedVehIsBike = true
		elseif(vc == 14) then
			PedVehIsBoat = true
		elseif(vc == 15) then
			PedVehIsHeli = true
		elseif(vc == 16) then
			PedVehIsPlane = true
		end
	end
end
Fwv = function (entity)
		    local hr = GetEntityHeading(entity) + 90.0
		    if hr < 0.0 then hr = 360.0 + hr end
		    hr = hr * 0.0174533
		    return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
      end
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
        local MyPed = PlayerPedId()
        local MyPedVeh = GetVehiclePedIsIn(MyPed, false)
        if IsPedInAnyVehicle(MyPed, false) then
            WichVehicleItIs(MyPedVeh)
            speedBuffer[2] = speedBuffer[1]
            speedBuffer[1] = GetEntitySpeed(MyPedVeh)
            
            velBuffer[2] = velBuffer[1]
            velBuffer[1] = GetEntityVelocity(MyPedVeh)
            
            if ((speedBuffer[2] ~= nil and velBuffer[2] ~= nil) and ((speedBuffer[2] > (MinSpeedBelt / 3.6) and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * seatbeltSpeedPedOut)) or (speedBuffer[1] > (MinSpeedBelt / 7.2) and (speedBuffer[1] - speedBuffer[2]) > (speedBuffer[2] * seatbeltSpeedPedOut)))) then
                if(PedVehIsMotorcycle == false and PedVehIsBike == false and PedVehIsHeli == false and PedVehIsPlane == false and PedVehIsBoat == false) then
                    if(not seatbeltIsOn)then
                        local co = GetEntityCoords(MyPed)
                        local fw = Fwv(MyPed)
                        if (IsVehicleWindowIntact(MyPedVeh, 6)) then
                            SmashVehicleWindow(MyPedVeh, 6)
                        end
						SetEntityCoords(MyPed, co.x + fw.x, co.y + fw.y, co.z-0.47, true, true, true)
                        Citizen.Wait(1)
                        SetPedToRagdoll(MyPed, 1000, 1000, 0, 0, 0, 0)
                        SetEntityVelocity(MyPed, velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
                    else
                        blackout()
                    end
                end
                local pedIsDriver = (GetPedInVehicleSeat(MyPedVeh, -1) == MyPed)
                if(pedIsDriver)then
                    if(autopilotActive)then
                        DeactivateAutopilot()
                    end
                    if(not seatbeltIsOn)then
                        TriggerEvent("esx_status:add","stress",600000)
                    else
                        TriggerEvent("esx_status:add","stress",300000)
                    end
                end
			end
        end
    end
end)
local function roundToNthDecimal(num, n)
    local mult = 10^(n or 0)
    return math.floor(num * mult + 0.5) / mult
  end
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(200)

		local player = PlayerPedId()
		local vehicle = GetVehiclePedIsIn(player, false)
		local position = GetEntityCoords(player)
		local vehicleIsOn = GetIsVehicleEngineRunning(vehicle)
		local vehicleInfo

		if IsPedInAnyVehicle(player, false) then
			
			local vehicleSpeedSource = GetEntitySpeed(vehicle)
			local vehicleSpeed
			vehicleSpeed = math.ceil(vehicleSpeedSource * 3.6)

			local vehicleNailSpeed

			vehicleNailSpeed = math.ceil(  280 - math.ceil( math.ceil(vehicleSpeed * 205) / Config.vehicle.maxSpeed) )
			
			local vehicleFuel = GetVehicleFuelLevel(vehicle)
			local vehicleGear = GetVehicleCurrentGear(vehicle)

			if (vehicleSpeed == 0 and vehicleGear == 0) or (vehicleSpeed == 0 and vehicleGear == 1) then
				vehicleGear = 'N'
			elseif vehicleSpeed > 0 and vehicleGear == 0 then
				vehicleGear = 'R'
			end
			
			local vehicleVal,vehicleLights,vehicleHighlights  = GetVehicleLightsState(vehicle)
			local vehicleIsLightsOn
			if vehicleLights == 1 and vehicleHighlights == 0 then
				vehicleIsLightsOn = 'normal'
			elseif (vehicleLights == 1 and vehicleHighlights == 1) or (vehicleLights == 0 and vehicleHighlights == 1) then
				vehicleIsLightsOn = 'high'
			else
				vehicleIsLightsOn = 'off'
            end
            
			
			local indicatorLights  = GetVehicleIndicatorLights(vehicle)
			if indicatorLights == 1 then
                vehicleSignalIndicator = 'left'
			elseif (indicatorLights == 2) then
                vehicleSignalIndicator = 'right'
            elseif (indicatorLights == 3) then
                vehicleSignalIndicator = 'both'   
            else
                vehicleSignalIndicator = 'off'
			end
			
			if PedVehIsCar == true then

				local prevSpeed = currSpeed
                currSpeed = vehicleSpeedSource

                SetPedConfigFlag(PlayerPedId(), 32, true)

                if not seatbeltIsOn then
                	local vehIsMovingFwd = GetEntitySpeedVector(vehicle, true).y > 1.0
                    local vehAcc = (prevSpeed - currSpeed) / GetFrameTime()
                    if(beltWarningSet == false) then
                        if(currSpeed > 1 or currSpeed < -1) then
                            beltWarningSet = true
                            TriggerEvent("esx:showNotification", "Acuerdate de ponerte el cinturón")
							DisableControlAction(0, 75, false)
						end
                    end
					if (vehIsMovingFwd and (prevSpeed > (seatbeltEjectSpeed/2.237)) and (vehAcc > (seatbeltEjectAccel*9.81))) then
						SetEntityCoords(player, position.x, position.y, position.z - 0.47, true, true, true)
                        SetEntityVelocity(player, prevVelocity.x, prevVelocity.y, prevVelocity.z)
                        SetPedToRagdoll(player, 1000, 1000, 0, 0, 0, 0)
                    else
						
                        prevVelocity = GetEntityVelocity(vehicle)
                    end
                else
					DisableControlAction(0, 75, true)
				
                end
            end
            
            rpm = GetVehicleCurrentRpm(vehicle)
            rpm = math.ceil(rpm * 10000, 2)
            vehicleNailRpm = 280 - math.ceil( math.ceil((rpm-2000) * 140) / 10000)
            cardamage = GetVehicleEngineHealth(vehicle) / 10 
            vehicleInfo = {
				updateVehicle = true,
                status = true,
                speed = vehicleSpeed,
                nail = vehicleNailSpeed,
                gear = vehicleGear,
                fuel = vehicleFuel,
                lights = vehicleIsLightsOn,
                signals = vehicleSignalIndicator,
                cruiser = vehicleCruiser,
				seatbelt = Config.vehicle.seatbelt,
				haveBelt = PedVehIsCar,
                damage = cardamage,
                rpmnail = vehicleNailRpm,
                rpm = rpm,
                config = {
                    speedUnit = Config.vehicle.speedUnit,
                    maxSpeed = Config.vehicle.maxSpeed
                }
			}
			vehicleInfo['seatbelt']['status'] = seatbeltIsOn
		else

			vehicleCruiser = 'off'
			vehicleNailSpeed = 0
            vehicleSignalIndicator = 'off'
			speedBuffer[1], speedBuffer[2] = 0.0, 0.0
            seatbeltIsOn = false
            beltWarningSet = false

			vehicleInfo = {
				updateVehicle = true,
                status = false,
                nail = 0,
                rpmnail = 0,
                seatbelt = { status = seatbeltIsOn },
                cruiser = vehicleCruiser,
                signals = vehicleSignalIndicator
			}
		end
		SendNUIMessage(vehicleInfo)
	end
end)


Citizen.CreateThread(function ()

	while true do
		Citizen.Wait(10)

		local player = PlayerPedId()
		local vehicle = GetVehiclePedIsIn(player, false)
		local vehicleClass = GetVehicleClass(vehicle)
		if seatbeltIsOn then 
			DisableControlAction(0, 75, true)
			DisableControlAction(27, 75, true)
		end
		if IsPedInAnyVehicle(player, false) then
			if IsControlJustReleased(0,  Keys['X']) then
				WichVehicleItIs(vehicle)
				if(PedVehIsCar)then
					seatbeltIsOn = not seatbeltIsOn
					if seatbeltIsOn then
						TriggerEvent("esx:showNotification", "Cinturón puesto", "success")
					else
						TriggerEvent("esx:showNotification", "Cinturón quitado", "error")
						beltWarningSet = false
						if(autopilotActive)then
							DeactivateAutopilot()
						end
					end
				end
			end
		end

		
		if IsControlJustPressed(1, Config.vehicle.keys.cruiser) and GetPedInVehicleSeat(vehicle, -1) == player then
			local vehicleClass = GetVehicleClass(vehicle)
			if(vehicleClass ~= 13 and vehicleClass ~= 15 and vehicleClass ~= 16)then
				local vehicleSpeedSource = GetEntitySpeed(vehicle)
				local kmhSpeed = math.ceil(vehicleSpeedSource*3.6)
				if vehicleCruiser == 'on' then
					vehicleCruiser = 'off'
					local handlingMaxSpeed = GetVehicleHandlingMaxSpeed(vehicle)
					SetEntityMaxSpeed(vehicle, handlingMaxSpeed)
				else
					if(kmhSpeed > 20)then
						vehicleCruiser = 'on'
						SetEntityMaxSpeed(vehicle, vehicleSpeedSource)
					end
				end
			end
        end
        if IsControlJustPressed(1, Config.vehicle.keys.signalLeft) then
			if vehicleSignalIndicator == 'off' then
				vehicleSignalIndicator = 'left'
			else
				vehicleSignalIndicator = 'off'
			end
			TriggerEvent('kc_chud:CarSignalLights', vehicleSignalIndicator)
		end

		if IsControlJustPressed(1, Config.vehicle.keys.signalRight) then
			if vehicleSignalIndicator == 'off' then
				vehicleSignalIndicator = 'right'
			else
				vehicleSignalIndicator = 'off'
			end

			TriggerEvent('kc_chud:CarSignalLights', vehicleSignalIndicator)
		end

		if IsControlJustPressed(1, Config.vehicle.keys.signalBoth) then
			if vehicleSignalIndicator == 'off' then
				vehicleSignalIndicator = 'both'
			else
				vehicleSignalIndicator = 'off'
			end
			TriggerEvent('kc_chud:CarSignalLights', vehicleSignalIndicator)
        end
	end
end)

RegisterNetEvent('kc_chud:setBeltOn')
AddEventHandler('kc_chud:setBeltOn', function()
	if not seatbeltIsOn then
		seatbeltIsOn = true
		TriggerEvent("esx:showNotification", "Cinturón puesto")
	end
end)
RegisterNetEvent('kc_chud:setBeltOff')
AddEventHandler('kc_chud:setBeltOff', function()
	if  seatbeltIsOn then
		seatbeltIsOn = false
		TriggerEvent("esx:showNotification", "Cinturón quitado")
		beltWarningSet = false
	end
end)

function blackout()
	if not isBlackedOut then
		isBlackedOut = true
		Citizen.CreateThread(function()
			DoScreenFadeOut(100)
			while not IsScreenFadedOut() do
				Citizen.Wait(10)
			end
			Citizen.Wait(Config.BlackoutTime)
			DoScreenFadeIn(250)
			isBlackedOut = false
			doTheEffect()
		end)
	end
end

function doTheEffect()
	SetTimecycleModifier('BarryFadeOut')
	SetTimecycleModifierStrength(math.min(0.1 / 10, 0.6))
	local myPed = PlayerPedId()
	local vehicle = GetVehiclePedIsUsing(myPed,false)
	SetVehicleEngineOn(vehicle, false, false, true)
	SetVehicleUndriveable(vehicle, true)
	
	SetTimecycleModifier("REDMIST_blend")
	ShakeGameplayCam("FAMILY5_DRUG_TRIP_SHAKE", 1.0)
	Wait(5000)
			
	SetTimecycleModifier("hud_def_desat_Trevor")
	
	Wait(3000)
	
	SetTimecycleModifier("")
	SetTransitionTimecycleModifier("")
	StopGameplayCamShaking()
	SetVehicleUndriveable(vehicle, false)
	SetVehicleEngineOn(vehicle, true, false, true)

end


AddEventHandler('kc_chud:CarSignalLights', function (status)
	local driver = GetVehiclePedIsIn(PlayerPedId(), false)
	local hasTrailer,vehicleTrailer = GetVehicleTrailerVehicle(driver,vehicleTrailer)
	local leftLight
	local rightLight

	if status == 'left' then
		leftLight = false
		rightLight = true
		if hasTrailer then driver = vehicleTrailer end

	elseif status == 'right' then
		leftLight = true
		rightLight = false
		if hasTrailer then driver = vehicleTrailer end

	elseif status == 'both' then
		leftLight = true
		rightLight = true
		if hasTrailer then driver = vehicleTrailer end

	else
		leftLight = false
		rightLight = false
		if hasTrailer then driver = vehicleTrailer end

	end

	TriggerServerEvent('kc_chud:syncCarLights', status)

	SetVehicleIndicatorLights(driver, 0, leftLight)
	SetVehicleIndicatorLights(driver, 1, rightLight)
end)



RegisterNetEvent('kc_chud:syncCarLights')
AddEventHandler('kc_chud:syncCarLights', function (driver, status)
	local target = GetPlayerFromServerId(driver)
	if target == nil or target == -1 then
		return
	  end
	if target ~= PlayerId() then
		local driver = GetVehiclePedIsIn(GetPlayerPed(target), false)

		if status == 'left' then
			leftLight = false
			rightLight = true

		elseif status == 'right' then
			leftLight = true
			rightLight = false

		elseif status == 'both' then
			leftLight = true
			rightLight = true

		else
			leftLight = false
			rightLight = false
		end

		SetVehicleIndicatorLights(driver, 0, leftLight)
		SetVehicleIndicatorLights(driver, 1, rightLight)

	end
end)

function GetVehicleHandlingMaxSpeed(vehicle)
	local handlingMaxSpeed =  GetVehicleHandlingFloat(vehicle,"CHandlingData","fInitialDriveMaxFlatVel")
	return handlingMaxSpeed
end

