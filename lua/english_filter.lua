-- 英文长度过滤插件
local function english_filter(input, env)
    -- 设定触发长度，比如输入 2 个字母以上才显示英文词库结果
    local min_length = 2
    
    for cand in input:iter() do
        -- 判断候选词是否来自你的英文翻译器 (wanxiang_english)
        -- 或者通过候选词内容是否包含英文字母来判断
        if (cand.type == "table" and #env.engine.context.input < min_length) then
            -- 如果输入长度太短，则跳过该候选词（不显示）
            goto continue
        end
        yield(cand)
        ::continue::
    end
end

return english_filter