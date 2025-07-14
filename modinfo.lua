-- Localization
local isCN = locale == "zh" or locale == "zhr" or locale == "zht"

-- Mod Info
name = not isCN and "Lazy Wortox" or "慵懒小恶魔"
description = not isCN and [[
󰀅 Lazy Wortox 󰀅

Make playing Wortox easier with these convenient features:
- Press a key to quickly drop souls from your inventory
- Press a key to open soul jars effortlessly
- Press a key to perform a leap in place
- Press a key to withdraw souls from your soul jars
- Press a key to Store souls from your inventory into jars

You can customize all key bindings and settings in the mod options menu.
]]
or
[[
󰀅 慵懒小恶魔 󰀅

本模组为Wortox带来便捷功能：
- 一键快速丢弃背包中的灵魂
- 一键打开灵魂罐
- 一键实现原地跳跃
- 一键从灵魂罐中取出灵魂
- 一键从物品栏中存入灵魂

所有按键和设置均可在模组选项中自定义。
]]
author = "Tian || TianYu"
version = "1.0"
forumthread = ""

-- Mod Icon
icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- Client Or Server Sided
client_only_mod = true
all_clients_require_mod = false

-- Mod Compatibility
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
hamlet_compatible = false
forge_compatible = false

-- Api Version
api_version = 10

-- Tags
server_filter_tags = {
   "wortox", "helper", "qol"
}

-- Key Options
local key_options = {}
local keys = {
    "None",
    -- Numbers
    "0","1","2","3","4","5","6","7","8","9",
    "None",
    -- Letters
    "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "None",
    -- Function keys
    "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
    "None",
    -- Numpad
    "KP_0","KP_1","KP_2","KP_3","KP_4","KP_5","KP_6","KP_7","KP_8","KP_9",
    "KP_PERIOD","KP_DIVIDE","KP_MULTIPLY","KP_MINUS","KP_PLUS",
    "KP_ENTER","KP_EQUALS",
    "None",
    -- Control & Modifier keys
    "TAB","SPACE","ENTER","ESCAPE","BACKSPACE","INSERT","DELETE","HOME","END","PAGEUP","PAGEDOWN",
    "PAUSE","PRINT","CAPSLOCK","SCROLLOCK","LSHIFT","RSHIFT","LCTRL","RCTRL","LALT","RALT",
    "LSUPER","RSUPER",
    "None",
    -- Symbols / Punctuation
    "MINUS","EQUALS","PERIOD","SLASH","SEMICOLON","LEFTBRACKET","RIGHTBRACKET","BACKSLASH","TILDE",
    "None",
    -- Arrows
    "UP","DOWN","RIGHT","LEFT"
}
for i = 1, #keys do
    key_options[i] = {description = keys[i], data = keys[i]}
end

-- Value Options
local function GenerateValueOptions(min, max, step)
    local options = {}
    local i = 1
    for v = min, max, step or 1 do
        options[i] = { description = v, data = v }
        i = i + 1
    end
    return options
end

-- Mod Config Helper
local function AddSection(lang_en, lang_cn)
    local tempName = "temp_"..lang_en:gsub("%s+", "_"):lower()
    return {
        name = tempName,
        label = not isCN and "☆ " .. lang_en .. " ──────────────────" or "☆ " .. lang_cn .. " ──────────────────",
        options = {{description = "", data = 0}},
        default = 0
    }
end

