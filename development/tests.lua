if Stage.get()~="data" then return end

data.extend{
  {
    type = "tips-and-tricks-item-category",
    name = "tests",
    order = "a"
  },
  {
    type = "tips-and-tricks-item",
    name = "tests",
    category = "tests",
    is_title = true,
    starting_status = "completed",
    order = "a"
  },
  {
    type = "tips-and-tricks-item",
    name = "interupt-signals-tests",
    category = "tests",
    indent=1,
    simulation = {
      init = "require(\"__interupt-signals__/development/tests/setup\")", 
      mods = { "interupt-signals" },
      length = 700,
    },
    trigger = { type="time-elapsed", ticks=10},
    starting_status = "unlocked",
    order = "b"
  }
}