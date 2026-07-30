-- number_first.lua
-- 检测输入是否是 1-9，并在第一位插入该数字

local digit_map = {
	["ling"] = { "⓪" },
	["yi"] = { "①" },
	["er"] = { "②" },
	["san"] = { "③" },
	["si"] = { "④" },
	["wu"] = { "⑤" },
	["liu"] = { "⑥" },
	["qi"] = { "⑦" },
	["ba"] = { "⑧" },
	["jiu"] = { "⑨" },
	["shi"] = { "⑩" },
}

local function filter(input, env)
	local context = env.engine.context
	local input_str = context.input
	local cand_list = {}

	for cand in input:iter() do
		table.insert(cand_list, cand)
	end

	local digit_list = digit_map[input_str]
	if digit_list then
		for _, value in ipairs(digit_list) do
			local cand = Candidate("raw", 0, #input_str, value, "")
			table.insert(cand_list, 2, cand)
		end
	end

	for _, cand in ipairs(cand_list) do
		yield(cand)
	end
end

return filter
