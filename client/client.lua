ESX = exports["es_extended"]:getSharedObject()
local cooldown = 60
local tick = 0
local checkRaceStatus = false
local casinoAudioBank = 'DLC_VINEWOOD/CASINO_GENERAL' -- Do not edit
local playerbal = 0 

RegisterNetEvent('mp_insidetrack:updatebal')
AddEventHandler('mp_insidetrack:updatebal', function (b)
    if b then 
  --  print('im updating this value : ' .. b)
    playerbal = (playerbal + b)
    end
end)

local function OpenInsideTrack()
    if Utils.InsideTrackActive then
        return
    end
    Utils.InsideTrackActive = true

    -- Scaleform
    Utils.Scaleform = RequestScaleformMovie('HORSE_RACING_CONSOLE')

    while not HasScaleformMovieLoaded(Utils.Scaleform) do
        Wait(0)
    end

    DisplayHud(false)
    SetPlayerControl(PlayerId(), false, 0)

    while not RequestScriptAudioBank(casinoAudioBank) do
        Wait(0)
    end

    Utils:ShowMainScreen()
    Utils:SetMainScreenCooldown(cooldown)

    -- Add horses
    Utils.AddHorses(Utils.Scaleform)

    Utils:DrawInsideTrack()
    Utils:HandleControls()
end

local function LeaveInsideTrack()
    Utils.InsideTrackActive = false

    DisplayHud(true)
    SetPlayerControl(PlayerId(), true, 0)
    SetScaleformMovieAsNoLongerNeeded(Utils.Scaleform)
    ReleaseNamedScriptAudioBank(casinoAudioBank)

    Utils.Scaleform = -1
end

function Utils:DrawInsideTrack()
    Citizen.CreateThread(function()
        while self.InsideTrackActive do
            Wait(0)
            local xMouse, yMouse = GetDisabledControlNormal(2, 239), GetDisabledControlNormal(2, 240)

            -- Fake cooldown
            tick = (tick + 10)

            if (tick == 1000) then
                if (cooldown == 1) then
                    cooldown = 60
                end
                
                cooldown = (cooldown - 1)
                tick = 0

                self:SetMainScreenCooldown(cooldown)
            end
            
            -- Mouse control
            BeginScaleformMovieMethod(self.Scaleform, 'SET_MOUSE_INPUT')
            ScaleformMovieMethodAddParamFloat(xMouse)
            ScaleformMovieMethodAddParamFloat(yMouse)
            EndScaleformMovieMethod()

            -- Draw
            DrawScaleformMovieFullscreen(self.Scaleform, 255, 255, 255, 255)
        end
    end)
end

