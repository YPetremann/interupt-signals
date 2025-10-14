require("util")

-- MARK: - Handler

local handlers_registry = {}

local function global_handler(event)
  for _, handler in pairs(handlers_registry) do
    handler(event)
  end
end


local function global_register(handler)
  script.on_event(defines.events.on_object_destroyed, handler)
end

-- MARK: -Handler Registry
local event = {}

--- register init handler
---@param handler fun(event:EventData.on_object_destroyed)
---@return uint32
function event.register(handler)
  for _id, _handler in pairs(handlers_registry) do
    if _handler == handler then return _id end
  end
  table.insert(handlers_registry, handler)
  global_register(global_handler)
  return #handlers_registry
end

--- unregister init handler
---@param filter {handler:function}|{id:uint32}
function event.unregister(filter)
  for handler_id, handler in pairs(handlers_registry) do
    if handler_id == filter.id or handler == filter.handler then
      handlers_registry[handler_id] = nil
    end
  end
  if #handlers_registry == 0 then global_register(nil) end
end

return require("utils.events.dummy")(event)
