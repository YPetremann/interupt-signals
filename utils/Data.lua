local Data = {}

---comment
---@generic T: data.AnyPrototype
---@param proto T
---@return T|nil
function Data.extends(proto)
  if Stage.is_data() then
    if data.raw[proto.type] and not data.raw[proto.type][proto.name] then
      data:extend{proto}
    end
    return data.raw[proto.type][proto.name]
  end
end

local DataNilMt = {
  __newindex = function() end,
  __index = function(_,type)
    return setmetatable({}, {
      __newindex = function() end,
      __index = function(_,name)
        return {}
      end
    })
  end,
}

local DataCopyMt = {
  __newindex = function() end,
  __index = function(_,type)
    return setmetatable({}, {
      __newindex = function() end,
      __index = function(_,name)
        if not data.raw[type] or not data.raw[type][name] then return {} end
        return table.deepcopy(data.raw[type][name] or {})
      end
    })
  end,
}

---@type data.raw
Data.raw = Stage.is_control() and setmetatable({},DataNilMt) or data.raw

---@type data.raw
Data.copy = Stage.is_control() and setmetatable({},DataNilMt) or setmetatable({},DataCopyMt)

return Data