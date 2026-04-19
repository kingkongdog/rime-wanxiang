-- 搭配 t9_tone_filter 使用
-- input 末尾通过 11 12 13 14 10 表示声调
-- input 末尾通过 01 02 03 04 00 表示声调, 同时筛选拼音最长的候选词
-- t9_tone_filter 筛选候选词之后，select 候选词，候选词不会直接上屏，只会改变 preedit。比如选择了 "干"字，preedit 会变成 "干11"
-- 这个 processor 注册 select_notifier，把选中的候选词直接上屏
-- 增加声母筛选功能：[01][a-z]
-- 支持同时筛选声母和声调，声母和声调顺序随意
-- TODO 每 select 一个候选词，就把第一位筛选声调删掉，把第一位筛选首字母删掉

local M = {}

function M.init(env)
    env.select_notifier = env.engine.context.select_notifier:connect(function(ctx)
        if not ctx:is_composing() then
            return
        end

        -- if not ctx.input:match("^%d+$") then
        --     return
        -- end
        
        local filter = ctx.input:match("[2-9]+[01](.*)$")
        local selected_candidate = ctx:get_selected_candidate()
        local selected_text = selected_candidate and selected_candidate.text or ""
        local selected_text_length = utf8.len(selected_text)
        if filter and #filter > 0 then
            ctx:pop_input(#filter)  -- 在把 01 设置为 delimiter 后，比如输入 42614，选择"干"后，preedit 变成 "干4"，01 消失了。
            filter = filter:gsub("%a", "", selected_text_length):gsub("%d", "", selected_text_length) -- 删掉筛选声调和首字母，删除的数量等于选择的候选词的长度
            ctx:push_input(filter)  -- 把剩下的数字和字母重新 push 进去

            local preedit = ctx:get_preedit().text
            if not preedit:match("%d") then
                env.engine:commit_text(preedit:gsub("‸$", ""))
                ctx:clear()
            end
        end
    end)
end

function M.fini(env)
   env.select_notifier:disconnect()
end

function M.func(key, env)
    local context = env.engine.context
    local krepr = key:repr()

    if not context:is_composing() then
        return 2
    end

    -- if not context.input:match("^%d+$") then
    --     return 2
    -- end

    -- 正常按下 backspace 回到前一个 pinyin 的候选词列表。这里拦截一下，改成删除声调和声母
    if context.input:match("[2-9]+[01].*$") and krepr == "BackSpace" then
        context:pop_input(1)
        return 1
    end

    return 2
end

return M