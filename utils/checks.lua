if Stage.is_control() then
  if mod_name ~= script.mod_name then
    error("Incorrect mod_name: expected " .. script.mod_name .. ", got " .. mod_name)
  end
  if mod_version ~= script.active_mods[script.mod_name] then
    error("Incorrect mod_version: expected " .. script.active_mods[script.mod_name] .. ", got " .. mod_version)
  end
  helpers.check_prototype_translations()
end