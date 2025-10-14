local effect_ids = {
  ["rail-layer-build"] = require("events.script_trigger_effect.rail-layer-build"),
}
local event = {}

local handlers = {}
local function global_handler(event)
  effectHandlers = handlers[event.effect_id] or {}
  for _, handler in pairs(effectHandlers) do handler(event) end
end

local function global_register(handler)
  script.on_event(defines.events.on_script_trigger_effect, handler)
end

--- register init handler
---@param effect_id string
---@param handler fun(event:EventData.on_script_trigger_effect)
---@return uint32
function event.register(effect_id, handler)
  handlers[effect_id] = handlers[effect_id] or {}
  for _id, _handler in pairs(handlers[effect_id]) do
    if _handler == handler then return _id end
  end
  table.insert(handlers[effect_id], handler)
  global_register(global_handler)
  return #handlers[effect_id]
end

--- unregister init handler
---@param filter {handler:function}|{id:uint32}|{effect_id:string}
function event.unregister(filter)
  for effect_id, effectHandlers in pairs(handlers) do
    for id, handler in pairs(effectHandlers) do
      if id == filter.id or handler == filter.handler or effect_id == filter.effect_id then
        effectHandlers[id] = nil
      end
    end
    if #effectHandlers == 0 then handlers[effect_id] = nil end
  end
  if #handlers == 0 then global_register(nil) end
end

return require("utils.events.dummy")(event)
