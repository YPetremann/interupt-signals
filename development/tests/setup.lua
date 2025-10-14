require("__core__/lualib/story")
local player  = game.simulation.create_test_player { name = "big k" }
local surface = player.surface

player.teleport({ -8.5, -1.5 })
player.character.direction = defines.direction.south

game.simulation.camera_player = player
game.simulation.camera_position = { 0, 0.5 }
game.simulation.camera_alt_info = true
game.simulation.camera_player_cursor_position = player.position

surface.create_entity { position = { 6, -6 }, name = "straight-rail", force = player.force }
surface.create_entity { position = { 6, -4 }, name = "straight-rail", force = player.force }
surface.create_entity { position = { 6, -2 }, name = "straight-rail", force = player.force }
surface.create_entity { position = { 6, 0 }, name = "straight-rail", force = player.force }
surface.create_entity { position = { 6, 2 }, name = "straight-rail", force = player.force }
surface.create_entity { position = { 6, 4 }, name = "straight-rail", force = player.force }
surface.create_entity { position = { 6, 6 }, name = "straight-rail", force = player.force }


local view_delay = 0.5

local function move_cursor(position, speed)
  return function() return game.simulation.move_cursor({ position = position, speed = speed or 0.75 }) end
end
local function mouse_click()
  return function() return game.simulation.mouse_click() end
end
local function control_press(control)
  return function() return game.simulation.control_press { control = control, notify = false } end
end
local function story_jump(to)
  return function() return story_jump_to(storage.story, to) end
end
local function cursor_stack(stack)
  return function()
    if stack == nil then
      player.cursor_stack.clear()
      return
    end
    player.cursor_stack.set_stack(stack)
  end
end
local function sound(name)
  return function() return game.play_sound { path = name, position = player.position } end
end
local function write(text)
  return function() return game.simulation.write { text = text } end
end
local function instant()
  return story_elapsed_check(0)
end
local function sleepDisplay()
  return story_elapsed_check(view_delay)
end

local station1_pos                          = { 9, -3 }
local station2_pos                          = { 9, 3 }
local combinator1_pos                       = { -8.5, 2.5 }
local combinator2_pos                       = { -6.5, 2.5 }
local train_station_rename_pos              = { -6.3, -4.1 }
local train_station_rename_valid_pos        = { -1.9, -3 }
local combinator_rename_pos                 = { -0.5, 0.6 }
local combinator_wildcard_pos               = { 0.5, 2.6 }

local station1
local station2
local combinator1
local combinator2
player.force.character_build_distance_bonus = 20
local story_table                           = {
  {
    { name = "loop" },
    { condition = move_cursor(player.position) },
    { action = function() print(" \n--- start of loop") end },

    -- setup entities
    { action = cursor_stack { name = "train-stop", count = 2 } },
    { condition = move_cursor(station1_pos),                            action = mouse_click() },
    { condition = move_cursor(station2_pos),                            action = mouse_click() },
    { action = cursor_stack { name = "constant-combinator", count = 2 } },
    { condition = move_cursor(combinator1_pos),                         action = mouse_click() },
    { condition = move_cursor(combinator2_pos),                         action = mouse_click() },
    {
      action = function()
        station1 = surface.find_entities_filtered { position = station1_pos, radius = 2, name = "train-stop" }[1]
        station2 = surface.find_entities_filtered { position = station2_pos, radius = 2, name = "train-stop" }[1]
        combinator1 = surface.find_entities_filtered { position = combinator1_pos, radius = 1, name = "constant-combinator" }
            [1]
        combinator2 = surface.find_entities_filtered { position = combinator2_pos, radius = 1, name = "constant-combinator" }
            [1]
        station1.backer_name = "Train station 1"
        station2.backer_name = "Train station 2"
      end
    },

    -- setup combinator 1
    { condition = move_cursor(player.position) },
    { condition = move_cursor(combinator1_pos),                action = mouse_click() },
    { condition = sleepDisplay() },
    { condition = move_cursor(combinator_rename_pos),          action = mouse_click() },
    { condition = move_cursor(combinator_wildcard_pos),        action = mouse_click() },
    { action = mouse_click() },
    { condition = sleepDisplay(),                              action = control_press("confirm-gui") },

    -- setup first station
    { condition = move_cursor(station1_pos),                   action = mouse_click() },
    { condition = move_cursor(train_station_rename_pos),       action = mouse_click() },
    { condition = sleepDisplay(),                              action = write("[item=iron-ore][item=copper-ore] Provide") },
    { condition = move_cursor(train_station_rename_valid_pos), action = mouse_click() },
    { condition = sleepDisplay(),                              action = control_press("confirm-gui") },

    -- setup combinator 2
    { condition = move_cursor(player.position) },
    { condition = move_cursor(combinator2_pos),                action = mouse_click() },
    { condition = sleepDisplay() },
    { condition = move_cursor(combinator_rename_pos),          action = mouse_click() },
    { condition = move_cursor(combinator_wildcard_pos),        action = mouse_click() },
    { action = mouse_click() },
    { condition = sleepDisplay(),                              action = control_press("confirm-gui") },

    -- setup second station
    { condition = move_cursor(station2_pos),                   action = mouse_click() },
    { condition = move_cursor(train_station_rename_pos),       action = mouse_click() },
    { condition = sleepDisplay(),                              action = write("[item=stone][item=coal] Provide") },
    { condition = move_cursor(train_station_rename_valid_pos), action = mouse_click() },
    { condition = sleepDisplay(),                              action = control_press("confirm-gui") },

    -- check combinator
    { condition = move_cursor(combinator1_pos),                action = mouse_click() },
    { condition = sleepDisplay(),                              action = control_press("confirm-gui") },

    -- check combinator
    { condition = move_cursor(combinator2_pos),                action = mouse_click() },
    { condition = sleepDisplay(),                              action = control_press("confirm-gui") },

    -- ending
    { condition = move_cursor(player.position) },
    {
      action = function()
        station1.die()
        station2.die()
        combinator1.die()
        combinator2.die()
      end
    },
    { condition = story_elapsed_check(4), action = story_jump("loop") }
  }
}

tip_story_init(story_table)
