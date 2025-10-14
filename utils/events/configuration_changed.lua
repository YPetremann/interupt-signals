local event = {}


local handlers = {}
local function global_handler(event)
  for _, handler in pairs(handlers) do handler(event) end
end

local function global_register(handler)
  script.on_configuration_changed(handler)
end

--- register init handler
---@param handler fun(event:ConfigurationChangedData)
---@return uint32
function event.register(handler)
  for _id, _handler in pairs(handlers) do
    if _handler == handler then return _id end
  end
  table.insert(handlers, handler)
  global_register(global_handler)
  return #handlers
end

--- unregister init handler
---@param filter {handler:function}|{id:uint32}
function event.unregister(filter)
  for _id, _handler in pairs(handlers) do
    if _id == filter.id or _handler == filter.handler then
      handlers[_id] = nil
    end
  end
  if #handlers == 0 then
    global_register(nil)
  end
end

return require("utils.events.dummy")(event)
