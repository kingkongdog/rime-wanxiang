local M = {}

function M.init(env)
    env.last_input = ""
end

function M.func(key, env)
  local engine = env.engine
  local context = engine.context
  local code = key.keycode
  local input = context.input or ""

  if code >= 48 and code <= 57 and #env.last_input == #input then
    -- 这里不要用 key:repr()，否则可能推入 Shift+1
    local char = string.char(code)
    context:push_input(char)
    env.last_input = input .. char
    return 1
  end

  return 2
end

return M