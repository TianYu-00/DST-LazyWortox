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
   "wortox"
}

-- Key Options
-- ..\SteamLibrary\steamapps\common\Don't Starve Together\data\databundles\scripts.zip\scripts\constants.lua
local key_options = {}
local keys = {
    "None",
    "0","1","2","3","4","5","6","7","8","9",
    "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
    "ALT","CTRL","SHIFT","TAB","BACKSPACE","PERIOD","SLASH","SEMICOLON","LEFTBRACKET","RIGHTBRACKET","BACKSLASH","TILDE"
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
        label = not isCN and "Soul Drop Key" or "灵魂释放按键",
        hover = not isCN and "Press this key to drop soul(s) from your inventory." or "按下此键从背包中丢弃灵魂。",
        options = key_options,
        default = "R"
    },
    {
        name = "Open_Soul_Jar_Key",
        label = not isCN and "Open Soul Jar Key" or "打开魂罐按键",
        hover = not isCN and "Press this key to open soul jar" or "按下此键打开灵魂罐",
        options = key_options,
        default = "C"
    },
    {
        name = "Self_Leap_Key",
        label = not isCN and "Self Leap Key" or "原地跳跃按键",
        hover = not isCN and "Press this key to perform a leap on the spot." or "按下此键执行原地跳跃动作",
        options = key_options,
        default = "V"
    },
    {
        name = "Take_Soul_From_Jar_Key",
        label = not isCN and "Take Soul From Jar Key" or "罐子取魂按键",
        hover = not isCN and "Press this key to withdraw souls from your soul jars." or "按下此键从灵魂罐中取出灵魂。",
        options = key_options,
        default = "B"
    },
    {
        name = "Put_Soul_In_Jar_Key",
        label = not isCN and "Put Soul In Jar Key" or "罐子放魂按键",
        hover = not isCN and "" or "",
        options = key_options,
        default = "G"
    },
    AddSection("Souls To Take Settings","取魂设置"),
    {
        name = "Amount_Of_Souls_To_Take",
        label = not isCN and "Amount Of Souls To Take" or "取魂数量",
        hover = not isCN and 
                        "How many souls to automatically extract from your jars each time you press the key.\nSet higher to withdraw more at once." 
                        or
                        "每次按键自动从血罐中取出的灵魂数量。\n数值越高，一次性取出越多。",
        options = GenerateValueOptions(1, 20),
        default = 5
    },
    {
        name = "Take_Soul_Retries",
        label = not isCN and "Soul Take Retry Attempts" or "取魂重试次数",
        hover = not isCN and 
                        "Number of times to retry taking souls from jars if the desired amount wasn't taken." 
                        or 
                        "如果未成功取出足够的灵魂，重试取魂的次数。",
        options = GenerateValueOptions(1, 5),
        default = 1
    },
    {
        name = "Frames_To_Wait_For_UI",
        label = not isCN and "Frames to Wait for UI" or "等待UI打开的帧数",
        hover = not isCN and 
                        "Number of frames to wait after opening the jar UI before taking souls.\nToo low may cause errors if the UI isn’t ready yet." 
                        or
                        "打开罐子界面后等待的帧数，之后才开始取出灵魂。\n等待时间太短可能导致UI未准备好而出错。",
        options = GenerateValueOptions(1, 60),
        default = 6
    },
    {
        name = "Frames_To_Move_To_Next_Jar",
        label = not isCN and "Frames Before Moving to Next Jar" or "切换到下一个罐子前等待的帧数",
        hover = not isCN and 
                        "Number of frames to wait after taking souls before attempting the next jar.\nHelps ensure the previous transfer completes smoothly."
                        or
                        "取出灵魂后，切换到下一个罐子前等待的帧数。\n确保上一次转移顺利完成。",
        options = GenerateValueOptions(1, 60),
        default = 2
    },
    AddSection("Souls To Put Settings","放魂设置"),
    {
        name = "Decimal_Put_Soul_In_Jar_Delay",
        label = not isCN and "Put Soul Delay (Seconds)" or "放灵魂延迟（秒数）",
        hover = not isCN and 
                        ""
                        or
                        "",
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
            "调试模式会在控制台打印额外信息。\n有助于故障排除或开发。",
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