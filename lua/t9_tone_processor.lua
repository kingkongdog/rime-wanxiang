-- 搭配 t9_tone_filter 使用
-- input 末尾通过 11 12 13 14 10 表示声调
-- input 末尾通过 01 02 03 04 00 表示声调, 同时筛选拼音最长的候选词
-- t9_tone_filter 筛选候选词之后，select 候选词，候选词不会直接上屏，只会改变 preedit。比如选择了 "干"字，preedit 会变成 "干11"
-- 这个 processor 注册 select_notifier，把选中的候选词直接上屏
-- 增加声母筛选功能：[01][a-z]
-- 支持同时筛选声母和声调，声母和声调顺序随意

local M = {}

local function get_selected_text_length(env)
    local context = env.engine.context
    -- 这里有个有意思的陷阱：gsub 函数返回两个值，第一个是替换后的字符串，第二个是替换的次数。
    -- utf8.len 如果不传第二个参数 1，gsub 返回的两个值将作为 len 的参数。
    -- 会报错：bad argument #2 to 'len' (initial position out of bounds)
    local length = utf8.len(context:get_script_text():gsub("[%z\1-\127]", ""), 1) - utf8.len(env.script_text:gsub("[%z\1-\127]", ""), 1)
    env.script_text = context:get_script_text()
    return length
end

function M.init(env)
    env.script_text = ""
    -- env.engine.context.commit_notifier:connect(function(ctx)
    --     local commit_text = ctx:get_commit_text()
    --     -- 在这里处理上屏的文字
    --     log.info("触发了上屏文字为: " .. commit_text)
    -- end)
    env.select_notifier = env.engine.context.select_notifier:connect(function(ctx)
        -- if not ctx.input:match("^%d+$") then
        --     return
        -- end
        
        local filter = ctx.input:match("[2-9]+[01](.*)$")
        -- local selected_candidate = ctx:get_selected_candidate()
        -- local selected_text = selected_candidate and selected_candidate.text or ""  -- 获取到的竟然不是上次 confirm 的候选词，而是当前候选词列表的第一项。
        -- local selected_text_length = utf8.len(selected_text)
        if filter then
            ctx:pop_input(#filter)
            local selected_text_length = get_selected_text_length(env)
            filter = filter:gsub("%a", "", selected_text_length):gsub("%d", "", selected_text_length) -- 删掉筛选声调和首字母，删除的数量等于选择的候选词的长度
            if #filter > 0 then
                ctx:push_input(filter)  -- 把剩下的数字和字母重新 push 进去
            else
                ctx:pop_input(1)  -- 如果没有剩下的了，就把 delimiter 也删掉
            end

            local preedit = ctx:get_preedit().text
            if not preedit:match("%d") then
                env.engine:commit()
                -- env.engine:commit_text(preedit:gsub("‸$", ""))
                -- ctx:clear()
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
        env.script_text = ""
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