-- input 末尾是 1 时，要求候选词的拼音的长度与 input 的长度一致
local function t9_input_length_filter(input, env)
    local context = env.engine.context
    local raw_input = context.input
    
    if raw_input:match("1$") and not raw_input:match("11$") then
        for cand in input:iter() do
            local pinyin = cand.comment or ""
            
            -- 计算 pinyin 长度不能用 #pinyin，否则带声调的元音的长度计算错误
            if utf8.len(pinyin) == #raw_input - 1 then
                yield(cand)
            end
        end
    else
        for cand in input:iter() do
            yield(cand)
        end
    end
end

return t9_input_length_filter