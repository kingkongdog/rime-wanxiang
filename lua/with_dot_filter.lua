-- 如果输入包含点号，则删除 preedit 中的所有空格
local function with_dot_filter(input, env)
  local rawInput = env.engine.context.input
  
  if rawInput:find("%.") then
    yield(Candidate("raw", 0, #rawInput, rawInput, ""))
    cand.preedit = cand.preedit:gsub(" ", "")
  else
    for cand in input:iter() do
      yield(cand)
    end
  end
end

return with_dot_filter