function Utils:HandleControls()
    Citizen.CreateThread(function()
        while self.InsideTrackActive do
            Wait(0)

            if IsControlJustPressed(2, 194) then
                LeaveInsideTrack()
            --    ESX.ShowHelpNotification('Dont Forget to Cashout!\n Use Command /cashout_track')
            ExecuteCommand('cashout_track')
                self:HandleBigScreen()
            end
            
            -- Left click
            if IsControlJustPressed(2, 237) then
                local clickedButton = self:GetMouseClickedButton()

                if self.ChooseHorseVisible then
                    if (clickedButton ~= 12) and (clickedButton ~= -1) then
                        self.CurrentHorse = (clickedButton - 1)
                        self:ShowBetScreen(self.CurrentHorse)
                        self.ChooseHorseVisible = false
                    end
                end

                -- Rules button
                if (clickedButton == 15) then
                    self:ShowRules()
                end

                -- Close buttons
                if (clickedButton == 12) then
                    if self.ChooseHorseVisible then
                        self.ChooseHorseVisible = false
                    end
                    
                    if self.BetVisible then
                        self:ShowHorseSelection()
                        self.BetVisible = false
                        self.CurrentHorse = -1
                        self.PlayerBalance = playerbal
                    else
                        self:ShowMainScreen()
                    end
                end
                TriggerEvent('mp_insidetrack:updatebal')
              --  self.PlayerBalance = playerbal
                -- Start bet
                if (clickedButton == 1) then
                    self:ShowHorseSelection()
                end

                -- Start race
                if (clickedButton == 10) then
                    if playerbal >= 100 then
                        
                    
                    self.CurrentSoundId = GetSoundId()
                    PlaySoundFrontend(self.CurrentSoundId, 'race_loop', 'dlc_vw_casino_inside_track_betting_single_event_sounds')
                    
                    self:StartRace()
                    checkRaceStatus = true
                    else
                        LeaveInsideTrack()
                        self:HandleBigScreen()
                        ESX.ShowHelpNotification('Uhm, You need to load some cash first!\n Example : /load_track 1000\n This loads 1000 dollars!')
                    end
                end

                -- Change bet
                if (clickedButton == 8) then
                    if (self.CurrentBet < playerbal) then
                 --   if (self.CurrentBet < self.PlayerBalance) then
                        self.CurrentBet = (self.CurrentBet + 100)
                        self.CurrentGain = (self.CurrentBet * 2)
                    --    self:UpdateBetValues(self.CurrentHorse, self.CurrentBet, self.PlayerBalance, self.CurrentGain)
                    self:UpdateBetValues(self.CurrentHorse, self.CurrentBet, playerbal, self.CurrentGain)
                    end
                end

                if (clickedButton == 9) then
                    if (self.CurrentBet > 100) then
                        self.CurrentBet = (self.CurrentBet - 100)
                        self.CurrentGain = (self.CurrentBet * 2)
                        self:UpdateBetValues(self.CurrentHorse, self.CurrentBet, playerbal, self.CurrentGain)
                       -- self:UpdateBetValues(self.CurrentHorse, self.CurrentBet, self.PlayerBalance, self.CurrentGain)
                    end
                end

                if (clickedButton == 13) then
                    self:ShowMainScreen()
                end

                -- Check race
                while checkRaceStatus do
                    Wait(0)

                    local raceFinished = self:IsRaceFinished()

                    if (raceFinished) then
                        StopSound(self.CurrentSoundId)
                        ReleaseSoundId(self.CurrentSoundId)

                        self.CurrentSoundId = -1
                        playerbal = (playerbal - self.CurrentBet)
                        if (self.CurrentHorse == self.CurrentWinner) then
                            -- Here you can add money
                            -- Exemple
                            -- TriggerServerEvent('myCoolEventWhoAddMoney', self.CurrentGain)
                            TriggerServerEvent('mp_insidetrack:joint', self.CurrentGain)
                            -- Refresh player balance
                          --  self.PlayerBalance = (self.PlayerBalance + self.CurrentGain)
                        --  ESX.GetPlayerData()
                         -- TriggerEvent('mp_insidetrack:updatebal', ESX.PlayerData.money)
                          TriggerEvent('mp_insidetrack:updatebal')
                          playerbal = (playerbal + self.CurrentGain)
                          --self.PlayerBalance = (playerbal + self.CurrentGain)
                          self:UpdateBetValues(self.CurrentHorse, self.CurrentBet, playerbal, self.CurrentGain)
                          --   self:UpdateBetValues(self.CurrentHorse, self.CurrentBet, self.PlayerBalance, self.CurrentGain)
                        end

                        self:ShowResults()

                        self.CurrentHorse = -1
                        self.CurrentWinner = -1
                        self.HorsesPositions = {}

                        checkRaceStatus = false
                    end
                end
            end
        end

        
    end)
end

RegisterCommand('itrack', OpenInsideTrack)

RegisterCommand('cashout_track', function(source)
local amount = playerbal
   if amount > 0 then 
    TriggerServerEvent('mp_insidetrack:joint', amount)
    playerbal = (amount - playerbal)
    ESX.ShowHelpNotification('Cashed out ' .. tostring(amount) .. '$\n We hope to see you again!')
   end
end, false)

local chairHash = -1005355458
local casinoInteriorId = 124162
local radius = 2.0 -- Radius to check if player is near the chair
local isNearChair = false
local isSitting = false

Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)

        -- Check if the player is in the casino interior
        if GetInteriorFromEntity(playerPed) == casinoInteriorId then
            -- Find the closest chair to the player
            local chair = GetClosestObjectOfType(playerPos.x, playerPos.y, playerPos.z, radius, chairHash, false, false, false)

            -- Calculate the distance between the player and the chair
            if DoesEntityExist(chair) then
                local chairPos = GetEntityCoords(chair)
                local distance = #(playerPos - chairPos)

                -- If the player is within the specified radius of the chair, set isNearChair to true
                if distance <= radius then
                    isNearChair = true
                    ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ to sit at the console!')
                else
                    isNearChair = false
                end
            end
        else
            isNearChair = false
        end

        -- Check if the player presses the E key while near the chair
        if isNearChair and IsControlJustPressed(0, 38) then
            if not isSitting then
                local chair = GetClosestObjectOfType(playerPos.x, playerPos.y, playerPos.z, radius, chairHash, false, false, false)
                local chairPos = GetEntityCoords(chair)
                TaskStartScenarioAtPosition(playerPed, "PROP_HUMAN_SEAT_CHAIR", chairPos.x, chairPos.y, chairPos.z+0.5, GetEntityHeading(chair)+180, 0, true, true)
                isSitting = true
                ExecuteCommand('itrack')
            else
                ClearPedTasksImmediately(playerPed)
                isSitting = false
            end
        end

        -- Check if the player presses the Backspace key while sitting in the chair
        if isSitting and IsControlJustPressed(0, 177) then
            ClearPedTasksImmediately(playerPed)
            isSitting = false
        end

        -- Wait before checking again
        Citizen.Wait(0)
    end
end)