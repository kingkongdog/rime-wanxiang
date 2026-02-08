-- 目标：使用原生 utf8 库实现动态候选词排序

local sep = "====================================================="

local tone_map = {["ā"]="a",["á"]="a",["ǎ"]="a",["à"]="a",["ē"]="e",["é"]="e",["ě"]="e",["è"]="e",["ī"]="i",["í"]="i",["ǐ"]="i",["ì"]="i",["ō"]="o",["ó"]="o",["ǒ"]="o",["ò"]="o",["ū"]="u",["ú"]="u",["ǔ"]="u",["ù"]="u",["ü"]="v",["ǘ"]="v",["ǚ"]="v",["ǜ"]="v"}
local tone_level_map = {["ā"]=1,["á"]=2,["ǎ"]=3,["à"]=4,["ē"]=1,["é"]=2,["ě"]=3,["è"]=4,["ī"]=1,["í"]=2,["ǐ"]=3,["ì"]=4,["ō"]=1,["ó"]=2,["ǒ"]=3,["ò"]=4,["ū"]=1,["ú"]=2,["ǔ"]=3,["ù"]=4,["ü"]=1,["ǘ"]=2,["ǚ"]=3,["ǜ"]=4}

local function t9_sorter(input)
    local l = {}

    -- 获取所有候选词
    for cand in input:iter() do
        table.insert(l, cand)
    end

    if #l == 0 then return end

    -- 获取第一个单字候选词索引
    -- 候选词排列是这样：多字候选词，然后单字候选词，多字和单字候选词后面都可能有 emoji，emoji 的长度一般是 1, comment 是 ""
    local first_single_index = -1
    local first_len = utf8.len(l[1].text)

    if first_len == 1 then
        first_single_index = 1
    else
        for i = 2, #l do
            if utf8.len(l[i].text) == 1 and l[i].comment ~= "" then
                first_single_index = i
                break
            end
        end
    end

    -- 全部是多字候选词
    if first_single_index == -1 then 
        for i = 1, #l do yield(l[i]) end
        return
    end

    -- 多字候选词直接 yield
    for i = 1, first_single_index - 1 do
        yield(l[i])
    end

    if first_len > 1 then
        yield(Candidate("raw", l[1]._start, l[1]._end, "--- 高频单字 ---", sep))
    end

    -- 单字候选词不到 18 个
    local multi_count = first_single_index - 1
    if #l - multi_count < 18 then
        for i = first_single_index, #l do 
            yield(l[i])
        end
        return
    end

    -- 前 18 个单字候选词直接 yield
    for i = first_single_index, first_single_index + 17 do 
        yield(l[i])
    end

    -- 剩余的单字按拼音排序
    local groupsMap = {}
    local group_pinyin = ""
    for i = first_single_index + 18, #l do
        local cand = l[i]
        if cand.comment ~= "" then
            group_pinyin = cand.comment
        end

        local group = groupsMap[group_pinyin]
        if group then
            table.insert(group.cands, cand)
        else
            local clean_pinyin = group_pinyin:gsub("[%z\128-\255][\128-\191]*", tone_map)
            local tone_level = tone_level_map[group_pinyin:match("[%z\128-\255][\128-\191]*")] or 0
            local tone_pos = group_pinyin:find("[%z\128-\255][\128-\191]*") or 0
            groupsMap[group_pinyin] = {pinyin_with_tone = group_pinyin, clean_pinyin = clean_pinyin, tone_level = tone_level, tone_pos = tone_pos, cands = { cand }}
        end
    end

    local groupsArr = {}
    for _, group in pairs(groupsMap) do
        table.insert(groupsArr, group)
    end

    -- 对组进行排序（只比较组里的第一个候选词）
    table.sort(groupsArr, function(a, b)
        if a.clean_pinyin ~= b.clean_pinyin then
            return a.clean_pinyin < b.clean_pinyin
        end

        if a.tone_pos ~= b.tone_pos then
            return a.tone_pos > b.tone_pos
        end

        return a.tone_level < b.tone_level
    end)

    -- 按组平铺输出
    for _, group in ipairs(groupsArr) do
        -- 分割线
        yield(Candidate("raw", l[1]._start, l[1]._end, "--- " .. group.pinyin_with_tone .. " ---", sep))
        for _, cand in ipairs(group.cands) do
            yield(cand)
        end
    end
end

return t9_sorter