local Setting={}

---add a startup setting
---@param setting data.AnyModSettingPrototype
---@return ModSetting
function Setting.startup(setting)
  if Stage.is_setting() then
    setting.setting_type = "startup"
    if not data.raw[setting.type] or not data.raw[setting.type][setting.name] then
      data:extend{setting}
    end
  end
  return settings.startup[setting.name]
end

---add a runtime global setting
---@param setting data.AnyModSettingPrototype
---@return ModSetting
function Setting.runtime(setting)
  if Stage.is_setting() then
    setting.setting_type = "runtime-global"
    if not data.raw[setting.type] or not data.raw[setting.type][setting.name] then
      data:extend{setting}
    end
  end
  if Stage.is_control() then return settings.global[setting.name] end
  return {value=nil}
end
local SettingName={}

local PlayerSettingsMt={}
function PlayerSettingsMt.__index(t,identifier)
  local name = rawget(t,SettingName)
  if identifier=="default" then return settings.player_default[name] end
  return settings.get_player_settings(identifier)[name]
end
function PlayerSettingsMt.__newindex(t,identifier)
  error("Setting is read-only")
end

---add a runtime user setting
---@param setting data.AnyModSettingPrototype
---@return { [string]: ModSetting }
function Setting.user(setting)
  if Stage.is_setting() then
    setting.setting_type = "runtime-per-user"
    if not data.raw[setting.type] or not data.raw[setting.type][setting.name] then
      data:extend{setting}
    end
  end
  if Stage.is_control() then
    local PlayerSetting=setmetatable({[SettingName]=setting.name}, PlayerSettingsMt)
    return PlayerSetting
  end
  return {}
end

return Setting