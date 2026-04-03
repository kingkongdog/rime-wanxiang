-- t9_vowel_tone_filter.lua
-- 逻辑：提取输入末尾的特殊元音或声调字符，过滤候选词

local function t9_vowel_tone_filter(input, env)
    local context = env.engine.context
    local raw_input = context.input
    
    -- 1. 提取约束条件
    -- 匹配末尾的特殊元音 (āōēīūǖ) 和声调符号 (①②③④)
    local target_vowel = raw_input:match("([āōēīūǖ])")
    local target_tone = raw_input:match("([①②③④])")
    
    -- 将符号映射为标准对比格式
    local vowel_map = { 
        ["ā"] = "a", ["ō"] = "o", ["ē"] = "e", 
        ["ī"] = "i", ["ū"] = "u", ["ǖ"] = "v" 
    }
    local tone_map = { ["①"] = "1", ["②"] = "2", ["③"] = "3", ["④"] = "4" }
    local vowel_tone_map = {
        ["ā"] = {"a", 1}, ["á"] = {"a", 2}, ["ǎ"] = {"a", 3}, ["à"] = {"a", 4}, 
        ["ō"] = {"o", 1}, ["ó"] = {"o", 2}, ["ǒ"] = {"o", 3}, ["ò"] = {"o", 4}, 
        ["ē"] = {"e", 1}, ["é"] = {"e", 2}, ["ě"] = {"e", 3}, ["è"] = {"e", 4}, 
        ["ī"] = {"i", 1}, ["í"] = {"i", 2}, ["ǐ"] = {"i", 3}, ["ì"] = {"i", 4}, 
        ["ū"] = {"u", 1}, ["ú"] = {"u", 2}, ["ǔ"] = {"u", 3}, ["ù"] = {"u", 4}, 
        ["ǖ"] = {"v", 1}, ["ǘ"] = {"v", 2}, ["ǚ"] = {"v", 3}, ["ǜ"] = {"v", 4}
    }

    local target_vowel_val = target_vowel and vowel_map[target_vowel] or nil
    local target_tone_val = target_tone and tone_map[target_tone] or nil

    -- 2. 开始过滤候选词
    for cand in input:iter() do
        -- 获取候选词的原始拼音 (preedit 或通过反查获取)
        -- 注意：这里假设你的词典里带有声调信息，或者你通过 algebra 将声调转换为了数字
        local pinyin = cand.comment or ""

        local cand_vowel_tone = pinyin:match("([āáǎàōóǒòēéěèīíǐìūúǔùǖǘǚǜ])")
        local cand_vowel_tone_val = cand_vowel_tone and vowel_tone_map[cand_vowel_tone] or nil
        local cand_vowel_val = cand_vowel_tone_val and cand_vowel_tone_val[1]
        local cand_tone_val = cand_vowel_tone_val and cand_vowel_tone_val[2]
        
        -- 如果没有输入筛选符，直接放行
        if not target_vowel_val and not target_tone_val then
            yield(cand)
            goto next_cand
        end

        local is_match = true

        -- 元音匹配校验
        if target_vowel_val and target_vowel_val ~= cand_vowel_val then
            is_match = false
        end

        -- 声调匹配校验
        if target_tone_val and target_tone_val ~= cand_tone_val then
            is_match = false
        end


        -- 3. 输出匹配的词
        if is_match then
            yield(cand)
        end

        ::next_cand::
    end
end

return t9_vowel_tone_filter