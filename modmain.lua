local G = GLOBAL

local debug_mode = GetModConfigData("Debug_Mode") or false
local soul_drop_key = GetModConfigData("Soul_Drop_Key") or "R"
local open_soul_jar_key = GetModConfigData("Open_Soul_Jar_Key") or "C"
local self_leap_key = GetModConfigData("Self_Leap_Key") or "V"
local take_soul_from_jar_key = GetModConfigData("Take_Soul_From_Jar_Key") or "B"
local amount_of_souls_to_take = GetModConfigData("Amount_Of_Souls_To_Take") or 5
local take_soul_retries = GetModConfigData("Take_Soul_Retries") or 1
local frames_to_wait_for_ui = GetModConfigData("Frames_To_Wait_For_UI") or 6
local frames_to_move_to_next_jar = GetModConfigData("Frames_To_Move_To_Next_Jar") or 1


-- Helper function to log debug messages
local function DebugLog (msg)
    if not debug_mode then return end
    print("[Lazy Wortox] " .. msg)
end


-- Check if the player is Wortox and is in game but also not input focused (typing in search bar or chat etc)
local function CheckPlayerState()
    DebugLog("Function: CheckPlayerState() called")
    local player = G.ThePlayer
    return player ~= nil and player.prefab == "wortox" and player.HUD and not player.HUD:HasInputFocus()
end

-- Drop soul function
local function DropSoul()
    DebugLog("Function: DropSoul() called")
    if not CheckPlayerState() then return end
    local player = G.ThePlayer

    -- Drop soul if it's being held by the cursor
    local active_item = player.replica.inventory:GetActiveItem()
    if active_item and active_item.prefab == "wortox_soul" then
        DebugLog("Found soul in active item, dropping it now")
        player.replica.inventory:DropItemFromInvTile(active_item)
        return
    end

    -- Otherwise try and find souls in inventory and drop from inventory
    for _, item in pairs(player.replica.inventory:GetItems()) do
        if item and item.prefab == "wortox_soul" then
            DebugLog("Found soul in inventory, dropping it now")
            player.replica.inventory:DropItemFromInvTile(item)
            return
        end
    end
end

-- Open soul jar function
local function OpenSoulJar()
    DebugLog("Function: OpenSoulJar() called")
    if not CheckPlayerState() then return end
    local player = G.ThePlayer
    for _, item in pairs(player.replica.inventory:GetItems()) do
        if item and item.prefab == "wortox_souljar" then
            DebugLog("Found soul jar in inventory, opening it now")
            player.replica.inventory:UseItemFromInvTile(item)
            return
        end
    end
end

-- Self leap function
local function SelfLeap()
    DebugLog("Function: SelfLeap() called")
    if not CheckPlayerState() then return end
    local player = G.ThePlayer
    local x, y, z = player.Transform:GetWorldPosition()
    DebugLog(string.format("Performing self leap at position: (%.2f, %.2f, %.2f)", x, y, z))
    G.SendRPCToServer(G.RPC.LeftClick, G.ACTIONS.BLINK.code, x, z)
end

-- Count current souls in inventory
local function GetCurrentSoulCount()
    DebugLog("Function: GetCurrentSoulCount() called")
    local count = 0
    local player = G.ThePlayer
    for _, item in pairs(player.replica.inventory:GetItems()) do
        if item and item.prefab == "wortox_soul" then
            DebugLog("Found soul in inventory, counting it now")
            count = count + item.replica.stackable:StackSize()
            DebugLog(string.format("Current soul count: %d", count))
        end
    end
    return count
end

