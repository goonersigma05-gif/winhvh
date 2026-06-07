-- Cipher — Zee Hood Silent Aim
-- Professional ESP & Aimbot System

-- ─────────────────────────────────────────────────────────────
-- ADONIS ANTICHEAT BYPASS
-- ─────────────────────────────────────────────────────────────

local getinfo = getinfo or debug.getinfo
local DEBUG   = false
local Hooked  = {}
local Detected, Kill

setthreadidentity(2)

for i, v in getgc(true) do
    if typeof(v) == "table" then
        local DetectFunc = rawget(v, "Detected")
        local KillFunc   = rawget(v, "Kill")

        if typeof(DetectFunc) == "function" and not Detected then
            Detected = DetectFunc
            local Old; Old = hookfunction(Detected, function(Action, Info, NoCrash)
                if Action ~= "_" then
                    if DEBUG then warn(`Adonis AntiCheat flagged\nMethod: {Action}\nInfo: {Info}`) end
                end
                return true
            end)
            table.insert(Hooked, Detected)
        end

        if rawget(v, "Variables") and rawget(v, "Process") and typeof(KillFunc) == "function" and not Kill then
            Kill = KillFunc
            local Old; Old = hookfunction(Kill, function(Info)
                if DEBUG then warn(`Adonis AntiCheat tried to kill (fallback): {Info}`) end
            end)
            table.insert(Hooked, Kill)
        end
    end
end

local Old; Old = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local LevelOrFunc, Info = ...
    if Detected and LevelOrFunc == Detected then
        if DEBUG then warn(`zins | adonis bypassed`) end
        return coroutine.yield(coroutine.running())
    end
    return Old(...)
end))

setthreadidentity(7)

-- ─────────────────────────────────────────────────────────────

-- Load custom styled UI library
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/goonersigma05-gif/winhvh/refs/heads/main/loader.lua'))()

local Options = getgenv().Options
local Toggles = getgenv().Toggles

-- SaveManager implementation
local SaveManager = {} do
    SaveManager.Folder = 'LinoriaLibSettings'
    SaveManager.Ignore = {}
    SaveManager.Parser = {
        Toggle = {
            Save = function(idx, object) return { type = 'Toggle', idx = idx, value = object.Value } end,
            Load = function(idx, data) if Toggles[idx] then Toggles[idx]:SetValue(data.value) end end,
        },
        Slider = {
            Save = function(idx, object) return { type = 'Slider', idx = idx, value = tostring(object.Value) } end,
            Load = function(idx, data) if Options[idx] then Options[idx]:SetValue(data.value) end end,
        },
        Dropdown = {
            Save = function(idx, object) return { type = 'Dropdown', idx = idx, value = object.Value, mutli = object.Multi } end,
            Load = function(idx, data) if Options[idx] then Options[idx]:SetValue(data.value) end end,
        },
        ColorPicker = {
            Save = function(idx, object) return { type = 'ColorPicker', idx = idx, value = object.Value:ToHex(), transparency = object.Transparency } end,
            Load = function(idx, data) if Options[idx] then Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency) end end,
        },
        KeyPicker = {
            Save = function(idx, object) return { type = 'KeyPicker', idx = idx, mode = object.Mode, key = object.Value } end,
            Load = function(idx, data) if Options[idx] then Options[idx]:SetValue({ data.key, data.mode }) end end,
        },
        Input = {
            Save = function(idx, object) return { type = 'Input', idx = idx, text = object.Value } end,
            Load = function(idx, data) if Options[idx] and type(data.text) == 'string' then Options[idx]:SetValue(data.text) end end,
        },
    }

    function SaveManager:SetIgnoreIndexes(list) for _, key in next, list do self.Ignore[key] = true end end
    function SaveManager:SetFolder(folder) self.Folder = folder; self:BuildFolderTree() end
    function SaveManager:SetLibrary(library) self.Library = library end
    function SaveManager:IgnoreThemeSettings() end
    
    function SaveManager:BuildFolderTree()
        local paths = { self.Folder, self.Folder .. '/settings' }
        for _, path in next, paths do if not isfolder(path) then makefolder(path) end end
    end

    function SaveManager:RefreshConfigList()
        local list = listfiles(self.Folder .. '/settings')
        local out = {}
        for _, file in next, list do
            if file:sub(-5) == '.json' then
                local pos = file:find('.json', 1, true)
                local start = pos
                local char = file:sub(pos, pos)
                while char ~= '/' and char ~= '\\' and char ~= '' do
                    pos = pos - 1
                    char = file:sub(pos, pos)
                end
                table.insert(out, file:sub(pos + 1, start - 1))
            end
        end
        return out
    end

    function SaveManager:GetConfigPath(name) return string.format('%s/settings/%s.json', self.Folder, name) end

    function SaveManager:Save(name)
        if not name then name = 'default' end
        local fullPath = self:GetConfigPath(name)
        local data = { }
        for idx, toggle in next, Toggles do
            if self.Ignore[idx] then continue end
            local parser = self.Parser[toggle.Type]
            if parser then table.insert(data, parser.Save(idx, toggle)) end
        end
        for idx, option in next, Options do
            if self.Ignore[idx] then continue end
            local parser = self.Parser[option.Type]
            if parser then table.insert(data, parser.Save(idx, option)) end
        end
        writefile(fullPath, game:GetService('HttpService'):JSONEncode(data))
        self.Library:Notify(string.format('Saved config %q', name))
    end

    function SaveManager:Load(name)
        if not name then name = 'default' end
        local fullPath = self:GetConfigPath(name)
        if not isfile(fullPath) then return self.Library:Notify('Config file not found') end
        local success, data = pcall(game:GetService('HttpService').JSONDecode, game:GetService('HttpService'), readfile(fullPath))
        if not success then return self.Library:Notify('Failed to decode config') end
        for _, entry in next, data do
            local parser = self.Parser[entry.type]
            if parser then parser.Load(entry.idx, entry) end
        end
        self.Library:Notify(string.format('Loaded config %q', name))
    end

    function SaveManager:BuildConfigSection(tab)
        local section = tab:AddRightGroupbox('Configuration')
        section:AddInput('SaveManager_ConfigName', { Text = 'Config name', Default = 'default', Placeholder = 'config name' })
        section:AddDivider()
        section:AddDropdown('SaveManager_ConfigList', { Values = self:RefreshConfigList(), AllowNull = true, Text = 'Config list' })
        section:AddButton({ Text = 'Create', Func = function()
            local name = Options.SaveManager_ConfigName.Value
            if name:gsub(' ', '') == '' then return self.Library:Notify('Invalid config name') end
            self:Save(name)
            Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            Options.SaveManager_ConfigList:SetValue(name)
        end})
        section:AddButton({ Text = 'Load', Func = function()
            local name = Options.SaveManager_ConfigList.Value
            if name:gsub(' ', '') == '' then return self.Library:Notify('Invalid config name') end
            self:Load(name)
        end})
        section:AddButton({ Text = 'Overwrite', Func = function()
            local name = Options.SaveManager_ConfigList.Value
            if name:gsub(' ', '') == '' then return self.Library:Notify('Invalid config name') end
            self:Save(name)
        end})
        section:AddButton({ Text = 'Refresh', Func = function()
            Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
        end})
        section:AddDivider()
        section:AddToggle('SaveManager_AutoLoad', { Text = 'Auto load', Default = false })
        section:AddInput('SaveManager_AutoLoadConfig', { Text = 'Auto load config', Default = 'default', Placeholder = 'config name' })
        self.ConfigSection = section
    end

    function SaveManager:LoadAutoloadConfig()
        if Options.SaveManager_AutoLoad and Options.SaveManager_AutoLoad.Value then
            task.spawn(function()
                wait(1)
                self:Load(Options.SaveManager_AutoLoadConfig.Value)
            end)
        end
    end
end

-- ThemeManager implementation
local ThemeManager = {} do
    ThemeManager.Folder = 'LinoriaLibSettings'
    function ThemeManager:SetLibrary(library) self.Library = library end
    function ThemeManager:SetFolder(folder) self.Folder = folder end
    function ThemeManager:ApplyToTab(tab) end
end

-- Get game name for title
local gameName = 'Da Hood'
pcall(function()
    gameName = game:GetService('MarketplaceService'):GetProductInfo(game.PlaceId).Name
end)

local Window = Library:CreateWindow({
    Title = 'Cipher',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Legitbot  = Window:AddTab('Legitbot'),
    Ragebot   = Window:AddTab('Ragebot'),
    Rage      = Window:AddTab('Rage'),
    Misc      = Window:AddTab('Misc'),
    Visuals   = Window:AddTab('Visuals'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- ─────────────────────────────────────────────────────────────
-- LEGITBOT TAB
-- ─────────────────────────────────────────────────────────────

local LegitbotBox = Tabs.Legitbot:AddLeftGroupbox('Legitbot')

-- ─────────────────────────────────────────────────────────────
-- RAGEBOT TAB
-- ─────────────────────────────────────────────────────────────

local RagebotTarget = nil
local RagebotTargetList    = {}  -- selected targets
local RagebotWhitelistList = {}  -- whitelisted players
local RagebotSearchResult  = nil -- current search result player

-- LEFT SIDE: Settings
local RagebotSettingsBox = Tabs.Ragebot:AddLeftGroupbox('Settings')

RagebotSettingsBox:AddLabel('⚠ HvH only — use C-Sync')
RagebotSettingsBox:AddLabel('& Legitbot for normal play')
RagebotSettingsBox:AddDivider()

RagebotSettingsBox:AddToggle('RagebotEnabled', {
    Text    = 'Enabled',
    Default = false,
    Tooltip = 'Enable/Disable ragebot',
    Callback = function(value)
        if not value then
            -- Disable C-Sync when ragebot is disabled
            if Toggles.CSyncEnabled then
                Toggles.CSyncEnabled:SetValue(false)
            end
            RagebotTarget = nil
        end
    end
}):AddKeyPicker('RagebotEnabledKeybind', {
    Default          = 'None',
    SyncToggleState  = true,
    Mode             = 'Toggle',
    Text             = 'Ragebot Keybind',
    NoUI             = false,
})

RagebotSettingsBox:AddToggle('RagebotTargetStats', {
    Text    = 'Show Stats',
    Default = false,
    Tooltip = 'Show target stats beside mouse cursor',
})

RagebotSettingsBox:AddToggle('RagebotTargetStatsAlwaysShow', {
    Text    = 'Always Show Stats',
    Default = false,
    Tooltip = 'Show stats UI even without a target',
})

RagebotSettingsBox:AddDivider()

RagebotSettingsBox:AddLabel('Settings')

RagebotSettingsBox:AddDropdown('RagebotSettings', {
    Values  = { 'View', 'Randomize Strafe' },
    Default = 1,
    Multi   = true,
    Text    = 'Options',
    Tooltip = 'View = Spectate target | Randomize Strafe = Add randomness to strafe pattern',
})

RagebotSettingsBox:AddDivider()

RagebotSettingsBox:AddLabel('Strafe Settings')

RagebotSettingsBox:AddSlider('RagebotStrafeSpeed', {
    Text     = 'Speed',
    Default  = 1,
    Min      = 0.5,
    Max      = 5,
    Rounding = 1,
    Compact  = true,
    Tooltip  = 'How fast to strafe around target',
})

RagebotSettingsBox:AddSlider('RagebotStrafeRange', {
    Text     = 'Range',
    Default  = 7,
    Min      = 5,
    Max      = 30,
    Rounding = 0,
    Compact  = true,
    Tooltip  = 'Distance to strafe',
})

RagebotSettingsBox:AddSlider('RagebotStrafeHeight', {
    Text     = 'Height',
    Default  = 2,
    Min      = 0,
    Max      = 20,
    Rounding = 0,
    Compact  = true,
    Tooltip  = 'Height variation',
})

RagebotSettingsBox:AddSlider('RagebotStrafeRandomness', {
    Text     = 'Randomness',
    Default  = 0,
    Min      = 0,
    Max      = 10,
    Rounding = 1,
    Compact  = true,
    Tooltip  = 'How random the strafe pattern is',
})

RagebotSettingsBox:AddDivider()

RagebotSettingsBox:AddToggle('RagebotPredictionEnabled', {
    Text    = 'Prediction',
    Default = true,
})

RagebotSettingsBox:AddSlider('RagebotPredictionMultiplier', {
    Text     = 'Multiplier',
    Default  = 2.4,
    Min      = 0.1,
    Max      = 5,
    Rounding = 1,
    Compact  = true,
})

RagebotSettingsBox:AddSlider('RagebotPredictionBase', {
    Text     = 'Base',
    Default  = 0.07,
    Min      = 0.01,
    Max      = 5,
    Rounding = 2,
    Compact  = true,
})

RagebotSettingsBox:AddDivider()

RagebotSettingsBox:AddToggle('ResolverEnabled', {
    Text    = 'Resolver',
    Default = false,
    Tooltip = 'Predict real position of void/flying/anti-aim players',
})

RagebotSettingsBox:AddSlider('ResolverRefreshTime', {
    Text     = 'Refresh Time',
    Default  = 3,
    Min      = 0,
    Max      = 10,
    Rounding = 1,
    Compact  = true,
    Tooltip  = 'How often the position history resets (seconds)',
})

RagebotSettingsBox:AddSlider('ResolverForgiveness', {
    Text     = 'Forgiveness',
    Default  = 14.4,
    Min      = 0,
    Max      = 20,
    Rounding = 1,
    Compact  = true,
    Tooltip  = 'Cluster radius — higher = more lenient grouping',
})

RagebotSettingsBox:AddSlider('ResolverVoidBonus', {
    Text     = 'Void Bonus',
    Default  = 5,
    Min      = 0,
    Max      = 12,
    Rounding = 1,
    Compact  = true,
    Tooltip  = 'Extra forgiveness when target is in the void',
})

RagebotSettingsBox:AddSlider('ResolverDistPenalty', {
    Text     = 'Distance Penalty',
    Default  = 2,
    Min      = 0,
    Max      = 5,
    Rounding = 1,
    Compact  = true,
    Tooltip  = 'Reduce forgiveness based on target distance',
})

-- RIGHT SIDE: Targeting
local RagebotBox = Tabs.Ragebot:AddRightGroupbox('Targeting')

-- Whitelist dropdown - shows all players so you can pick who to whitelist
RagebotBox:AddDropdown('RagebotWhitelistSelect', {
    Values  = {"Loading..."},
    Default = 1,
    Multi   = false,
    Text    = 'Whitelist',
})

-- Targets dropdown - shows all players
RagebotBox:AddDropdown('RagebotTargetSelect', {
    Values  = {"Loading..."},
    Default = 1,
    Multi   = false,
    Text    = 'Targets',
})

RagebotBox:AddDivider()

-- Player search input
RagebotBox:AddInput('RagebotSearchInput', {
    Default     = '',
    Numeric     = false,
    Finished    = false,
    Text        = 'Player Search',
    Placeholder = 'player...',
    MaxLength   = 32,
})

-- Search result label — updates as you type
local RagebotResultLabel = RagebotBox:AddLabel('result: --')

RagebotBox:AddDivider()

-- Buttons row 1: Whitelist | Target (side-by-side)
local WhitelistBtn = RagebotBox:AddButton({
    Text = 'Whitelist',
    Func = function()
        -- Use search result first, fall back to dropdown selection
        local result = RagebotSearchResult
        if not result then
            local dropVal = Options.RagebotWhitelistSelect and Options.RagebotWhitelistSelect.Value
            if dropVal and dropVal ~= 'Loading...' and dropVal ~= 'No players available' then
                result = dropVal
            end
        end
        if not result then
            Library:Notify('Search a player or select from dropdown first', 2)
            return
        end
        local already = false
        for _, n in ipairs(RagebotWhitelistList) do
            if n == result then already = true; break end
        end
        if not already then
            table.insert(RagebotWhitelistList, result)
            if RagebotTarget and RagebotTarget.Name == result then
                RagebotTarget = nil
                Toggles.CSyncEnabled:SetValue(false)
            end
            Library:Notify('Whitelisted: ' .. result, 2)
        else
            Library:Notify(result .. ' already whitelisted', 2)
        end
    end
})

WhitelistBtn:AddButton({
    Text = 'Target',
    Func = function()
        -- Use search result first, fall back to dropdown selection
        local result = RagebotSearchResult
        if not result then
            local dropVal = Options.RagebotTargetSelect and Options.RagebotTargetSelect.Value
            if dropVal and dropVal ~= 'Loading...' and dropVal ~= 'No players available' then
                result = dropVal
            end
        end
        if not result then
            Library:Notify('Search a player or select from dropdown first', 2)
            return
        end

        -- Check if ragebot is enabled
        if not Toggles.RagebotEnabled or not Toggles.RagebotEnabled.Value then
            Library:Notify('Enable ragebot first', 2)
            return
        end

        -- Check not whitelisted
        for _, n in ipairs(RagebotWhitelistList) do
            if n == result then
                Library:Notify(result .. ' is whitelisted', 2)
                return
            end
        end
        local plr = game:GetService('Players'):FindFirstChild(result)
        if plr then
            RagebotTarget = plr
            Toggles.CSyncEnabled:SetValue(true)
            Library:Notify('Targeting: ' .. result, 2)
        else
            Library:Notify('Player not in game', 2)
        end
    end
})

-- Buttons row 2: Clear Whitelist | Clear Targets (side-by-side)
local ClearWhitelistBtn = RagebotBox:AddButton({
    Text = 'Clear Whitelist',
    Func = function()
        RagebotWhitelistList = {}
        -- Restore player list in dropdown
        local playerList = UpdateRagebotPlayerList()
        Options.RagebotWhitelistSelect:SetValues(playerList)
        Library:Notify('Whitelist cleared', 2)
    end
})

ClearWhitelistBtn:AddButton({
    Text = 'Clear Targets',
    Func = function()
        RagebotTarget = nil
        Toggles.CSyncEnabled:SetValue(false)
        Library:Notify('Target cleared', 2)
    end
})

RagebotBox:AddDivider()

RagebotBox:AddToggle('RagebotHighlight', {
    Text    = 'Highlight Target',
    Default = true,
    Tooltip = 'Highlight the ragebot target',
})

RagebotBox:AddLabel('Highlight Colors'):AddColorPicker('RagebotHighlightFill', {
    Default = Color3.fromRGB(255, 0, 0),
    Title   = 'Fill Color',
}):AddColorPicker('RagebotHighlightOutline', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'Outline Color',
})

RagebotBox:AddSlider('RagebotHighlightFillTrans', {
    Text     = 'Fill Transparency',
    Default  = 0.5,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Compact  = false,
})

RagebotBox:AddSlider('RagebotHighlightOutlineTrans', {
    Text     = 'Outline Transparency',
    Default  = 0,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Compact  = false,
})

RagebotBox:AddDivider()

RagebotBox:AddToggle('HitboxExpanderEnabled', {
    Text    = 'Hitbox Expander',
    Default = false,
    Tooltip = 'Expand target hitboxes for easier hits',
})

RagebotBox:AddLabel('Hitbox Colors'):AddColorPicker('HitboxMainColor', {
    Default = Color3.fromRGB(0, 85, 255),
    Title   = 'Main Color',
}):AddColorPicker('HitboxOutlineColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'Outline Color',
})

RagebotBox:AddSlider('HitboxSizeX', {
    Text     = 'Size X',
    Default  = 10,
    Min      = 1,
    Max      = 50,
    Rounding = 1,
    Compact  = true,
})

RagebotBox:AddSlider('HitboxSizeY', {
    Text     = 'Size Y',
    Default  = 10,
    Min      = 1,
    Max      = 50,
    Rounding = 1,
    Compact  = true,
})

RagebotBox:AddSlider('HitboxSizeZ', {
    Text     = 'Size Z',
    Default  = 10,
    Min      = 1,
    Max      = 50,
    Rounding = 1,
    Compact  = true,
})

-- ─────────────────────────────────────────────────────────────
-- BACK TO LEGITBOT
-- ─────────────────────────────────────────────────────────────

LegitbotBox:AddToggle('AimbotEnabled', {
    Text    = 'Enabled',
    Default = false,
    Tooltip = 'Redirect bullets toward the closest enemy',
}):AddKeyPicker('AimbotKeybind', {
    Default          = 'None',
    SyncToggleState  = true,
    Mode             = 'Toggle',
    Text             = 'Legitbot Keybind',
    NoUI             = false,
})

LegitbotBox:AddToggle('StickyAim', {
    Text    = 'Sticky Aim',
    Default = false,
    Tooltip = 'Lock onto first target until they die',
})

LegitbotBox:AddToggle('TeamCheck', {
    Text    = 'Team Check',
    Default = true,
    Tooltip = 'Skip teammates',
})

LegitbotBox:AddToggle('VisibleCheck', {
    Text    = 'Visible Check',
    Default = false,
    Tooltip = 'Only lock onto visible targets',
})

LegitbotBox:AddToggle('FriendCheck', {
    Text    = 'Friend Check',
    Default = false,
    Tooltip = 'Skip friends',
})

LegitbotBox:AddToggle('AntiLock', {
    Text    = 'Anti Lock',
    Default = false,
    Tooltip = 'Make you harder to lock onto by other players',
})

LegitbotBox:AddSlider('AntiLockHeight', {
    Text     = 'Sky Height',
    Default  = 90,
    Min      = 50,
    Max      = 999,
    Rounding = 0,
    Compact  = true,
    Tooltip  = 'How high the velocity spike goes (high values = embarrass them)',
})

LegitbotBox:AddDropdown('TargetPart', {
    Values  = { 'HumanoidRootPart', 'Head', 'Torso' },
    Default = 1,
    Multi   = false,
    Text    = 'Target Part',
})

LegitbotBox:AddToggle('PredictionEnabled', {
    Text    = 'Prediction',
    Default = false,
    Tooltip = 'Enable bullet prediction',
})

LegitbotBox:AddSlider('Prediction', {
    Text     = 'Prediction Amount',
    Default  = 0.13,
    Min      = 0.11,
    Max      = 0.20,
    Rounding = 2,
    Compact  = false,
})

LegitbotBox:AddSlider('HitChance', {
    Text     = 'Hit Chance (%)',
    Default  = 100,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Compact  = false,
    Tooltip  = 'Chance to hit (100 = always hit)',
})

LegitbotBox:AddDivider()

LegitbotBox:AddToggle('LookAtTarget', {
    Text    = 'Look at Target',
    Default = false,
    Tooltip = 'Face your character toward the locked target',
})

LegitbotBox:AddToggle('ForceHitEnabled', {
    Text    = 'Force Hit',
    Default = false,
    Tooltip = 'Always hit target no matter distance or obstacles',
})

LegitbotBox:AddToggle('AntiAimViewer', {
    Text    = 'Anti Aim Viewer',
    Default = false,
    Tooltip = 'Prevents others from seeing your camera angles',
})

local FOVBox = Tabs.Legitbot:AddLeftGroupbox('FOV Circle')

FOVBox:AddToggle('FOVEnabled', {
    Text    = 'Show FOV',
    Default = false,
    Tooltip = 'Display FOV circle',
})

FOVBox:AddSlider('FOVRadius', {
    Text     = 'Radius',
    Default  = 200,
    Min      = 50,
    Max      = 800,
    Rounding = 0,
    Compact  = false,
})

FOVBox:AddToggle('FOVFilled', {
    Text    = 'Filled',
    Default = false,
})

FOVBox:AddSlider('FOVFillTransparency', {
    Text     = 'Fill Transparency',
    Default  = 0.8,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Compact  = false,
})

FOVBox:AddLabel('FOV Colors'):AddColorPicker('FOVColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'Main Color',
}):AddColorPicker('FOVOutlineColor', {
    Default = Color3.fromRGB(0, 0, 0),
    Title   = 'Outline Color',
}):AddColorPicker('FOVFillColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'Fill Color',
})

FOVBox:AddDivider()

FOVBox:AddToggle('FOVSpinningDots', {
    Text    = 'Spinning Dots',
    Default = false,
    Tooltip = 'Add animated dots around FOV',
})

FOVBox:AddSlider('FOVDotCount', {
    Text     = 'Dot Count',
    Default  = 8,
    Min      = 3,
    Max      = 24,
    Rounding = 0,
    Compact  = false,
})

FOVBox:AddSlider('FOVSpinSpeed', {
    Text     = 'Spin Speed',
    Default  = 2,
    Min      = 0.5,
    Max      = 10,
    Rounding = 1,
    Compact  = false,
})

FOVBox:AddToggle('FOVRainbow', {
    Text    = 'Rainbow Mode',
    Default = false,
})

-- ─────────────────────────────────────────────────────────────
-- CAMLOCK TAB (RIGHT SIDE)
-- ─────────────────────────────────────────────────────────────

local CamlockBox = Tabs.Legitbot:AddRightGroupbox('Camlock')

CamlockBox:AddToggle('CamlockEnabled', {
    Text    = 'Enabled',
    Default = false,
    Tooltip = 'Lock camera to closest target',
}):AddKeyPicker('CamlockKeybind', {
    Default          = 'None',
    SyncToggleState  = true,
    Mode             = 'Toggle',
    Text             = 'Camlock Keybind',
    NoUI             = false,
})

CamlockBox:AddToggle('CamlockStickyAim', {
    Text    = 'Sticky Aim',
    Default = false,
    Tooltip = 'Lock onto first target until they die',
})

CamlockBox:AddToggle('CamlockTeamCheck', {
    Text    = 'Team Check',
    Default = true,
    Tooltip = 'Skip teammates',
})

CamlockBox:AddToggle('CamlockVisibleCheck', {
    Text    = 'Visible Check',
    Default = false,
    Tooltip = 'Only lock onto visible targets',
})

CamlockBox:AddToggle('CamlockFriendCheck', {
    Text    = 'Friend Check',
    Default = false,
    Tooltip = 'Skip friends',
})

CamlockBox:AddToggle('CamlockAntiAimViewer', {
    Text    = 'Anti Aim Viewer',
    Default = false,
    Tooltip = 'Prevents others from seeing your camera angles',
})

CamlockBox:AddDropdown('CamlockTargetPart', {
    Values  = { 'HumanoidRootPart', 'Head', 'Torso' },
    Default = 1,
    Multi   = false,
    Text    = 'Target Part',
})

CamlockBox:AddToggle('CamlockPredictionEnabled', {
    Text    = 'Prediction',
    Default = false,
    Tooltip = 'Enable bullet prediction',
})

CamlockBox:AddSlider('CamlockPrediction', {
    Text     = 'Prediction Amount',
    Default  = 0.13,
    Min      = 0.11,
    Max      = 0.20,
    Rounding = 2,
    Compact  = false,
})

CamlockBox:AddSlider('CamlockHitChance', {
    Text     = 'Hit Chance (%)',
    Default  = 100,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Compact  = false,
    Tooltip  = 'Chance to hit (100 = always hit)',
})

CamlockBox:AddDivider()

CamlockBox:AddLabel('Smoothness')

CamlockBox:AddSlider('CamlockSmoothnessX', {
    Text     = 'Smoothness X',
    Default  = 1,
    Min      = 0.1,
    Max      = 5,
    Rounding = 1,
    Compact  = false,
    Tooltip  = 'Camera smoothness on X axis',
})

