local G = GLOBAL

---- Mod config data
-- Settings
local soul_drop_key = GetModConfigData("Soul_Drop_Key") or "R"
local open_soul_jar_key = GetModConfigData("Open_Soul_Jar_Key") or "C"
local self_leap_key = GetModConfigData("Self_Leap_Key") or "V"
local take_soul_from_jar_key = GetModConfigData("Take_Soul_From_Jar_Key") or "B"
local put_soul_in_jar_key = GetModConfigData("Put_Soul_In_Jar_Key") or "G"
local leap_to_mouse_key = GetModConfigData("Leap_To_Mouse_Key") or "H"
local show_range_key = GetModConfigData("Show_Range_Key") or "F7"
-- Take soul settings
local amount_of_souls_to_take = GetModConfigData("Amount_Of_Souls_To_Take") or 5
local take_soul_retries = GetModConfigData("Take_Soul_Retries") or 1
local wait_for_ui_delay = GetModConfigData("Wait_For_UI_Delay") or 6
local move_to_next_jar_delay = GetModConfigData("Move_To_Next_Jar_Delay") or 2
-- Put soul settings
local amount_of_souls_to_store = GetModConfigData("Amount_Of_Souls_To_Store") or 5
local soul_hand_check_interval = GetModConfigData("Soul_Hand_Check_Interval") or 0.4
-- Debud settings
local debug_mode = GetModConfigData("Debug_Mode") or false

--
local PREFAB_SOUL  = "wortox_soul"
local PREFAB_JAR   = "wortox_souljar"
local jar_capacity = G.TUNING.STACK_SIZE_SMALLITEM or 40
local MAX_LEAP_DISTANCE = G.ACTIONS.BLINK.distance or 36
local SOULHEAL_RANGE = G.TUNING.WORTOX_SOULHEAL_RANGE or 8
local SOULHEAL_SKILLTREE_1_RANGE = G.TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_1_RANGE or 3
local SOULHEAL_SKILLTREE_2_RANGE = G.TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_2_RANGE or 3
local range_circles = nil


----------------------------------- Debug Log ----------------------------------- 

local function DebugLog (msg)
    if not debug_mode then return end
    print("[Lazy Wortox] " .. msg)
end

----------------------------------- Get Stack Size ----------------------------------- 

local function GetStackSize(item)
    return (item and item.replica.stackable and item.replica.stackable:StackSize()) or 0
end


----------------------------------- Check Player State ----------------------------------- 

local function CheckPlayerState()
    local player = G.ThePlayer
    return player ~= nil and player.prefab == "wortox" and player.HUD and not player.HUD:HasInputFocus()
end

----------------------------------- Drop Soul ----------------------------------- 

local function DropSoul()
    if not CheckPlayerState() then return end
    DebugLog("Function: DropSoul() called")
    local player = G.ThePlayer

    -- Drop soul if it's being held by the cursor
    local active_item = player.replica.inventory:GetActiveItem()
    if active_item and active_item.prefab == PREFAB_SOUL then
        DebugLog("Found soul in active item, dropping it now")
        player.replica.inventory:DropItemFromInvTile(active_item)
        return
    end

    -- Otherwise try and find souls in inventory and drop from inventory
    for _, item in pairs(player.replica.inventory:GetItems()) do
        if item and item.prefab == PREFAB_SOUL then
            DebugLog("Found soul in inventory, dropping it now")
            player.replica.inventory:DropItemFromInvTile(item)
            return
        end
    end
end


----------------------------------- Open Soul Jar -----------------------------------

local function OpenSoulJar()
    if not CheckPlayerState() then return end
    DebugLog("Function: OpenSoulJar() called")
    local player = G.ThePlayer
    for _, item in pairs(player.replica.inventory:GetItems()) do
        if item and item.prefab == PREFAB_JAR then
            DebugLog("Found soul jar in inventory, opening it now")
            player.replica.inventory:UseItemFromInvTile(item)
            return
        end
    end
end

----------------------------------- Self Leap ----------------------------------- 

local function SelfLeap()
    if not CheckPlayerState() then return end
    DebugLog("Function: SelfLeap() called")
    local player = G.ThePlayer
    local x, y, z = player.Transform:GetWorldPosition()
    DebugLog(string.format("Performing self leap at position: (%.2f, %.2f, %.2f)", x, y, z))
    G.SendRPCToServer(G.RPC.LeftClick, G.ACTIONS.BLINK.code, x, z)
