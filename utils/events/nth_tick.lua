local event = {}

local handlers = {}
local function global_handler(event)
  for _, handler in pairs(handlers) do handler(event) end
end

local function global_register(tick, handler)
  script.on_nth_tick(tick, handler)
end

--- register init handler
---@param tick uint32|uint32[]
---@param handler fun(event: NthTickEventData)
---@return uint32
function event.register(tick, handler)
  local ticks = type(tick) == "number" and { tick }
      or type(tick) == "table" and tick
      or {}

  for _, tick in pairs(ticks) do
    handlers[tick] = handlers[tick] or {}
    table.insert(handlers[tick], handler)
    global_register(tick, global_handler)
  end
  return #handlers
end

--- unregister init handler
---@param filter {handler:function}|{id:uint32}|{tick:uint32}
function event.unregister(filter)
  for tick, handlerList in pairs(handlers) do
    for id, handler in pairs(handlerList) do
      if handler == filter.handler or id == filter.id or tick == filter.tick then
        handlerList[id] = nil
      end
    end
    if #handlerList == 0 then
      handlers[tick] = nil
      global_register(tick, nil)
    end
  end
end

return require("utils.events.dummy")(event)
