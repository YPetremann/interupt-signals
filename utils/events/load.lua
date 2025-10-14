local event={}

local handlers = {}
local function global_handler()
  for _, handler in pairs(handlers) do handler() end
end

local function global_register(handler)
  script.on_load(handler)
end

--- register load handler
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
---@param handlerOrId function|uint32
function event.unregister(handlerOrId)
  local id = type(handlerOrId) == "number" and handlerOrId or nil
  local handler = type(handlerOrId) == "function" and handlerOrId or nil
  for _id, _handler in pairs(handlers) do 
    if _id == id or _handler == handler then
      handlers[_id] = nil
    end
  end
  if #handlers == 0 then
    global_register(nil)
  end
end

return require("utils.events.dummy")(event)