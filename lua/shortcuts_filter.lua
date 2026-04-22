local wanxiang = require("wanxiang/wanxiang")
local privacy = require("./privacy")

local jianma = {
  l = "了",
  d = "的",
  b = "吧",
  n = "呢",
  m = "吗",
  z = "在",
  s = "是"
}

local function deal_with_jianma(input, segment)
    local text = jianma[input]
    if text then
      yield(Candidate("raw", segment._start, segment._end, text, ""))
    end
end

local function deal_with_privacy(input, segment)
    local arr = privacy[input]
    if arr then
      for _, text in ipairs(arr) do
        yield(Candidate("raw", segment._start, segment._end, text, ""))
      end
    end
end

local M = {}

function M.init(env)
    env.is_t9 = false
    if wanxiang.get_input_method_type then
        local im_type = wanxiang.get_input_method_type(env)
        if im_type == "t9" then
            env.is_t9 = true
        end
    end
end

function M.func(input, env)
  local rawInput = env.engine.context.input

  local composition = env.engine.context.composition
  if not composition:empty() then
    local segment = composition:back()
    local segment_input = rawInput:sub(segment._start + 1, segment._end)

    if not env.is_t9 then
      deal_with_jianma(segment_input, segment)
    end

    deal_with_privacy(segment_input, segment)
  end

  for cand in input:iter() do
    yield(cand)
  end
end

return M