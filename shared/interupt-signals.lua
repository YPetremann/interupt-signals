local player_built_entity = require("utils.events.player_built_entity")
local entity_logistic_slot_changed = require("utils.events.entity_logistic_slot_changed")
local entity_renamed = require("utils.events.entity_renamed")
local object_destroyed = require("utils.events.object_destroyed")
local gui_closed = require("utils.events.gui_closed")
local robot_built_entity = require "utils.events.robot_built_entity"
local platform_built_entity = require "utils.events.platform_built_entity"
local script_raised_built = require "utils.events.script_raised_built"
local script_raised_revive = require "utils.events.script_raised_revive"
local init = require("utils.events.init")

local virtual_group_name = "[virtual-signal=signal-everything][virtual-signal=signal-signal-parameter]"
local item_group_name = "[virtual-signal=signal-everything][virtual-signal=signal-item-parameter]"
local fuel_group_name = "[virtual-signal=signal-everything][virtual-signal=signal-fuel-parameter]"
local fluid_group_name = "[virtual-signal=signal-everything][virtual-signal=signal-fluid-parameter]"
local group_names = {
  [virtual_group_name] = true,
  [item_group_name] = true,
  [fuel_group_name] = true,
  [fluid_group_name] = true,
}

---@class Object
---@field type string
---@field old_name string?
---@field name string?
---@field entity LuaEntity
---@field force LuaForce

---comment
---@return table<integer, Object>
local function get_objects_store()
  if not storage.objects then storage.objects = {} end
  return storage.objects
end

---@class ForceStore
---@field train_stops table<number, boolean>
---@field constant_combinators table<number, boolean>
---@field virtuals table<integer, LogisticFilter>
---@field items table<integer, LogisticFilter>
---@field fuels table<integer, LogisticFilter>
---@field fluids table<integer, LogisticFilter>

---comment
---@return ForceStore
local function get_force_store(force)
  if not storage.forces then storage.forces = {} end
  if not storage.forces[force.name] then
    storage.forces[force.name] = {
      train_stops = {},
      virtuals = {},
      items = {},
      fuels = {},
      fluids = {},
      constant_combinators = {}
    }
  end
  return storage.forces[force.name]
end

local signal_types = { item = "item", fluid = "fluid", ["virtual-signal"] = "virtual" }
local function process_train_stop(name)
  if not name then return {} end
  local signals = {}
  for signal_type, signal_name in string.gmatch(name, "%[([%w-]+)=([%w-]+)%]") do
    local key = signal_type .. "=" .. signal_name
    local type = signal_types[signal_type]
    local name = signal_name
    if type and name then
      if not signals[key] then
        signals[key] = { type = type, name = name, count = 0 }
      end
      signals[key].count = signals[key].count + 1
    end
  end
  return signals
end

local function process_train_stops(force_store)
  local objects = get_objects_store()
  local global_signals = {}
  for unit_number in pairs(force_store.train_stops) do
    local obj = objects[unit_number]
    local signals = process_train_stop(obj.name)
    for key, signal in pairs(signals) do
      if not global_signals[key] then
        global_signals[key] = { type = signal.type, name = signal.name, count = 0 }
      end
      global_signals[key].count = global_signals[key].count + signal.count
    end
  end

  force_store.items = {}
  force_store.fuels = {}
  force_store.fluids = {}
  force_store.virtuals = {}
  for _, signal in pairs(global_signals) do
    local model = {
      value = { name = signal.name, type = signal.type, quality = "normal", comparator = "=" },
      min = signal.count,
      import_from = "nauvis"
    }
    if signal.type == "item" then table.insert(force_store.items, model) end
    if signal.type == "fluid" then table.insert(force_store.fluids, model) end
    if signal.type == "virtual" then table.insert(force_store.virtuals, model) end
    if signal.type == "item" and prototypes.item[signal.name].fuel_value > 0 then table.insert(force_store.fuels, model) end
    if signal.type == "fluid" and prototypes.fluid[signal.name].fuel_value > 0 then table.insert(force_store.fuels, model) end
  end
end

---comment
---@param control_behaviour LuaConstantCombinatorControlBehavior
---@param name string
---@param filters table<integer, LogisticFilter>
local function update_group(control_behaviour, name, filters)
  ---@type LuaLogisticSection
  local section = nil

  for _, isection in pairs(control_behaviour.sections) do
    if isection.group == name then
      section = isection
      break
    end
  end


  local had_section = section ~= nil
  if not had_section then section = control_behaviour.add_section(name) --[[@as LuaLogisticSection]] end
  section.filters = filters
  if not had_section then control_behaviour.remove_section(section.index) end
end