CamlockBox:AddSlider('CamlockSmoothnessY', {
    Text     = 'Smoothness Y',
    Default  = 1,
    Min      = 0.1,
    Max      = 5,
    Rounding = 1,
    Compact  = false,
    Tooltip  = 'Camera smoothness on Y axis',
})

CamlockBox:AddSlider('CamlockSmoothnessZ', {
    Text     = 'Smoothness Z',
    Default  = 1,
    Min      = 0.1,
    Max      = 5,
    Rounding = 1,
    Compact  = false,
    Tooltip  = 'Camera smoothness on Z axis',
})

local CamlockFOVBox = Tabs.Legitbot:AddRightGroupbox('Camlock FOV Circle')

CamlockFOVBox:AddToggle('CamlockFOVEnabled', {
    Text    = 'Show FOV',
    Default = false,
    Tooltip = 'Display camlock FOV circle',
})

CamlockFOVBox:AddSlider('CamlockFOVRadius', {
    Text     = 'Radius',
    Default  = 200,
    Min      = 50,
    Max      = 800,
    Rounding = 0,
    Compact  = false,
})

CamlockFOVBox:AddToggle('CamlockFOVFilled', {
    Text    = 'Filled',
    Default = false,
})

CamlockFOVBox:AddSlider('CamlockFOVFillTransparency', {
    Text     = 'Fill Transparency',
    Default  = 0.8,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Compact  = false,
})

CamlockFOVBox:AddLabel('FOV Colors'):AddColorPicker('CamlockFOVColor', {
    Default = Color3.fromRGB(100, 200, 255),
    Title   = 'Main Color',
}):AddColorPicker('CamlockFOVOutlineColor', {
    Default = Color3.fromRGB(0, 0, 0),
    Title   = 'Outline Color',
}):AddColorPicker('CamlockFOVFillColor', {
    Default = Color3.fromRGB(100, 200, 255),
    Title   = 'Fill Color',
})

CamlockFOVBox:AddDivider()

CamlockFOVBox:AddToggle('CamlockFOVSpinningDots', {
    Text    = 'Spinning Dots',
    Default = false,
    Tooltip = 'Add animated dots around FOV',
})

CamlockFOVBox:AddSlider('CamlockFOVDotCount', {
    Text     = 'Dot Count',
    Default  = 8,
    Min      = 3,
    Max      = 24,
    Rounding = 0,
    Compact  = false,
})

CamlockFOVBox:AddSlider('CamlockFOVSpinSpeed', {
    Text     = 'Spin Speed',
    Default  = 2,
    Min      = 0.5,
    Max      = 10,
    Rounding = 1,
    Compact  = false,
})

CamlockFOVBox:AddToggle('CamlockFOVRainbow', {
    Text    = 'Rainbow Mode',
    Default = false,
})

-- ─────────────────────────────────────────────────────────────
-- VISUALS TAB
-- ─────────────────────────────────────────────────────────────

local ESPBox = Tabs.Visuals:AddLeftGroupbox('ESP')

ESPBox:AddToggle('ESPEnabled', {
    Text    = 'Enabled',
    Default = false,
})

ESPBox:AddToggle('ESPBoxes', {
    Text    = 'Boxes',
    Default = true,
})

ESPBox:AddSlider('ESPRounding', {
    Text     = 'Corner Radius',
    Default  = 8,
    Min      = 0,
    Max      = 20,
    Rounding = 0,
    Compact  = false,
})

ESPBox:AddLabel('Box Colors'):AddColorPicker('ESPBoxColor', {
    Default = Color3.fromRGB(255, 100, 200),
    Title   = 'Box Color',
})

ESPBox:AddLabel('Fill Gradient'):AddColorPicker('ESPFillColor1', {
    Default = Color3.fromRGB(180, 0, 255),
    Title   = 'Color 1',
}):AddColorPicker('ESPFillColor2', {
    Default = Color3.fromRGB(255, 0, 150),
    Title   = 'Color 2',
}):AddColorPicker('ESPFillColor3', {
    Default = Color3.fromRGB(0, 100, 255),
    Title   = 'Color 3',
})

ESPBox:AddToggle('ESPFilled', {
    Text    = 'Gradient Fill',
    Default = true,
})

ESPBox:AddSlider('ESPFillTransparency', {
    Text     = 'Fill Transparency',
    Default  = 0.7,
    Min      = 0,
    Max      = 1,
    Rounding = 2,
    Compact  = false,
})

ESPBox:AddToggle('ESPFillRotate', {
    Text    = 'Rotating Fill',
    Default = true,
    Tooltip = 'Spin the gradient inside the box',
})

ESPBox:AddDropdown('ESPFillRotateDir', {
    Values  = { 'Clockwise', 'Counter-Clockwise' },
    Default = 1,
    Multi   = false,
    Text    = 'Direction',
})

ESPBox:AddSlider('ESPFillRotateSpeed', {
    Text     = 'Rotation Speed',
    Default  = 1,
    Min      = 0.1,
    Max      = 5,
    Rounding = 1,
    Compact  = false,
})

ESPBox:AddLabel('Box Gradient'):AddColorPicker('ESPBoxColor1', {
    Default = Color3.fromRGB(255, 0, 100),
    Title   = 'Color 1',
}):AddColorPicker('ESPBoxColor2', {
    Default = Color3.fromRGB(255, 100, 0),
    Title   = 'Color 2',
}):AddColorPicker('ESPBoxColor3', {
    Default = Color3.fromRGB(100, 0, 255),
    Title   = 'Color 3',
})

ESPBox:AddToggle('ESPBoxGradient', {
    Text    = 'Gradient Box',
    Default = true,
    Tooltip = 'Gradient flows around all 4 sides',
})

ESPBox:AddDivider()

ESPBox:AddToggle('ESPHealthBar', {
    Text    = 'Health Bar',
    Default = true,
})

ESPBox:AddDropdown('ESPHealthBarSide', {
    Values  = { 'Left', 'Right', 'Top', 'Bottom' },
    Default = 1,
    Multi   = false,
    Text    = 'Health Bar Position',
})

ESPBox:AddLabel('Health Colors'):AddColorPicker('ESPHealthColorHigh', {
    Default = Color3.fromRGB(0, 220, 0),
    Title   = 'High Health',
}):AddColorPicker('ESPHealthColorMid', {
    Default = Color3.fromRGB(220, 180, 0),
    Title   = 'Mid Health',
}):AddColorPicker('ESPHealthColorLow', {
    Default = Color3.fromRGB(220, 0, 0),
    Title   = 'Low Health',
})

ESPBox:AddLabel('Health BG'):AddColorPicker('ESPHealthBGColor', {
    Default = Color3.fromRGB(20, 20, 20),
    Title   = 'Health Background',
})

ESPBox:AddLabel('Text Color'):AddColorPicker('ESPTextColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'Text Color',
})

ESPBox:AddDivider()

ESPBox:AddToggle('ESPNames', {
    Text    = 'Names',
    Default = true,
})

ESPBox:AddToggle('ESPDistance', {
    Text    = 'Distance',
    Default = true,
})

ESPBox:AddSlider('ESPMaxDistance', {
    Text     = 'Max Distance',
    Default  = 500,
    Min      = 100,
    Max      = 2000,
    Rounding = 0,
    Compact  = false,
})

-- ─────────────────────────────────────────────────────────────
-- BULLET TRACERS (Moved from Misc to Visuals)
-- ─────────────────────────────────────────────────────────────

local TracerBox = Tabs.Visuals:AddLeftGroupbox('Bullet Tracers')

TracerBox:AddToggle('BulletTracersEnabled', {
    Text    = 'Enabled',
    Default = false,
    Tooltip = 'Show visual tracers for your bullets',
})

TracerBox:AddDropdown('TracerMode', {
    Values  = { 'Line', 'Beam', 'Gradient' },
    Default = 1,
    Multi   = false,
    Text    = 'Tracer Mode',
})

TracerBox:AddLabel('Colors'):AddColorPicker('TracerStartColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'Start Color',
}):AddColorPicker('TracerEndColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'End Color',
})

TracerBox:AddSlider('TracerThickness', {
    Text     = 'Thickness',
    Default  = 1,
    Min      = 0.1,
    Max      = 5,
    Rounding = 1,
    Compact  = false,
})

TracerBox:AddSlider('TracerLifetime', {
    Text     = 'Lifetime (s)',
    Default  = 0.5,
    Min      = 0.1,
    Max      = 3,
    Rounding = 1,
    Compact  = false,
})

-- ─────────────────────────────────────────────────────────────
-- SELF VISUALS
-- ─────────────────────────────────────────────────────────────

local SelfVisualsBox = Tabs.Visuals:AddRightGroupbox('Self Visuals')

SelfVisualsBox:AddToggle('ToolChangerEnabled', {
    Text    = 'Tool Changer',
    Default = false,
    Tooltip = 'Change your tool material and color',
})

SelfVisualsBox:AddDropdown('ToolMaterial', {
    Values  = { 'Neon', 'ForceField', 'Glass', 'Plastic', 'Metal', 'Wood' },
    Default = 1,
    Multi   = false,
    Text    = 'Tool Material',
})

SelfVisualsBox:AddLabel('Tool Color'):AddColorPicker('ToolColor', {
    Default = Color3.fromRGB(255, 0, 255),
    Title   = 'Tool Color',
})

SelfVisualsBox:AddDivider()

SelfVisualsBox:AddToggle('CharacterChangerEnabled', {
    Text    = 'Character Changer',
    Default = false,
    Tooltip = 'Change your character material and color',
})

SelfVisualsBox:AddDropdown('CharacterMaterial', {
    Values  = { 'Neon', 'ForceField', 'Glass', 'Plastic', 'Metal', 'Wood' },
    Default = 1,
    Multi   = false,
    Text    = 'Character Material',
})

SelfVisualsBox:AddLabel('Character Color'):AddColorPicker('CharacterColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'Character Color',
})

SelfVisualsBox:AddDivider()

SelfVisualsBox:AddToggle('SelfAuraEnabled', {
    Text    = 'Self Aura',
    Default = false,
    Tooltip = 'Show aura around your character',
})

SelfVisualsBox:AddDropdown('AuraStyle', {
    Values  = { 'Starlight', 'Heavenly', 'Ribbon', 'Sakura', 'Angel', 'Wind', 'Flow', 'Star' },
    Default = 1,
    Multi   = false,
    Text    = 'Aura Style',
})

SelfVisualsBox:AddLabel('Aura Color'):AddColorPicker('SelfAuraColor', {
    Default = Color3.fromRGB(133, 220, 255),
    Title   = 'Aura Color',
})

SelfVisualsBox:AddDivider()

SelfVisualsBox:AddToggle('JumpCircleEnabled', {
    Text    = 'Jump Circle',
    Default = false,
    Tooltip = 'Show a circle when you jump that fades out',
})

SelfVisualsBox:AddLabel('Jump Circle Color'):AddColorPicker('JumpCircleColor', {
    Default = Color3.fromRGB(0, 255, 255),
    Title   = 'Jump Circle Color',
})

local OtherVisualsBox = Tabs.Visuals:AddRightGroupbox('Other')

OtherVisualsBox:AddToggle('TargetTracerEnabled', {
    Text    = 'Target Tracer',
    Default = false,
    Tooltip = 'Draw a line from the locked target to your cursor',
})

OtherVisualsBox:AddLabel('Tracer Colors'):AddColorPicker('TracerMainColor', {
    Default = Color3.fromRGB(255, 50, 50),
    Title   = 'Main Color',
}):AddColorPicker('TracerOutlineColor', {
    Default = Color3.fromRGB(0, 0, 0),
    Title   = 'Outline Color',
})

OtherVisualsBox:AddDivider()

OtherVisualsBox:AddToggle('SpectateTarget', {
    Text    = 'Spectate Target',
    Default = false,
}):AddKeyPicker('SpectateKeybind', {
    Default          = 'None',
    SyncToggleState  = true,
    Mode             = 'Toggle',
    Text             = 'Spectate Keybind',
    NoUI             = false,
})

OtherVisualsBox:AddDivider()

OtherVisualsBox:AddToggle('CrosshairEnabled', {
    Text    = 'Custom Crosshair',
    Default = false,
    Tooltip = 'Draw custom crosshair',
})

OtherVisualsBox:AddLabel('Crosshair Colors'):AddColorPicker('CrosshairMainColor', {
    Default = Color3.fromRGB(0, 255, 0),
    Title   = 'Main Color',
}):AddColorPicker('CrosshairOutlineColor', {
    Default = Color3.fromRGB(0, 0, 0),
    Title   = 'Outline Color',
})

OtherVisualsBox:AddSlider('CrosshairLength', {
    Text     = 'Length',
    Default  = 10,
    Min      = 5,
    Max      = 30,
    Rounding = 0,
    Compact  = true,
})

OtherVisualsBox:AddSlider('CrosshairSpacing', {
    Text     = 'Spacing',
    Default  = 5,
    Min      = 0,
    Max      = 20,
    Rounding = 0,
    Compact  = true,
})

OtherVisualsBox:AddSlider('CrosshairWidth', {
    Text     = 'Width',
    Default  = 2,
    Min      = 1,
    Max      = 5,
    Rounding = 0,
    Compact  = true,
})

OtherVisualsBox:AddToggle('CrosshairSpinning', {
    Text    = 'Spinning',
    Default = false,
})

OtherVisualsBox:AddToggle('CrosshairPulsing', {
    Text    = 'Pulsing',
    Default = false,
})

OtherVisualsBox:AddSlider('CrosshairSpinSpeed', {
    Text     = 'Spin Speed',
    Default  = 3,
    Min      = 1,
    Max      = 10,
    Rounding = 1,
    Compact  = true,
})

OtherVisualsBox:AddSlider('CrosshairPulseSpeed', {
    Text     = 'Pulse Speed',
    Default  = 2,
    Min      = 1,
    Max      = 10,
    Rounding = 1,
    Compact  = true,
})

OtherVisualsBox:AddToggle('CrosshairOnTarget', {
    Text    = 'Position on Target',
    Default = false,
    Tooltip = 'Follow locked target instead of screen center',
})

-- ─────────────────────────────────────────────────────────────
-- WORLD SECTION
-- ─────────────────────────────────────────────────────────────

local WorldBox = Tabs.Visuals:AddRightGroupbox('World')

WorldBox:AddToggle('FogEnabled', {
    Text    = 'Custom Fog',
    Default = false,
    Tooltip = 'Customize world fog',
})

WorldBox:AddSlider('FogStart', {
    Text     = 'Fog Start',
    Default  = 0,
    Min      = 0,
    Max      = 500,
    Rounding = 0,
    Compact  = false,
})

WorldBox:AddSlider('FogEnd', {
    Text     = 'Fog End',
    Default  = 1000,
    Min      = 100,
    Max      = 10000,
    Rounding = 0,
    Compact  = false,
})

WorldBox:AddLabel('Fog Color'):AddColorPicker('FogColor', {
    Default = Color3.fromRGB(192, 192, 192),
    Title   = 'Fog Color',
})

WorldBox:AddDivider()

WorldBox:AddToggle('AmbientEnabled', {
    Text    = 'Custom Ambient',
    Default = false,
    Tooltip = 'Change ambient lighting',
})

WorldBox:AddLabel('Ambient Color'):AddColorPicker('AmbientColor', {
    Default = Color3.fromRGB(128, 128, 128),
    Title   = 'Ambient Color',
})

WorldBox:AddDivider()

WorldBox:AddToggle('BrightnessEnabled', {
    Text    = 'Custom Brightness',
    Default = false,
})

WorldBox:AddSlider('Brightness', {
    Text     = 'Brightness',
    Default  = 1,
    Min      = 0,
    Max      = 5,
    Rounding = 1,
    Compact  = false,
})

WorldBox:AddDivider()

WorldBox:AddToggle('ClockTimeEnabled', {
    Text    = 'Clock Time',
    Default = false,
})

WorldBox:AddSlider('ClockTime', {
    Text     = 'Time',
    Default  = 14,
    Min      = 0,
    Max      = 24,
    Rounding = 0,
    Compact  = false,
    Tooltip  = '0 = Midnight, 12 = Noon, 24 = Midnight',
})

WorldBox:AddDivider()

WorldBox:AddToggle('ExposureEnabled', {
    Text    = 'Exposure',
    Default = false,
})

WorldBox:AddSlider('Exposure', {
    Text     = 'Exposure',
    Default  = 0,
    Min      = -3,
    Max      = 3,
    Rounding = 1,
    Compact  = false,
})

WorldBox:AddDivider()

WorldBox:AddToggle('RainEnabled', {
    Text    = 'Rain',
    Default = false,
})

WorldBox:AddLabel('Rain Color'):AddColorPicker('RainColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'Rain Color',
})

WorldBox:AddSlider('RainRate', {
    Text     = 'Rate',
    Default  = 60,
    Min      = 10,
    Max      = 100,
    Rounding = 0,
    Compact  = true,
})

-- ─────────────────────────────────────────────────────────────
-- MISC TAB
-- ─────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────
-- RAGE TAB (Combat features)
-- ─────────────────────────────────────────────────────────────

local RageCombatBox = Tabs.Rage:AddLeftGroupbox('Combat')

RageCombatBox:AddToggle('AntiStompEnabled', {
    Text    = 'Anti Stomp',
    Default = false,
    Tooltip = 'Reset character when health drops to 10 or below',
})

RageCombatBox:AddToggle('AntiStompReturnToPosition', {
    Text    = 'Return to Death Position',
    Default = false,
    Tooltip = 'Teleport back to where you died after respawning',
})

RageCombatBox:AddDivider()

RageCombatBox:AddToggle('Wallbang', {
    Text    = 'Wallbang',
    Default = false,
    Tooltip = 'Shoot through walls',
})

RageCombatBox:AddDivider()

RageCombatBox:AddToggle('NoSlowEnabled', {
    Text    = 'No Slow',
    Default = false,
    Tooltip = 'Remove movement slowdown when shooting',
})

RageCombatBox:AddDivider()

RageCombatBox:AddToggle('InfiniteJumpEnabled', {
    Text    = 'Infinite Jump',
    Default = false,
    Tooltip = 'Jump infinitely in the air',
})

RageCombatBox:AddDivider()

RageCombatBox:AddToggle('CSyncEnabled', {
    Text    = 'C-Sync',
    Default = false,
    Tooltip = 'Desync your position around the target',
}):AddKeyPicker('CSyncKeybind', {
    Default         = 'None',
    SyncToggleState = true,
    Mode            = 'Toggle',
    Text            = 'C-Sync Keybind',
    NoUI            = false,
})

RageCombatBox:AddToggle('CSyncSticky', {
    Text    = 'Sticky',
    Default = false,
    Tooltip = 'Lock onto whoever is closest when you activate — stays on them until you turn off',
})

RageCombatBox:AddSlider('CSyncRange', {
    Text     = 'Range',
    Default  = 10,
    Min      = 1,
    Max      = 30,
    Rounding = 0,
    Compact  = false,
    Tooltip  = 'Random teleport range around target',
})

RageCombatBox:AddToggle('CSyncIndicator', {
    Text    = 'Show Indicator',
    Default = true,
    Tooltip = 'Show 2D indicator at desync position',
})

RageCombatBox:AddToggle('CSyncIndicatorAlwaysShow', {
    Text    = 'Show Always',
    Default = false,
    Tooltip = 'Show indicator even when C-Sync is off, tracks closest player to cursor',
})

RageCombatBox:AddLabel('Indicator Colors'):AddColorPicker('CSyncIndicatorFrameColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'Frame Color',
}):AddColorPicker('CSyncIndicatorCenterColor', {
    Default = Color3.fromRGB(255, 50, 50),
    Title   = 'Center Color',
})

RageCombatBox:AddSlider('OrbitSpeed', {
    Text     = 'Orbit Speed',
    Default  = 5,
    Min      = 0.5,
    Max      = 20,
    Rounding = 1,
    Compact  = false,
})

-- Movement Section
local RageMovementBox = Tabs.Rage:AddLeftGroupbox('Movement')

RageMovementBox:AddToggle('WalkspeedEnabled', {
    Text    = 'Walkspeed',
    Default = false,
}):AddKeyPicker('WalkspeedKeybind', {
    Default          = 'None',
    SyncToggleState  = true,
    Mode             = 'Toggle',
    Text             = 'Walkspeed Keybind',
    NoUI             = false,
})

RageMovementBox:AddSlider('WalkspeedValue', {
    Text     = 'Speed',
    Default  = 50,
    Min      = 16,
    Max      = 500,
    Rounding = 0,
    Compact  = false,
})

RageMovementBox:AddDivider()

RageMovementBox:AddToggle('JumpPowerEnabled', {
    Text    = 'Jump Power',
    Default = false,
}):AddKeyPicker('JumpPowerKeybind', {
    Default          = 'None',
    SyncToggleState  = true,
    Mode             = 'Toggle',
    Text             = 'Jump Power Keybind',
    NoUI             = false,
})

RageMovementBox:AddSlider('JumpPowerValue', {
    Text     = 'Power',
    Default  = 50,
    Min      = 50,
    Max      = 500,
    Rounding = 0,
    Compact  = false,
})

RageMovementBox:AddDivider()

RageMovementBox:AddToggle('FlyEnabled', {
    Text    = 'Fly',
    Default = false,
}):AddKeyPicker('FlyKeybind', {
    Default          = 'None',
    SyncToggleState  = true,
    Mode             = 'Toggle',
    Text             = 'Fly Keybind',
    NoUI             = false,
})

RageMovementBox:AddSlider('FlySpeed', {
    Text     = 'Fly Speed',
    Default  = 50,
    Min      = 10,
    Max      = 500,
    Rounding = 0,
    Compact  = false,
})

-- Void Teleport on RIGHT side
local RageVoidBox = Tabs.Rage:AddRightGroupbox('Void Teleport')

RageVoidBox:AddToggle('VoidEnabled', {
    Text    = 'Enabled',
    Default = false,
}):AddKeyPicker('VoidKeybind', {
    Default          = 'None',
    SyncToggleState  = false,
    Mode             = 'Toggle',
    Text             = 'Void Keybind',
    NoUI             = false,
})

RageVoidBox:AddDropdown('VoidMode', {
    Values  = { 'Normal', 'Spam', 'Random' },
    Default = 1,
    Multi   = false,
    Text    = 'Void Mode',
    Tooltip = 'Normal: Toggle in/out | Spam: Rapid teleport | Random: Random movement in void',
})

RageVoidBox:AddSlider('VoidDistance', {
    Text     = 'Void Distance',
    Default  = 500000,
    Min      = 10000,
    Max      = 9999999999999999999,
    Rounding = 0,
    Compact  = false,
})

RageVoidBox:AddSlider('VoidSpamDelay', {
    Text     = 'Spam Delay (ms)',
    Default  = 100,
    Min      = 10,
    Max      = 1000,
    Rounding = 0,
    Compact  = false,
    Tooltip  = 'Delay between teleports in Spam mode',
})

RageVoidBox:AddSlider('VoidRandomX', {
    Text     = 'Random X Range',
    Default  = 100,
    Min      = 10,
    Max      = 1000,
    Rounding = 0,
    Compact  = false,
    Tooltip  = 'Random movement range on X axis',
})

RageVoidBox:AddSlider('VoidRandomY', {
    Text     = 'Random Y Range',
    Default  = 100,
    Min      = 10,
    Max      = 1000,
    Rounding = 0,
    Compact  = false,
    Tooltip  = 'Random movement range on Y axis',
})

RageVoidBox:AddSlider('VoidRandomZ', {
    Text     = 'Random Z Range',
    Default  = 100,
    Min      = 10,
    Max      = 1000,
    Rounding = 0,
    Compact  = false,
    Tooltip  = 'Random movement range on Z axis',
})

-- ─────────────────────────────────────────────────────────────
-- NETWORK HACK SECTION (Rage right side)
-- ─────────────────────────────────────────────────────────────

local NetworkHackBox = Tabs.Rage:AddRightGroupbox('Network Hack')

NetworkHackBox:AddToggle('NetworkHackEnabled', {
    Text    = 'Network Hack',
    Default = false,
    Tooltip = 'Teleport closest player to cursor in front of you',
}):AddKeyPicker('NetworkHackKeybind', {
    Default         = 'None',
    SyncToggleState = true,
    Mode            = 'Toggle',
    Text            = 'Network Hack Keybind',
    NoUI            = false,
})

-- ─────────────────────────────────────────────────────────────
-- MISC TAB (Utility features)
-- ─────────────────────────────────────────────────────────────

local PlayersBox = Tabs.Misc:AddLeftGroupbox('Players')

PlayersBox:AddDropdown('MiscPlayerSelect', {
    Values  = {"Loading..."},
    Default = 1,
    Multi   = false,
    Text    = 'Select Player',
})

PlayersBox:AddToggle('MiscSpectatePlayer', {
    Text    = 'Spectate Player',
    Default = false,
    Tooltip = 'Automatically spectate selected player',
})

PlayersBox:AddButton('Teleport to Player', function()
    local selectedName = Options.MiscPlayerSelect.Value
    
    if not selectedName or selectedName == "No players available" or selectedName == "Loading..." then
        Library:Notify('Select a player first', 2)
        return
    end
    
    local targetPlayer = game.Players:FindFirstChild(selectedName)
    if not targetPlayer then
        Library:Notify('Player not found', 2)
        return
    end
    
    local myHRP = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild('HumanoidRootPart')
    
    if myHRP and targetHRP then
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
        Library:Notify('Teleported to ' .. selectedName, 2)
    else
        Library:Notify('Cannot teleport - character not found', 2)
    end
end)

local MiscBox = Tabs.Misc:AddLeftGroupbox('Misc')

MiscBox:AddToggle('AutoReload', {
    Text    = 'Auto Reload',
    Default = false,
    Tooltip = 'Automatically reload when out of ammo',
})

MiscBox:AddDivider()

MiscBox:AddToggle('AutoMaskEnabled', {
    Text    = 'Auto Mask',
    Default = false,
    Tooltip = 'Automatically buy and equip Surgeon Mask',
})

MiscBox:AddDivider()

MiscBox:AddToggle('AutoArmorEnabled', {
    Text    = 'Auto Armor',
    Default = false,
    Tooltip = 'Automatically buy armor when below 70',
})

MiscBox:AddDivider()

MiscBox:AddToggle('SpinbotEnabled', {
    Text    = 'Spinbot',
    Default = false,
    Tooltip = 'Spin your character continuously',
}):AddKeyPicker('SpinbotKeybind', {
    Default         = 'None',
    SyncToggleState = true,
    Mode            = 'Toggle',
    Text            = 'Spinbot Keybind',
    NoUI            = false,
})

MiscBox:AddSlider('SpinbotSpeed', {
    Text     = 'Speed',
    Default  = 10,
    Min      = 1,
    Max      = 50,
    Rounding = 0,
    Compact  = true,
})

MiscBox:AddDivider()

MiscBox:AddToggle('JitterEnabled', {
    Text    = 'Jitter',
    Default = false,
    Tooltip = 'Randomly jitter your character position',
}):AddKeyPicker('JitterKeybind', {
    Default         = 'None',
    SyncToggleState = true,
    Mode            = 'Toggle',
    Text            = 'Jitter Keybind',
    NoUI            = false,
})

MiscBox:AddSlider('JitterX', {
    Text     = 'Jitter X',
    Default  = 5,
    Min      = 0,
    Max      = 20,
    Rounding = 1,
    Compact  = true,
})

