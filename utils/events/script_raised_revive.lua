require("util")

local function table_includes(tbl, val)
  for _, v in pairs(tbl) do if v == val then return true end end
  return false
end

local function flatten(tbl, n)
  n = n or 1
  if n <= 0 then return tbl end
  local out = {}
  for _, v in pairs(tbl or {}) do
    if type(v) == "table" then
      for _, v2 in pairs(flatten(v, n - 1)) do table.insert(out, v2) end
    else
      table.insert(out, v)
    end
  end
  return out
end

-- MARK: -Filters Porcessors

local rail_types = { "straight-rail", "curved-rail-a", "curved-rail-b", "half-diagonal-rail", "elevated-straight-rail",
  "elevated-curved-rail-a", "elevated-curved-rail-b", "elevated-half-diagonal-rail", "rail-ramp" }
local rail_signal_types = { "rail-signal", "rail-chain-signal" }
local rolling_stock_types = { "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon" }
local robot_logistic_type = { "logistic-robot", "construction-robot" }
local vehicle_type = { "car", "tank", "spider-vehicle" }
local turret_type = { "ammo-turret", "electric-turret", "fluid-turret", "artillery-turret" }
local crafting_machine_type = { "assembling-machine", "furnace", "rocket-silo" }
local wall_connectable = { "wall", "gate" }
local transport_belt_connectable = { "transport-belt", "underground-belt", "splitter", "loader-1x1", "loader",
  "lane-splitter", "linked-belt" }
local circuit_network_connectable = { "constant-combinator", "decider-combinator", "arithmetic-combinator",
  "power-switch", "circuit-network" }


local filter_processors = {
  ["name"] = function(f, e) return e.entity.name == f.name end,
  ["type"] = function(f, e) return e.entity.type == f.type end,
  ["force"] = function(f, e) return e.entity.force.name == f.force end,
  ["ghost_name"] = function(f, e) return e.entity.ghost_name == f.ghost_name end,
  ["ghost_type"] = function(f, e) return e.entity.ghost_type == f.ghost_type end,
  ["ghost"] = function(f, e) return e.entity.type == "entity-ghost" or e.entity.type == "tile-ghost" end,
  ["rail"] = function(f, e) return table_includes(rail_types, e.entity.type) end,
  ["rail-signal"] = function(f, e) return table_includes(rail_signal_types, e.entity.type) end,
  ["rolling-stock"] = function(f, e) return table_includes(rolling_stock_types, e.entity.type) end,
  ["robot-with-logistics-interface"] = function(f, e) return table_includes(robot_logistic_type, e.entity.type) end,
  ["vehicle"] = function(f, e) return table_includes(vehicle_type, e.entity.type) end,
  ["turret"] = function(f, e) return table_includes(turret_type, e.entity.type) end,
  ["crafting-machine"] = function(f, e) return table_includes(crafting_machine_type, e.entity.type) end,
  ["wall-connectable"] = function(f, e) return table_includes(wall_connectable, e.entity.type) end,
  ["transport-belt-connectable"] = function(f, e) return table_includes(transport_belt_connectable, e.entity.type) end,
  ["circuit-network-connectable"] = function(f, e) return table_includes(circuit_network_connectable, e.entity.type) end,
  ["default"] = function(f, e) return true end,
}

local function filters_processor(filters, event)
  if #filters == 0 then return true end
  local passed = false
  for _, single_filter in pairs(filters) do
    if single_filter.mode ~= "and" then
      if passed then return true end
      passed = true
    end
    local filter_processor = filter_processors[single_filter.filter] or filter_processors["default"]
    local result = filter_processor(single_filter, event)
    if single_filter.invert then result = not result end
    if not result then passed = false end
  end
  return passed
end

-- MARK: -Filters Registry

local filters_registry = {}

local function get_filter(filter)
  for id, existing_filter in pairs(filters_registry) do
    if table.compare(existing_filter, filter) then return id end
  end
end

--- register filter, check if it already exists and return its id
local function register_filter(filter)
  local id = get_filter(filter)
  if id then return id end
  table.insert(filters_registry, filter)
  return #filters_registry
end

local function unregister_filter(id)
  filters_registry[id] = nil
end

-- MARK: - Handler

local handlers_registry = {}

local function global_handler(event)
  local only_one = #filters_registry == 1
  local passed = false
  for filter_id, filter in pairs(filters_registry) do
    for _, handler in pairs(handlers_registry[filter_id]) do
      if only_one or filters_processor(filter, event) then
        passed = true
        handler(event)
      end
    end
  end
  if not passed then error("Event player_built_entity should have been processed") end
end


local function global_register(handler, filters)
  filters = filters and flatten(filters, 1)
  script.on_event(defines.events.script_raised_revive, handler, filters)
end

-- MARK: -Handler Registry
local event = {}

--- register init handler
---@param filter LuaScriptRaisedReviveEventFilter[]
---@param handler fun(event:EventData.script_raised_revive )
---@return uint32
function event.register(filter, handler)
  print("register player_built_entity event")
  filter = filter or {}
  local filter_id = register_filter(filter)
  handlers_registry[filter_id] = handlers_registry[filter_id] or {}
  for _id, _handler in pairs(handlers_registry[filter_id]) do
    if _handler == handler then return _id end
  end
  table.insert(handlers_registry[filter_id], handler)
  global_register(global_handler, filters_registry)
  return #handlers_registry[filter_id]
end

--- unregister init handler
---@param filter {handler:function}|{id:uint32}|{filter:LuaScriptRaisedReviveEventFilter[]}
function event.unregister(filter)
  local _filter_id = nil
  if filter.filter then _filter_id = get_filter(filter.filter) end
  for filter_id, filterHandlers in pairs(handlers_registry) do
    for handler_id, handler in pairs(filterHandlers) do
      if handler_id == filter.id or handler == filter.handler or filter_id == _filter_id then
        filterHandlers[handler_id] = nil
      end
    end
    if #filterHandlers == 0 then
      handlers_registry[filter_id] = nil
      unregister_filter(filter_id)
    end
  end
  if #handlers_registry == 0 then global_register(nil) end
end

return require("utils.events.dummy")(event)
