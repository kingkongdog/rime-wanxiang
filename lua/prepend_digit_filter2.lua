-- number_first.lua
local digit_map = {
  ["ling"] = "⓪",
  ["yi"]   = "①",
  ["er"]   = "②",
  ["san"]  = "③",
  ["si"]   = "④",
  ["wu"]   = "⑤",
  ["liu"]  = "⑥",
  ["qi"]   = "⑦",
  ["ba"]   = "⑧",
  ["jiu"]  = "⑨",
  ["shi"]  = "⑩",
}

local function filter(input, env)
  local context = env.engine.context
  local input_str = context.input
  local target_symbol = digit_map[input_str]

  -- 1. 如果当前输入不匹配目标拼音，直接流式放行，不做任何额外处理（性能开销极低）
  if not target_symbol then
    for cand in input:iter() do
      yield(cand)
    end
    return
  end

  -- 2. 匹配拼音时的逻辑：在第 2 个位置插入自定义符号
  local count = 0
  local inserted = false
  local symbol_cand = Candidate("raw", 0, #input_str, target_symbol, "")

  for cand in input:iter() do
    count = count + 1
    -- 如果到了第 2 位且尚未插入，先 yield 自定义符号
    if count == 2 then
      yield(symbol_cand)
      inserted = true
    end
    yield(cand)
  end

  -- 边缘情况处理：如果原候选词总数少于 1 个（例如 0 个或 1 个），确保符号依然能被输出
  if not inserted then
    yield(symbol_cand)
  end
end

return filter