MiscBox:AddSlider('JitterY', {
    Text     = 'Jitter Y',
    Default  = 5,
    Min      = 0,
    Max      = 20,
    Rounding = 1,
    Compact  = true,
})

MiscBox:AddSlider('JitterZ', {
    Text     = 'Jitter Z',
    Default  = 5,
    Min      = 0,
    Max      = 20,
    Rounding = 1,
    Compact  = true,
})

MiscBox:AddDivider()

MiscBox:AddToggle('NoVoidKillEnabled', {
    Text    = 'No Void Kill',
    Default = false,
    Tooltip = 'Disables void death',
})

MiscBox:AddDivider()

MiscBox:AddToggle('TargetRingEnabled', {
    Text    = 'Target Ring',
    Default = false,
    Tooltip = 'Show ring on locked target',
})

MiscBox:AddLabel('Ring Colors'):AddColorPicker('TargetRingColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title   = 'Ring Color',
}):AddColorPicker('TargetRingOutlineColor', {
    Default = Color3.fromRGB(0, 0, 0),
    Title   = 'Outline Color',
})

MiscBox:AddToggle('TargetRingScan', {
    Text    = 'Scanning Animation',
    Default = true,
    Tooltip = 'Ring scans up and down',
})

local TargetInfoBox = Tabs.Misc:AddRightGroupbox('Target Info')

TargetInfoBox:AddToggle('TargetInfoEnabled', {
    Text    = 'Show Target Info',
    Default = false,
    Tooltip = 'Show draggable target info panel on screen',
})

TargetInfoBox:AddDivider()
TargetInfoBox:AddLabel('Health Colors'):AddColorPicker('TIHealthColorHigh', {
    Default = Color3.fromRGB(0, 210, 0),
    Title   = 'High Health',
}):AddColorPicker('TIHealthColorMid', {
    Default = Color3.fromRGB(210, 180, 0),
    Title   = 'Mid Health',
}):AddColorPicker('TIHealthColorLow', {
    Default = Color3.fromRGB(210, 0, 0),
    Title   = 'Low Health',
})

local SoundsBox = Tabs.Misc:AddRightGroupbox('Sounds')

SoundsBox:AddToggle('HitOverlayEnabled', {
    Text    = 'Hit Overlay',
    Default = false,
    Tooltip = 'Flash screen edges when hitting target',
})

SoundsBox:AddLabel('Overlay Color'):AddColorPicker('HitOverlayColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title   = 'Hit Overlay Color',
})

SoundsBox:AddSlider('HitOverlayDuration', {
    Text     = 'Duration (ms)',
    Default  = 300,
    Min      = 100,
    Max      = 1000,
    Rounding = 0,
    Compact  = false,
})

SoundsBox:AddDivider()

SoundsBox:AddToggle('HitSoundsEnabled', {
    Text    = 'Hit Sounds',
    Default = false,
    Tooltip = 'Play sound when locked target takes damage',
})

SoundsBox:AddDropdown('HitSound', {
    Values  = {
        "Rust Headshot", "Neverlose", "Bubble", "Laser", "Steve", "Call of Duty", "Bat",
        "TF2 Critical", "Saber", "Bameware", "Money", "Notif", "Shutter", "RIFK7",
        "LazerBeam", "WindowsXPError", "TF2Hitsound", "TF2Bat", "BowHit", "Bow",
        "OSU", "OneNN", "Rust", "TF2Pan", "Mario", "Bell", "Pick", "Pop", "Sans",
        "Fart", "Big", "Vine", "Bruh", "Skeet", "Fatality", "Bonk", "Minecraft",
        "Gamesense", "Bamboo", "Crowbar", "Weeb", "Beep", "Bambi", "Stone",
        "Old Fatality", "Click", "Ding", "Snow", "Osu", "TF2", "Slime", "Among Us",
        "One", "BulletDeflect", "Default", "UwU", "Cod", "Blood SFX", "Blood Burst", "Blood Hit"
    },
    Default = 1,
    Multi   = false,
    Text    = 'Hit Sound',
})

SoundsBox:AddSlider('HitSoundVolume', {
    Text     = 'Volume',
    Default  = 0.5,
    Min      = 0,
    Max      = 20,
    Rounding = 2,
    Compact  = false,
})

SoundsBox:AddDivider()

SoundsBox:AddToggle('HitNotificationsEnabled', {
    Text    = 'Hit Notifications',
    Default = false,
    Tooltip = 'Show damage notifications when hitting targets',
})

SoundsBox:AddSlider('HitNotifDuration', {
    Text     = 'Duration (s)',
    Default  = 3,
    Min      = 1,
    Max      = 10,
    Rounding = 1,
    Compact  = true,
})

SoundsBox:AddDivider()

SoundsBox:AddToggle('DamageNumbersEnabled', {
    Text    = 'Damage Numbers',
    Default = false,
    Tooltip = 'Show floating damage numbers above enemies',
})

SoundsBox:AddLabel('Damage Number Colors'):AddColorPicker('DamageNumberColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title   = 'Number Color',
}):AddColorPicker('DamageNumberOutline', {
    Default = Color3.fromRGB(0, 0, 0),
    Title   = 'Outline Color',
})

SoundsBox:AddSlider('DamageNumberSize', {
    Text     = 'Size',
    Default  = 20,
    Min      = 10,
    Max      = 50,
    Rounding = 0,
    Compact  = true,
})

-- ─────────────────────────────────────────────────────────────
-- EMOTES
-- ─────────────────────────────────────────────────────────────

local EmoteBox = Tabs.Misc:AddLeftGroupbox('Emotes')

local EmoteAnims = {
    kickinglegs     = 120370790028350,
    heyyamove       = 119734573196374,
    animeah         = 78982325370329,
    spongebobdance  = 18443245017,
    crossed         = 128386160365167,
    invisibleme     = 126995783634131,
    imagination     = 18443237526,
    yungblud        = 15609995579,
    strangerthings  = 70692992882447,
    laugh           = 3337966527,
    floss           = 5917459365,
    sleep           = 4686925579,
    hype            = 3695333486,
    sad             = 4841407203,
    goofyhands      = 14496531574,
    tornado         = 135373056067761,
    jabbaswitchway  = 77791964179635,
}

local EmoteList = {
    "kickinglegs","heyyamove","animeah","spongebobdance","crossed",
    "invisibleme","imagination","yungblud","strangerthings","laugh",
    "floss","sleep","hype","sad","goofyhands","tornado","jabbaswitchway"
}

EmoteBox:AddToggle('EmotesEnabled', {
    Text    = 'Emotes',
    Default = false,
    Tooltip = 'Play a looping emote animation',
}):AddKeyPicker('EmoteKeybind', {
    Default         = 'None',
    SyncToggleState = true,
    Mode            = 'Toggle',
    Text            = 'Emote Keybind',
    NoUI            = false,
})

EmoteBox:AddDropdown('EmoteSelected', {
    Values  = EmoteList,
    Default = 1,
    Multi   = false,
    Text    = 'Selected Emote',
})

EmoteBox:AddSlider('EmoteSpeed', {
    Text     = 'Emote Speed',
    Default  = 10,
    Min      = 1,
    Max      = 100,
    Rounding = 0,
    Compact  = false,
    Tooltip  = 'Animation playback speed (10 = normal)',
})

-- ─────────────────────────────────────────────────────────────
-- SERVICES & LOCALS
-- ─────────────────────────────────────────────────────────────

local Players          = game:GetService('Players')
local RunService       = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local SoundService     = game:GetService('SoundService')

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ─────────────────────────────────────────────────────────────
-- TARGET STATS UI
-- ─────────────────────────────────────────────────────────────

local StatsScreenGui = Instance.new('ScreenGui')
StatsScreenGui.Name = 'TargetStatsGUI'
StatsScreenGui.ResetOnSpawn = false
StatsScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
StatsScreenGui.Parent = PlayerGui

local StatsFrame = Instance.new('Frame')
StatsFrame.Name = 'StatsFrame'
StatsFrame.Size = UDim2.new(0, 200, 0, 80)
StatsFrame.Position = UDim2.new(0.5, -100, 1, -120)
StatsFrame.AnchorPoint = Vector2.new(0.5, 0)
StatsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatsFrame.BackgroundTransparency = 0.3
StatsFrame.BorderSizePixel = 0
StatsFrame.Visible = false
StatsFrame.Parent = StatsScreenGui

local StatsCorner = Instance.new('UICorner')
StatsCorner.CornerRadius = UDim.new(0, 8)
StatsCorner.Parent = StatsFrame

local TargetLabel = Instance.new('TextLabel')
TargetLabel.Name = 'TargetLabel'
TargetLabel.Size = UDim2.new(1, 0, 0, 25)
TargetLabel.Position = UDim2.new(0, 0, 0, 5)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = 'Target: None'
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.TextSize = 14
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.Parent = StatsFrame

local HealthLabel = Instance.new('TextLabel')
HealthLabel.Name = 'HealthLabel'
HealthLabel.Size = UDim2.new(1, 0, 0, 20)
HealthLabel.Position = UDim2.new(0, 0, 0, 30)
HealthLabel.BackgroundTransparency = 1
HealthLabel.Text = 'Health: 0/0'
HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
HealthLabel.TextSize = 12
HealthLabel.Font = Enum.Font.Gotham
HealthLabel.Parent = StatsFrame

local ArmorLabel = Instance.new('TextLabel')
ArmorLabel.Name = 'ArmorLabel'
ArmorLabel.Size = UDim2.new(1, 0, 0, 20)
ArmorLabel.Position = UDim2.new(0, 0, 0, 50)
ArmorLabel.BackgroundTransparency = 1
ArmorLabel.Text = 'Armor: 0'
ArmorLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
ArmorLabel.TextSize = 12
ArmorLabel.Font = Enum.Font.Gotham
ArmorLabel.Parent = StatsFrame

-- ─────────────────────────────────────────────────────────────
-- HIT NOTIFICATIONS SYSTEM
-- Shows stacking notifications when hitting targets
-- Format: "Inflicted [player] for [damage] in [part]"
-- ─────────────────────────────────────────────────────────────

local HitNotifScreenGui = Instance.new('ScreenGui')
HitNotifScreenGui.Name = 'HitNotificationsGUI'
HitNotifScreenGui.ResetOnSpawn = false
HitNotifScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HitNotifScreenGui.Parent = game:GetService('CoreGui')

local ActiveNotifications = {}

local function CreateHitNotification(playerName, damage, partName)
    if not Toggles.HitNotificationsEnabled or not Toggles.HitNotificationsEnabled.Value then return end
    
    local accentColor = Library.AccentColor or Color3.fromRGB(0, 85, 255)
    local duration = Options.HitNotifDuration and Options.HitNotifDuration.Value or 3
    
    -- Create notification frame
    local notifFrame = Instance.new('Frame')
    notifFrame.Size = UDim2.new(0, 400, 0, 30)
    notifFrame.BackgroundTransparency = 1
    notifFrame.Parent = HitNotifScreenGui
    
    -- Main text with outline
    local mainText = Instance.new('TextLabel')
    mainText.Size = UDim2.new(1, 0, 1, 0)
    mainText.BackgroundTransparency = 1
    mainText.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainText.TextSize = 16
    mainText.Font = Enum.Font.Arial
    mainText.TextXAlignment = Enum.TextXAlignment.Center
    mainText.RichText = true
    -- Thick black outline
    mainText.TextStrokeTransparency = 0
    mainText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    mainText.Parent = notifFrame
    
    -- Build rich text with accent color highlights
    local accentHex = string.format("#%02X%02X%02X", 
        math.floor(accentColor.R * 255),
        math.floor(accentColor.G * 255),
        math.floor(accentColor.B * 255)
    )
    
    local richText = string.format(
        'Inflicted <font color="%s">%s</font> for <font color="%s">%d</font> in <font color="%s">%s</font>',
        accentHex, playerName,
        accentHex, damage,
        accentHex, partName
    )
    
    mainText.Text = richText
    
    -- Position in stack (middle-lower of screen)
    local screenHeight = Camera.ViewportSize.Y
    local startY = screenHeight * 0.65 -- Start at 65% down the screen
    local stackIndex = #ActiveNotifications
    
    notifFrame.Position = UDim2.new(0.5, -200, 0, startY + (stackIndex * 35))
    
    -- Add to active notifications
    table.insert(ActiveNotifications, {
        frame = notifFrame,
        createdTime = tick(),
        duration = duration
    })
    
    -- Fade in
    mainText.TextTransparency = 1
    game:GetService('TweenService'):Create(mainText, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
end

-- Update and cleanup notifications every frame
task.spawn(function()
    while task.wait() do
        local currentTime = tick()
        local toRemove = {}
        
        for i, notif in ipairs(ActiveNotifications) do
            local elapsed = currentTime - notif.createdTime
            
            if elapsed >= notif.duration then
                -- Fade out
                local mainText = notif.frame:FindFirstChildOfClass('TextLabel')
                if mainText then
                    game:GetService('TweenService'):Create(mainText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
                end
                task.wait(0.3)
                notif.frame:Destroy()
                table.insert(toRemove, i)
            end
        end
        
        -- Remove destroyed notifications
        for i = #toRemove, 1, -1 do
            table.remove(ActiveNotifications, toRemove[i])
        end
        
        -- Reposition stack
        local screenHeight = Camera.ViewportSize.Y
        local startY = screenHeight * 0.65
        for i, notif in ipairs(ActiveNotifications) do
            notif.frame:TweenPosition(
                UDim2.new(0.5, -200, 0, startY + ((i - 1) * 35)),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.2,
                true
            )
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- DAMAGE NUMBERS SYSTEM
-- Shows floating damage text above enemies when you hit them
-- ─────────────────────────────────────────────────────────────

local DamageNumbersScreenGui = Instance.new('ScreenGui')
DamageNumbersScreenGui.Name = 'DamageNumbersGUI'
DamageNumbersScreenGui.ResetOnSpawn = false
DamageNumbersScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
DamageNumbersScreenGui.Parent = game:GetService('CoreGui')

local ActiveDamageNumbers = {}

local function CreateDamageNumber(character, damage)
    if not Toggles.DamageNumbersEnabled or not Toggles.DamageNumbersEnabled.Value then return end
    if not character or not character:FindFirstChild('Head') then return end
    
    local head = character:FindFirstChild('Head')
    local mainColor = Options.DamageNumberColor and Options.DamageNumberColor.Value or Color3.fromRGB(255, 255, 255)
    local outlineColor = Options.DamageNumberOutline and Options.DamageNumberOutline.Value or Color3.fromRGB(0, 0, 0)
    local textSize = Options.DamageNumberSize and Options.DamageNumberSize.Value or 20
    
    -- Create BillboardGui attached to head
    local billboard = Instance.new('BillboardGui')
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.Parent = DamageNumbersScreenGui
    
    -- Damage text
    local damageText = Instance.new('TextLabel')
    damageText.Size = UDim2.new(1, 0, 1, 0)
    damageText.BackgroundTransparency = 1
    damageText.Text = tostring(damage)
    damageText.TextColor3 = mainColor
    damageText.TextSize = textSize
    damageText.Font = Enum.Font.Arial
    damageText.TextStrokeTransparency = 0
    damageText.TextStrokeColor3 = outlineColor
    damageText.Parent = billboard
    
    -- Store for cleanup
    table.insert(ActiveDamageNumbers, {
        billboard = billboard,
        createdTime = tick(),
        startOffset = Vector3.new(0, 2, 0)
    })
    
    -- Animate upward and fade out
    local TweenService = game:GetService('TweenService')
    local duration = 1.5
    
    -- Float upward
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local alpha = elapsed / duration
            billboard.StudsOffset = Vector3.new(0, 2 + (alpha * 3), 0)
            damageText.TextTransparency = alpha
            damageText.TextStrokeTransparency = alpha
            task.wait()
        end
        billboard:Destroy()
    end)
end

-- Cleanup old damage numbers
task.spawn(function()
    while task.wait(0.5) do
        local currentTime = tick()
        for i = #ActiveDamageNumbers, 1, -1 do
            local dmgNum = ActiveDamageNumbers[i]
            if currentTime - dmgNum.createdTime > 1.5 then
                pcall(function() dmgNum.billboard:Destroy() end)
                table.remove(ActiveDamageNumbers, i)
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- ANTI AIM VIEWER (Prevents others from seeing your camera angles)
-- ─────────────────────────────────────────────────────────────

task.spawn(function()
    task.wait(2)
    while task.wait() do
        if not Toggles.AntiAimViewer or not Toggles.AntiAimViewer.Value then
            continue
        end
        
        local players = Players:GetPlayers()
        local closestPlayer = nil
        local closestDistance = math.huge
        
        for _, player in ipairs(players) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") then
                local playerPosition = player.Character.PrimaryPart.Position
                local viewportPosition = Camera:WorldToViewportPoint(playerPosition)
                local distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(viewportPosition.X, viewportPosition.Y)).Magnitude
                
                if distance < closestDistance then
                    closestPlayer = player
                    closestDistance = distance
                end
            end
        end
        
        -- Reset to prevent tracking
        if closestPlayer then
            closestPlayer = nil
            closestDistance = math.huge
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- RAGEBOT HIGHLIGHT, NO SPREAD, AUTO RELOAD
-- ─────────────────────────────────────────────────────────────

local RagebotHighlight = nil

-- Update or create ragebot highlight
local function UpdateRagebotHighlight()
    -- Remove existing highlight
    if RagebotHighlight then
        RagebotHighlight:Destroy()
        RagebotHighlight = nil
    end
    
    -- Create new highlight if enabled and we have a target
    if Toggles.RagebotHighlight and Toggles.RagebotHighlight.Value and RagebotTarget and RagebotTarget.Character then
        local highlight = Instance.new("Highlight")
        highlight.Name = "RagebotHighlight"
        highlight.FillColor = Options.RagebotHighlightFill.Value
        highlight.OutlineColor = Options.RagebotHighlightOutline.Value
        highlight.FillTransparency = Options.RagebotHighlightFillTrans.Value
        highlight.OutlineTransparency = Options.RagebotHighlightOutlineTrans.Value
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = RagebotTarget.Character
        RagebotHighlight = highlight
    end
end

-- Update highlight when colors/transparency change
task.spawn(function()
    task.wait(2)
    if Options.RagebotHighlightFill then
        Options.RagebotHighlightFill:OnChanged(UpdateRagebotHighlight)
    end
    if Options.RagebotHighlightOutline then
        Options.RagebotHighlightOutline:OnChanged(UpdateRagebotHighlight)
    end
    if Options.RagebotHighlightFillTrans then
        Options.RagebotHighlightFillTrans:OnChanged(UpdateRagebotHighlight)
    end
    if Options.RagebotHighlightOutlineTrans then
        Options.RagebotHighlightOutlineTrans:OnChanged(UpdateRagebotHighlight)
    end
    if Toggles.RagebotHighlight then
        Toggles.RagebotHighlight:OnChanged(UpdateRagebotHighlight)
    end
end)

-- Update highlight in loop
task.spawn(function()
    task.wait(2)
    while task.wait(0.5) do
        UpdateRagebotHighlight()
    end
end)

-- Auto Reload (automatically reloads when out of ammo)
task.spawn(function()
    task.wait(2)
    while task.wait(0.1) do
        if Toggles.AutoReload and Toggles.AutoReload.Value then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass('Tool')
                if tool then
                    -- Check ammo
                    local ammo = tool:FindFirstChild('Ammo')
                    if ammo and ammo.Value <= 0 then
                        -- Press R to reload
                        pcall(function()
                            keypress(0x52) -- R key
                            task.wait(0.05)
                            keyrelease(0x52)
                        end)
                    end
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- RAGEBOT PLAYER LIST UPDATER (now that services are loaded)
-- ─────────────────────────────────────────────────────────────

local function UpdateRagebotPlayerList()
    local playerList = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(playerList, plr.Name)
        end
    end
    if #playerList == 0 then
        playerList = {"No players available"}
    end
    return playerList
end

-- Search logic: fires every time the input changes
task.spawn(function()
    task.wait(2)
    if not Options.RagebotSearchInput then return end
    Options.RagebotSearchInput:OnChanged(function()
        local query = Options.RagebotSearchInput.Value:lower():gsub('%s+', '')
        if query == '' then
            RagebotSearchResult = nil
            RagebotResultLabel:SetText('result: --')
            return
        end

        local best = nil
        local bestScore = math.huge

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local name = plr.Name:lower()
            local display = plr.DisplayName:lower()

            -- Exact match wins immediately
            if name == query or display == query then
                best = plr; break
            end

            -- Prefix match
            local nameStart    = name:sub(1, #query) == query
            local displayStart = display:sub(1, #query) == query

            if nameStart or displayStart then
                local score = #name  -- shorter name = better score
                if score < bestScore then
                    bestScore = score
                    best = plr
                end
            end
        end

        if best then
            RagebotSearchResult = best.Name
            RagebotResultLabel:SetText('result: ' .. best.Name .. ' (' .. best.DisplayName .. ')')
        else
            RagebotSearchResult = nil
            RagebotResultLabel:SetText('result: no match')
        end
    end)
end)

-- Selecting from the Targets dropdown also sets search result so buttons work
task.spawn(function()
    task.wait(2)
    if not Options.RagebotTargetSelect then return end
    Options.RagebotTargetSelect:OnChanged(function()
        local val = Options.RagebotTargetSelect.Value
        if val and val ~= 'Loading...' and val ~= 'No players available' then
            RagebotSearchResult = val
            RagebotResultLabel:SetText('result: ' .. val)
        end
    end)
end)

-- Auto-update player list when players join/leave
Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    local updatedList = UpdateRagebotPlayerList()
    if Options.RagebotTargetSelect then
        Options.RagebotTargetSelect:SetValues(updatedList)
    end
    if Options.RagebotWhitelistSelect then
        Options.RagebotWhitelistSelect:SetValues(updatedList)
    end
    if Options.MiscPlayerSelect then
        Options.MiscPlayerSelect:SetValues(updatedList)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    task.wait(0.5)
    local updatedList = UpdateRagebotPlayerList()
    if Options.RagebotTargetSelect then
        Options.RagebotTargetSelect:SetValues(updatedList)
    end
    if Options.RagebotWhitelistSelect then
        Options.RagebotWhitelistSelect:SetValues(updatedList)
    end
    if Options.MiscPlayerSelect then
        Options.MiscPlayerSelect:SetValues(updatedList)
    end
    
    -- If the removed player was the ragebot target, unset it
    if RagebotTarget == plr then
        RagebotTarget = nil
        Toggles.CSyncEnabled:SetValue(false)
        Library:Notify('Ragebot target left, unset', 3)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- HIT SOUNDS
-- ─────────────────────────────────────────────────────────────

local HitSounds = {
    ["Rust Headshot"]      = "rbxassetid://138750331387064",
    ["Neverlose"]          = "rbxassetid://110168723447153",
    ["Bubble"]             = "rbxassetid://6534947588",
    ["Laser"]              = "rbxassetid://7837461331",
    ["Steve"]              = "rbxassetid://4965083997",
    ["Call of Duty"]       = "rbxassetid://5952120301",
    ["Bat"]                = "rbxassetid://3333907347",
    ["TF2 Critical"]       = "rbxassetid://296102734",
    ["Saber"]              = "rbxassetid://8415678813",
    ["Bameware"]           = "rbxassetid://3124331820",
    ["Money"]              = "rbxassetid://13956013041",
    ["Notif"]              = "rbxassetid://6696469190",
    ["Shutter"]            = "rbxassetid://10066921516",
    ["RIFK7"]              = "rbxassetid://9102080552",
    ["LazerBeam"]          = "rbxassetid://130791043",
    ["WindowsXPError"]     = "rbxassetid://160715357",
    ["TF2Hitsound"]        = "rbxassetid://3455144981",
    ["TF2Bat"]             = "rbxassetid://3333907347",
    ["BowHit"]             = "rbxassetid://1053296915",
    ["Bow"]                = "rbxassetid://3442683707",
    ["OSU"]                = "rbxassetid://7147454322",
    ["OneNN"]              = "rbxassetid://7349055654",
    ["Rust"]               = "rbxassetid://6565371338",
    ["TF2Pan"]             = "rbxassetid://3431749479",
    ["Mario"]              = "rbxassetid://5709456554",
    ["Bell"]               = "rbxassetid://6534947240",
    ["Pick"]               = "rbxassetid://1347140027",
    ["Pop"]                = "rbxassetid://198598793",
    ["Sans"]               = "rbxassetid://3188795283",
    ["Fart"]               = "rbxassetid://130833677",
    ["Big"]                = "rbxassetid://5332005053",
    ["Vine"]               = "rbxassetid://5332680810",
    ["Bruh"]               = "rbxassetid://4578740568",
    ["Skeet"]              = "rbxassetid://5633695679",
    ["Fatality"]           = "rbxassetid://6534947869",
    ["Bonk"]               = "rbxassetid://5766898159",
    ["Minecraft"]          = "rbxassetid://5869422451",
    ["Gamesense"]          = "rbxassetid://4817809188",
    ["Bamboo"]             = "rbxassetid://3769434519",
    ["Crowbar"]            = "rbxassetid://546410481",
    ["Weeb"]               = "rbxassetid://6442965016",
    ["Beep"]               = "rbxassetid://8177256015",
    ["Bambi"]              = "rbxassetid://8437203821",
    ["Stone"]              = "rbxassetid://3581383408",
    ["Old Fatality"]       = "rbxassetid://6607142036",
    ["Click"]              = "rbxassetid://8053704437",
    ["Ding"]               = "rbxassetid://7149516994",
    ["Snow"]               = "rbxassetid://6455527632",
    ["Osu"]                = "rbxassetid://7149255551",
    ["TF2"]                = "rbxassetid://2868331684",
    ["Slime"]              = "rbxassetid://6916371803",
    ["Among Us"]           = "rbxassetid://5700183626",
    ["One"]                = "rbxassetid://7380502345",
    ["BulletDeflect"]      = "rbxassetid://1657157666",
    ["Default"]            = "rbxassetid://330595293",
    ["UwU"]                = "rbxassetid://8679659744",
    ["Cod"]                = "rbxassetid://160432334",
    ["Blood SFX"]          = "rbxassetid://8164951181",
    ["Blood Burst"]        = "rbxassetid://3781479909",
    ["Blood Hit"]          = "rbxassetid://429400881",
}

local HitSoundInstance = Instance.new('Sound')
HitSoundInstance.Parent = SoundService

local LastTargetHealth = nil
local LastRagebotHealth = nil
local LastCamlockHealth = nil

local function PlayHitSound()
    if not Toggles.HitSoundsEnabled.Value then return end
    
    local soundName = Options.HitSound.Value
    local soundId   = HitSounds[soundName]
    if not soundId then return end
    
    HitSoundInstance.SoundId = soundId
    HitSoundInstance.Volume = Options.HitSoundVolume.Value
    HitSoundInstance:Play()
end

-- ─────────────────────────────────────────────────────────────
-- HIT OVERLAY (Screen Edge Flash)
-- ─────────────────────────────────────────────────────────────

local HitOverlay = {}
local PlayerGui = LocalPlayer:WaitForChild('PlayerGui')
local HitOverlayScreenGui = Instance.new('ScreenGui')
HitOverlayScreenGui.Name = 'CipherHitOverlay'
HitOverlayScreenGui.ResetOnSpawn = false
HitOverlayScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HitOverlayScreenGui.DisplayOrder = 999
HitOverlayScreenGui.IgnoreGuiInset = true
HitOverlayScreenGui.Parent = PlayerGui

-- Top overlay
HitOverlay.Top = Instance.new('Frame')
HitOverlay.Top.Name = 'HitOverlayTop'
HitOverlay.Top.Size = UDim2.new(1, 0, 0, 200)
HitOverlay.Top.Position = UDim2.new(0, 0, 0, 0)
HitOverlay.Top.AnchorPoint = Vector2.new(0, 0)
HitOverlay.Top.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
HitOverlay.Top.BackgroundTransparency = 1
HitOverlay.Top.BorderSizePixel = 0
HitOverlay.Top.ZIndex = 999
HitOverlay.Top.Parent = HitOverlayScreenGui

local topGradient = Instance.new('UIGradient')
topGradient.Rotation = 90
topGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 1)
})
topGradient.Parent = HitOverlay.Top

-- Bottom overlay
HitOverlay.Bottom = Instance.new('Frame')
HitOverlay.Bottom.Name = 'HitOverlayBottom'
HitOverlay.Bottom.Size = UDim2.new(1, 0, 0, 200)
HitOverlay.Bottom.Position = UDim2.new(0, 0, 1, 0)
HitOverlay.Bottom.AnchorPoint = Vector2.new(0, 1)
HitOverlay.Bottom.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
HitOverlay.Bottom.BackgroundTransparency = 1
HitOverlay.Bottom.BorderSizePixel = 0
HitOverlay.Bottom.ZIndex = 999
HitOverlay.Bottom.Parent = HitOverlayScreenGui

local bottomGradient = Instance.new('UIGradient')
bottomGradient.Rotation = 270
bottomGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 1)
})
bottomGradient.Parent = HitOverlay.Bottom

