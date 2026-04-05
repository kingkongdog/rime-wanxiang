-- 搭配 t9_tone_filter 使用
-- input 末尾通过 11 12 13 14 10 表示声调
-- t9_tone_filter 筛选候选词之后，select 候选词，候选词不会直接上屏，只会改变 preedit。比如选择了 "干"字，preedit 会变成 "干11"
-- 这个 processor 注册 select_notifier，把选中的候选词直接上屏
-- 增加 input 末尾是 1 功能

local M = {}

function M.init(env)
    env.select_notifier = env.engine.context.select_notifier:connect(function(ctx)
        if ctx.input:match("1[0-4]$") then
            ctx.pop_input(2)
        end
    end)
end

function M.fini(env)
   env.select_notifier:disconnect()
end

return M