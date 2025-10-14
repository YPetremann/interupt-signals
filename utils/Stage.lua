Stage = {}

---@type "setting" | "setting-updates" | "setting-final-fixes" | "data" | "data-updates" | "data-final-fixes" | "control" | "migration"
local stage = nil

function Stage.set(new_stage)
  if stage then error("Stage is already set to "..stage) end
  stage = new_stage
end
function Stage.get() return stage end

local function includes(tbl, val)
  for _, v in pairs(tbl) do if v == val then return true end end
  return false
end

function Stage.is_setting() return includes({"setting", "setting-updates", "setting-final-fixes"}, stage) end
function Stage.is_data() return includes({"data", "data-updates", "data-final-fixes"}, stage) end
function Stage.is_updates() return includes({"setting-updates", "data-updates"}, stage) end
function Stage.is_final_fixes() return includes({"setting-final-fixes", "data-final-fixes"}, stage) end
function Stage.is_control() return includes({"control"}, stage) end
function Stage.is_migration() return includes({"migration"}, stage) end

return Stage