-- Left overlay
HitOverlay.Left = Instance.new('Frame')
HitOverlay.Left.Name = 'HitOverlayLeft'
HitOverlay.Left.Size = UDim2.new(0, 200, 1, 0)
HitOverlay.Left.Position = UDim2.new(0, 0, 0, 0)
HitOverlay.Left.AnchorPoint = Vector2.new(0, 0)
HitOverlay.Left.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
HitOverlay.Left.BackgroundTransparency = 1
HitOverlay.Left.BorderSizePixel = 0
HitOverlay.Left.ZIndex = 999
HitOverlay.Left.Parent = HitOverlayScreenGui

local leftGradient = Instance.new('UIGradient')
leftGradient.Rotation = 0
leftGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 1)
})
leftGradient.Parent = HitOverlay.Left

-- Right overlay
HitOverlay.Right = Instance.new('Frame')
HitOverlay.Right.Name = 'HitOverlayRight'
HitOverlay.Right.Size = UDim2.new(0, 200, 1, 0)
HitOverlay.Right.Position = UDim2.new(1, 0, 0, 0)
HitOverlay.Right.AnchorPoint = Vector2.new(1, 0)
HitOverlay.Right.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
HitOverlay.Right.BackgroundTransparency = 1
HitOverlay.Right.BorderSizePixel = 0
HitOverlay.Right.ZIndex = 999
HitOverlay.Right.Parent = HitOverlayScreenGui

local rightGradient = Instance.new('UIGradient')
rightGradient.Rotation = 180
rightGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 1)
})
rightGradient.Parent = HitOverlay.Right

-- Flash hit overlay
local function FlashHitOverlay()
    if not Toggles.HitOverlayEnabled or not Toggles.HitOverlayEnabled.Value then return end
    
    local color = Options.HitOverlayColor.Value
    local duration = Options.HitOverlayDuration.Value / 1000
    
    -- Set color
    HitOverlay.Top.BackgroundColor3 = color
    HitOverlay.Bottom.BackgroundColor3 = color
    HitOverlay.Left.BackgroundColor3 = color
    HitOverlay.Right.BackgroundColor3 = color
    
    -- Flash in
    HitOverlay.Top.BackgroundTransparency = 0.3
    HitOverlay.Bottom.BackgroundTransparency = 0.3
    HitOverlay.Left.BackgroundTransparency = 0.3
    HitOverlay.Right.BackgroundTransparency = 0.3
    
    -- Fade out
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < duration do
            local alpha = (tick() - startTime) / duration
            local transparency = 0.3 + (alpha * 0.7) -- 0.3 to 1.0
            
            HitOverlay.Top.BackgroundTransparency = transparency
            HitOverlay.Bottom.BackgroundTransparency = transparency
            HitOverlay.Left.BackgroundTransparency = transparency
            HitOverlay.Right.BackgroundTransparency = transparency
            
            task.wait()
        end
        
        HitOverlay.Top.BackgroundTransparency = 1
        HitOverlay.Bottom.BackgroundTransparency = 1
        HitOverlay.Left.BackgroundTransparency = 1
        HitOverlay.Right.BackgroundTransparency = 1
    end)
end

-- ─────────────────────────────────────────────────────────────
-- RESOLVER LOGIC
-- Clusters position history to find the real un-jittered position
-- Works on void players, fast flyers, anti-aim, HVH
-- ─────────────────────────────────────────────────────────────

local ResolverData = {}  -- per-player state: { positionstr={}, rnpatterns=nil, lrefresh=0 }

local function ResolverGetPosition(player)
    if not Toggles.ResolverEnabled or not Toggles.ResolverEnabled.Value then return nil end
    if not player or not player.Character then return nil end

    local hrp = player.Character:FindFirstChild('HumanoidRootPart')
    if not hrp then return nil end

    local currentPos = hrp.Position

    -- Per-player state
    if not ResolverData[player] then
        ResolverData[player] = { positionstr = {}, rnpatterns = nil, lrefresh = tick() }
    end
    local state = ResolverData[player]

    local now = tick()
    local refreshTime = Options.ResolverRefreshTime and Options.ResolverRefreshTime.Value or 3

    -- Reset history on interval
    if now - state.lrefresh >= refreshTime then
        state.positionstr = {}
        state.rnpatterns  = nil
        state.lrefresh    = now
    end

    local forgiveness = Options.ResolverForgiveness and Options.ResolverForgiveness.Value or 14.4
    local minCluster  = 4
    local distPenalty = Options.ResolverDistPenalty and Options.ResolverDistPenalty.Value or 2

    -- Void bonus: if abs(X)+abs(Z) < 8955 the player is likely in the void
    if math.abs(currentPos.X) + math.abs(currentPos.Z) < 8955 then
        forgiveness = forgiveness + (Options.ResolverVoidBonus and Options.ResolverVoidBonus.Value or 5)
    end

    -- Distance-based penalty
    local myChar = LocalPlayer.Character
    if myChar and myChar:FindFirstChild('HumanoidRootPart') then
        local dist = (currentPos - myChar.HumanoidRootPart.Position).Magnitude
        forgiveness = math.clamp(forgiveness - (dist / 100) * distPenalty, 1, 100)
    end

    -- Record position
    table.insert(state.positionstr, { pos = currentPos, time = now })
    if #state.positionstr > 500 then
        table.remove(state.positionstr, 1)
    end

    -- Need at least 10 samples
    if #state.positionstr < 10 then return currentPos end

    -- Cluster analysis: find densest cluster of positions
    local history = state.positionstr
    local clusters = {}

    for i = 1, #history do
        local p = history[i].pos
        local count = 0
        local sum   = Vector3.new(0, 0, 0)

        for j = 1, #history do
            local q = history[j].pos
            if (p - q).Magnitude <= forgiveness then
                count = count + 1
                sum   = sum + q
            end
        end

        if count >= minCluster then
            table.insert(clusters, { pos = sum / count, count = count })
        end
    end

    -- Pick the densest cluster
    local best = nil
    for _, c in ipairs(clusters) do
        if not best or c.count > best.count then
            best = c
        end
    end

    if best then
        state.rnpatterns = best.pos
        return best.pos
    end

    return currentPos
end

-- Clean up state when players leave
Players.PlayerRemoving:Connect(function(plr)
    ResolverData[plr] = nil
end)

-- ─────────────────────────────────────────────────────────────
-- WALLBANG LOGIC (Always active for ragebot)
-- ─────────────────────────────────────────────────────────────

local WallbangFolders = {}

-- Enable wallbang for ragebot automatically
local function EnableWallbangForRagebot()
    local Ignored = workspace:FindFirstChild('Ignored')
    
    if Ignored then
        for _, FolderName in ipairs({"Vehicles", "MAP"}) do
            local Folder = workspace:FindFirstChild(FolderName)
            if Folder and not WallbangFolders[FolderName] then
                WallbangFolders[FolderName] = Folder.Parent
                Folder.Parent = Ignored
            end
        end
    end
end

-- Manual wallbang toggle
task.spawn(function()
    task.wait(2)
    if not Toggles.Wallbang then return end
    Toggles.Wallbang:OnChanged(function()
        local Ignored = workspace:FindFirstChild('Ignored')
        if Toggles.Wallbang.Value then
            EnableWallbangForRagebot()
        else
            if not RagebotTarget then
                for FolderName, OriginalParent in pairs(WallbangFolders) do
                    local Folder = Ignored and Ignored:FindFirstChild(FolderName)
                    if Folder then
                        Folder.Parent = OriginalParent or workspace
                    end
                end
                WallbangFolders = {}
            end
        end
    end)
end)

-- Always enable wallbang when ragebot target is set
task.spawn(function()
    while task.wait(1) do
        if RagebotTarget then
            EnableWallbangForRagebot()
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- NETWORK HACK LOGIC
-- Continuously teleports closest player to cursor in front of you
-- ─────────────────────────────────────────────────────────────

local NetworkHackTarget = nil

local function GetNetworkHackTarget()
    local closest, closestDist = nil, math.huge
    local mouseHit = Mouse.Hit.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end
        local hrp = char:FindFirstChild('HumanoidRootPart')
        if not hrp then continue end
        local dist = (hrp.Position - mouseHit).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = plr
        end
    end
    return closest
end

task.spawn(function()
    task.wait(2)
    RunService.RenderStepped:Connect(function()
        if not Toggles.NetworkHackEnabled or not Toggles.NetworkHackEnabled.Value then
            NetworkHackTarget = nil
            return
        end

        -- Update target to closest to mouse
        NetworkHackTarget = GetNetworkHackTarget()

        if not NetworkHackTarget then return end
        local targetChar = NetworkHackTarget.Character
        if not targetChar then return end
        local targetHRP = targetChar:FindFirstChild('HumanoidRootPart')
        if not targetHRP then return end

        local myChar = LocalPlayer.Character
        if not myChar then return end
        local myHRP = myChar:FindFirstChild('HumanoidRootPart')
        if not myHRP then return end

        -- Teleport them directly in front of you (-6.5 studs on your look vector)
        targetHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, -6.5)
    end)
end)

-- ─────────────────────────────────────────────────────────────
-- BULLET TP LOGIC
-- ─────────────────────────────────────────────────────────────



-- ─────────────────────────────────────────────────────────────
-- BULLET TRACERS LOGIC
-- ─────────────────────────────────────────────────────────────

local TracerContainer = Instance.new('Folder')
TracerContainer.Name = 'BulletTracers'
TracerContainer.Parent = workspace

local function CreateTracer(startPos, endPos)
    if not Toggles.BulletTracersEnabled or not Toggles.BulletTracersEnabled.Value then return end
    
    local startColor = Options.TracerStartColor.Value
    local endColor = Options.TracerEndColor.Value
    local thickness = Options.TracerThickness.Value
    local lifetime = Options.TracerLifetime.Value
    local mode = Options.TracerMode.Value
    
    local colorSequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, startColor),
        ColorSequenceKeypoint.new(1, endColor)
    })
    
    local startPart = Instance.new('Part')
    startPart.Size = Vector3.new(0, 0, 0)
    startPart.Massless = true
    startPart.Transparency = 1
    startPart.CanCollide = false
    startPart.Position = startPos
    startPart.Anchored = true
    startPart.Parent = TracerContainer
    
    local startAttachment = Instance.new('Attachment')
    startAttachment.Parent = startPart
    
    local impactPart = Instance.new('Part')
    impactPart.Size = Vector3.new(0, 0, 0)
    impactPart.Transparency = 1
    impactPart.CanCollide = false
    impactPart.Position = endPos
    impactPart.Anchored = true
    impactPart.Massless = true
    impactPart.Parent = TracerContainer
    
    local impactAttachment = Instance.new('Attachment')
    impactAttachment.Parent = impactPart
    
    local beam = Instance.new('Beam')
    beam.FaceCamera = true
    beam.Color = colorSequence
    beam.Attachment0 = startAttachment
    beam.Attachment1 = impactAttachment
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Width0 = thickness
    beam.Width1 = thickness
    beam.Transparency = NumberSequence.new(0)
    
    -- Different tracer modes with DIFFERENT textures
    if mode == 'Line' then
        beam.Texture = '' -- No texture, solid line
    elseif mode == 'Beam' then
        beam.Texture = 'rbxassetid://446111271' -- Classic beam texture
    elseif mode == 'Gradient' then
        beam.Texture = 'rbxassetid://5714372878' -- Gradient texture
        beam.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 0.8)
        })
    end
    
    beam.TextureSpeed = 1
    beam.TextureLength = 1
    beam.Parent = startPart
    
    -- Fade out
    task.spawn(function()
        task.wait(lifetime * 0.8)
        local fadeTime = lifetime * 0.2
        local startTime = tick()
        
        while tick() - startTime < fadeTime do
            local alpha = (tick() - startTime) / fadeTime
            if mode ~= 'Gradient' then
                beam.Transparency = NumberSequence.new(alpha)
            end
            task.wait()
        end
        
        startPart:Destroy()
        impactPart:Destroy()
    end)
end

-- Monitor for bullet rays (with error handling)
local BulletRayConnection
pcall(function()
    local Ignored = workspace:FindFirstChild('Ignored')
    if Ignored then
        local Siren = Ignored:FindFirstChild('Siren')
        if Siren then
            local Radius = Siren:FindFirstChild('Radius')
            if Radius then
                BulletRayConnection = Radius.ChildAdded:Connect(function(obj)
                    pcall(function()
                        if obj and obj.Name == 'BULLET_RAYS' then
                            local ownerName = obj:GetAttribute('OwnerCharacter')
                            if ownerName == LocalPlayer.Name then
                                local startPos = obj.CFrame.Position
                                local lookVector = obj.CFrame.LookVector
                                
                                local raycastParams = RaycastParams.new()
                                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                raycastParams.IgnoreWater = true
                                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, TracerContainer}
                                
                                local ray = workspace:Raycast(startPos, lookVector * 1000, raycastParams)
                                local endPos = ray and ray.Position or (startPos + lookVector * 1000)
                                
                                CreateTracer(startPos, endPos)
                            end
                            
                            -- Remove bullet rays if tracers enabled (prevents error)
                            if Toggles.BulletTracersEnabled and Toggles.BulletTracersEnabled.Value then
                                task.spawn(function()
                                    task.wait(0.1)
                                    if obj and obj.Parent then
                                        obj:Destroy()
                                    end
                                end)
                            end
                        end
                    end)
                end)
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- EMOTE LOGIC
-- ─────────────────────────────────────────────────────────────

local CurrentEmoteTrack = nil

local function StopEmote()
    if CurrentEmoteTrack then
        pcall(function() CurrentEmoteTrack:Stop() end)
        CurrentEmoteTrack = nil
    end
end

local function PlayEmote(name, speed)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild('Humanoid', 5)
    if not hum then return end
    local animator = hum:FindFirstChildOfClass('Animator')
    if not animator then return end

    StopEmote()

    local animId = EmoteAnims[name]
    if not animId then return end

    local anim = Instance.new('Animation')
    anim.AnimationId = 'rbxassetid://' .. tostring(animId)

    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4
    track.Looped = true
    track:Play()
    track:AdjustSpeed(math.max(speed, 0.01))
    CurrentEmoteTrack = track
end

-- React to toggle
task.spawn(function()
    task.wait(2)
    if not Toggles.EmotesEnabled then return end
    Toggles.EmotesEnabled:OnChanged(function()
        if Toggles.EmotesEnabled.Value then
            local name  = Options.EmoteSelected.Value
            local speed = Options.EmoteSpeed.Value / 10
            PlayEmote(name, speed)
        else
            StopEmote()
        end
    end)
end)

-- React to dropdown change
task.spawn(function()
    task.wait(2)
    if not Options.EmoteSelected then return end
    Options.EmoteSelected:OnChanged(function()
        if Toggles.EmotesEnabled.Value then
            local name  = Options.EmoteSelected.Value
            local speed = Options.EmoteSpeed.Value / 10
            PlayEmote(name, speed)
        end
    end)
end)

-- React to speed change
task.spawn(function()
    task.wait(2)
    if not Options.EmoteSpeed then return end
    Options.EmoteSpeed:OnChanged(function()
        if Toggles.EmotesEnabled.Value and CurrentEmoteTrack then
            local speed = Options.EmoteSpeed.Value / 10
            pcall(function() CurrentEmoteTrack:AdjustSpeed(math.max(speed, 0.01)) end)
        end
    end)
end)

-- Replay emote after respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if Toggles.EmotesEnabled.Value then
        local name  = Options.EmoteSelected.Value
        local speed = Options.EmoteSpeed.Value / 10
        PlayEmote(name, speed)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- SPECTATE LOGIC
-- ─────────────────────────────────────────────────────────────

local OriginalCameraSubject = nil

task.spawn(function()
    task.wait(2)
    if not Toggles.SpectateTarget then return end
    Toggles.SpectateTarget:OnChanged(function()
        if not Toggles.SpectateTarget.Value then
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
            if myHum then
                Camera.CameraSubject = myHum
            elseif OriginalCameraSubject then
                Camera.CameraSubject = OriginalCameraSubject
            end
            OriginalCameraSubject = nil
        end
    end)
end)

-- Restore camera when View is deselected from Settings dropdown
task.spawn(function()
    task.wait(2)
    if Options.RagebotSettings then
        Options.RagebotSettings:OnChanged(function()
            local viewSelected = Options.RagebotSettings.Value and Options.RagebotSettings.Value["View"] == true
            if not viewSelected then
                -- Always restore to our own humanoid, not saved subject (which may be dead)
                local myChar = LocalPlayer.Character
                local myHum = myChar and myChar:FindFirstChildOfClass('Humanoid')
                if myHum then
                    Camera.CameraSubject = myHum
                elseif OriginalCameraSubject then
                    Camera.CameraSubject = OriginalCameraSubject
                end
                OriginalCameraSubject = nil
            end
        end)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- SELF AURA SYSTEM (juju-style real particle auras)
-- ─────────────────────────────────────────────────────────────

local AuraParticles   = {}  -- active emitter instances parented to body parts
local AuraConn        = nil
local AuraAssets      = {}  -- cached loaded models

-- Preload all aura models in background
task.spawn(function()
    local ids = {
        ['Starlight'] = 'rbxassetid://134645216613107',
        ['Heavenly']  = 'rbxassetid://139300897520961',
        ['Ribbon']    = 'rbxassetid://132069507632161',
        ['Sakura']    = 'rbxassetid://81755778619404',
        ['Angel']     = 'rbxassetid://97658130917593',
        ['Wind']      = 'rbxassetid://80694081850877',
        ['Flow']      = 'rbxassetid://119913533725648',
        ['Star']      = 'rbxassetid://73754563740680',
    }
    for name, id in pairs(ids) do
        local ok, result = pcall(function()
            return game:GetObjects(id)[1]
        end)
        if ok and result then
            AuraAssets[name] = result
        end
    end
end)

local AuraParts = {} -- track folder for cleanup

local function DestroyAura()
    if AuraConn then AuraConn:Disconnect(); AuraConn = nil end
    for _, p in pairs(AuraParticles) do
        pcall(function() p:Destroy() end)
    end
    AuraParticles = {}
    for _, p in pairs(AuraParts) do
        pcall(function() p:Destroy() end)
    end
    AuraParts = {}
end

local function ApplyAuraColor(color)
    local colorSeq = ColorSequence.new(color)
    for _, emitter in pairs(AuraParticles) do
        pcall(function()
            local cn = emitter.ClassName
            if cn == 'ParticleEmitter' or cn == 'Beam' or cn == 'Trail' then
                emitter.Color = colorSeq
            elseif cn == 'PointLight' then
                emitter.Color = color
            end
        end)
    end
end

local function BuildAura()
    DestroyAura()
    local char = LocalPlayer.Character
    if not char then return end

    local style = Options.AuraStyle.Value
    local color = Options.SelfAuraColor.Value
    local colorSeq = ColorSequence.new(color)

    local model = AuraAssets[style]
    if not model then
        -- Asset not loaded yet, retry in 1s
        task.delay(1, function()
            if Toggles.SelfAuraEnabled and Toggles.SelfAuraEnabled.Value then
                BuildAura()
            end
        end)
        return
    end

    -- Clone the model and distribute its particle children to matching body parts
    local cloned = model:Clone()
    local bodyPartNames = {
        'Head','Torso','Left Arm','Right Arm','Left Leg','Right Leg',
        'UpperTorso','LowerTorso',
        'LeftUpperArm','RightUpperArm','LeftLowerArm','RightLowerArm','LeftHand','RightHand',
        'LeftUpperLeg','RightUpperLeg','LeftLowerLeg','RightLowerLeg','LeftFoot','RightFoot',
        'HumanoidRootPart',
    }

    for _, modelPart in ipairs(cloned:GetChildren()) do
        local charPart = char:FindFirstChild(modelPart.Name)
        if charPart and charPart:IsA('BasePart') then
            for _, child in ipairs(modelPart:GetChildren()) do
                local ok, _ = pcall(function()
                    local inst = child:Clone()
                    inst.Name = '__AURA_FX'
                    -- Apply color
                    local cn = inst.ClassName
                    if cn == 'ParticleEmitter' or cn == 'Beam' or cn == 'Trail' then
                        inst.Color = colorSeq
                    elseif cn == 'PointLight' then
                        inst.Color = color
                    end
                    inst.Parent = charPart
                    AuraParticles[#AuraParticles+1] = inst
                end)
            end
        end
    end
    cloned:Destroy()
end

-- Live color update
task.spawn(function()
    task.wait(2)
    if not Options.SelfAuraColor then return end
    Options.SelfAuraColor:OnChanged(function()
        ApplyAuraColor(Options.SelfAuraColor.Value)
    end)
end)

-- Rebuild on style change
task.spawn(function()
    task.wait(2)
    if not Options.AuraStyle then return end
    Options.AuraStyle:OnChanged(function()
        if Toggles.SelfAuraEnabled and Toggles.SelfAuraEnabled.Value then
            BuildAura()
        end
    end)
end)

-- Toggle on/off
task.spawn(function()
    task.wait(2)
    if not Toggles.SelfAuraEnabled then return end
    Toggles.SelfAuraEnabled:OnChanged(function()
        if Toggles.SelfAuraEnabled.Value then
            BuildAura()
        else
            DestroyAura()
        end
    end)
end)

-- Rebuild on respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    if Toggles.SelfAuraEnabled and Toggles.SelfAuraEnabled.Value then
        BuildAura()
    end
end)

-- ─────────────────────────────────────────────────────────────
-- JUMP CIRCLE SYSTEM
-- ─────────────────────────────────────────────────────────────

local JumpCircles = {}

local function CreateJumpCircle(position, color)
    if not Toggles.JumpCircleEnabled or not Toggles.JumpCircleEnabled.Value then return end
    
    -- Create outer ring
    local outerRing = Instance.new('Part')
    outerRing.Name = 'JumpCircleOuter'
    outerRing.Shape = Enum.PartType.Cylinder
    outerRing.Size = Vector3.new(0.2, 5, 5)
    outerRing.Material = Enum.Material.Neon
    outerRing.Color = color
    outerRing.Anchored = true
    outerRing.CanCollide = false
    outerRing.Transparency = 0.3
    outerRing.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    outerRing.Parent = workspace
    
    -- Create inner circle (to make a hole)
    local innerCircle = Instance.new('Part')
    innerCircle.Name = 'JumpCircleInner'
    innerCircle.Shape = Enum.PartType.Cylinder
    innerCircle.Size = Vector3.new(0.25, 3, 3) -- Slightly taller, smaller diameter
    innerCircle.Material = Enum.Material.Neon
    innerCircle.Color = color
    innerCircle.Anchored = true
    innerCircle.CanCollide = false
    innerCircle.Transparency = 1 -- Invisible, creates hole effect
    innerCircle.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    innerCircle.Parent = outerRing
    
    -- Use NegateOperation to create donut shape
    local success, ring = pcall(function()
        return outerRing:SubtractAsync({innerCircle})
    end)
    
    if success and ring then
        ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
        ring.Anchored = true
        ring.CanCollide = false
        ring.Material = Enum.Material.Neon
        ring.Color = color
        ring.Transparency = 0.3
        ring.Parent = workspace
        outerRing:Destroy()
        innerCircle:Destroy()
        outerRing = ring
    else
        -- Fallback: just use outer ring if CSG fails
        innerCircle:Destroy()
    end
    
    table.insert(JumpCircles, {part = outerRing, time = tick()})
    
    -- Fade out animation
    task.spawn(function()
        local startTime = tick()
        local duration = 1.5
        local startSize = outerRing.Size
        local endSize = Vector3.new(0.2, 15, 15)
        
        while tick() - startTime < duration do
            local alpha = (tick() - startTime) / duration
            outerRing.Transparency = 0.3 + (alpha * 0.7)
            outerRing.Size = startSize:Lerp(endSize, alpha)
            task.wait()
        end
        
        outerRing:Destroy()
        for i, data in ipairs(JumpCircles) do
            if data.part == outerRing then
                table.remove(JumpCircles, i)
                break
            end
        end
    end)
end

-- Monitor for jumps
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChildOfClass('Humanoid')
    if hum then
        hum.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
                local hrp = char:FindFirstChild('HumanoidRootPart')
                if hrp then
                    local color = Options.JumpCircleColor and Options.JumpCircleColor.Value or Color3.fromRGB(0, 255, 255)
                    CreateJumpCircle(hrp.Position - Vector3.new(0, 3, 0), color)
                end
            end
        end)
    end
end)