---@param force LuaForce
local function refresh_sections(force)
  local force_store = get_force_store(force)
  local objects = get_objects_store()
  if table_size(force_store.constant_combinators) == 0 then return end

  local unit_number = next(force_store.constant_combinators) --[[@as number]]
  local entity = objects[unit_number].entity
  if not entity or not entity.valid then return end
  local control_behaviour = entity.get_or_create_control_behavior()

  -- process all train stops to find signals in their names
  process_train_stops(force_store)
  update_group(control_behaviour, virtual_group_name, force_store.virtuals)
  update_group(control_behaviour, item_group_name, force_store.items)
  update_group(control_behaviour, fuel_group_name, force_store.fuels)
  update_group(control_behaviour, fluid_group_name, force_store.fluids)
end

init.register(function()
  storage.objects = {}
  storage.forces = {}

  local has_processed = false
  for _, surface in pairs(game.surfaces) do
    local constant_combinators = surface.find_entities_filtered { type = "constant-combinator" }
    local train_stops = surface.find_entities_filtered { type = "train-stop" }
    for _, entity in pairs(constant_combinators) do
      local force = entity.force
      local unit_number = entity.unit_number or 0
      get_objects_store()[unit_number] = { type = "constant-combinator", entity = entity, force = force }
      get_force_store(force).constant_combinators[unit_number] = true
      script.register_on_object_destroyed(entity)
      has_processed = true
    end
    for _, entity in pairs(train_stops) do
      local force = entity.force
      local name = entity.backer_name
      local unit_number = entity.unit_number or 0
      get_objects_store()[unit_number] = {
        type = "train_stop",
        old_name = nil,
        name = name,
        entity = entity,
        force = force
      }
      get_force_store(force).train_stops[unit_number] = true
      script.register_on_object_destroyed(entity)
      has_processed = true
    end
  end

  if has_processed then
    for _, force in pairs(game.forces) do
      refresh_sections(force)
    end
  end
end)

-- MARK: constant combinators events
local function built_constant_combinator(event)
  local entity = event.entity
  local force = entity.force
  local unit_number = entity.unit_number or 0
  get_objects_store()[unit_number] = { type = "constant-combinator", entity = entity, force = force }
  local constant_combinators = get_force_store(force).constant_combinators
  constant_combinators[unit_number] = true
  script.register_on_object_destroyed(entity)

  -- when first creating constant combinator, refresh right away
  if table_size(constant_combinators) == 1 then
    refresh_sections(force)
  end
end

gui_closed.register(function(event)
  local entity = event.entity
  if not entity or entity.type ~= "constant-combinator" then return end
  refresh_sections(entity.force)
end)

entity_logistic_slot_changed.register(function(event)
  local entity = event.entity
  if not group_names[event.section.group] then return end
  refresh_sections(entity.force --[[@as LuaForce]])
end)

local function built_train_stop(event)
  local entity = event.entity
  local force = entity.force
  local name = entity.backer_name
  local unit_number = entity.unit_number or 0
  get_objects_store()[unit_number] = { type = "train_stop", old_name = nil, name = name, entity = entity, force = force }
  get_force_store(force).train_stops[unit_number] = true
  script.register_on_object_destroyed(entity)
  refresh_sections(force --[[@as LuaForce]])
end

entity_renamed.register(function(event)
  local obj = get_objects_store()[event.entity.unit_number]
  if not obj then return end

  obj.old_name = event.old_name
  obj.name = obj.entity.backer_name
  refresh_sections(obj.entity.force --[[@as LuaForce]])
end)

object_destroyed.register(function(event)
  if event.type ~= defines.target_type.entity then return end
  local unit_number = event.useful_id
  local obj = get_objects_store()[unit_number]
  if not obj then return end

  if obj.type == "train_stop" then
    obj.old_name = obj.name
    obj.name = nil
    refresh_sections(obj.force)
    get_force_store(obj.force).train_stops[unit_number] = nil
  elseif obj.type == "constant-combinator" then
    get_force_store(obj.force).constant_combinators[unit_number] = nil
  end
  get_objects_store()[unit_number] = nil
end)

player_built_entity.register({ { filter = "type", type = "constant-combinator" } }, built_constant_combinator)
robot_built_entity.register({ { filter = "type", type = "constant-combinator" } }, built_constant_combinator)
platform_built_entity.register({ { filter = "type", type = "constant-combinator" } }, built_constant_combinator)
script_raised_revive.register({ { filter = "type", type = "constant-combinator" } }, built_constant_combinator)

player_built_entity.register({ { filter = "type", type = "train-stop" } }, built_train_stop)
robot_built_entity.register({ { filter = "type", type = "train-stop" } }, built_train_stop)
platform_built_entity.register({ { filter = "type", type = "train-stop" } }, built_train_stop)
script_raised_built.register({ { filter = "type", type = "train-stop" } }, built_train_stop)
script_raised_revive.register({ { filter = "type", type = "train-stop" } }, built_train_stop)
