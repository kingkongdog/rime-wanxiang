-- input 末尾通过 11 12 13 14 10 表示声调
-- input 末尾通过 01 02 03 04 00 表示声调, 同时筛选拼音最长的候选词
-- 增加声母筛选功能：[01][a-z]
-- 支持同时筛选声母和声调，声母和声调顺序随意
-- 增加支持多声调多声母功能：[01]1234bpmf：【01】后面的数字序列分别对应每个字的声调，字母对应每个字的声母，数字和字母顺序随意，比如 1a2b3c4d 或者 a1b2c3d4 或者 1a2b3c4d 或者 a1b2c3d4 等等
-- TODO: 发现会把 emoji 过滤掉。如果想保留 emoji 的话，就要把原始的候选词分组，就要提前循环一次。那就可以把 0 和 1 前缀统一了。按照 长度过滤 -> 声调过滤 -> 首字母过滤 的顺序来处理就好了。

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

    local function split_by_space (str)
        local results = {}

        for word in string.gmatch(str, "%S+") do
            table.insert(results, word)
        end

        return results
    end

    local comment_map = {}
    local function check_cand_wanted(cand_comment, cand_pinyin_length, target_pinyin_length, target_tone_array, target_first_letter_array)
        local is_wanted = comment_map[cand_comment]
        if is_wanted then
            return is_wanted
        end

        is_wanted = true

        if is_wanted and target_pinyin_length > 0 and cand_pinyin_length ~= target_pinyin_length then
            comment_map[cand_comment] = false
            return false
        end

        local pinyin_array = split_by_space(cand_comment)

        if is_wanted and target_tone_array then
            for i, target_tone in ipairs(target_tone_array) do
                if i > #pinyin_array then
                    break
                end

                local cand_vowel = pinyin_array[i]:match("[%z\128-\255][\128-\191]*")
                if not cand_vowel then
                    cand_vowel = cand_comment:match("([aoeiu])")    -- 注意 ü 在上面匹配到 -- 注意这个元音字母的排列顺序可是有讲究的。
                end
                local cand_tone = cand_vowel and vowel_tone_map[cand_vowel] or nil
                -- 声调匹配校验
                if target_tone ~= cand_tone then
                    is_wanted = false
                    break
                end
            end
        end

        if is_wanted and target_first_letter_array then
            for i, target_first_letter in ipairs(target_first_letter_array) do
                if i > #pinyin_array then
                    break
                end

                local cand_first_letter = pinyin_array[i]:match("[%z\1-\127\194-\244][\128-\191]*")
                cand_first_letter = cand_first_letter and vowel_letter_map[cand_first_letter] or cand_first_letter or nil
                -- 首字母匹配校验
                if target_first_letter ~= cand_first_letter then
                    is_wanted = false
                    break
                end
            end
        end

        comment_map[cand_comment] = is_wanted
        return is_wanted
    end

    local function get_target_tone_array(input, prefix)
        local suffix = input:match("[2-9]+" .. prefix .. "(.*)$")

        if suffix and suffix:match("[0-4]") then
            local results = {}
            for num in suffix:gmatch("[0-4]") do
                table.insert(results, tonumber(num))
            end
            return results
        end

        return null
    end

    local function get_target_first_letter_array(input, prefix)
        local suffix = input:match("[2-9]+" .. prefix .. "(.*)$")

        if suffix and suffix:match("[a-z]") then
            local results = {}
            for letter in suffix:gmatch("[a-z]") do
                table.insert(results, letter)
            end
            return results
        end

        return null
    end

    local is_cand_wanted
    local function yield_cand(cand, cand_pinyin_length, target_pinyin_length, target_tone_array, target_first_letter_array)
        local comment = cand.comment
        if comment == "" and is_cand_wanted then
            yield(cand)
        elseif comment ~= "" then
            is_cand_wanted = check_cand_wanted(comment, cand_pinyin_length, target_pinyin_length, target_tone_array, target_first_letter_array)
            if is_cand_wanted then
                yield(cand)
            end
        end
    end

    -- 1. 提取约束条件
    -- 根据声调筛选
    local target_tone_prefix_0 = get_target_tone_array(raw_input, "0")
    local target_tone_prefix_1 = get_target_tone_array(raw_input, "1")
    local target_tone = target_tone_prefix_0 or target_tone_prefix_1

    -- 根据首字母筛选
    local target_first_letter_prefix_0 = get_target_first_letter_array(raw_input, "0")
    local target_first_letter_prefix_1 = get_target_first_letter_array(raw_input, "1")
    local target_first_letter = target_first_letter_prefix_0 or target_first_letter_prefix_1

    -- 如果没有输入筛选符，直接放行
    if not target_tone and not target_first_letter then
        for cand in input:iter() do
            yield(cand)
        end
    end

    -- 获取最长的候选词拼音长度
    if target_tone_prefix_0 or target_first_letter_prefix_0 then 
        local maxLength = 0
        local cands = {}
        local pure_input = raw_input:match("^(.*)0")  -- 去掉末尾的声调或首字母筛选符
        local pure_input_length = #pure_input
        for cand in input:iter() do
            local pinyin = cand.comment:gsub("%s+", "")
            -- 计算 pinyin 长度不能用 #pinyin，否则带声调的元音的长度计算错误
            local length = utf8.len(pinyin)
            table.insert(cands, { cand, length })
            if length > maxLength and length <= pure_input_length then  -- 有时候候选词长度会大于 input 长度，比如想输入囧， 按下 54664
                maxLength = length
            end
        end

        is_cand_wanted = false
        for i, cand_obj in ipairs(cands) do
            local cand = cand_obj[1]
            local length = cand_obj[2]
            yield_cand(cand, length, maxLength, target_tone, target_first_letter)
        end
    end

    if target_tone_prefix_1 or target_first_letter_prefix_1 then
        is_cand_wanted = false
        for cand in input:iter() do
            yield_cand(cand, nil, nil, target_tone, target_first_letter)
        end
    end
end

return t9_tone_filter