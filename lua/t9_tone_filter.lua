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

    local vowel_letter_map = {
        ["a"] = "a", ["ā"] = "a", ["á"] = "a", ["ǎ"] = "a", ["à"] = "a",
        ["o"] = "o", ["ō"] = "o", ["ó"] = "o", ["ǒ"] = "o", ["ò"] = "o",
        ["e"] = "e", ["ē"] = "e", ["é"] = "e", ["ě"] = "e", ["è"] = "e",
        ["i"] = "i", ["ī"] = "i", ["í"] = "i", ["ǐ"] = "i", ["ì"] = "i",
        ["u"] = "u", ["ū"] = "u", ["ú"] = "u", ["ǔ"] = "u", ["ù"] = "u",
        ["ü"] = "v", ["ǖ"] = "v", ["ǘ"] = "v", ["ǚ"] = "v", ["ǜ"] = "v"
    }

    local function yield_cand_by_tone_and_first_letter(cand, target_tone, target_first_letter)
        local reserve = true

        if target_tone then
            local cand_vowel = cand.comment:match("[%z\128-\255][\128-\191]*")
            if not cand_vowel then
                cand_vowel = cand.comment:match("([aoeiu])")    -- 注意 ü 在上面匹配到
            end
            local cand_tone = cand_vowel and vowel_tone_map[cand_vowel] or nil
            -- 声调匹配校验
            if target_tone ~= cand_tone then
                reserve = false
            end
        end

        if target_first_letter then
            local cand_first_letter = cand.comment:match("[%z\1-\127\194-\244][\128-\191]*")
            cand_first_letter = cand_first_letter and vowel_letter_map[cand_first_letter] or cand_first_letter or nil
             -- 首字母匹配校验
            if target_first_letter ~= cand_first_letter then
                reserve = false
            end
        end

        if reserve then
            yield(cand)
        end
    end

    -- 1. 提取约束条件
    -- 根据声调筛选
    local target_tone_prefix_0 = raw_input:match("[2-9]+0.*([0-4])$")
    local target_tone_prefix_1 = raw_input:match("[2-9]+1.*([0-4])$")
    local target_tone = target_tone_prefix_0 or target_tone_prefix_1
    target_tone = target_tone and tonumber(target_tone)

    -- 根据首字母筛选
    local target_first_letter_prefix_0 = raw_input:match("[2-9]+0.*([a-z])$")
    local target_first_letter_prefix_1 = raw_input:match("[2-9]+1.*([a-z])$")
    local target_first_letter = target_first_letter_prefix_0 or target_first_letter_prefix_1

    -- 如果没有输入筛选符，直接放行
    if not target_tone and not target_first_letter then
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
                yield_cand_by_tone_and_first_letter(cand[1], target_tone, target_first_letter)
            end
        end
    end

    if target_tone_prefix_1 then
        for cand in input:iter() do
            yield_cand_by_tone_and_first_letter(cand, target_tone, target_first_letter)
        end
    end
end

return t9_tone_filter