end

----------------------------------- Count Current Souls In Inventory ----------------------------------- 

local function GetCurrentSoulCount()
    if not CheckPlayerState() then return end
    DebugLog("Function: GetCurrentSoulCount() called")
    local count = 0
    local player = G.ThePlayer
    for _, item in pairs(player.replica.inventory:GetItems()) do
        if item and item.prefab == PREFAB_SOUL then
            DebugLog("Found soul in inventory, counting it now")
            count = count + item.replica.stackable:StackSize()
            DebugLog(string.format("Current soul count: %d", count))
        end
    end
    return count
end

----------------------------------- Soul Helper Functions ----------------------------------- 

local function GetAllSoulData()
    if not CheckPlayerState() then return end
    local player = G.ThePlayer
    local souls = {}
    for slot_index, item in pairs(player.replica.inventory:GetItems()) do
        if item and item.prefab == PREFAB_SOUL then
            table.insert(souls, {
                item = item,
                index = slot_index
            })
        end
    end
    return souls
end

----------------------------------- Jar Helper Functions ----------------------------------- 
local function BuildJarList(filter)
    if not CheckPlayerState() then return end
    local list  = {}
    local items = G.ThePlayer.replica.inventory:GetItems()
    for index, item in pairs(items) do
        if item and item.prefab == PREFAB_JAR and filter(item) then
            list[#list + 1] = { item = item, index = index }
        end
    end
    return list
end

local GetAllJarsData = function()
    return BuildJarList(function() return true end)
end

local GetAllNotFullJarsData = function()
    return BuildJarList(function(jar)
        return jar.replica._.inventoryitem.classified.percentused:value() < 100
    end)
end

local GetAllNonEmptyJarsData = function()
    return BuildJarList(function(jar)
        return jar.replica._.inventoryitem.classified.percentused:value() > 0
    end)
end

----------------------------------- Take Soul From Jar ----------------------------------- 

local function TakeSoulFromJar(total_to_take, retry_count)
    if not CheckPlayerState() then return end
    DebugLog(string.format("Function: TakeSoulFromJar(%d,%d) called", total_to_take, retry_count or 0))
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

    local jars = GetAllNonEmptyJarsData()

    if #jars == 0 or total_to_take <= 0 then
        DebugLog("No jars or nothing to take.")
        player.is_already_performing_take_soul = nil
        return
    end

    local max_ui_wait_retries = 20 -- Retry limit when waiting for UI ("doing" tag)

    -- Recursive function to process each jar
    local function TryJar(index, souls_left)
        DebugLog(string.format("Function: TryJar(%d,%d) called", index, souls_left))
        -- Done with jars or got enough souls
        if index > #jars or souls_left <= 0 then
            -- Wait briefly, then compare soul count to confirm how many were gained
            player:DoTaskInTime(0.4, function()
                local gained  = GetCurrentSoulCount() - before_count
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
        local jar = jars[index].item
        local percent = jar.replica._.inventoryitem.classified.percentused:value()
        local in_jar = math.floor((percent / 100) * jar_capacity)
        local take = math.min(in_jar, souls_left)
        DebugLog(string.format("Taking %d souls from jar %d (has %d)", take, index, in_jar))

        -- Open jar UI
        player.replica.inventory:UseItemFromInvTile(jar)

        local retries = 0
        -- Wait for the jar UI to open (signaled by the "doing" tag)
        local function WaitForOpen()
            DebugLog("Function: WaitForOpen() called")
            if player:HasTag("doing") then
                -- When UI is open, take souls from the jar
                player:DoTaskInTime(wait_for_ui_delay * G.FRAMES, function()
                    G.SendRPCToServer(G.RPC.MoveItemFromCountOfSlot, 1, jar, nil, take)
                    -- After taking souls, try the next jar
                    player:DoTaskInTime(move_to_next_jar_delay * G.FRAMES, function()
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


----------------------------------- Put Soul In Jar ----------------------------------- 

local function PutSoulInJar(total_to_put, on_repeat)
    if not CheckPlayerState() then return end
    DebugLog("Function: PutSoulInJar() called")
    local player = G.ThePlayer
    total_to_put = total_to_put or 5
    on_repeat = on_repeat or false

    if player.is_already_performing_put_soul then
        DebugLog("Already storing souls, aborting new request.")
        return
    end

    player.is_already_performing_put_soul = true

    local active_item = player.replica.inventory:GetActiveItem()

    local souls = GetAllSoulData()
    local has_souls_in_hand = active_item and active_item.prefab == PREFAB_SOUL and GetStackSize(active_item) > 0


    if #souls == 0 and not has_souls_in_hand then
        DebugLog("No souls to store.")
        player.is_already_performing_put_soul = nil
        return
    end

    local soul = souls[1]
    if not soul or not soul.index then
        if not has_souls_in_hand then
            DebugLog("No valid soul for transfer.")
            player.is_already_performing_put_soul = nil
            return
        end
    end

    local jars = GetAllNotFullJarsData()
    if #jars == 0 then
        DebugLog("No jars with space left.")
        player.is_already_performing_put_soul = nil
        G.SendRPCToServer(G.RPC.AddAllOfActiveItemToSlot, soul.index)
        return
    end
    
    if not on_repeat then
        G.SendRPCToServer(G.RPC.TakeActiveItemFromCountOfSlot, soul.index, nil, total_to_put)
    end

    -- player.replica.inventory:UseItemFromInvTile(jars[1].item) -- This works too but it plays 2 animations, one for jar opening and one for soul placing. not efficient

    G.SendRPCToServer(G.RPC.UseItemFromInvTile, G.ACTIONS.STORE.code, jars[1].item, nil, nil) -- Could cause stagger when movement speed is high while store action plays, but this way is faster and more efficient
    
    player:DoTaskInTime(soul_hand_check_interval , function()
        local active_item = player.replica.inventory:GetActiveItem()
        if active_item and active_item.prefab == PREFAB_SOUL then
            local stack_size = GetStackSize(active_item)
            DebugLog("Active soul stack size: " .. tostring(stack_size))
            if stack_size > 0 then
                DebugLog("Still has soul in hand, repeating...")
                player.is_already_performing_put_soul = nil
                PutSoulInJar(stack_size, true)
                return
            end
        end

        DebugLog("No more active souls to store.")
        player.is_already_performing_put_soul = nil
    end)
end

----------------------------------- Leap To Mouse ----------------------------------- 

local function LeapToMouse()
    if not CheckPlayerState() then return end
    DebugLog("Function: LeapToMouse() called")
    local soul_amount = GetCurrentSoulCount()
    if soul_amount <= 0 then
        DebugLog("No souls to leap with.")
        return
    end

    local player = G.ThePlayer
    -- mouse position
    local mx, _, mz = G.TheInput:GetWorldPosition():Get()
    -- player position
    local px, _, pz = player.Transform:GetWorldPosition()
    -- straight‑line 2‑D distance
    local dist = math.sqrt((mx - px)^2 + (mz - pz)^2)
    if dist <= MAX_LEAP_DISTANCE and G.TheWorld.Map:IsPassableAtPoint(mx, 0, mz) then
        G.SendRPCToServer(G.RPC.LeftClick,G.ACTIONS.BLINK.code,mx, mz)
    end
end

----------------------------------- Show Range ----------------------------------- 

local function unpackcolor(c)
    return c[1], c[2], c[3], c[4] or 0
end

local function CreateRangeIndicator(inst, rotation, scale, color)
    local circle = G.CreateEntity()
    circle.persists = false

    -- Add essential components before accessing them
    circle.entity:AddTransform()
    circle.entity:AddAnimState()

    -- Set up transform properties: rotation and scale
    circle.Transform:SetRotation(rotation)
    circle.Transform:SetScale(scale, scale, scale)

    -- Set up animation bank/build, then play animation
    circle.AnimState:SetBank("firefighter_placement")
    circle.AnimState:SetBuild("firefighter_placement")
    circle.AnimState:PlayAnimation("idle", true)

    -- Configure animation rendering options
    circle.AnimState:SetOrientation(G.ANIM_ORIENTATION.OnGround)
    circle.AnimState:SetLayer(G.LAYER_BACKGROUND)
    circle.AnimState:SetSortOrder(3)
    circle.AnimState:SetLightOverride(1)
    circle.AnimState:SetAddColour(unpackcolor(color))

    -- Add tags to control interaction and game logic
    circle:AddTag("NOCLICK")
    circle:AddTag("placer")

    -- Parent to the inst entity for proper positioning
    circle.entity:SetParent(inst.entity)

    return circle
end

local function GetHealRange()
    if not CheckPlayerState() then return end

    local player = G.ThePlayer
    local skilltreeupdater = player and player.components.skilltreeupdater
    if not skilltreeupdater then return SOULHEAL_RANGE end

    local final_range = SOULHEAL_RANGE

    if skilltreeupdater:IsActivated("wortox_soulprotector_1") then
        final_range = final_range + SOULHEAL_SKILLTREE_1_RANGE
        if skilltreeupdater:IsActivated("wortox_soulprotector_2") then
            final_range = final_range + SOULHEAL_SKILLTREE_2_RANGE
        end
    end

    return final_range
end

local function ScaleCalculator(range)
    return math.sqrt(range * 300 / 1900)
end

-- NOTE: MAYBE work on splitting up the range indicators to provide more flexibility in the future BUT for now, this is fine.
-- Also should probably update the labels and hovers in modinfo.lua -- Need to update Leap_To_Mouse_Key and Show_Range_Key.
-- But that is it for today, it is bed time - 4:20 AM - 14/07/2025
local function ToggleRangeIndicator()
    if not CheckPlayerState() then return end
    DebugLog("Function: ToggleRangeIndicator() called")
    local player = G.ThePlayer
    if not player then return end

    -- If range circles already exist, remove them and clear the table
    if range_circles then
        for _, circle in pairs(range_circles) do
            if circle and circle:IsValid() then
                circle:Remove()
            end
        end
        range_circles = nil
        return
    end

    -- Create new range circles
    range_circles = {
        CreateRangeIndicator(player, 0, ScaleCalculator(MAX_LEAP_DISTANCE), {0, 1, 1, 0}),
        CreateRangeIndicator(player, 0, ScaleCalculator(GetHealRange()), {1, 0, 0, 0}),
    }
end


----------------------------------- FOR TESTING PURPOSES ONLY ----------------------------------- 

local function Test()
    if not CheckPlayerState() then return end
    print("TEST123")
end

----------------------------------- KEY HANDLERS ----------------------------------- 

local mouse_map = {
    -- strings.lua, line 13640
    ['\238\132\128'] = 1000, -- MOUSEBUTTON_LEFT
    ['\238\132\129'] = 1001, -- MOUSEBUTTON_RIGHT
    ['\238\132\130'] = 1002, -- MOUSEBUTTON_MIDDLE
    ['\238\132\133'] = 1003, -- MOUSEBUTTON_SCROLLUP
    ['\238\132\134'] = 1004, -- MOUSEBUTTON_SCROLLDOWN
    ['\238\132\131'] = 1005, -- MOUSEBUTTON_4
    ['\238\132\132'] = 1006, -- MOUSEBUTTON_5
}

local function InputHelper(key, on_down_fn, on_up_fn)
    if not key or key == "None" then return end

    local code = mouse_map[key] or G["KEY_" .. key]

    if not code then return end

    DebugLog("CODE for key: " .. key .. " is: " .. tostring(code))

    if code >= 1000 and code <= 1006 then
        -- Mouse key
        G.TheInput:AddMouseButtonHandler(function(button, down, x, y)
            if button == code then
                if down and on_down_fn then
                    on_down_fn()
                elseif (not down) and on_up_fn then
                    on_up_fn()
                end
            end
        end)
    else
        -- Keyboard key
        if on_down_fn then
            G.TheInput:AddKeyDownHandler(code, on_down_fn)
        end
        if on_up_fn then
            G.TheInput:AddKeyUpHandler(code, on_up_fn)
        end
    end
end

AddSimPostInit(function()
    InputHelper(soul_drop_key, DropSoul, nil)
    InputHelper(open_soul_jar_key, nil, OpenSoulJar)
    InputHelper(self_leap_key, SelfLeap, nil)
    InputHelper(take_soul_from_jar_key, nil, function() TakeSoulFromJar(amount_of_souls_to_take) end)
    InputHelper(put_soul_in_jar_key, nil, function() PutSoulInJar(amount_of_souls_to_store) end)
    InputHelper(leap_to_mouse_key, nil, LeapToMouse)
    InputHelper(show_range_key, nil, ToggleRangeIndicator)
end)