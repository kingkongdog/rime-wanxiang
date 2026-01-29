local M = {}

function M.init(env)
    env.last_input_time_ms = 0
end

function M.func(key, env)
  local engine = env.engine
  local context = engine.context
  local code = key.keycode
  local input_time_ms = rime_api.get_time_ms()

  if code >= 48 and code <= 57 and input_time_ms - env.last_input_time_ms > 70 then
    -- 这里不要用 key:repr()，否则可能推入 Shift+1
    context:push_input(string.char(code))
    env.last_input_time_ms = input_time_ms
    return 1
  end

  return 2
end

return M