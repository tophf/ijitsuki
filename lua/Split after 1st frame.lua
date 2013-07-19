script_name = "Split 1 frame"
script_description = "Splits selected lines after 1st frame"
return aegisub.register_macro(script_name, script_description, function(subs, sel, active)
  if not aegisub.frame_from_ms(0) then
    aegisub.log("Load video first!")
    aegisub.cancel()
  end
  for i = #sel, 1, -1 do
    local j = sel[i]
    local l = subs[j]
    if l.class == "dialogue" then
      local t_nextframe = aegisub.ms_from_frame(aegisub.frame_from_ms(l.start_time) + 1)
      local t_end0 = l.end_time
      l.end_time = t_nextframe
      subs.insert(j, l)
      l.start_time, l.end_time = t_nextframe, t_end0
      subs[j + 1] = l
    end
  end
  return sel
end)
