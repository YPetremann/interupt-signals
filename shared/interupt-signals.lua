local player_built_entity = require("utils.events.player_built_entity")
local entity_logistic_slot_changed = require("utils.events.entity_logistic_slot_changed")
local entity_renamed = require("utils.events.entity_renamed")
local object_destroyed = require("utils.events.object_destroyed")
local gui_closed = require("utils.events.gui_closed")
local init = require("utils.events.init")

local groupname = "[virtual-signal=signal-everything][virtual-signal=signal-signal-parameter]"

init.register(function()
  storage.objects = {}
  storage.forces = {}
end)

local function get_objects_store()
  if not storage.objects then storage.objects = {} end
  return storage.objects
end

local function get_force_store(force)
  if not storage.forces then storage.forces = {} end
  if not storage.forces[force.name] then
    storage.forces[force.name] = {
      train_stops = {},
      filters= {},
      constant_combinators = {}
    }
  end
  return storage.forces[force.name]
end

local function get_control_behaviour(force_store)
  local exist = false
  for i in pairs(force_store.constant_combinators) do exist = true break end
  if not exist then return nil,nil end
  local objects = get_objects_store()
  for unit_number, _ in pairs(force_store.constant_combinators) do
    local entity = objects[unit_number].entity
    if not entity or not entity.valid then goto continue end
    local control_behaviour = entity.get_or_create_control_behavior()
    if not control_behaviour then goto continue end
    for _,section in pairs(control_behaviour.sections) do
      if section.group == groupname then
        return control_behaviour, section
      end
    end
    ::continue::
  end

  local entity = nil
  for unit_number in pairs(force_store.constant_combinators) do
    local obj = objects[unit_number]
    if obj then
      local ent = objects[unit_number].entity
      if ent and ent.valid then entity=ent end
    end
  end
  if not entity then return nil,nil end
  local control_behaviour = entity.get_or_create_control_behavior()
  return control_behaviour, nil
end

--- this function processes a train stop name and returns the signals found in it
--- for example, a train stop named "Iron Ore [item=iron-ore][fluid=water][item=iron-ore]"
--- will return {{type="item",name="iron-ore",count=2}, {type="fluid",name="water",count=1}}
--- count depends on the number of times the signal appears in the name
local function process_train_stop(name)
  if not name then return {} end
  local signals = {}
  for signal_type, signal_name in string.gmatch(name, "%[(%a+)=(%S-)%]") do
    if signal_type and signal_name then
      local key = signal_type.."="..signal_name
      if not signals[key] then signals[key] = { type = signal_type, name = signal_name, count = 0 } end
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
    for key,signal in pairs(signals) do
      if not global_signals[key] then
        global_signals[key] = { type = signal.type, name = signal.name, count = 0 }
      end
      global_signals[key].count = global_signals[key].count + signal.count
    end
  end

  force_store.filters = {}
  for _,signal in pairs(global_signals) do
    table.insert(force_store.filters, {
      value = {
        name = signal.name,
        type = signal.type,
        quality = "normal",
        comparator = "=",
      },
      min = signal.count,
      max = signal.count,
      import_from = "nauvis"
    })
  end
end

local function refresh_sections(force)
  local force_store = get_force_store(force)
  local control_behaviour, section = get_control_behaviour(force_store)
  if not control_behaviour then return end

  -- process all train stops to find signals in their names
  process_train_stops(force_store)

  local had_section = section ~= nil
  if not had_section then section = control_behaviour.add_section(groupname) end
  section.filters = force_store.filters
  if not had_section then control_behaviour.remove_section(section.index) end
end

-- MARK: constant combinators events
player_built_entity.register({ { filter = "type", type = "constant-combinator" } }, function(event)
  local entity = event.entity
  local force = entity.force
  local unit_number = entity.unit_number
  get_objects_store()[unit_number] = { type = "constant-combinator", entity=entity, force = force }
  get_force_store(force).constant_combinators[unit_number] = true
  script.register_on_object_destroyed(entity)
  -- we check if the entity has the group

  refresh_sections(force, entity)

  -- remove group
end)

player_built_entity.register({ { filter = "type", type = "train-stop" } }, function(event)
  local entity = event.entity
  local force = entity.force
  local name = entity.backer_name
  local unit_number = entity.unit_number
  get_objects_store()[unit_number] = { type = "train_stop", old_name = nil, name = name, entity=entity, force = force }
  get_force_store(force).train_stops[unit_number] = true
  script.register_on_object_destroyed(entity)
  refresh_sections(force)
end)


gui_closed.register(function(event)
  local entity = event.entity
  if not entity or entity.type ~= "constant-combinator" then return end
  refresh_sections(entity.force, entity)
end)

entity_logistic_slot_changed.register(function(event)
  local entity = event.entity
  if event.section.group ~= groupname then return end
  refresh_sections(entity.force, entity)
end)

entity_renamed.register(function(event)
  local entity = event.entity
  local unit_number = entity.unit_number
  local objects = get_objects_store()
  objects[unit_number].old_name = event.old_name
  objects[unit_number].name = entity.backer_name
  refresh_sections(entity.force)
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
