local map = {
  l = "了",
  d = "的",
  b = "吧",
  n = "呢",
  m = "吗",
  z = "在",
  s = "是"
}

local function shortcuts_filter(input, env)
  local rawInput = env.engine.context.input

  local composition = env.engine.context.composition
  if not composition:empty() then
    local segment = composition:back()
    local segment_input = rawInput:sub(segment._start + 1, segment._end)
    local text = map[segment_input]
    if text then
      yield(Candidate("raw", segment._start, segment._end, text, ""))
    end
  end

  for cand in input:iter() do
    yield(cand)
  end
end

return shortcuts_filter