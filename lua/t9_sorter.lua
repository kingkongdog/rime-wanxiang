-- 功能：根据首个候选词的长度，动态调整后续单字的排序方式

local function sort_filter(input)
  local code = utf8.len("李刚")
  for cand in input:iter() do
    yield(Candidate("raw", 0, #code, code, ""))
  end
end

return sort_filter