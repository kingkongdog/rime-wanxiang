-- 解决预测候选出现时，按空格会往 input 里 push 0 的问题

local M = {}

function M.func(key, env)
    local engine = env.engine
    local context = engine.context
    local input = context.input
    local keycode = key.keycode

    engine:commit_text(tostring(keycode))
    context:clear()
    return 1

    -- if key:release() then
    --     return 2
    -- end

    -- if context:is_composing() and keycode == 48 then
    --     engine:commit_text(" ")
    --     context:clear()
    --     return 1
    -- end

    -- return 2
end

return M