-- Setup for existing character
task.spawn(function()
    task.wait(2)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum then
            hum.StateChanged:Connect(function(oldState, newState)
                if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
                    local hrp = char:FindFirstChild('HumanoidRootPart')
                    if hrp then
                        local color = Options.JumpCircleColor and Options.JumpCircleColor.Value or Color3.fromRGB(0, 255, 255)
                        CreateJumpCircle(hrp.Position - Vector3.new(0, 3, 0), color)
                    end
                end
            end)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- VOID TELEPORT LOGIC
-- ─────────────────────────────────────────────────────────────

local OriginalPosition = nil
local InVoid = false
local VoidSpamConnection = nil
local VoidRandomConnection = nil

local function StopVoidLoops()
    if VoidSpamConnection then
        VoidSpamConnection:Disconnect()
        VoidSpamConnection = nil
    end
    if VoidRandomConnection then
        VoidRandomConnection:Disconnect()
        VoidRandomConnection = nil
    end
end

task.spawn(function()
    task.wait(2)
    if not Options.VoidKeybind then return end
    Options.VoidKeybind:OnClick(function()
        if not Toggles.VoidEnabled.Value then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    
    local mode = Options.VoidMode.Value
    local distance = Options.VoidDistance.Value
    
    -- NORMAL MODE: Toggle in/out
    if mode == 'Normal' then
        StopVoidLoops()
        
        if not InVoid then
            OriginalPosition = hrp.CFrame
            hrp.CFrame = hrp.CFrame + Vector3.new(0, distance, 0)
            InVoid = true
        else
            if OriginalPosition then
                hrp.CFrame = OriginalPosition
                OriginalPosition = nil
            end
            InVoid = false
        end
    
    -- SPAM MODE: Rapid teleport back and forth
    elseif mode == 'Spam' then
        if not InVoid then
            OriginalPosition = hrp.CFrame
            InVoid = true
            
            VoidSpamConnection = RunService.Heartbeat:Connect(function()
                if not Toggles.VoidEnabled.Value or not InVoid then
                    StopVoidLoops()
                    return
                end
                
                local myChar = LocalPlayer.Character
                if not myChar then return end
                local myHRP = myChar:FindFirstChild('HumanoidRootPart')
                if not myHRP then return end
                
                local delay = Options.VoidSpamDelay.Value / 1000
                local currentTime = tick()
                
                -- Spam teleport logic
                if math.floor(currentTime / delay) % 2 == 0 then
                    -- Void position
                    if OriginalPosition then
                        myHRP.CFrame = OriginalPosition + Vector3.new(0, distance, 0)
                    end
                else
                    -- Original position
                    if OriginalPosition then
                        myHRP.CFrame = OriginalPosition
                    end
                end
            end)
        else
            -- Stop spam
            StopVoidLoops()
            if OriginalPosition then
                hrp.CFrame = OriginalPosition
                OriginalPosition = nil
            end
            InVoid = false
        end
    
    -- RANDOM MODE: Random movement in void
    elseif mode == 'Random' then
        if not InVoid then
            OriginalPosition = hrp.CFrame
            hrp.CFrame = hrp.CFrame + Vector3.new(0, distance, 0)
            InVoid = true
            
            VoidRandomConnection = RunService.Heartbeat:Connect(function()
                if not Toggles.VoidEnabled.Value or not InVoid then
                    StopVoidLoops()
                    return
                end
                
                local myChar = LocalPlayer.Character
                if not myChar then return end
                local myHRP = myChar:FindFirstChild('HumanoidRootPart')
                if not myHRP then return end
                
                local rangeX = Options.VoidRandomX.Value
                local rangeY = Options.VoidRandomY.Value
                local rangeZ = Options.VoidRandomZ.Value
                
                local randomOffset = Vector3.new(
                    math.random(-rangeX, rangeX),
                    math.random(-rangeY, rangeY),
                    math.random(-rangeZ, rangeZ)
                )
                
                if OriginalPosition then
                    myHRP.CFrame = OriginalPosition + Vector3.new(0, distance, 0) + randomOffset
                end
            end)
        else
            -- Return from void
            StopVoidLoops()
            if OriginalPosition then
                hrp.CFrame = OriginalPosition
                OriginalPosition = nil
            end
            InVoid = false
        end
    end
end)
end) -- end task.spawn for VoidKeybind

-- ─────────────────────────────────────────────────────────────
-- C-SYNC LOGIC (Using provided code)
-- ─────────────────────────────────────────────────────────────

local CSyncData = {
    client_character = nil,
    client_rootpart = nil,
    saved_desync = nil,
    current_target = nil,
    hook_active = false,
    strafe_cframe = nil
}

-- Character and RootPart updater
task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild('HumanoidRootPart') then
            CSyncData.client_character = char
            CSyncData.client_rootpart = char.HumanoidRootPart
        end
        task.wait(1)
    end
end)

-- Create 2D Indicator
local CSyncScreenGui = Instance.new('ScreenGui')
CSyncScreenGui.Name = 'CSyncIndicatorGUI'
CSyncScreenGui.ResetOnSpawn = false
CSyncScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
CSyncScreenGui.Parent = PlayerGui

-- Background frame (outer ring/frame image - asset 5552526748)
local CSyncBackground = Instance.new('ImageLabel')
CSyncBackground.Name = 'BackgroundCircle'
CSyncBackground.Size = UDim2.new(0, 40, 0, 40)
CSyncBackground.AnchorPoint = Vector2.new(0.5, 0.5)
CSyncBackground.Position = UDim2.new(0.5, 0, 0.5, 0)
CSyncBackground.BackgroundTransparency = 1
CSyncBackground.Image = 'rbxassetid://5552526748'
CSyncBackground.ImageColor3 = Color3.fromRGB(255, 255, 255)
CSyncBackground.ImageTransparency = 0
CSyncBackground.Visible = false
CSyncBackground.ZIndex = 9
CSyncBackground.Parent = CSyncScreenGui

-- Center icon (inner image - asset 136429941616201)
local CSyncIndicator = Instance.new('ImageLabel')
CSyncIndicator.Name = 'CSyncIndicator'
CSyncIndicator.Size = UDim2.new(0, 22, 0, 22)
CSyncIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
CSyncIndicator.Position = UDim2.new(0.5, 0, 0.5, 0)
CSyncIndicator.BackgroundTransparency = 1
CSyncIndicator.Image = 'rbxassetid://136429941616201'
CSyncIndicator.ImageColor3 = Color3.fromRGB(255, 50, 50)
CSyncIndicator.ImageTransparency = 0
CSyncIndicator.Visible = false
CSyncIndicator.ZIndex = 10
CSyncIndicator.Parent = CSyncScreenGui

-- Helper to set indicator position + visibility
local function SetIndicatorPosition(worldPos)
    local screen_pos, on_screen = Camera:WorldToViewportPoint(worldPos)
    if on_screen and screen_pos.Z > 0 then
        local pos = UDim2.new(0, screen_pos.X, 0, screen_pos.Y)
        CSyncIndicator.Position = pos
        CSyncBackground.Position = pos

        local vp = Camera.ViewportSize
        local pad = 20
        local in_bounds = screen_pos.X > pad and screen_pos.X < (vp.X - pad)
                      and screen_pos.Y > pad and screen_pos.Y < (vp.Y - pad)

        CSyncIndicator.Visible = in_bounds
        CSyncBackground.Visible = in_bounds
    else
        CSyncIndicator.Visible = false
        CSyncBackground.Visible = false
    end
end

local function HideIndicator()
    CSyncIndicator.Visible = false
    CSyncBackground.Visible = false
end

-- Wire color pickers — apply immediately and on every change
task.spawn(function()
    task.wait(0.5)
    -- Frame color
    CSyncBackground.ImageColor3 = Options.CSyncIndicatorFrameColor.Value
    Options.CSyncIndicatorFrameColor:OnChanged(function()
        CSyncBackground.ImageColor3 = Options.CSyncIndicatorFrameColor.Value
    end)
    -- Center color
    CSyncIndicator.ImageColor3 = Options.CSyncIndicatorCenterColor.Value
    Options.CSyncIndicatorCenterColor:OnChanged(function()
        CSyncIndicator.ImageColor3 = Options.CSyncIndicatorCenterColor.Value
    end)
end)

-- Get Closest Player to Cursor
local function GetClosestPlayerToCursor()
    local closest, shortest = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild('HumanoidRootPart') then
            local screenPos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if dist < shortest then
                    closest = plr
                    shortest = dist
                end
            end
        end
    end
    return closest
end

-- Hook Management
local CSyncOldIndex
local function EnableCSyncHook()
    if not CSyncData.hook_active then
        CSyncOldIndex = hookmetamethod(game, '__index', function(self, index)
            if not checkcaller()
                and Toggles.CSyncEnabled and Toggles.CSyncEnabled.Value
                and CSyncData.saved_desync
                and CSyncData.current_target
                and index == 'CFrame'
                and self == CSyncData.client_rootpart then
                return CSyncData.saved_desync
            end
            return CSyncOldIndex(self, index)
        end)
        CSyncData.hook_active = true
    end
end

local function DisableCSyncHook()
    if CSyncData.hook_active and CSyncOldIndex then
        hookmetamethod(game, '__index', CSyncOldIndex)
        CSyncData.hook_active = false
    end
end

-- Get random position around target with strafe settings
local function GetRandomPositionAroundTarget(target_root, range)
    -- Use ragebot strafe settings if ragebot target is set
    local strafeRange = range
    local strafeHeight = 0
    
    if RagebotTarget then
        strafeRange = Options.RagebotStrafeRange.Value or range
        strafeHeight = Options.RagebotStrafeHeight.Value or 5
    end
    
    local random_x = math.random(-strafeRange, strafeRange)
    local random_y = math.random(-strafeHeight, strafeHeight)
    local random_z = math.random(-strafeRange, strafeRange)
    local random_offset = Vector3.new(random_x, random_y, random_z)
    local random_position = target_root.Position + random_offset
    return CFrame.new(random_position)
end

-- Main C-Sync Heartbeat Loop
RunService.Heartbeat:Connect(function()
    if not Toggles.CSyncEnabled or not Toggles.CSyncEnabled.Value then
        -- Show Always: show indicator on YOUR OWN body when not csyncing
        if Toggles.CSyncIndicator and Toggles.CSyncIndicator.Value
        and Toggles.CSyncIndicatorAlwaysShow and Toggles.CSyncIndicatorAlwaysShow.Value then
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            if myHRP then
                SetIndicatorPosition(myHRP.Position)
            else
                HideIndicator()
            end
        else
            HideIndicator()
        end
        DisableCSyncHook()
        CSyncData.current_target = nil
        return
    end
    
    local client_root = CSyncData.client_rootpart
    if not client_root then
        DisableCSyncHook()
        return
    end
    
    -- Determine target based on settings
    local target_root = nil
    
    -- Priority 1: Ragebot target (highest priority)
    if RagebotTarget and RagebotTarget.Character then
        target_root = RagebotTarget.Character:FindFirstChild('HumanoidRootPart')
        CSyncData.current_target = RagebotTarget
    -- Priority 2: Sticky — lock onto closest at activation, hold until turned off
    elseif Toggles.CSyncSticky and Toggles.CSyncSticky.Value then
        if not CSyncData.current_target or not CSyncData.current_target.Character then
            -- First activation or target left — find closest by world distance (works in void too)
            local closest_player = nil
            local closest_distance = math.huge

            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild('HumanoidRootPart')
                    if hrp then
                        local distance = (client_root.Position - hrp.Position).Magnitude
                        if distance < closest_distance then
                            closest_distance = distance
                            closest_player = player
                        end
                    end
                end
            end

            CSyncData.current_target = closest_player
        end
        -- Keep using the locked target
        if CSyncData.current_target and CSyncData.current_target.Character then
            target_root = CSyncData.current_target.Character:FindFirstChild('HumanoidRootPart')
        end
    -- No sticky, no ragebot — always use closest by world distance (works in void too)
    else
        local closest_player = nil
        local closest_distance = math.huge

        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild('HumanoidRootPart')
                if hrp then
                    local distance = (client_root.Position - hrp.Position).Magnitude
                    if distance < closest_distance then
                        closest_distance = distance
                        closest_player = player
                    end
                end
            end
        end

        CSyncData.current_target = closest_player
        target_root = closest_player and closest_player.Character and closest_player.Character:FindFirstChild('HumanoidRootPart')
    end
    
    if not target_root then
        HideIndicator()
        DisableCSyncHook()
        return
    end
    
    -- Enable hook
    EnableCSyncHook()
    
    -- Generate random position
    local range = Options.CSyncRange.Value or 10
    -- Use resolver position as base if enabled
    local basePos = target_root.Position
    if Toggles.ResolverEnabled and Toggles.ResolverEnabled.Value and CSyncData.current_target then
        local resolved = ResolverGetPosition(CSyncData.current_target)
        if resolved then basePos = resolved end
    end
    local strafeRange  = range
    local strafeHeight = 0
    if RagebotTarget then
        strafeRange  = Options.RagebotStrafeRange.Value  or range
        strafeHeight = Options.RagebotStrafeHeight.Value or 5
    end
    local rx = math.random(-strafeRange, strafeRange)
    local ry = math.random(-strafeHeight, strafeHeight)
    local rz = math.random(-strafeRange, strafeRange)
    local random_strafe_cframe = CFrame.new(basePos + Vector3.new(rx, ry, rz))
    CSyncData.strafe_cframe = random_strafe_cframe
    
    -- Update 2D indicator
    if Toggles.CSyncIndicator and Toggles.CSyncIndicator.Value then
        SetIndicatorPosition(random_strafe_cframe.Position)
    else
        HideIndicator()
    end
    
    -- Save real position and apply desync
    CSyncData.saved_desync = client_root.CFrame
    client_root.CFrame = random_strafe_cframe
    
    -- Wait one frame
    RunService.RenderStepped:Wait()
    
    -- Return to real position
    client_root.CFrame = CSyncData.saved_desync
end)

-- ─────────────────────────────────────────────────────────────
-- AUTO MASK LOGIC
-- ─────────────────────────────────────────────────────────────

local AutoMaskBuying = false

local function HasMask()
    -- Check if player already has mask in inventory
    local backpack = LocalPlayer.Backpack
    local char = LocalPlayer.Character
    
    -- Check backpack
    if backpack:FindFirstChild('Mask') or backpack:FindFirstChild('Surgeon Mask') or backpack:FindFirstChild('SurgeonMask') then
        return true
    end
    
    -- Check equipped in character
    if char and (char:FindFirstChild('Mask') or char:FindFirstChild('Surgeon Mask') or char:FindFirstChild('SurgeonMask')) then
        return true
    end
    
    return false
end

local function BuyAndEquipMask()
    if AutoMaskBuying then return end
    if HasMask() then return end
    
    AutoMaskBuying = true
    
    local char = LocalPlayer.Character
    if not char then 
        AutoMaskBuying = false
        return 
    end
    
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then 
        AutoMaskBuying = false
        return 
    end
    
    -- Save original position
    local originalPos = hrp.CFrame
    
    -- Find mask shop
    local maskShop = nil
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA('Model') and (obj.Name:find('Surgeon Mask') or obj.Name:find('SurgeonMask')) then
            maskShop = obj
            break
        end
    end
    
    if maskShop then
        local head = maskShop:FindFirstChild('Head')
        local cd = maskShop:FindFirstChild('ClickDetector')
        
        if head and cd then
            -- Teleport to mask pad
            hrp.CFrame = head.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.3)
            
            -- Buy mask
            pcall(function()
                fireclickdetector(cd)
            end)
            
            task.wait(0.3)
            
            -- Teleport back
            hrp.CFrame = originalPos
            
            task.wait(0.5)
            
            -- Equip mask if we have it
            local mask = LocalPlayer.Backpack:FindFirstChild('Mask') or 
                        LocalPlayer.Backpack:FindFirstChild('Surgeon Mask') or 
                        LocalPlayer.Backpack:FindFirstChild('SurgeonMask')
            
            if mask and mask:IsA('Tool') then
                local hum = char:FindFirstChildOfClass('Humanoid')
                if hum then
                    -- Equip the mask tool
                    hum:EquipTool(mask)
                    task.wait(0.7) -- Wait for tool to fully equip
                    
                    -- Activate the tool (click/hold) to ready it
                    pcall(function()
                        mask:Activate()
                    end)
                    
                    task.wait(0.3) -- Wait a moment after activation
                    
                    -- Now press E to put on mask
                    pcall(function()
                        keypress(0x45) -- E key
                        task.wait(0.2)
                        keyrelease(0x45)
                    end)
                    
                    task.wait(0.2)
                end
            end
        end
    end
    
    task.wait(3)
    AutoMaskBuying = false
end

-- Monitor for auto mask
RunService.Heartbeat:Connect(function()
    if not Toggles.AutoMaskEnabled or not Toggles.AutoMaskEnabled.Value then return end
    if AutoMaskBuying then return end
    if HasMask() then return end
    
    BuyAndEquipMask()
end)

-- ─────────────────────────────────────────────────────────────
-- ANTI STOMP WITH RETURN TO DEATH POSITION
-- ─────────────────────────────────────────────────────────────

local AntiStompDeathPosition = nil
local AntiStompTriggered = false
local AntiStompShouldReturn = false

-- Monitor for low health
task.spawn(function()
    task.wait(2)
    while task.wait(0.1) do
        if Toggles.AntiStompEnabled and Toggles.AntiStompEnabled.Value then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass('Humanoid')
                local hrp = char:FindFirstChild('HumanoidRootPart')
                
                if hum and hrp and hum.Health > 0 and hum.Health <= 10 and not AntiStompTriggered then
                    AntiStompTriggered = true
                    
                    -- Save death position if return option is enabled
                    if Toggles.AntiStompReturnToPosition and Toggles.AntiStompReturnToPosition.Value then
                        AntiStompDeathPosition = hrp.CFrame
                        AntiStompShouldReturn = true
                    end
                    
                    -- Force reset
                    task.wait(0.1)
                    if LocalPlayer.Character then
                        LocalPlayer.Character:BreakJoints()
                    end
                end
            end
        end
    end
end)

-- Return to death position after respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    AntiStompTriggered = false -- Reset trigger flag
    
    if AntiStompShouldReturn and AntiStompDeathPosition then
        task.spawn(function()
            task.wait(1) -- Wait for character to fully load
            
            local hrp = char:FindFirstChild('HumanoidRootPart')
            if hrp and AntiStompDeathPosition then
                hrp.CFrame = AntiStompDeathPosition
                Library:Notify('Returned to death position', 2)
            end
            
            -- Clear after teleporting
            AntiStompDeathPosition = nil
            AntiStompShouldReturn = false
        end)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- AUTO ARMOR LOGIC
-- ─────────────────────────────────────────────────────────────

local AutoArmorBuying = false

local function GetCurrentArmor()
    local char = LocalPlayer.Character
    if not char then return 100 end
    
    local bodyEffects = char:FindFirstChild('BodyEffects')
    if bodyEffects then
        local armor = bodyEffects:FindFirstChild('Armor')
        if armor and armor:IsA('NumberValue') then
            return armor.Value
        end
    end
    return 100
end

local function BuyArmor()
    if AutoArmorBuying then return end
    AutoArmorBuying = true
    
    local char = LocalPlayer.Character
    if not char then 
        AutoArmorBuying = false
        return 
    end
    
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then 
        AutoArmorBuying = false
        return 
    end
    
    -- Save original position
    local originalPos = hrp.CFrame
    
    -- Find armor shop
    local armorShop = nil
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA('Model') and obj.Name:find('Full Armor') then
            armorShop = obj
            break
        end
    end
    
    if armorShop then
        local head = armorShop:FindFirstChild('Head')
        local cd = armorShop:FindFirstChild('ClickDetector')
        
        if head and cd then
            -- Teleport to armor pad
            hrp.CFrame = head.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.3)
            
            -- Buy once
            pcall(function()
                fireclickdetector(cd)
            end)
            
            task.wait(0.3)
            
            -- Teleport back
            hrp.CFrame = originalPos
        end
    end
    
    task.wait(3)
    AutoArmorBuying = false
end

-- Monitor armor
RunService.Heartbeat:Connect(function()
    if not Toggles.AutoArmorEnabled or not Toggles.AutoArmorEnabled.Value then return end
    if AutoArmorBuying then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local bodyEffects = char:FindFirstChild('BodyEffects')
    if not bodyEffects then return end
    
    local armor = bodyEffects:FindFirstChild('Armor')
    if not armor then return end
    
    -- Buy if armor is less than 70
    if armor.Value < 70 then
        BuyArmor()
    end
end)

-- ─────────────────────────────────────────────────────────────
-- JUMP POWER LOGIC
-- ─────────────────────────────────────────────────────────────

RunService.Heartbeat:Connect(function()
    if Toggles.JumpPowerEnabled and Toggles.JumpPowerEnabled.Value then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hum then
                hum.JumpPower = Options.JumpPowerValue.Value
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- INFINITE JUMP
-- ─────────────────────────────────────────────────────────────

UserInputService.JumpRequest:Connect(function()
    if Toggles.InfiniteJumpEnabled and Toggles.InfiniteJumpEnabled.Value then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- NO SLOW (Remove movement slowdown when shooting)
-- ─────────────────────────────────────────────────────────────

task.spawn(function()
    task.wait(2)
    while task.wait(0.1) do
        if Toggles.NoSlowEnabled and Toggles.NoSlowEnabled.Value then
            local char = LocalPlayer.Character
            if char then
                local bodyEffects = char:FindFirstChild('BodyEffects')
                if bodyEffects then
                    local movement = bodyEffects:FindFirstChild('Movement')
                    if movement then
                        local noJumping = movement:FindFirstChild('NoJumping')
                        local noWalkSpeed = movement:FindFirstChild('NoWalkSpeed')
                        
                        if noJumping and noJumping.Value == true then
                            noJumping.Value = false
                        end
                        
                        if noWalkSpeed and noWalkSpeed.Value == true then
                            noWalkSpeed.Value = false
                        end
                    end
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- FOV DRAWING SYSTEM (Legitbot & Camlock)
-- ─────────────────────────────────────────────────────────────

local FOVCircle = Drawing.new('Circle')
FOVCircle.Thickness   = 2
FOVCircle.NumSides    = 64
FOVCircle.Filled      = false
FOVCircle.Visible     = false
FOVCircle.Transparency = 1
FOVCircle.Color       = Color3.fromRGB(255, 255, 255)

local FOVDots = {}
for i = 1, 24 do
    local dot = Drawing.new('Circle')
    dot.Thickness = 1
    dot.Radius    = 3
    dot.Filled    = true
    dot.Visible   = false
    dot.Transparency = 1
    FOVDots[i] = dot
end

-- Camlock FOV Circle (separate from Legitbot)
local CamlockFOVCircle = Drawing.new('Circle')
CamlockFOVCircle.Thickness   = 2
CamlockFOVCircle.NumSides    = 64
CamlockFOVCircle.Filled      = false
CamlockFOVCircle.Visible     = false
CamlockFOVCircle.Transparency = 1
CamlockFOVCircle.Color       = Color3.fromRGB(100, 200, 255)

local CamlockFOVDots = {}
for i = 1, 24 do
    local dot = Drawing.new('Circle')
    dot.Thickness = 1
    dot.Radius    = 3
    dot.Filled    = true
    dot.Visible   = false
    dot.Transparency = 1
    CamlockFOVDots[i] = dot
end

-- Custom Crosshair
local CrosshairLines = {}
local crosshairAngle = 0

for i = 1, 4 do
    -- Outline
    local outline = Drawing.new('Line')
    outline.Thickness = 3
    outline.Color = Color3.fromRGB(0, 0, 0)
    outline.Visible = false
    outline.Transparency = 1
    
    -- Main line
    local main = Drawing.new('Line')
    main.Thickness = 2
    main.Color = Color3.fromRGB(0, 255, 0)
    main.Visible = false
    main.Transparency = 1
    
    CrosshairLines[i] = {outline = outline, main = main}
end

-- Target Ring
local TargetRing = {
    outline = nil,
    fill = nil,
    scanOffset = 0
}

local function CreateTargetRing()
    if not TargetRing.fill then
        -- Flat horizontal cylinder - OUTLINE (slightly larger, black)
        TargetRing.outline = Instance.new('Part')
        TargetRing.outline.Size = Vector3.new(7, 0.01, 7)
        TargetRing.outline.Material = Enum.Material.Neon
        TargetRing.outline.Color = Color3.fromRGB(0, 0, 0)
        TargetRing.outline.Anchored = true
        TargetRing.outline.CanCollide = false
        TargetRing.outline.Transparency = 0
        TargetRing.outline.CastShadow = false
        local om = Instance.new('CylinderMesh', TargetRing.outline)
        om.Scale = Vector3.new(1, 1, 1)

        -- Flat horizontal cylinder - FILL (colored, semi transparent)
        TargetRing.fill = Instance.new('Part')
        TargetRing.fill.Size = Vector3.new(6.5, 0.01, 6.5)
        TargetRing.fill.Material = Enum.Material.Neon
        TargetRing.fill.Color = Color3.fromRGB(255, 0, 0)
        TargetRing.fill.Anchored = true
        TargetRing.fill.CanCollide = false
        TargetRing.fill.Transparency = 0.35
        TargetRing.fill.CastShadow = false
        local fm = Instance.new('CylinderMesh', TargetRing.fill)
        fm.Scale = Vector3.new(1, 1, 1)
    end
end

CreateTargetRing()

-- Target Stats Drawing (beside mouse)
local TargetStatsText = Drawing.new('Text')
TargetStatsText.Size = 14
TargetStatsText.Center = false
TargetStatsText.Outline = true
TargetStatsText.Color = Color3.fromRGB(255, 255, 255)
TargetStatsText.Visible = false

local TargetHealthText = Drawing.new('Text')
TargetHealthText.Size = 13
TargetHealthText.Center = false
TargetHealthText.Outline = true
TargetHealthText.Color = Color3.fromRGB(0, 255, 0)
TargetHealthText.Visible = false

local function HSVToRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    return Color3.fromRGB(r * 255, g * 255, b * 255)
end

-- ─────────────────────────────────────────────────────────────
-- TARGET TRACER DRAWINGS
-- ─────────────────────────────────────────────────────────────

local TargetTracerOutline = Drawing.new('Line')
TargetTracerOutline.Thickness = 3
TargetTracerOutline.Color     = Color3.fromRGB(0, 0, 0)
TargetTracerOutline.Visible   = false

local TargetTracerMain = Drawing.new('Line')
TargetTracerMain.Thickness = 1
TargetTracerMain.Color     = Color3.fromRGB(255, 50, 50)
TargetTracerMain.Visible   = false

-- ─────────────────────────────────────────────────────────────
-- PROFESSIONAL ESP SYSTEM
-- ─────────────────────────────────────────────────────────────

local function CreateDrawing(type, properties)
    local drawing = Drawing.new(type)
    for prop, value in pairs(properties or {}) do
        drawing[prop] = value
    end
    return drawing
end

local ESPObjects = {}

local ESP_GRADIENT_SEGMENTS = 20
local ESP_BOX_SEGMENTS = 20
local ESP_FILL_SEGMENTS = 200  -- 1px lines for smooth gradient

local function CreateESP(player)
    local healthSegs = {}
    for i = 1, ESP_GRADIENT_SEGMENTS do
        healthSegs[i] = CreateDrawing('Square', {Thickness = 1, Filled = true})
    end
    local boxSides = {}
    for s = 1, 4 do
        boxSides[s] = {}
        for i = 1, ESP_BOX_SEGMENTS do
            boxSides[s][i] = CreateDrawing('Line', {Thickness = 1})
        end
    end
    local fillLines = {}
    for i = 1, ESP_FILL_SEGMENTS do
        fillLines[i] = CreateDrawing('Line', {Thickness = 2})
    end
    return {
        player = player,
        box_outline = CreateDrawing('Square', {Thickness = 2, Filled = false}),
        box_gradient = CreateDrawing('Square', {Thickness = 2, Filled = false}),
        box_inner = CreateDrawing('Square', {Thickness = 1, Filled = false}),
        box_inline  = CreateDrawing('Square', {Thickness = 1, Filled = false}),
        box_fill    = CreateDrawing('Square', {Thickness = 1, Filled = true}),
        box_sides   = boxSides,
        fill_lines  = fillLines,
        health_bg   = CreateDrawing('Square', {Thickness = 1, Filled = true}),
        health_bar  = CreateDrawing('Square', {Thickness = 1, Filled = true}),
        health_segs = healthSegs,
        health_outline = CreateDrawing('Square', {Thickness = 1, Filled = false}),
        name_text   = CreateDrawing('Text',   {Center = true, Outline = true, Size = 13, Font = 2}),
        distance_text = CreateDrawing('Text', {Center = true, Outline = true, Size = 12, Font = 2}),
        tracer      = CreateDrawing('Line',   {Thickness = 1}),
    }
end

local function RemoveESP(player)
    if ESPObjects[player] then
        local obj = ESPObjects[player]
        if obj.health_segs then
            for _, seg in ipairs(obj.health_segs) do pcall(function() seg:Remove() end) end
        end
        if obj.box_sides then
            for _, side in ipairs(obj.box_sides) do
                for _, seg in ipairs(side) do pcall(function() seg:Remove() end) end
            end
        end
        if obj.fill_lines then
            for _, l in ipairs(obj.fill_lines) do pcall(function() l:Remove() end) end
        end
        for k, drawing in pairs(obj) do
            if k ~= 'health_segs' and k ~= 'box_sides' and k ~= 'fill_lines' and typeof(drawing) == 'userdata' and drawing.Remove then
                pcall(function() drawing:Remove() end)
            end
        end
        ESPObjects[player] = nil
    end
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        ESPObjects[player] = CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        ESPObjects[player] = CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- ─────────────────────────────────────────────────────────────
-- TARGET FINDING (Legitbot & Camlock)
-- ─────────────────────────────────────────────────────────────

local CurrentTarget = nil
local CamlockTarget = nil

-- Rain system variables
local RainPart = nil
local RainParticle = nil

task.spawn(function()
    task.wait(2)
    if not Toggles.AimbotEnabled then return end
    Toggles.AimbotEnabled:OnChanged(function()
        if not Toggles.AimbotEnabled.Value then
            CurrentTarget = nil
        end
    end)
end)

task.spawn(function()
    task.wait(2)
    if not Toggles.CamlockEnabled then return end
    Toggles.CamlockEnabled:OnChanged(function()
        if not Toggles.CamlockEnabled.Value then
            CamlockTarget = nil
        end
    end)
end)

local function GetClosestTarget()
    local mousePos  = Vector2.new(Mouse.X, Mouse.Y)
    local radius    = Options.FOVRadius.Value
    local partName  = Options.TargetPart.Value
    local teamCheck = Toggles.TeamCheck.Value
    local visCheck  = Toggles.VisibleCheck.Value
    local friendCheck = Toggles.FriendCheck.Value
    local myTeam    = LocalPlayer.Team

    local bestDist  = math.huge
    local bestPart  = nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if teamCheck and myTeam and player.Team == myTeam then continue end
        if friendCheck and player:IsFriendsWith(LocalPlayer.UserId) then continue end

        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass('Humanoid')
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(partName)
        if not part then continue end

        -- Visible check
        if visCheck then
            local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
            local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, char})
            if hit then continue end -- Something blocking, skip target
        end

        local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
        if not onScreen or screenPos.Z <= 0 then continue end

        local screenV2 = Vector2.new(screenPos.X, screenPos.Y)
        local dist     = (screenV2 - mousePos).Magnitude

        if Toggles.FOVEnabled.Value and dist > radius then continue end

        if dist < bestDist then
            bestDist = dist
            bestPart = part
        end
    end

    return bestPart
end

-- Camlock target finding (closest to center of screen)
local function GetClosestCamlockTarget()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local radius    = Options.CamlockFOVRadius.Value
    local partName  = Options.CamlockTargetPart.Value
    local teamCheck = Toggles.CamlockTeamCheck.Value
    local visCheck  = Toggles.CamlockVisibleCheck.Value
    local friendCheck = Toggles.CamlockFriendCheck.Value
    local myTeam    = LocalPlayer.Team

    local bestDist  = math.huge
    local bestPart  = nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if teamCheck and myTeam and player.Team == myTeam then continue end
        if friendCheck and player:IsFriendsWith(LocalPlayer.UserId) then continue end

        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass('Humanoid')
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(partName)
        if not part then continue end

        -- Visible check
        if visCheck then
            local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
            local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, char})
            if hit then continue end
        end

        local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
        if not onScreen or screenPos.Z <= 0 then continue end

        local screenV2 = Vector2.new(screenPos.X, screenPos.Y)
        local dist     = (screenV2 - screenCenter).Magnitude

        if Toggles.CamlockFOVEnabled.Value and dist > radius then continue end

        if dist < bestDist then
            bestDist = dist
            bestPart = part
        end
    end

    return bestPart