-- Mod Config
configuration_options = {
    AddSection("Settings","设置"),
    {
        name = "Soul_Drop_Key",
        label = not isCN and "Drop Soul Key" or "丢弃灵魂按键",
        hover = not isCN and 
                        "Key that instantly drops any soul you’re holding or the first soul in your inventory."
                        or
                        "快速丢弃手中或背包灵魂的按键。",
        options = key_options,
        default = "R"
    },
    {
        name = "Open_Soul_Jar_Key",
        label = not isCN and "Open Jar Key" or "打开罐子按键",
        hover = not isCN and 
                        "Opens the first soul‑jar found in your inventory."
                        or
                        "打开背包中第一个灵魂罐。",
        options = key_options,
        default = "C"
    },
    {
        name = "Self_Leap_Key",
        label = not isCN and "Self‑Leap Key" or "原地跳跃按键",
        hover = not isCN and 
                        "Makes Wortox jump on the spot."
                        or
                        "让小恶魔原地跳跃。",
        options = key_options,
        default = "V"
    },
    {
        name = "Take_Soul_From_Jar_Key",
        label = not isCN and "Take Soul Key" or "取魂按键",
        hover = not isCN and 
                        "Withdraws souls from jars."
                        or
                        "从灵魂罐取出灵魂。",
        options = key_options,
        default = "B"
    },
    {
        name = "Put_Soul_In_Jar_Key",
        label = not isCN and "Store Soul Key" or "存魂按键",
        hover = not isCN and 
                        "Stores souls into jars."
                        or 
                        "将灵魂存入罐子。",
        options = key_options,
        default = "G"
    },
    {
        name = "Leap_To_Mouse_Key",
        label = not isCN and "Leap_To_Mouse_Key" or "Leap_To_Mouse_Key",
        hover = not isCN and 
                        ""
                        or 
                        "",
        options = key_options,
        default = "H" -- Temp default, remember to change it later !!!
    },
    {
        name = "Show_Range_Key",
        label = not isCN and "Show_Range_Key" or "Show_Range_Key",
        hover = not isCN and 
                        ""
                        or 
                        "",
        options = key_options,
        default = "F7" -- Temp default, remember to change it later !!!
    },
    AddSection("Souls To Take Settings","取魂设置"),
    {
        name = "Amount_Of_Souls_To_Take",
        label = not isCN and "Souls per Take" or "每次取魂数量",
        hover = not isCN and 
                        "How many souls to withdraw each time you press the key." 
                        or
                        "每次按取魂键时要取出的灵魂数量。",
        options = GenerateValueOptions(1, 20),
        default = 5
    },
    {
        name = "Take_Soul_Retries",
        label = not isCN and "Take Retries" or "取魂重试次数",
        hover = not isCN and 
                        "Number of extra attempts if the desired amount wasn’t taken." 
                        or
                        "若未成功取出足够的灵魂时重试的次数。",
        options = GenerateValueOptions(1, 5),
        default = 1
    },
    {
        name = "Wait_For_UI_Delay",
        label = not isCN and "UI Wait (frames)" or "等待UI帧数",
        hover = not isCN and 
                        "Frames to wait after opening a jar UI before moving souls." 
                        or
                        "打开罐子界面后等待的游戏帧数，再开始取魂。",
        options = GenerateValueOptions(1, 60),
        default = 6
    },
    {
        name = "Move_To_Next_Jar_Delay",
        label = not isCN and "Delay Between Jars" or "罐子切换延迟",
        hover = not isCN and 
                        "Frames to wait after withdrawing souls from one jar \n" .. "before starting to interact with the next jar."
                        or
                        "从一个罐子取出灵魂后，在操作下一个罐子前等待的帧数。",
        options = GenerateValueOptions(1, 60),
        default = 2
    },
    AddSection("Souls To Store Settings","存魂设置"),
    {
        name = "Amount_Of_Souls_To_Store",
        label = not isCN and "Souls per Store" or "每次存魂数量",
        hover = not isCN and 
                        "How many souls to store each time you press the key." 
                        or
                        "每次按存魂键时要存入的灵魂数量。",
        options = GenerateValueOptions(1, 20),
        default = 5
    },
    {
        name = "Soul_Hand_Check_Interval",
        label = not isCN and "Hand‑Check (sec)" or "手持检查间隔",
        hover = not isCN and 
                        "Seconds to wait before checking if more souls remain in hand for the next store cycle."
                        or
                        "检测手中是否还有灵魂前等待的秒数，用于放魂循环。",
        options = GenerateValueOptions(0.1, 1, 0.1),
        default = 0.4
    },
    AddSection("Debug","调试"),
    {
        name = "Debug_Mode",
        label = not isCN and "Debug Mode" or "调试模式",
        hover = not isCN and 
                        "Debug mode will print additional information to the console.\nUseful for troubleshooting or development."
                        or
                        "调试模式会在控制台显示额外信息。\n有助于故障排除或开发。",
        options = {
            { description = "True", data = true },
            { description = "False", data = false }
        },
        default = false
    }

}

-- Emoji Icons
-- Source: https://dst-api-docs.fandom.com/wiki/Icon_codes

-- ["Red skull"] = "󰀀",
-- ["Beefalo"] = "󰀁",
-- ["Chest"] = "󰀂",
-- ["Chester"] = "󰀃",
-- ["Crockpot"] = "󰀄",
-- ["Eye"] = "󰀅",
-- ["Teeth"] = "󰀆",
-- ["Farm"] = "󰀇",

-- ["Fire"] = "󰀈",
-- ["Ghost"] = "󰀉",
-- ["Tombstone"] = "󰀊",
-- ["Meatbat"] = "󰀋",
-- ["Hammer"] = "󰀌",
-- ["Heart"] = "󰀍",
-- ["Stomach"] = "󰀎",
-- ["Lightbulb"] = "󰀏",

-- ["Pig"] = "󰀐",
-- ["Manure"] = "󰀑",
-- ["Red gem"] = "󰀒",
-- ["Brain"] = "󰀓",
-- ["Science machine"] = "󰀔",
-- ["White skull"] = "󰀕",
-- ["Top hat"] = "󰀖",
-- ["Spider net"] = "󰀗",

-- ["Swords"] = "󰀘",
-- ["Strong arm"] = "󰀙",
-- ["Gold nugget"] = "󰀚",
-- ["Torch"] = "󰀛",
-- ["Red flower"] = "󰀜",
-- ["Alchemy engine"] = "󰀝",
-- ["Backpack"] = "󰀞",
-- ["Bee hive"] = "󰀟",

-- ["Berry bush"] = "󰀠",
-- ["Carrot"] = "󰀡",
-- ["Fried egg"] = "󰀢",
-- ["Eyeplant"] = "󰀣",
-- ["Firepit"] = "󰀤",
-- ["Beefalo horn"] = "󰀥",
-- ["Meat"] = "󰀦",
-- ["Diamond"] = "󰀧",

-- ["Salt"] = "󰀨",
-- ["Shadow Manipulator"] = "󰀩",
-- ["Shovel"] = "󰀪",
-- ["Thumb up"] = "󰀫",
-- ["Trap"] = "󰀬",
-- ["Goblet"] = "󰀭",
-- ["Hand"] = "󰀮",
-- ["Wormhole"] = "󰀯"


-- Looking through my code and wanting to mod yourself? have a look at the below links.
-- Links
-- https://dst-api-docs.fandom.com/wiki/Modinfo.lua
-- https://forums.kleientertainment.com/forums/topic/116302-ultromans-tutorial-collection-newcomer-intro/
-- https://forums.kleientertainment.com/forums/topic/126774-documentation-list-of-all-engine-functions/
-- https://dst-api-docs.fandom.com/wiki/AddKeyDownHandler