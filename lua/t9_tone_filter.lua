-- input 末尾通过 11 12 13 14 10 表示声调
-- input 末尾通过 01 02 03 04 00 表示声调, 同时筛选拼音最长的候选词

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

    local function yield_cand_by_tone(cand, target_tone)
        local cand_vowel = cand.comment:match("[%z\128-\255][\128-\191]*")
        if not cand_vowel then
            cand_vowel = cand.comment:match("([aoeiu])")    -- 注意 ü 在上面匹配到
        end
        local cand_tone = cand_vowel and vowel_tone_map[cand_vowel] or nil
        -- 声调匹配校验
        if target_tone == cand_tone then
            yield(cand)
        end
    end

    -- 1. 提取约束条件
    local target_tone_prefix_0 = raw_input:match("[2-9]+0([0-4])$")
    local target_tone_prefix_1 = raw_input:match("[2-9]+1([0-4])$")
    local target_tone = target_tone_prefix_0 or target_tone_prefix_1
    target_tone = target_tone and tonumber(target_tone)

    -- 如果没有输入筛选符，直接放行
    if not target_tone then
        for cand in input:iter() do
            yield(cand)
        end
    end

    -- 获取最长的候选词拼音长度
    if target_tone_prefix_0 then 
        local maxLength = 0
        local cands = {}
        for cand in input:iter() do
            local pinyin = cand.comment:gsub("%s+", "")
            local length = utf8.len(pinyin)
            table.insert(cands, {cand, length})
            if length > maxLength and length <= #raw_input - 2 then  -- 有时候候选词长度会大于 input 长度，比如想输入囧， 按下 54664
                maxLength = length
            end
        end

        for i, cand in ipairs(cands) do
            -- 计算 pinyin 长度不能用 #pinyin，否则带声调的元音的长度计算错误
            if cand[2] == maxLength then
                yield_cand_by_tone(cand[1], target_tone)
            end
        end
    end

    if target_tone_prefix_1 then
        for cand in input:iter() do
            yield_cand_by_tone(cand, target_tone)
        end
    end
end

return t9_tone_filter