-- Take souls from jars
-- Hello future me or whoever is reading this, this function is a bit complex so i'll add more comments to help with understanding.
local function TakeSoulFromJar(total_to_take, retry_count)
    DebugLog(string.format("Function: TakeSoulFromJar(%d,%d) called", total_to_take, retry_count or 0))
    -- Check player state
    if not CheckPlayerState() then return end
    local player = G.ThePlayer
    total_to_take = total_to_take or 5 -- Default to 5 souls if no value provided
    retry_count = retry_count or 0 -- Retry count for attempts to reach the goal

    -- Prevent multiple simultaneous soul-taking actions
    if player.is_already_performing_take_soul then
        DebugLog("Already taking souls, aborting new request.")
        return
    end

    player.is_already_performing_take_soul = true

    -- Record the current soul count to verify gain later
    local before_count = GetCurrentSoulCount()

    -- Collect all soul jars from player's inventory
    local jars = {}
    for _, item in pairs(player.replica.inventory:GetItems()) do
        if item and item.prefab == "wortox_souljar" then
            table.insert(jars, item)
        end
    end

    -- Exit early if there are no jars or nothing to take
    if #jars == 0 or total_to_take <= 0 then
        DebugLog("No jars or nothing to take.")
        player.is_already_performing_take_soul = nil
        return
    end

    local jar_capacity = G.TUNING.STACK_SIZE_SMALLITEM or 40 -- Each jar's max soul capacity
    local max_ui_wait_retries = 20 -- Retry limit when waiting for UI ("doing" tag)

    -- Recursive function to process each jar
    local function TryJar(index, souls_left)
        DebugLog(string.format("Function: TryJar(%d,%d) called", index, souls_left))
        -- Done with jars or got enough souls
        if index > #jars or souls_left <= 0 then
            -- Wait briefly, then compare soul count to confirm how many were gained
            player:DoTaskInTime(0.4, function()
                local after_count = GetCurrentSoulCount()
                local gained = after_count - before_count
                local missing = total_to_take - gained

                DebugLog(string.format("Took %d/%d souls", gained, total_to_take))

                -- If souls are missing, retry x times to take them
                if missing > 0 and retry_count < take_soul_retries then
                    DebugLog("Retrying to take missing " .. missing .. " souls...")
                    player.is_already_performing_take_soul = nil
                    TakeSoulFromJar(missing, retry_count + 1)
                else
                    player.is_already_performing_take_soul = nil
                end
            end)
            return
        end

        -- Select the current jar
        local jar = jars[index]
        -- Calculate current soul count in the jar based on its percent used
        local percent = jar.replica._.inventoryitem.classified.percentused:value()
        local in_jar = math.floor((percent / 100) * jar_capacity)

        -- Skip empty jars
        if in_jar <= 0 then
            return TryJar(index + 1, souls_left)
        end

        -- Take as many souls as needed or available
        local take = math.min(in_jar, souls_left)
        DebugLog(string.format("Taking %d souls from jar %d (has %d)", take, index, in_jar))

        -- Open the jar by simulating right-click
        player.replica.inventory:UseItemFromInvTile(jar)
        local retries = 0

        -- Wait for the jar UI to open (signaled by the "doing" tag)
        local function WaitForOpen()
            DebugLog("Function: WaitForOpen() called")
            if player:HasTag("doing") then
                -- When UI is open, take souls from the jar
                player:DoTaskInTime(frames_to_wait_for_ui * G.FRAMES, function()
                    G.SendRPCToServer(G.RPC.MoveItemFromCountOfSlot, 1, jar, nil, take)
                    -- After taking souls, try the next jar
                    player:DoTaskInTime(frames_to_move_to_next_jar * G.FRAMES, function()
                        TryJar(index + 1, souls_left - take)
                    end)
                end)
            else
                -- Retry if UI hasn't opened yet
                retries = retries + 1
                if retries > max_ui_wait_retries then
                    DebugLog("Timeout opening jar " .. index)
                    return TryJar(index + 1, souls_left)
                end
                -- Wait a bit and check again
                player:DoTaskInTime(0.1, WaitForOpen)
            end
        end

        -- Start waiting for the UI to open
        player:DoTaskInTime(3 * G.FRAMES, WaitForOpen)
    end

    -- Start processing jars from the first one
    TryJar(1, total_to_take)
end




-------------------------------------------------------------------------------------------

-- For my testing purposes
local function Test()
    if not CheckPlayerState() then return end
    print("TEST123")
end

-------------------------------------------------------------------------------------------

-- Soul Drop Handler
if soul_drop_key ~= "None" then
    local keycode = G["KEY_" .. soul_drop_key]
    G.TheInput:AddKeyDownHandler(keycode, DropSoul)
end

-- Open Soul Jar Handler
if open_soul_jar_key ~= "None" then
    local keycode = G["KEY_" .. open_soul_jar_key]
    G.TheInput:AddKeyDownHandler(keycode, OpenSoulJar)
end

-- Self Leap Handler
if self_leap_key ~= "None" then
    local keycode = G["KEY_" .. self_leap_key]
    G.TheInput:AddKeyDownHandler(keycode, SelfLeap)
end

-- Take Soul From Jar Handler
if take_soul_from_jar_key ~= "None" then
    local keycode = G["KEY_" .. take_soul_from_jar_key]
    G.TheInput:AddKeyUpHandler(keycode, function()
        TakeSoulFromJar(amount_of_souls_to_take)
    end)
end