end

-- ─────────────────────────────────────────────────────────────
-- MOUSE.HIT HOOK (Simple redirect - Ragebot > Legitbot)
-- ─────────────────────────────────────────────────────────────

pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    
    local oldIndex = mt.__index
    
    mt.__index = newcclosure(function(self, key)
        if not checkcaller() and self == Mouse and (key == 'Hit' or key == 'hit' or key == 'Target' or key == 'target') then
            -- Priority 1: Ragebot — CurrentTarget is synced to ragebot target's part every frame
            if Toggles.RagebotEnabled and Toggles.RagebotEnabled.Value and RagebotTarget and RagebotTarget.Character then
                local targetChar = RagebotTarget.Character
                local hum = targetChar:FindFirstChildOfClass('Humanoid')

                if hum and hum.Health > 0 then
                    -- Use synced CurrentTarget part (already the right part, already cached)
                    local targetPart = (CurrentTarget and CurrentTarget.Parent == targetChar and CurrentTarget)
                                    or targetChar:FindFirstChild(Options.TargetPart and Options.TargetPart.Value or 'Head')
                                    or targetChar:FindFirstChild('HumanoidRootPart')

                    if targetPart then
                        local targetPos = targetPart.Position

                        -- Resolver: override XZ with clustered position if enabled
                        if Toggles.ResolverEnabled and Toggles.ResolverEnabled.Value then
                            local resolved = ResolverGetPosition(RagebotTarget)
                            if resolved then
                                targetPos = Vector3.new(resolved.X, targetPart.Position.Y, resolved.Z)
                            end
                        end

                        local velocity = targetPart.AssemblyLinearVelocity or Vector3.zero

                        -- Prediction: base * multiplier
                        local pred = 0.165
                        if Toggles.RagebotPredictionEnabled and Toggles.RagebotPredictionEnabled.Value then
                            local base = (Options.RagebotPredictionBase and Options.RagebotPredictionBase.Value) or 0.07
                            local mult = (Options.RagebotPredictionMultiplier and Options.RagebotPredictionMultiplier.Value) or 2.4
                            pred = base * mult
                        end

                        targetPos = targetPos + (velocity * pred)

                        if key == 'Target' or key == 'target' then
                            return targetPart
                        end
                        return CFrame.new(targetPos)
                    end
                end
            end
            
            -- Priority 2: Camlock target
            if Toggles.CamlockEnabled and Toggles.CamlockEnabled.Value and CamlockTarget and CamlockTarget.Parent then
                local hitChance = Options.CamlockHitChance.Value
                local randomChance = math.random(0, 100)
                
                if randomChance <= hitChance then
                    local targetPos = CamlockTarget.Position
                    
                    -- Only apply prediction if enabled
                    if Toggles.CamlockPredictionEnabled and Toggles.CamlockPredictionEnabled.Value then
                        local pred = Options.CamlockPrediction.Value
                        local velocity = CamlockTarget.AssemblyLinearVelocity or Vector3.zero
                        targetPos = targetPos + velocity * pred
                    end
                    
                    return CFrame.new(targetPos)
                end
            end
            
            -- Priority 3: Legitbot target
            if Toggles.AimbotEnabled and Toggles.AimbotEnabled.Value and CurrentTarget and CurrentTarget.Parent then
                local hitChance = Options.HitChance.Value
                local randomChance = math.random(0, 100)
                
                if randomChance <= hitChance then
                    local targetPos = CurrentTarget.Position
                    
                    -- Only apply prediction if enabled
                    if Toggles.PredictionEnabled and Toggles.PredictionEnabled.Value then
                        local pred = Options.Prediction.Value
                        local velocity = CurrentTarget.AssemblyLinearVelocity or Vector3.zero
                        targetPos = targetPos + velocity * pred
                    end
                    
                    return CFrame.new(targetPos)
                end
            end
        end
        
        return oldIndex(self, key)
    end)
    
    setreadonly(mt, true)
end)

-- ─────────────────────────────────────────────────────────────
-- RAGEBOT AUTO SHOOT
-- Fires mouse1 automatically when ragebot target is set and alive.
-- Bullet redirect from the __index hook still applies to every shot.
-- ─────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────
-- SILENT AIM / FORCE HIT — FireServer hook
-- Replaces ALL position-type args with predicted target position.
-- Works for Ragebot (always), Camlock (when on), Legitbot (ForceHit toggle).
-- ─────────────────────────────────────────────────────────────
local oldFireServer
pcall(function()
    for _, v in pairs(getgc()) do
        if type(v) == "table" and rawget(v, "FireServer") then
            oldFireServer = hookfunction(v.FireServer, newcclosure(function(self, ...)
                local args = {...}

                -- Determine active target character + hit part
                local targetChar = nil
                local isRagebot  = false

                if Toggles.RagebotEnabled and Toggles.RagebotEnabled.Value and RagebotTarget and RagebotTarget.Character then
                    -- CurrentTarget is synced to the ragebot target's part every frame — use it directly
                    targetChar = RagebotTarget.Character
                    isRagebot  = true
                elseif Toggles.CamlockEnabled and Toggles.CamlockEnabled.Value and CamlockTarget and CamlockTarget.Parent then
                    targetChar = CamlockTarget.Parent
                elseif Toggles.ForceHitEnabled and Toggles.ForceHitEnabled.Value and CurrentTarget and CurrentTarget.Parent then
                    targetChar = CurrentTarget.Parent
                end

                if targetChar then
                    local partName   = (Options.TargetPart and Options.TargetPart.Value) or 'HumanoidRootPart'
                    -- For ragebot: prefer the already-synced CurrentTarget part (same as legitbot path)
                    local targetPart
                    if isRagebot and CurrentTarget and CurrentTarget.Parent == targetChar then
                        targetPart = CurrentTarget
                    else
                        targetPart = targetChar:FindFirstChild(partName)
                                  or targetChar:FindFirstChild('HumanoidRootPart')
                    end

                    if targetPart then
                        -- Build predicted position (same prediction logic as Mouse.Hit hook)
                        local targetPos = targetPart.Position
                        local velocity  = targetPart.AssemblyLinearVelocity or Vector3.zero

                        if isRagebot then
                            -- Resolver override (XZ only, keep real Y)
                            if Toggles.ResolverEnabled and Toggles.ResolverEnabled.Value then
                                local resolved = ResolverGetPosition(RagebotTarget)
                                if resolved then
                                    targetPos = Vector3.new(resolved.X, targetPos.Y, resolved.Z)
                                end
                            end

                            local pred = 0.165
                            if Toggles.RagebotPredictionEnabled and Toggles.RagebotPredictionEnabled.Value then
                                local base = (Options.RagebotPredictionBase and Options.RagebotPredictionBase.Value) or 0.07
                                local mult = (Options.RagebotPredictionMultiplier and Options.RagebotPredictionMultiplier.Value) or 2.4
                                pred = base * mult
                            end
                            targetPos = targetPos + velocity * pred
                        end

                        local hitCF = CFrame.new(targetPos)

                        -- Replace every arg that looks like a hit position or part reference
                        for i, arg in ipairs(args) do
                            local t = typeof(arg)
                            if t == 'Instance' and arg:IsA('BasePart') then
                                -- Part arg → replace with actual target part
                                args[i] = targetPart
                            elseif t == 'CFrame' then
                                -- CFrame hit position → replace with predicted CFrame
                                args[i] = hitCF
                            elseif t == 'Vector3' then
                                -- Raw Vector3 hit position → replace with predicted pos
                                args[i] = targetPos
                            end
                        end
                    end
                end

                return oldFireServer(self, unpack(args))
            end))
            break
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- MAX SHOOT DISTANCE MODIFIER (Infinite range for Ragebot + Force Hit)
-- ─────────────────────────────────────────────────────────────

-- Modify gun MaxDistance to allow infinite range
task.spawn(function()
    task.wait(2)
    while task.wait(1) do
        local ragebotActive = Toggles.RagebotEnabled and Toggles.RagebotEnabled.Value and RagebotTarget ~= nil
        if (Toggles.ForceHitEnabled and Toggles.ForceHitEnabled.Value) or ragebotActive then
            local char = LocalPlayer.Character
            if char then
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA('Tool') then
                        -- Find gun configuration
                        for _, obj in pairs(tool:GetDescendants()) do
                            if obj:IsA('NumberValue') and (obj.Name == 'MaxDistance' or obj.Name == 'Range' or obj.Name == 'MaxShootDistance') then
                                obj.Value = 10000 -- Set to very high distance
                            end
                        end
                    end
                end
                
                -- Also check backpack
                for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA('Tool') then
                        for _, obj in pairs(tool:GetDescendants()) do
                            if obj:IsA('NumberValue') and (obj.Name == 'MaxDistance' or obj.Name == 'Range' or obj.Name == 'MaxShootDistance') then
                                obj.Value = 10000
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
-- AIM VIEWER SYSTEM (REMOVED)
-- ─────────────────────────────────────────────────────────────

-- Aim viewer removed per user request

-- ─────────────────────────────────────────────────────────────
-- MAIN RENDER LOOP
-- ─────────────────────────────────────────────────────────────

local spinAngle = 0

-- ─────────────────────────────────────────────────────────────
-- TARGET INFO PANEL
-- ─────────────────────────────────────────────────────────────
local TargetInfoGui = Instance.new('ScreenGui')
TargetInfoGui.Name = 'TargetInfoGui'
TargetInfoGui.ResetOnSpawn = false
TargetInfoGui.DisplayOrder = 999
pcall(function() TargetInfoGui.Parent = game:GetService('CoreGui') end)
if not TargetInfoGui.Parent then TargetInfoGui.Parent = LocalPlayer:WaitForChild('PlayerGui') end

local TIFrame = Instance.new('Frame')
TIFrame.Name = 'TIFrame'
TIFrame.Size = UDim2.new(0, 320, 0, 210)
TIFrame.Position = UDim2.new(0, 100, 0, 200)
TIFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
TIFrame.BackgroundTransparency = 0
TIFrame.BorderSizePixel = 0
TIFrame.Visible = false
TIFrame.Active = true
TIFrame.Parent = TargetInfoGui

-- Title bar
local TITitle = Instance.new('TextLabel')
TITitle.Size = UDim2.new(1, 0, 0, 36)
TITitle.Position = UDim2.new(0, 0, 0, 0)
TITitle.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
TITitle.BackgroundTransparency = 0
TITitle.BorderSizePixel = 0
TITitle.Text = 'Target Info'
TITitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TITitle.Font = Enum.Font.Arial
TITitle.TextSize = 16
TITitle.Parent = TIFrame
-- Cover bottom corners of title
local TITitleCover = Instance.new('Frame')
TITitleCover.Size = UDim2.new(1, 0, 0, 10)
TITitleCover.Position = UDim2.new(0, 0, 1, -10)
TITitleCover.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
TITitleCover.BorderSizePixel = 0
TITitleCover.Parent = TITitle

-- Make draggable via title bar
do
    local dragging, dragStart, startPos
    TITitle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = TIFrame.Position
        end
    end)
    TITitle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    game:GetService('UserInputService').InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            TIFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Inner content box (dark box with slight border)
local TIInner = Instance.new('Frame')
TIInner.Size = UDim2.new(1, -20, 1, -46)
TIInner.Position = UDim2.new(0, 10, 0, 40)
TIInner.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
TIInner.BorderSizePixel = 0
TIInner.Parent = TIFrame

local TIContent = Instance.new('Frame')
TIContent.Size = UDim2.new(1, -16, 1, -12)
TIContent.Position = UDim2.new(0, 8, 0, 6)
TIContent.BackgroundTransparency = 1
TIContent.BorderSizePixel = 0
TIContent.Parent = TIInner

local function makeTIRow(parent, yPos, labelText)
    local row = Instance.new('Frame')
    row.Size = UDim2.new(1, 0, 0, 22)
    row.Position = UDim2.new(0, 0, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new('TextLabel')
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(225, 225, 225)
    lbl.Font = Enum.Font.Arial
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local val = Instance.new('TextLabel')
    val.Size = UDim2.new(0.55, 0, 1, 0)
    val.Position = UDim2.new(0.45, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = '[--]'
    val.TextColor3 = Color3.fromRGB(255, 255, 255)
    val.Font = Enum.Font.Arial
    val.TextSize = 14
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = row
    return val
end

local function makeTIBar(parent, yPos, fillColor, bgColor)
    local bg = Instance.new('Frame')
    bg.Size = UDim2.new(1, 0, 0, 9)
    bg.Position = UDim2.new(0, 0, 0, yPos)
    bg.BackgroundColor3 = bgColor or Color3.fromRGB(30, 30, 30)
    bg.BorderSizePixel = 0
    bg.Parent = parent
    local fill = Instance.new('Frame')
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = fillColor
    fill.BorderSizePixel = 0
    fill.Parent = bg
    return fill
end

-- Layout matching the reference image:
-- Target row, Health row + bar, Armor row + bar, Gun row
local TITargetVal  = makeTIRow(TIContent, 0,   'Target')
local TIHealthVal  = makeTIRow(TIContent, 26,  'Health')
local TIHealthBar  = makeTIBar(TIContent, 50,  Color3.fromRGB(255, 255, 255), Color3.fromRGB(25, 25, 25))
local TIArmorVal   = makeTIRow(TIContent, 68,  'Armor')
local TIArmorBar   = makeTIBar(TIContent, 92,  Color3.fromRGB(40, 40, 40), Color3.fromRGB(25, 25, 25))
local TIGunVal     = makeTIRow(TIContent, 110, 'Gun')

-- Health bar gradient (low=red → mid=yellow → high=green)
local TIHealthGradient = Instance.new('UIGradient')
TIHealthGradient.Rotation = 0
TIHealthGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(210, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(210, 180, 0)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 210, 0)),
})
TIHealthGradient.Parent = TIHealthBar

local ESPFillAngle = 0  -- rotating fill angle in radians

