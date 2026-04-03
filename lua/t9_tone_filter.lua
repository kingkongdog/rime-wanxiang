-- input 末尾通过 11 12 13 14 10 表示声调
local function t9_tone_filter(input, env)
    local context = env.engine.context
    local raw_input = context.input
    
    local vowel_tone_map = {
        ["a"] = 0, ["ā"] = 1, ["á"] = 2, ["ǎ"] = 3, ["à"] = 4,
        ["o"] = 0, ["ō"] = 1, ["ó"] = 2, ["ǒ"] = 3, ["ò"] = 4,
        ["e"] = 0, ["ē"] = 1, ["é"] = 2, ["ě"] = 3, ["è"] = 4,
        ["i"] = 0, ["ī"] = 1, ["í"] = 2, ["ǐ"] = 3, ["ì"] = 4,
        ["u"] = 0, ["ū"] = 1, ["ú"] = 2, ["ǔ"] = 3, ["ù"] = 4,
        ["ü"] = 0, ["ǖ"] = 1, ["ǘ"] = 2, ["ǚ"] = 3, ["ǜ"] = 4
    }

    -- 1. 提取约束条件
    local target_tone = raw_input:match("1([0-4])$")
    target_tone = target_tone and tonumber(target_tone)

    -- 如果没有输入筛选符，直接放行
    if not target_tone then
        for cand in input:iter() do
            yield(cand)
        end
    end

    -- 2. 开始过滤候选词
    for cand in input:iter() do
        local pinyin = cand.comment or ""
        
        -- 计算 pinyin 长度不能用 #pinyin，否则带声调的元音的长度计算错误
        if utf8.len(pinyin) == #raw_input - 2 then
            local cand_vowel = pinyin:match("[%z\128-\255][\128-\191]*")
    
            local cand_tone = cand_vowel and vowel_tone_map[cand_vowel] or nil
    
            -- 声调匹配校验
            if target_tone == cand_tone then
                yield(cand)
            end
        end

    end
end

return t9_tone_filter