local dummy = {}
function dummy.register() end
function dummy.unregister() end

---make the event dummy if not control stage
---@generic T any
---@param event T
---@return T
local function protect(event) return not Stage.is_control() and dummy or event end

return protect