local Connection
task.spawn(function()
    task.wait(2)
    Connection = RunService.RenderStepped:Connect(function(deltaTime)
    if Library.Unloaded then
        FOVCircle:Remove()
        for _, dot in pairs(FOVDots) do
            dot:Remove()
        end
        CamlockFOVCircle:Remove()
        for _, dot in pairs(CamlockFOVDots) do
            dot:Remove()
        end
        for i = 1, 4 do
            CrosshairLines[i].outline:Remove()
            CrosshairLines[i].main:Remove()
        end
        if TargetRing.fill then
            TargetRing.fill:Destroy()
        end
        if TargetRing.outline then
            TargetRing.outline:Destroy()
        end
        for player in pairs(ESPObjects) do
            RemoveESP(player)
        end
        Connection:Disconnect()
        return
    end

    local mousePos = UserInputService:GetMouseLocation()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Update fill rotation angle
    if Toggles.ESPFillRotate and Toggles.ESPFillRotate.Value then
        local speed = Options.ESPFillRotateSpeed and Options.ESPFillRotateSpeed.Value or 1
        local dir = (Options.ESPFillRotateDir and Options.ESPFillRotateDir.Value == 'Counter-Clockwise') and -1 or 1
        ESPFillAngle = ESPFillAngle + dir * speed * deltaTime
    end

    -- Update target for legitbot
    if Toggles.AimbotEnabled.Value then
        local sticky = Toggles.StickyAim.Value

        if sticky and CurrentTarget then
            local char = CurrentTarget.Parent
            local hum  = char and char:FindFirstChildOfClass('Humanoid')
            -- Clear target if they died or character is gone
            if not char or not hum or hum.Health <= 0 or not CurrentTarget.Parent then
                CurrentTarget = nil
                LastTargetHealth = nil
            end
        end

        if not sticky or not CurrentTarget then
            CurrentTarget = GetClosestTarget()
            if CurrentTarget then
                local char = CurrentTarget.Parent
                local hum  = char and char:FindFirstChildOfClass('Humanoid')
                if hum then
                    LastTargetHealth = hum.Health
                end
            else
                LastTargetHealth = nil
            end
        end
        
        -- Monitor legitbot target health for hit sounds/overlay
        if CurrentTarget and CurrentTarget.Parent then
            local char = CurrentTarget.Parent
            local hum  = char:FindFirstChildOfClass('Humanoid')
            if hum then
                if LastTargetHealth and hum.Health < LastTargetHealth then
                    local damage = math.floor(LastTargetHealth - hum.Health)
                    local player = Players:GetPlayerFromCharacter(char)
                    local partName = CurrentTarget.Name or 'Unknown'
                    
                    PlayHitSound()
                    FlashHitOverlay()
                    CreateDamageNumber(char, damage)
                    
                    if player then
                        CreateHitNotification(player.Name, damage, partName)
                    end
                end
                LastTargetHealth = hum.Health
            else
                -- Humanoid is gone, clear target
                CurrentTarget = nil
                LastTargetHealth = nil
            end
        end
    else
        CurrentTarget = nil
        LastTargetHealth = nil
    end

    -- ── RAGEBOT → CurrentTarget sync ─────────────────────────────────────────
    -- Runs AFTER the legitbot block so it always wins regardless of AimbotEnabled.
    -- Forces CurrentTarget to the ragebot target's part so ragebot rides the
    -- exact same Mouse.Hit + FireServer hit pipeline as legitbot.
    if Toggles.RagebotEnabled and Toggles.RagebotEnabled.Value and RagebotTarget then
        local char = RagebotTarget.Character
        if char then
            local partName = Options.TargetPart and Options.TargetPart.Value or 'Head'
            local part = char:FindFirstChild(partName) or char:FindFirstChild('HumanoidRootPart')
            if part then
                CurrentTarget = part
            end
        end
    end
    -- ─────────────────────────────────────────────────────────────────────────

    -- Update Camlock target
    if Toggles.CamlockEnabled and Toggles.CamlockEnabled.Value then
        local sticky = Toggles.CamlockStickyAim.Value

        if sticky and CamlockTarget then
            local char = CamlockTarget.Parent
            local hum  = char and char:FindFirstChildOfClass('Humanoid')
            if not char or not hum or hum.Health <= 0 or not CamlockTarget.Parent then
                CamlockTarget = nil
                LastCamlockHealth = nil
            end
        end

        if not sticky or not CamlockTarget then
            CamlockTarget = GetClosestCamlockTarget()
            if CamlockTarget then
                local char = CamlockTarget.Parent
                local hum  = char and char:FindFirstChildOfClass('Humanoid')
                if hum then
                    LastCamlockHealth = hum.Health
                end
            else
                LastCamlockHealth = nil
            end
        end
        
        -- Lock camera to target with smoothness
        if CamlockTarget and CamlockTarget.Parent then
            local char = CamlockTarget.Parent
            local hum  = char:FindFirstChildOfClass('Humanoid')
            if hum then
                -- Monitor camlock target health for hit sounds/overlay
                if LastCamlockHealth and hum.Health < LastCamlockHealth then
                    local damage = math.floor(LastCamlockHealth - hum.Health)
                    local player = Players:GetPlayerFromCharacter(char)
                    local partName = CamlockTarget.Name or 'Unknown'
                    
                    PlayHitSound()
                    FlashHitOverlay()
                    CreateDamageNumber(char, damage)
                    
                    if player then
                        CreateHitNotification(player.Name, damage, partName)
                    end
                end
                LastCamlockHealth = hum.Health
                
                local targetPos = CamlockTarget.Position
                
                -- Apply prediction if enabled
                if Toggles.CamlockPredictionEnabled and Toggles.CamlockPredictionEnabled.Value then
                    local pred = Options.CamlockPrediction.Value
                    local velocity = CamlockTarget.AssemblyLinearVelocity or Vector3.zero
                    targetPos = targetPos + velocity * pred
                end
                
                -- Apply smoothness (lerp camera)
                local smoothX = Options.CamlockSmoothnessX.Value
                local smoothY = Options.CamlockSmoothnessY.Value
                local smoothZ = Options.CamlockSmoothnessZ.Value
                
                local currentCF = Camera.CFrame
                local targetCF = CFrame.new(currentCF.Position, targetPos)
                
                -- Lerp with different smoothness per axis
                local lerpedCF = currentCF:Lerp(targetCF, 1 / math.max(smoothX, smoothY, smoothZ))
                Camera.CFrame = lerpedCF
            else
                CamlockTarget = nil
                LastCamlockHealth = nil
            end
        end
    else
        CamlockTarget = nil
        LastCamlockHealth = nil
    end
    
    -- Monitor ragebot target health for hit sounds/overlay (NO AUTO STOMP - causes kick)
    if RagebotTarget and RagebotTarget.Character then
        local char = RagebotTarget.Character
        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum then
            -- Initialize health if this is a new target
            if LastRagebotHealth == nil then
                LastRagebotHealth = hum.Health
            -- Check if health decreased (hit detected)
            elseif hum.Health < LastRagebotHealth then
                local damage = math.floor(LastRagebotHealth - hum.Health)
                local partName = (CurrentTarget and CurrentTarget.Name) or (Options.TargetPart and Options.TargetPart.Value) or 'Head'
                
                PlayHitSound()
                FlashHitOverlay()
                CreateDamageNumber(char, damage)
                CreateHitNotification(RagebotTarget.Name, damage, partName)
                
                LastRagebotHealth = hum.Health
            -- Update health (handles healing)
            else
                LastRagebotHealth = hum.Health
            end
        else
            LastRagebotHealth = nil
        end
    else
        LastRagebotHealth = nil
    end

    -- Spectate (priority: Ragebot > Camlock > Legitbot)
    -- Check if "View" is selected in RagebotSettings dropdown (multi-select: Value is {["View"]=true})
    local shouldSpectateRagebot = Options.RagebotSettings
        and Options.RagebotSettings.Value
        and Options.RagebotSettings.Value["View"] == true

    if shouldSpectateRagebot and RagebotTarget and RagebotTarget.Character then
        local char = RagebotTarget.Character
        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum and hum.Health > 0 then
            if not OriginalCameraSubject then
                OriginalCameraSubject = Camera.CameraSubject
            end
            Camera.CameraSubject = hum
        else
            -- Target dead or no humanoid — restore to self
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
            if myHum then Camera.CameraSubject = myHum end
            OriginalCameraSubject = nil
        end
    elseif Toggles.SpectateTarget.Value and CamlockTarget and CamlockTarget.Parent then
        local char = CamlockTarget.Parent
        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum then
            if not OriginalCameraSubject then
                OriginalCameraSubject = Camera.CameraSubject
            end
            Camera.CameraSubject = hum
        end
    elseif Toggles.SpectateTarget.Value and CurrentTarget and CurrentTarget.Parent then
        local char = CurrentTarget.Parent
        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum then
            if not OriginalCameraSubject then
                OriginalCameraSubject = Camera.CameraSubject
            end
            Camera.CameraSubject = hum
        end
    else
        if OriginalCameraSubject then
            Camera.CameraSubject = OriginalCameraSubject
            OriginalCameraSubject = nil
        end
    end
    
    -- Look at Target (face character toward locked target)
    if Toggles.LookAtTarget and Toggles.LookAtTarget.Value and CurrentTarget and CurrentTarget.Parent then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild('HumanoidRootPart')
            if hrp then
                local targetPos = CurrentTarget.Position
                local lookAt = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                hrp.CFrame = lookAt
            end
        end
    end
    
    -- Target Stats beside mouse (for Ragebot, Legitbot, or Camlock)
    if Toggles.RagebotTargetStats and Toggles.RagebotTargetStats.Value then
        local alwaysShow = Toggles.RagebotTargetStatsAlwaysShow and Toggles.RagebotTargetStatsAlwaysShow.Value
        
        -- Determine which target to show
        local displayTarget = nil
        local displayName = "None"
        
        -- Priority: Ragebot then Camlock then Legitbot
        if RagebotTarget and RagebotTarget.Character then
            displayTarget = RagebotTarget.Character
            displayName = RagebotTarget.Name
        elseif CamlockTarget and CamlockTarget.Parent then
            displayTarget = CamlockTarget.Parent
            local player = Players:GetPlayerFromCharacter(CamlockTarget.Parent)
            if player then
                displayName = player.Name
            else
                displayName = "Unknown"
            end
        elseif CurrentTarget and CurrentTarget.Parent then
            displayTarget = CurrentTarget.Parent
            local player = Players:GetPlayerFromCharacter(CurrentTarget.Parent)
            if player then
                displayName = player.Name
            else
                displayName = "Unknown"
            end
        end
        
        if alwaysShow or displayTarget then
            local mouseX = mousePos.X + 20
            local mouseY = mousePos.Y
            
            if displayTarget then
                local hum = displayTarget:FindFirstChildOfClass('Humanoid')
                
                if hum then
                    -- Target name
                    TargetStatsText.Position = Vector2.new(mouseX, mouseY)
                    TargetStatsText.Text = "Target: " .. displayName
                    TargetStatsText.Visible = true
                    
                    -- Health
                    TargetHealthText.Position = Vector2.new(mouseX, mouseY + 15)
                    TargetHealthText.Text = string.format("Health: %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
                    
                    -- Color based on health
                    local healthPercent = hum.Health / hum.MaxHealth
                    if healthPercent > 0.6 then
                        TargetHealthText.Color = Color3.fromRGB(0, 255, 0)
                    elseif healthPercent > 0.3 then
                        TargetHealthText.Color = Color3.fromRGB(255, 255, 0)
                    else
                        TargetHealthText.Color = Color3.fromRGB(255, 0, 0)
                    end
                    
                    TargetHealthText.Visible = true
                else
                    TargetStatsText.Visible = false
                    TargetHealthText.Visible = false
                end
            elseif alwaysShow then
                -- Show "No Target" when always show is enabled
                TargetStatsText.Position = Vector2.new(mouseX, mouseY)
                TargetStatsText.Text = "Target: None"
                TargetStatsText.Visible = true
                
                TargetHealthText.Position = Vector2.new(mouseX, mouseY + 15)
                TargetHealthText.Text = "Health: 0/0"
                TargetHealthText.Color = Color3.fromRGB(255, 0, 0)
                TargetHealthText.Visible = true
            else
                TargetStatsText.Visible = false
                TargetHealthText.Visible = false
            end
        else
            TargetStatsText.Visible = false
            TargetHealthText.Visible = false
        end
    else
        TargetStatsText.Visible = false
        TargetHealthText.Visible = false
    end
    
    -- Spectate selected player from Misc
    if Toggles.MiscSpectatePlayer and Toggles.MiscSpectatePlayer.Value then
        local selectedName = Options.MiscPlayerSelect.Value
        if selectedName and selectedName ~= "No players available" and selectedName ~= "Loading..." then
            local targetPlayer = Players:FindFirstChild(selectedName)
            if targetPlayer and targetPlayer.Character then
                local hum = targetPlayer.Character:FindFirstChildOfClass('Humanoid')
                if hum then
                    if not OriginalCameraSubject then
                        OriginalCameraSubject = Camera.CameraSubject
                    end
                    Camera.CameraSubject = hum
                end
            end
        end
    elseif not (Options.RagebotSettings and Options.RagebotSettings.Value and Options.RagebotSettings.Value["View"] == true) then
        if not (Toggles.SpectateTarget and Toggles.SpectateTarget.Value) then
            if OriginalCameraSubject and Camera.CameraSubject ~= OriginalCameraSubject then
                -- Always restore to own humanoid to avoid dead camera subjects
                local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
                if myHum then
                    Camera.CameraSubject = myHum
                else
                    Camera.CameraSubject = OriginalCameraSubject
                end
                OriginalCameraSubject = nil
            end
        end
    end

    -- FOV — always show when FOVEnabled is on (Legitbot FOV - follows mouse)
    if Toggles.FOVEnabled.Value then
        local radius      = Options.FOVRadius.Value
        local rainbow     = Toggles.FOVRainbow.Value
        local mainColor   = rainbow and HSVToRGB((tick() % 1), 1, 1) or Options.FOVColor.Value
        local outlineColor = Options.FOVOutlineColor.Value
        local fillColor   = rainbow and HSVToRGB((tick() % 1), 1, 1) or Options.FOVFillColor.Value
        local filled      = Toggles.FOVFilled.Value
        local fillTrans   = Options.FOVFillTransparency.Value

        -- Black outline circle (rendered first, behind everything)
        if not FOVDots._blackOutline then
            FOVDots._blackOutline = Drawing.new('Circle')
            FOVDots._blackOutline.Filled    = false
            FOVDots._blackOutline.Thickness = 2
            FOVDots._blackOutline.NumSides  = 64
        end
        FOVDots._blackOutline.Position = mousePos
        FOVDots._blackOutline.Radius   = radius + 1
        FOVDots._blackOutline.Color    = outlineColor
        FOVDots._blackOutline.Visible  = true

        -- Main color outline (on top of black)
        if not FOVDots._outlineCircle then
            FOVDots._outlineCircle = Drawing.new('Circle')
            FOVDots._outlineCircle.Filled    = false
            FOVDots._outlineCircle.Thickness = 1
            FOVDots._outlineCircle.NumSides  = 64
        end
        FOVDots._outlineCircle.Position = mousePos
        FOVDots._outlineCircle.Radius   = radius
        FOVDots._outlineCircle.Color    = mainColor
        FOVDots._outlineCircle.Visible  = true

        -- Fill circle behind both outlines
        if filled then
            FOVCircle.Filled       = true
            FOVCircle.Color        = fillColor
            FOVCircle.Transparency = fillTrans
            FOVCircle.Position     = mousePos
            FOVCircle.Radius       = radius - 1
            FOVCircle.Visible      = true
        else
            FOVCircle.Visible = false
        end

        -- Spinning dots
        spinAngle = spinAngle + (Options.FOVSpinSpeed.Value * deltaTime)
        local doSpin   = Toggles.FOVSpinningDots.Value
        local dotCount = math.floor(Options.FOVDotCount.Value)
        if not FOVDots._dots then FOVDots._dots = {} end

        if doSpin then
            for i = 1, dotCount do
                if not FOVDots._dots[i] then
                    FOVDots._dots[i] = Drawing.new('Circle')
                    FOVDots._dots[i].Radius    = 3
                    FOVDots._dots[i].Filled    = true
                    FOVDots._dots[i].Thickness = 1
                end
                local angle = spinAngle + (i / dotCount) * math.pi * 2
                FOVDots._dots[i].Position = Vector2.new(
                    mousePos.X + math.cos(angle) * radius,
                    mousePos.Y + math.sin(angle) * radius
                )
                FOVDots._dots[i].Color   = rainbow and HSVToRGB((tick() * 0.5 + i * (1/dotCount)) % 1, 1, 1) or mainColor
                FOVDots._dots[i].Visible = true
            end
            for i = dotCount + 1, 32 do
                if FOVDots._dots[i] then FOVDots._dots[i].Visible = false end
            end
        else
            if FOVDots._dots then
                for _, d in pairs(FOVDots._dots) do d.Visible = false end
            end
        end

    else
        FOVCircle.Visible = false
        if FOVDots._blackOutline then FOVDots._blackOutline.Visible = false end
        if FOVDots._outlineCircle then FOVDots._outlineCircle.Visible = false end
        if FOVDots._dots then for _, d in pairs(FOVDots._dots) do d.Visible = false end end
    end
    
    -- Camlock FOV — always show when CamlockFOVEnabled is on (center of screen)
    if Toggles.CamlockFOVEnabled and Toggles.CamlockFOVEnabled.Value then
        local radius      = Options.CamlockFOVRadius.Value
        local rainbow     = Toggles.CamlockFOVRainbow.Value
        local mainColor   = rainbow and HSVToRGB((tick() % 1), 1, 1) or Options.CamlockFOVColor.Value
        local outlineColor = Options.CamlockFOVOutlineColor.Value
        local fillColor   = rainbow and HSVToRGB((tick() % 1), 1, 1) or Options.CamlockFOVFillColor.Value
        local filled      = Toggles.CamlockFOVFilled.Value
        local fillTrans   = Options.CamlockFOVFillTransparency.Value

        -- Black outline circle
        if not CamlockFOVDots._blackOutline then
            CamlockFOVDots._blackOutline = Drawing.new('Circle')
            CamlockFOVDots._blackOutline.Filled    = false
            CamlockFOVDots._blackOutline.Thickness = 2
            CamlockFOVDots._blackOutline.NumSides  = 64
        end
        CamlockFOVDots._blackOutline.Position = screenCenter
        CamlockFOVDots._blackOutline.Radius   = radius + 1
        CamlockFOVDots._blackOutline.Color    = outlineColor
        CamlockFOVDots._blackOutline.Visible  = true

        -- Main color outline
        if not CamlockFOVDots._outlineCircle then
            CamlockFOVDots._outlineCircle = Drawing.new('Circle')
            CamlockFOVDots._outlineCircle.Filled    = false
            CamlockFOVDots._outlineCircle.Thickness = 1
            CamlockFOVDots._outlineCircle.NumSides  = 64
        end
        CamlockFOVDots._outlineCircle.Position = screenCenter
        CamlockFOVDots._outlineCircle.Radius   = radius
        CamlockFOVDots._outlineCircle.Color    = mainColor
        CamlockFOVDots._outlineCircle.Visible  = true

        -- Fill circle
        if filled then
            CamlockFOVCircle.Filled       = true
            CamlockFOVCircle.Color        = fillColor
            CamlockFOVCircle.Transparency = fillTrans
            CamlockFOVCircle.Position     = screenCenter
            CamlockFOVCircle.Radius       = radius - 1
            CamlockFOVCircle.Visible      = true
        else
            CamlockFOVCircle.Visible = false
        end

        -- Spinning dots
        local doSpin   = Toggles.CamlockFOVSpinningDots.Value
        local dotCount = math.floor(Options.CamlockFOVDotCount.Value)
        if not CamlockFOVDots._dots then CamlockFOVDots._dots = {} end

        if doSpin then
            for i = 1, dotCount do
                if not CamlockFOVDots._dots[i] then
                    CamlockFOVDots._dots[i] = Drawing.new('Circle')
                    CamlockFOVDots._dots[i].Radius    = 3
                    CamlockFOVDots._dots[i].Filled    = true
                    CamlockFOVDots._dots[i].Thickness = 1
                end
                local angle = spinAngle + (i / dotCount) * math.pi * 2
                CamlockFOVDots._dots[i].Position = Vector2.new(
                    screenCenter.X + math.cos(angle) * radius,
                    screenCenter.Y + math.sin(angle) * radius
                )
                CamlockFOVDots._dots[i].Color   = rainbow and HSVToRGB((tick() * 0.5 + i * (1/dotCount)) % 1, 1, 1) or mainColor
                CamlockFOVDots._dots[i].Visible = true
            end
            for i = dotCount + 1, 32 do
                if CamlockFOVDots._dots[i] then CamlockFOVDots._dots[i].Visible = false end
            end
        else
            if CamlockFOVDots._dots then
                for _, d in pairs(CamlockFOVDots._dots) do d.Visible = false end
            end
        end

    else
        CamlockFOVCircle.Visible = false
        if CamlockFOVDots._blackOutline then CamlockFOVDots._blackOutline.Visible = false end
    end
    
    -- Custom Crosshair
    if Toggles.CrosshairEnabled and Toggles.CrosshairEnabled.Value then
        local length = Options.CrosshairLength and Options.CrosshairLength.Value or 10
        local spacing = Options.CrosshairSpacing and Options.CrosshairSpacing.Value or 5
        local width = Options.CrosshairWidth and Options.CrosshairWidth.Value or 2
        local mainColor = Options.CrosshairMainColor and Options.CrosshairMainColor.Value or Color3.fromRGB(0, 255, 0)
        local outlineColor = Options.CrosshairOutlineColor and Options.CrosshairOutlineColor.Value or Color3.fromRGB(0, 0, 0)
        local spinning = Toggles.CrosshairSpinning and Toggles.CrosshairSpinning.Value
        local pulsing = Toggles.CrosshairPulsing and Toggles.CrosshairPulsing.Value
        local onTarget = Toggles.CrosshairOnTarget and Toggles.CrosshairOnTarget.Value
        
        -- Default to mouse position
        local crosshairPos = mousePos
        
        -- Override to target position if enabled and target exists
        if onTarget then
            local target = nil
            if RagebotTarget and RagebotTarget.Character then
                target = RagebotTarget.Character:FindFirstChild('Head')
            elseif CamlockTarget and CamlockTarget.Parent then
                target = CamlockTarget.Parent:FindFirstChild('Head')
            elseif CurrentTarget and CurrentTarget.Parent then
                target = CurrentTarget.Parent:FindFirstChild('Head')
            end
            
            if target then
                local sp, onScreen = Camera:WorldToViewportPoint(target.Position)
                if onScreen and sp.Z > 0 then
                    crosshairPos = Vector2.new(sp.X, sp.Y)
                end
            end
        end
        
        -- Spinning animation
        if spinning then
            local spinSpeed = Options.CrosshairSpinSpeed and Options.CrosshairSpinSpeed.Value or 3
            crosshairAngle = (crosshairAngle + spinSpeed * deltaTime * 360) % 360
        else
            crosshairAngle = 0
        end
        
        -- Pulsing animation
        local pulseMultiplier = 1
        if pulsing then
            local pulseSpeed = Options.CrosshairPulseSpeed and Options.CrosshairPulseSpeed.Value or 2
            pulseMultiplier = 0.7 + math.sin(tick() * pulseSpeed) * 0.3
        end
        
        local finalLength = length * pulseMultiplier
        local finalSpacing = spacing * pulseMultiplier
        
        -- Draw 4 lines (top, bottom, left, right)
        local angles = {0, 90, 180, 270}
        for i = 1, 4 do
            local angle = math.rad(angles[i] + crosshairAngle)
            local cos = math.cos(angle)
            local sin = math.sin(angle)
            
            local startX = crosshairPos.X + cos * finalSpacing
            local startY = crosshairPos.Y + sin * finalSpacing
            local endX = crosshairPos.X + cos * (finalSpacing + finalLength)
            local endY = crosshairPos.Y + sin * (finalSpacing + finalLength)
            
            -- Outline
            CrosshairLines[i].outline.From = Vector2.new(startX, startY)
            CrosshairLines[i].outline.To = Vector2.new(endX, endY)
            CrosshairLines[i].outline.Color = outlineColor
            CrosshairLines[i].outline.Thickness = width + 2
            CrosshairLines[i].outline.Visible = true
            
            -- Main line
            CrosshairLines[i].main.From = Vector2.new(startX, startY)
            CrosshairLines[i].main.To = Vector2.new(endX, endY)
            CrosshairLines[i].main.Color = mainColor
            CrosshairLines[i].main.Thickness = width
            CrosshairLines[i].main.Visible = true
        end
    else
        for i = 1, 4 do
            CrosshairLines[i].outline.Visible = false
            CrosshairLines[i].main.Visible = false
        end
    end

    -- Professional ESP System
    if Toggles.ESPEnabled.Value then
        local maxDist = Options.ESPMaxDistance.Value
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or not ESPObjects[player] then continue end
            
            local esp = ESPObjects[player]
            local char = player.Character
            
            local function hideAllESP()
                for k, drawing in pairs(esp) do
                    if k ~= 'health_segs' and k ~= 'box_sides' and k ~= 'fill_lines' and typeof(drawing) == 'userdata' then drawing.Visible = false end
                end
                if esp.health_segs then
                    for _, seg in ipairs(esp.health_segs) do seg.Visible = false end
                end
                if esp.box_sides then
                    for _, side in ipairs(esp.box_sides) do
                        for _, seg in ipairs(side) do seg.Visible = false end
                    end
                end
                if esp.fill_lines then
                    for _, l in ipairs(esp.fill_lines) do l.Visible = false end
                end
            end

            if not char then
                hideAllESP()
                continue
            end
            
            local hum = char:FindFirstChildOfClass('Humanoid')
            local hrp = char:FindFirstChild('HumanoidRootPart')
            
            if not hum or hum.Health <= 0 or not hrp then
                hideAllESP()
                continue
            end
            
            local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
            if distance > maxDist then
                hideAllESP()
                continue
            end
            
            -- Calculate box
            local head = char:FindFirstChild('Head')
            if not head then
                hideAllESP()
                continue
            end
            
            local headPos = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
            local legPos = hrp.Position - Vector3.new(0, 3, 0)
            
            local topScreen, topVisible = Camera:WorldToViewportPoint(headPos)
            local bottomScreen, bottomVisible = Camera:WorldToViewportPoint(legPos)
            
            if not topVisible or not bottomVisible or topScreen.Z <= 0 then
                hideAllESP()
                continue
            end
            
            local height = math.abs(bottomScreen.Y - topScreen.Y)
            local width = height * 0.5
            local x = topScreen.X - width / 2
            local y = topScreen.Y
            
            -- Check if this is the locked target
            local isTarget = CurrentTarget and CurrentTarget.Parent == char
            local boxColor = Options.ESPBoxColor.Value
            
            -- Box ESP
            if Toggles.ESPBoxes.Value then
                if Toggles.ESPBoxGradient and Toggles.ESPBoxGradient.Value then
                    -- No black outline when gradient is on
                    esp.box_outline.Visible = false
                    esp.box_inline.Visible = false
                    local c1 = Options.ESPBoxColor1 and Options.ESPBoxColor1.Value or Color3.fromRGB(255, 0, 100)
                    local c2 = Options.ESPBoxColor2 and Options.ESPBoxColor2.Value or Color3.fromRGB(255, 100, 0)
                    local c3 = Options.ESPBoxColor3 and Options.ESPBoxColor3.Value or Color3.fromRGB(100, 0, 255)
                    -- keypoints: 0=c1, 0.333=c2, 0.666=c3, 1=c1
                    local function perimColor(t)
                        t = t % 1
                        if t < 0.333 then
                            return c1:Lerp(c2, t / 0.333)
                        elseif t < 0.666 then
                            return c2:Lerp(c3, (t - 0.333) / 0.333)
                        else
                            return c3:Lerp(c1, (t - 0.666) / 0.334)
                        end
                    end
                    -- perimeter: top(left→right), right(top→bottom), bottom(right→left), left(bottom→top)
                    -- total perimeter = 2*(w+h), each side fraction:
                    local perim = 2 * (width + height)
                    local N = ESP_BOX_SEGMENTS
                    -- side definitions: [fraction start, fraction end, start pos, end pos]
                    local sideDefs = {
                        {f0 = 0,                       f1 = width/perim,
                         ax=x,       ay=y,          bx=x+width, by=y},
                        {f0 = width/perim,             f1 = (width+height)/perim,
                         ax=x+width, ay=y,          bx=x+width, by=y+height},
                        {f0 = (width+height)/perim,    f1 = (2*width+height)/perim,
                         ax=x+width, ay=y+height,   bx=x,       by=y+height},
                        {f0 = (2*width+height)/perim,  f1 = 1,
                         ax=x,       ay=y+height,   bx=x,       by=y},
                    }
                    for s, sd in ipairs(sideDefs) do
                        for i = 1, N do
                            local t0 = sd.f0 + (sd.f1 - sd.f0) * ((i-1)/N)
                            local t1 = sd.f0 + (sd.f1 - sd.f0) * (i/N)
                            local tm = (t0 + t1) / 2
                            local px0 = sd.ax + (sd.bx - sd.ax) * ((i-1)/N)
                            local py0 = sd.ay + (sd.by - sd.ay) * ((i-1)/N)
                            local px1 = sd.ax + (sd.bx - sd.ax) * (i/N)
                            local py1 = sd.ay + (sd.by - sd.ay) * (i/N)
                            esp.box_sides[s][i].From      = Vector2.new(px0, py0)
                            esp.box_sides[s][i].To        = Vector2.new(px1, py1)
                            esp.box_sides[s][i].Color     = perimColor(tm)
                            esp.box_sides[s][i].Thickness = 1
                            esp.box_sides[s][i].Visible   = true
                        end
                    end
                else
                    -- Smooth gradient box style (black outer → gradient → black inner)
                    for _, side in ipairs(esp.box_sides) do
                        for _, seg in ipairs(side) do seg.Visible = false end
                    end
                    
                    -- Layer 1: Outer black outline
                    esp.box_outline.Size = Vector2.new(width + 6, height + 6)
                    esp.box_outline.Position = Vector2.new(x - 3, y - 3)
                    esp.box_outline.Color = Color3.fromRGB(0, 0, 0)
                    esp.box_outline.Thickness = 3
                    esp.box_outline.Visible = true
                    
                    -- Layer 2: Gradient colored border
                    esp.box_gradient.Size = Vector2.new(width + 2, height + 2)
                    esp.box_gradient.Position = Vector2.new(x - 1, y - 1)
                    esp.box_gradient.Color = boxColor
                    esp.box_gradient.Thickness = 2
                    esp.box_gradient.Visible = true
                    
                    -- Layer 3: Inner black outline
                    esp.box_inner.Size = Vector2.new(width, height)
                    esp.box_inner.Position = Vector2.new(x, y)
                    esp.box_inner.Color = Color3.fromRGB(0, 0, 0)
                    esp.box_inner.Thickness = 1
                    esp.box_inner.Visible = true
                    
                    -- Hide unused
                    esp.box_inline.Visible = false
                    esp.box_fill.Visible = false
                end

                -- Gradient fill with optional rotation
                if Toggles.ESPFilled.Value then
                    local fc1   = Options.ESPFillColor1 and Options.ESPFillColor1.Value or Color3.fromRGB(180, 0, 255)
                    local fc2   = Options.ESPFillColor2 and Options.ESPFillColor2.Value or Color3.fromRGB(255, 0, 150)
                    local fc3   = Options.ESPFillColor3 and Options.ESPFillColor3.Value or Color3.fromRGB(0, 100, 255)
                    local trans = Options.ESPFillTransparency and Options.ESPFillTransparency.Value or 0.7
                    local angle = ESPFillAngle
                    local cosA  = math.cos(angle)
                    local sinA  = math.sin(angle)
                    local N     = ESP_FILL_SEGMENTS
                    local bx    = x + 1
                    local by    = y + 1
                    local bw    = math.max(1, width - 2)
                    local bh    = math.max(1, height - 2)
                    local cx2   = bx + bw / 2
                    local cy2   = by + bh / 2
                    local halfDiag = math.sqrt((bw/2)^2 + (bh/2)^2)
                    local sliceH = math.ceil(bh / N) + 1
                    for i = 1, N do
                        local rowY = by + (i - 1) * bh / N
                        if rowY > by + bh then
                            esp.fill_lines[i].Visible = false
                        else
                            -- project this line's center onto the rotating gradient axis
                            local midY = rowY + bh / N * 0.5
                            local midX = cx2  -- horizontal center, constant
                            local proj = (midX - cx2) * cosA + (midY - cy2) * sinA
                            local t = math.clamp((proj / halfDiag + 1) / 2, 0, 1)
                            local fc
                            if t < 0.5 then
                                fc = fc1:Lerp(fc2, t * 2)
                            else
                                fc = fc2:Lerp(fc3, (t - 0.5) * 2)
                            end
                            esp.fill_lines[i].From        = Vector2.new(bx, rowY)
                            esp.fill_lines[i].To          = Vector2.new(bx + bw, rowY)
                            esp.fill_lines[i].Color       = fc
                            esp.fill_lines[i].Transparency = trans
                            esp.fill_lines[i].Thickness   = sliceH
                            esp.fill_lines[i].Visible     = true
                        end
                    end
                    esp.box_fill.Visible = false
                else
                    for _, l in ipairs(esp.fill_lines) do l.Visible = false end
                    esp.box_fill.Visible = false
                end
            else
                esp.box_outline.Visible = false
                esp.box_inline.Visible = false
                esp.box_fill.Visible = false
                for _, side in ipairs(esp.box_sides) do
                    for _, seg in ipairs(side) do seg.Visible = false end
                end
            end

            -- Health bar with correct position support
            if Toggles.ESPHealthBar.Value then
                local healthPercent = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local side = Options.ESPHealthBarSide.Value
                local barThick = 4
                local barInner = 2
                local segs = esp.health_segs
                local N = ESP_GRADIENT_SEGMENTS

                local cHigh = Options.ESPHealthColorHigh and Options.ESPHealthColorHigh.Value or Color3.fromRGB(0, 220, 0)
                local cMid  = Options.ESPHealthColorMid  and Options.ESPHealthColorMid.Value  or Color3.fromRGB(220, 180, 0)
                local cLow  = Options.ESPHealthColorLow  and Options.ESPHealthColorLow.Value  or Color3.fromRGB(220, 0, 0)

                if side == 'Left' then
                    local barX = x - barThick - 2
                    local barH = math.max(1, math.floor(height * healthPercent))
                    esp.health_outline.Size     = Vector2.new(barThick, height)
                    esp.health_outline.Position = Vector2.new(barX, y)
                    esp.health_bg.Size          = Vector2.new(barInner, height - 2)
                    esp.health_bg.Position      = Vector2.new(barX + 1, y + 1)
                    local bgTop    = y + 1
                    local bgBottom = y + height - 1
                    local fillTop  = bgBottom - math.max(0, barH - 2)
                    local fillH    = bgBottom - fillTop
                    local segH     = fillH / N
                    local visCount = math.ceil(N * healthPercent)
                    for i = 1, N do
                        local t = 1 - (i - 0.5) / N
                        local c = t <= 0.5 and cLow:Lerp(cMid, t * 2) or cMid:Lerp(cHigh, (t - 0.5) * 2)
                        local sy = fillTop + (i - 1) * segH
                        local sh = math.min(math.max(1, math.ceil(segH)), bgBottom - sy)
                        segs[i].Size     = Vector2.new(barInner, math.max(1, sh))
                        segs[i].Position = Vector2.new(barX + 1, sy)
                        segs[i].Color    = c
                        segs[i].Visible  = (sh > 0) and (i > (N - visCount))
                    end

                elseif side == 'Right' then
                    local barX = x + width + 2
                    local barH = math.max(1, math.floor(height * healthPercent))
                    esp.health_outline.Size     = Vector2.new(barThick, height)
                    esp.health_outline.Position = Vector2.new(barX, y)
                    esp.health_bg.Size          = Vector2.new(barInner, height - 2)
                    esp.health_bg.Position      = Vector2.new(barX + 1, y + 1)
                    local bgTop    = y + 1
                    local bgBottom = y + height - 1
                    local fillTop  = bgBottom - math.max(0, barH - 2)
                    local fillH    = bgBottom - fillTop
                    local segH     = fillH / N
                    local visCount = math.ceil(N * healthPercent)
                    for i = 1, N do
                        local t = 1 - (i - 0.5) / N
                        local c = t <= 0.5 and cLow:Lerp(cMid, t * 2) or cMid:Lerp(cHigh, (t - 0.5) * 2)
                        local sy = fillTop + (i - 1) * segH
                        local sh = math.min(math.max(1, math.ceil(segH)), bgBottom - sy)
                        segs[i].Size     = Vector2.new(barInner, math.max(1, sh))
                        segs[i].Position = Vector2.new(barX + 1, sy)
                        segs[i].Color    = c
                        segs[i].Visible  = (sh > 0) and (i > (N - visCount))
                    end

                elseif side == 'Top' then
                    local barW = math.max(1, math.floor(width * healthPercent))
                    esp.health_outline.Size     = Vector2.new(width, barThick)
                    esp.health_outline.Position = Vector2.new(x, y - barThick - 2)
                    esp.health_bg.Size          = Vector2.new(width - 2, barInner)
                    esp.health_bg.Position      = Vector2.new(x + 1, y - barThick - 1)
                    local bgLeft  = x + 1
                    local bgRight = x + width - 1
                    local fillW   = math.max(0, barW - 2)
                    local segW    = fillW / N
                    local visCount = math.ceil(N * healthPercent)
                    for i = 1, N do
                        local t = (i - 0.5) / N
                        local c = t <= 0.5 and cLow:Lerp(cMid, t * 2) or cMid:Lerp(cHigh, (t - 0.5) * 2)
                        local sx = bgLeft + (i - 1) * segW
                        local sw = math.min(math.max(1, math.ceil(segW)), bgRight - sx)
                        segs[i].Size     = Vector2.new(math.max(1, sw), barInner)
                        segs[i].Position = Vector2.new(sx, y - barThick - 1)
                        segs[i].Color    = c
                        segs[i].Visible  = (sw > 0) and (i <= visCount)
                    end

                elseif side == 'Bottom' then
                    local barW = math.max(1, math.floor(width * healthPercent))
                    esp.health_outline.Size     = Vector2.new(width, barThick)
                    esp.health_outline.Position = Vector2.new(x, y + height + 2)
                    esp.health_bg.Size          = Vector2.new(width - 2, barInner)
                    esp.health_bg.Position      = Vector2.new(x + 1, y + height + 3)
                    local bgLeft  = x + 1
                    local bgRight = x + width - 1
                    local fillW   = math.max(0, barW - 2)
                    local segW    = fillW / N
                    local visCount = math.ceil(N * healthPercent)
                    for i = 1, N do
                        local t = (i - 0.5) / N
                        local c = t <= 0.5 and cLow:Lerp(cMid, t * 2) or cMid:Lerp(cHigh, (t - 0.5) * 2)
                        local sx = bgLeft + (i - 1) * segW
                        local sw = math.min(math.max(1, math.ceil(segW)), bgRight - sx)
                        segs[i].Size     = Vector2.new(math.max(1, sw), barInner)
                        segs[i].Position = Vector2.new(sx, y + height + 3)
                        segs[i].Color    = c
                        segs[i].Visible  = (sw > 0) and (i <= visCount)
                    end
                end

                esp.health_outline.Color   = Color3.fromRGB(0, 0, 0)
                esp.health_outline.Visible = true
                esp.health_bg.Color        = Options.ESPHealthBGColor.Value
                esp.health_bg.Transparency = 0.4
                esp.health_bg.Visible      = true
                esp.health_bar.Visible     = false -- unused, segments used instead
                esp.health_bar.Size        = Vector2.new(0, 0)
            else
                esp.health_outline.Visible = false
                esp.health_bg.Visible      = false
                esp.health_bar.Visible     = false
                esp.health_bar.Size        = Vector2.new(0, 0)
                for i = 1, ESP_GRADIENT_SEGMENTS do
                    esp.health_segs[i].Visible = false
                end
            end
            
            -- Name
            if Toggles.ESPNames.Value then
                esp.name_text.Text = player.Name  -- Use real name instead of DisplayName
                esp.name_text.Position = Vector2.new(x + width / 2, y - 16)
                esp.name_text.Color = Options.ESPTextColor.Value
                esp.name_text.Visible = true
            else
                esp.name_text.Visible = false
            end
            
            -- Distance
            if Toggles.ESPDistance.Value then
                local distMeters = math.floor(distance * 0.28)
                esp.distance_text.Text = tostring(distMeters) .. " m"
                esp.distance_text.Position = Vector2.new(x + width / 2, y + height + 2)
                esp.distance_text.Color = Options.ESPTextColor.Value
                esp.distance_text.Visible = true
            else
                esp.distance_text.Visible = false
            end
            
            -- (ESP per-player tracer removed — use Target Tracer in Visuals tab)
        end
    else
        for _, esp in pairs(ESPObjects) do
            for k, drawing in pairs(esp) do
                if k ~= 'health_segs' and k ~= 'box_sides' and k ~= 'fill_lines' and typeof(drawing) == 'userdata' then drawing.Visible = false end
            end
            if esp.health_segs then
                for _, seg in ipairs(esp.health_segs) do seg.Visible = false end
            end
            if esp.box_sides then
                for _, side in ipairs(esp.box_sides) do
                    for _, seg in ipairs(side) do seg.Visible = false end
                end
            end
            if esp.fill_lines then
                for _, l in ipairs(esp.fill_lines) do l.Visible = false end
            end
        end
    end

    -- Target Tracer (from cursor to locked target's body)
    -- Priority: Ragebot > Camlock > Legitbot
    local tracerTarget = nil
    
    if RagebotTarget and RagebotTarget.Character then
        local hrp = RagebotTarget.Character:FindFirstChild('HumanoidRootPart')
        if hrp then
            tracerTarget = hrp
        end
    elseif CamlockTarget and CamlockTarget.Parent then
        tracerTarget = CamlockTarget
    elseif CurrentTarget and CurrentTarget.Parent then
        tracerTarget = CurrentTarget
    end
    
    if Toggles.TargetTracerEnabled.Value and tracerTarget then
        local screenPos, onScreen = Camera:WorldToViewportPoint(tracerTarget.Position)

        if onScreen and screenPos.Z > 0 then
            local targetV2 = Vector2.new(screenPos.X, screenPos.Y)

            -- Outline (drawn first, thicker, behind)
            TargetTracerOutline.From    = mousePos
            TargetTracerOutline.To      = targetV2
            TargetTracerOutline.Color   = Options.TracerOutlineColor.Value
            TargetTracerOutline.Thickness = 3
            TargetTracerOutline.Visible = true

            -- Main line (thinner, on top)
            TargetTracerMain.From    = mousePos
            TargetTracerMain.To      = targetV2
            TargetTracerMain.Color   = Options.TracerMainColor.Value
            TargetTracerMain.Thickness = 1
            TargetTracerMain.Visible = true
        else
            TargetTracerOutline.Visible = false
            TargetTracerMain.Visible    = false
        end
    else
        TargetTracerOutline.Visible = false
        TargetTracerMain.Visible    = false
    end

    -- Hitbox Expander (expand enemy hitboxes for easier hits)
    if Toggles.HitboxExpanderEnabled and Toggles.HitboxExpanderEnabled.Value then
        local sizeX = Options.HitboxSizeX and Options.HitboxSizeX.Value or 10
        local sizeY = Options.HitboxSizeY and Options.HitboxSizeY.Value or 10
        local sizeZ = Options.HitboxSizeZ and Options.HitboxSizeZ.Value or 10
        local mainColor = Options.HitboxMainColor and Options.HitboxMainColor.Value or Color3.fromRGB(0, 85, 255)
        local outlineColor = Options.HitboxOutlineColor and Options.HitboxOutlineColor.Value or Color3.fromRGB(255, 255, 255)
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild('HumanoidRootPart')
                if hrp then
                    pcall(function()
                        hrp.Size = Vector3.new(sizeX, sizeY, sizeZ)
                        hrp.Transparency = 0.7
                        hrp.BrickColor = BrickColor.new(mainColor)
                        hrp.Material = Enum.Material.Neon
                        hrp.CanCollide = false
                        
                        -- Add selection box for outline
                        local selectionBox = hrp:FindFirstChild('HitboxOutline')
                        if not selectionBox then
                            selectionBox = Instance.new('SelectionBox')
                            selectionBox.Name = 'HitboxOutline'
                            selectionBox.Adornee = hrp
                            selectionBox.LineThickness = 0.05
                            selectionBox.Parent = hrp
                        end
                        selectionBox.Color3 = outlineColor
                    end)
                end
            end
        end
    else
        -- Reset hitboxes when disabled
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild('HumanoidRootPart')
                if hrp then
                    pcall(function()
                        hrp.Size = Vector3.new(2, 2, 1) -- Default Roblox size
                        hrp.Transparency = 1
                        hrp.CanCollide = false
                        
                        -- Remove outline
                        local selectionBox = hrp:FindFirstChild('HitboxOutline')
                        if selectionBox then
                            selectionBox:Destroy()
                        end
                    end)
                end
            end
        end
    end

    -- Walkspeed (velocity-based)
    if Toggles.WalkspeedEnabled.Value then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild('HumanoidRootPart')
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                local speed = Options.WalkspeedValue.Value
                hrp.Velocity = Vector3.new(
                    hum.MoveDirection.X * speed,
                    hrp.Velocity.Y,
                    hum.MoveDirection.Z * speed
                )
            end
        end
    end

    -- Fly (CFrame-based with velocity reset)
    if Toggles.FlyEnabled.Value then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild('HumanoidRootPart')
            if hrp then
                -- Stop all velocity when flying
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                
                local speed = Options.FlySpeed.Value / 60
                local camCF = Camera.CFrame
                local moveVector = Vector3.zero

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveVector = moveVector + camCF.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveVector = moveVector - camCF.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveVector = moveVector - camCF.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveVector = moveVector + camCF.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveVector = moveVector + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveVector = moveVector - Vector3.new(0, 1, 0)
                end

                if moveVector.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + (moveVector.Unit * speed)
                end
            end
        end
    end
    
    -- Spinbot (rotate character continuously)
    if Toggles.SpinbotEnabled and Toggles.SpinbotEnabled.Value then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild('HumanoidRootPart')
            if hrp then
                local speed = Options.SpinbotSpeed and Options.SpinbotSpeed.Value or 10
                spinAngle = (spinAngle + speed) % 360
                hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
            end
        end
    end
    
    -- Jitter (randomly offset character position)
    if Toggles.JitterEnabled and Toggles.JitterEnabled.Value then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild('HumanoidRootPart')
            if hrp then
                local jitterX = Options.JitterX and Options.JitterX.Value or 5
                local jitterY = Options.JitterY and Options.JitterY.Value or 5
                local jitterZ = Options.JitterZ and Options.JitterZ.Value or 5
                
                local randomOffset = Vector3.new(
                    (math.random() - 0.5) * jitterX,
                    (math.random() - 0.5) * jitterY,
                    (math.random() - 0.5) * jitterZ
                )
                
                hrp.CFrame = hrp.CFrame + randomOffset
            end
        end
    end
    
    -- No Void Kill
    if Toggles.NoVoidKillEnabled and Toggles.NoVoidKillEnabled.Value then
        workspace.FallenPartsDestroyHeight = -0 / 0
    else
        workspace.FallenPartsDestroyHeight = -500
    end
    
    -- Target Ring
    if Toggles.TargetRingEnabled and Toggles.TargetRingEnabled.Value then
        local target = nil
        local targetChar = nil
        
        if RagebotTarget and RagebotTarget.Character then
            targetChar = RagebotTarget.Character
        elseif CamlockTarget and CamlockTarget.Parent then
            targetChar = CamlockTarget.Parent
        elseif CurrentTarget and CurrentTarget.Parent then
            targetChar = CurrentTarget.Parent
        end
        
        if targetChar then
            local hrp = targetChar:FindFirstChild('HumanoidRootPart')
            if hrp then target = hrp end
        end
        
        if target and TargetRing.fill and TargetRing.outline then
            TargetRing.fill.Color = Options.TargetRingColor and Options.TargetRingColor.Value or Color3.fromRGB(255, 0, 0)
            TargetRing.outline.Color = Options.TargetRingOutlineColor and Options.TargetRingOutlineColor.Value or Color3.fromRGB(0, 0, 0)
            
            -- Scanning: disc moves from feet (-3) to head (+3) and back
            local scanning = Toggles.TargetRingScan and Toggles.TargetRingScan.Value
            local yOffset = 0
            if scanning then
                TargetRing.scanOffset = (TargetRing.scanOffset + deltaTime * 0.5) % 1
                yOffset = math.sin(TargetRing.scanOffset * math.pi * 2) * 3
            end
            
            -- Flat horizontal disc positioned at target center + scan offset
            local pos = target.Position + Vector3.new(0, yOffset, 0)
            TargetRing.outline.CFrame = CFrame.new(pos)
            TargetRing.fill.CFrame   = CFrame.new(pos + Vector3.new(0, 0.02, 0))
            
            TargetRing.outline.Parent = workspace
            TargetRing.fill.Parent    = workspace
        else
            if TargetRing.fill   then TargetRing.fill.Parent   = nil end
            if TargetRing.outline then TargetRing.outline.Parent = nil end
        end
    else
        if TargetRing.fill   then TargetRing.fill.Parent   = nil end
        if TargetRing.outline then TargetRing.outline.Parent = nil end
    end
    
    -- Anti Lock handled separately (see anti-lock heartbeat connection)

    -- Target Info Panel
    if Toggles.TargetInfoEnabled and Toggles.TargetInfoEnabled.Value then
        TIFrame.Visible = true
        local infoTarget = nil
        local infoChar = nil
        if RagebotTarget and RagebotTarget.Character then
            infoTarget = RagebotTarget
            infoChar = RagebotTarget.Character
        elseif CamlockTarget and CamlockTarget.Parent then
            infoChar = CamlockTarget.Parent
            infoTarget = game:GetService('Players'):GetPlayerFromCharacter(infoChar)
        elseif CurrentTarget and CurrentTarget.Parent then
            infoChar = CurrentTarget.Parent
            infoTarget = game:GetService('Players'):GetPlayerFromCharacter(infoChar)
        end

        if infoChar and infoTarget then
            local hum = infoChar:FindFirstChildOfClass('Humanoid')
            local hp = hum and math.floor(hum.Health) or 0
            local maxHp = hum and math.floor(hum.MaxHealth) or 100
            local tool = infoChar:FindFirstChildOfClass('Tool')
            local bodyEffects = infoChar:FindFirstChild('BodyEffects')
            local armorVal = bodyEffects and bodyEffects:FindFirstChild('Armor')
            local armor = armorVal and math.floor(armorVal.Value) or 0
            local maxArmor = 130

            TITargetVal.Text = infoTarget.Name
            TIHealthVal.Text = '[' .. hp .. ']'
            TIArmorVal.Text  = '[' .. armor .. ']'
            TIGunVal.Text    = tool and ('[' .. tool.Name .. ']') or '[None]'
            TIHealthBar.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
            TIArmorBar.Size  = UDim2.new(math.clamp(armor / maxArmor, 0, 1), 0, 1, 0)
            TIArmorBar.BackgroundColor3 = armor > 0 and Color3.fromRGB(130, 90, 210) or Color3.fromRGB(40, 40, 40)

            -- Update health bar gradient using the 3 color pickers
            local cHigh = Options.TIHealthColorHigh and Options.TIHealthColorHigh.Value or Color3.fromRGB(0, 210, 0)
            local cMid  = Options.TIHealthColorMid  and Options.TIHealthColorMid.Value  or Color3.fromRGB(210, 180, 0)
            local cLow  = Options.TIHealthColorLow  and Options.TIHealthColorLow.Value  or Color3.fromRGB(210, 0, 0)
            TIHealthGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   cLow),
                ColorSequenceKeypoint.new(0.5, cMid),
                ColorSequenceKeypoint.new(1,   cHigh),
            })
        else
            TITargetVal.Text = '--'
            TIHealthVal.Text = '[--]'
            TIArmorVal.Text  = '[--]'
            TIGunVal.Text    = '[--]'
            TIHealthBar.Size = UDim2.new(0, 0, 1, 0)
            TIArmorBar.Size  = UDim2.new(0, 0, 1, 0)
        end
    else
        TIFrame.Visible = false
    end
    
    -- World Settings
    local lighting = game:GetService('Lighting')
    
    -- Fog
    if Toggles.FogEnabled and Toggles.FogEnabled.Value then
        lighting.FogStart = Options.FogStart.Value
        lighting.FogEnd = Options.FogEnd.Value
        lighting.FogColor = Options.FogColor.Value
    end
    
    -- Ambient
    if Toggles.AmbientEnabled and Toggles.AmbientEnabled.Value then
        lighting.Ambient = Options.AmbientColor.Value
    end
    
    -- Brightness
    if Toggles.BrightnessEnabled and Toggles.BrightnessEnabled.Value then
        lighting.Brightness = Options.Brightness.Value
    end
    
    -- Clock Time
    if Toggles.ClockTimeEnabled and Toggles.ClockTimeEnabled.Value then
        lighting.ClockTime = Options.ClockTime.Value
    end
    
    -- Exposure
    if Toggles.ExposureEnabled and Toggles.ExposureEnabled.Value then
        lighting.ExposureCompensation = Options.Exposure.Value
    end
    
    -- Rain
    if Toggles.RainEnabled and Toggles.RainEnabled.Value then
        if not RainPart then
            -- Create rain part that follows camera
            RainPart = Instance.new('Part')
            RainPart.Size = Vector3.new(40, 40, 85)
            RainPart.CanCollide = false
            RainPart.Transparency = 1
            RainPart.Anchored = true
            RainPart.Name = 'RainEmitter'
            RainPart.Parent = workspace
            
            -- Create particle emitter
            RainParticle = Instance.new('ParticleEmitter')
            RainParticle.Texture = 'rbxassetid://1822883048'
            RainParticle.EmissionDirection = Enum.NormalId.Bottom
            RainParticle.Speed = NumberRange.new(60, 60)
            RainParticle.Lifetime = NumberRange.new(0.8, 0.8)
            RainParticle.Rate = 600
            RainParticle.LockedToPart = true
            RainParticle.LightEmission = 0.05
            RainParticle.LightInfluence = 0.9
            RainParticle.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
            RainParticle.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 10),
                NumberSequenceKeypoint.new(1, 10)
            })
            RainParticle.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.25, 0.784),
                NumberSequenceKeypoint.new(0.75, 0.784),
                NumberSequenceKeypoint.new(1, 1)
            })
            RainParticle.Parent = RainPart
        end
        
        -- Update rain position to follow camera
        RainPart.CFrame = CFrame.new(Camera.CFrame.Position + Vector3.new(0, 20, 0))
        
        -- Update rain color and rate
        local rainColor = Options.RainColor and Options.RainColor.Value or Color3.fromRGB(255, 255, 255)
        local rainRate = Options.RainRate and Options.RainRate.Value or 60
        RainParticle.Color = ColorSequence.new(rainColor)
        RainParticle.Rate = rainRate * 10 -- Scale rate (60 = 600 particles)
    else
        -- Clean up rain when disabled
        if RainPart then
            RainPart:Destroy()
            RainPart = nil
            RainParticle = nil
        end
    end
    
    -- Tool Changer
    if Toggles.ToolChangerEnabled and Toggles.ToolChangerEnabled.Value then
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass('Tool')
            if tool then
                local material = Enum.Material[Options.ToolMaterial.Value]
                local color = Options.ToolColor.Value
                
                for _, part in pairs(tool:GetDescendants()) do
                    if part:IsA('BasePart') then
                        part.Material = material
                        part.Color = color
                    end
                end
            end
        end
    end
    
    -- Character Changer
    if Toggles.CharacterChangerEnabled and Toggles.CharacterChangerEnabled.Value then
        local char = LocalPlayer.Character
        if char then
            local material = Enum.Material[Options.CharacterMaterial.Value]
            local color = Options.CharacterColor.Value
            
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA('BasePart') and part.Name ~= 'HumanoidRootPart' then
                    part.Material = material
                    part.Color = color
                end
            end
        end
    end
    
