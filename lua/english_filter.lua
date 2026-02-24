local function english_filter(input, env)
    -- 设定触发长度：输入 2 个及以上字母才显示英文
    local min_length = 2
    
    for cand in input:iter() do
        -- 核心逻辑：
        -- 1. 使用 string.match 检查候选词文本 (cand.text) 是否只包含英文字母 [a-zA-Z]
        -- 2. 检查当前输入框内的编码长度 (#env.engine.context.input)
        
        local is_pure_english = cand.text:match("^[a-zA-Z]+$")
        local input_len = #env.engine.context.input

        if is_pure_english and input_len < min_length then
            -- 如果是纯英文且输入太短，跳过该候选词
            -- TODO 有些英文后面会有表情符号，一并过滤掉
            goto continue
        end
        
        yield(cand)
        ::continue::
    end
end

return english_filter