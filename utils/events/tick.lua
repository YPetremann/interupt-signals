local event = {}

local handlers = {}
local function global_handler()
  for _, handler in pairs(handlers) do handler() end
end

local function global_register(handler)
  script.on_event(defines.events.on_tick, handler)
end

--- register init handler
---@param handler function
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