end) -- end RenderStepped
end) -- end task.spawn for RenderStepped

-- ─────────────────────────────────────────────────────────────
-- ANTI-LOCK SYSTEM (Separate heartbeat to avoid moving player)
-- ─────────────────────────────────────────────────────────────

task.spawn(function()
    task.wait(2)
    RunService.Heartbeat:Connect(function()
        if Toggles.AntiLock and Toggles.AntiLock.Value then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild('HumanoidRootPart')
            if hrp then
                local skyAmount = Options.AntiLockHeight and Options.AntiLockHeight.Value or 90
                local originalVel = hrp.Velocity
                
                -- Spike velocity upward
                hrp.Velocity = Vector3.new(0, skyAmount, 0)
                
                -- Wait and restore
                RunService.RenderStepped:Wait()
                
                if hrp and hrp.Parent then
                    hrp.Velocity = originalVel
                end
            end
        end
    end
end)
end) -- end task.spawn for Heartbeat

-- ─────────────────────────────────────────────────────────────
-- UI SETTINGS TAB
-- ─────────────────────────────────────────────────────────────

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddToggle('KeybindMenuOpen', {
    Default  = false,
    Text     = 'Open Keybind Menu',
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})
MenuGroup:AddToggle('ShowCustomCursor', {
    Text     = 'Custom Cursor',
    Default  = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel('Menu Accent Color'):AddColorPicker('MenuAccentColor', {
    Default = Color3.fromRGB(255, 145, 0),
    Title = 'Menu Accent',
    Callback = function(Value)
        Library.AccentColor = Value
        Library.AccentColorDark = Library:GetDarkerColor(Value)
        Library:UpdateColorsUsingRegistry()
    end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'RightShift',
    NoUI    = true,
    Text    = 'Menu keybind',
})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('Cipher')
SaveManager:SetFolder('Cipher/cipher')

-- Build config section first
SaveManager:BuildConfigSection(Tabs['UI Settings'])

-- Add delete config button in a simple right groupbox
local DeleteBox = Tabs['UI Settings']:AddRightGroupbox('Delete Config')

DeleteBox:AddButton('Delete Selected Config', function()
    -- Get config name from SaveManager's dropdown
    local configName = Options.SaveManager_ConfigList and Options.SaveManager_ConfigList.Value
    
    if not configName or configName == '' then
        Library:Notify('Select a config from the dropdown first', 3)
        return
    end
    
    local success, err = pcall(function()
        -- Correct path based on SaveManager source code
        local configPath = SaveManager.Folder .. '/settings/' .. configName .. '.json'
        
        if isfile(configPath) then
            delfile(configPath)
            Library:Notify('Deleted config: ' .. configName, 3)
            
            -- Refresh config list
            Options.SaveManager_ConfigList:SetValues(SaveManager:RefreshConfigList())
            Options.SaveManager_ConfigList:SetValue(nil)
        else
            Library:Notify('Config file not found: ' .. configPath, 3)
        end
    end)
    
    if not success then
        Library:Notify('Error: ' .. tostring(err), 3)
    end
end)

ThemeManager:ApplyToTab(Tabs['UI Settings'])

-- Orange/gold accent color to match the screenshot style
Library.AccentColor = Color3.fromRGB(255, 145, 0)
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

SaveManager:LoadAutoloadConfig()

-- Initialize player lists after UI is fully built
task.spawn(function()
    task.wait(0.5)
    local initialList = UpdateRagebotPlayerList()
    
    if Options.RagebotTargetSelect then
        Options.RagebotTargetSelect:SetValues(initialList)
    end
    if Options.RagebotWhitelistSelect then
        Options.RagebotWhitelistSelect:SetValues(initialList)
    end
    if Options.MiscPlayerSelect then
        Options.MiscPlayerSelect:SetValues(initialList)
    end
end)

-- Disable all toggles and reset colors on load (fresh start)
task.spawn(function()
    task.wait(0.5)
    -- This ensures clean state - user can enable what they want
    -- Colors remain as defined defaults
end)

-- ─────────────────────────────────────────────────────────────
-- UNLOAD
-- ─────────────────────────────────────────────────────────────

Library:OnUnload(function()
    if Connection then Connection:Disconnect() end
    pcall(function() TargetInfoGui:Destroy() end)

    pcall(function() FOVCircle:Remove() end)
    for _, dot in pairs(FOVDots) do
        pcall(function() dot:Remove() end)
    end
    pcall(function() CamlockFOVCircle:Remove() end)
    for _, dot in pairs(CamlockFOVDots) do
        pcall(function() dot:Remove() end)
    end
    for i = 1, 4 do
        pcall(function() CrosshairLines[i].outline:Remove() end)
        pcall(function() CrosshairLines[i].main:Remove() end)
    end
    pcall(function()
        if TargetRing.fill then
            TargetRing.fill:Destroy()
        end
        if TargetRing.outline then
            TargetRing.outline:Destroy()
        end
    end)
    pcall(function() TargetTracerOutline:Remove() end)
    pcall(function() TargetTracerMain:Remove() end)

    for player in pairs(ESPObjects) do
        RemoveESP(player)
    end

    -- Restore wallbang
    local Ignored = workspace:FindFirstChild('Ignored')
    for FolderName, OriginalParent in pairs(WallbangFolders) do
        local Folder = Ignored and Ignored:FindFirstChild(FolderName)
        if Folder then
            Folder.Parent = OriginalParent or workspace
        end
    end

    -- Restore camera
    if OriginalCameraSubject then
        Camera.CameraSubject = OriginalCameraSubject
    end

    -- Stop emote
    StopEmote()

    -- Reset hitboxes
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild('HumanoidRootPart')
            if hrp then
                pcall(function()
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.CanCollide = false
                    local selectionBox = hrp:FindFirstChild('HitboxOutline')
                    if selectionBox then selectionBox:Destroy() end
                end)
            end
        end
    end

    -- Cleanup hit notifications
    for _, notif in ipairs(ActiveNotifications) do
        pcall(function() notif.frame:Destroy() end)
    end
    ActiveNotifications = {}
    pcall(function() HitNotifScreenGui:Destroy() end)

    -- Cleanup damage numbers
    for _, dmgNum in ipairs(ActiveDamageNumbers) do
        pcall(function() dmgNum.billboard:Destroy() end)
    end
    ActiveDamageNumbers = {}
    pcall(function() DamageNumbersScreenGui:Destroy() end)

    -- Cleanup rain
    if RainPart then
        pcall(function() RainPart:Destroy() end)
        RainPart = nil
        RainParticle = nil
    end

    -- Return from void
    if InVoid and OriginalPosition then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild('HumanoidRootPart')
            if hrp then hrp.CFrame = OriginalPosition end
        end
    end

    CurrentTarget = nil
    CamlockTarget = nil
    Library.Unloaded = true
    print('Cipher unloaded')
end)
