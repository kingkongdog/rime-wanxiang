-- 目标：使用原生 utf8 库实现动态候选词排序

local sep = "====================================================="

-- 1. 定义映射表（放在 Filter 函数外部，只需加载一次）
local tone_map = {
    ["ā"]="a", ["á"]="a", ["ǎ"]="a", ["à"]="a",
    ["ē"]="e", ["é"]="e", ["ě"]="e", ["è"]="e",
    ["ī"]="i", ["í"]="i", ["ǐ"]="i", ["ì"]="i",
    ["ō"]="o", ["ó"]="o", ["ǒ"]="o", ["ò"]="o",
    ["ū"]="u", ["ú"]="u", ["ǔ"]="u", ["ù"]="u",
    ["ü"]="v", ["ǘ"]="v", ["ǚ"]="v", ["ǜ"]="v"
}

-- 2. 创建缓存表（核心优化点）
local clean_cache = setmetatable({}, { __mode = "kv" }) -- 弱引用表，防止内存溢出

-- 2. 统一替换函数
local function clean_pinyin(s)
    if not s or s == "" then return "" end

    -- 如果缓存里有，直接返回，不再计算
    if clean_cache[s] then return clean_cache[s] end

    -- 使用正则匹配所有多字节字符，并根据映射表替换
    -- [%z\128-\255] 匹配所有非标准 ASCII 字符
    local str = s:gsub("[%z\128-\255][\128-\191]*", tone_map)

    -- 存入缓存
    clean_cache[s] = str

    return str
end

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
            table.insert(group, cand)
        else
            groupsMap[group_pinyin] = {cand}
        end
    end

    local groupsArr = {}
    for _, group in pairs(groupsMap) do
        table.insert(groupsArr, group)
    end

    -- 对组进行排序（只比较组里的第一个候选词）
    table.sort(groupsArr, function(group_a, group_b)
        local a = group_a[1]
        local b = group_b[1]

        -- 获取排序用的 Key
        local raw_a = a.comment
        local raw_b = b.comment

        -- 获取纯字母拼音
        local clean_a = clean_pinyin(raw_a)
        local clean_b = clean_pinyin(raw_b)

        if clean_a ~= clean_b then
            -- 基础字母不同，按纯字母排 (如 a < b)
            return clean_a < clean_b
        else
            -- 基础字母相同 (如 a vs ā)，按原始字符串排
            -- 这样保证了 a 会排在 ai 前面，且声调固定的顺序
            return raw_a < raw_b
        end
    end)

    -- 按组平铺输出
    for _, group in ipairs(groupsArr) do
        -- 分割线
        yield(Candidate("raw", l[1]._start, l[1]._end, "--- " .. group[1].comment .. " ---", sep))
        for _, cand in ipairs(group) do
            yield(cand)
        end
    end
end

return t9_sorter