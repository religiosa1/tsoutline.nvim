---@module 'snacks.picker'

---@class OutlineNodesSet
---@field private lines table<number, table<number, { priority: number, node: OutlineNode }>> table of lines, containing map of columns to priority
local OutlineNodesSet = {}
OutlineNodesSet.__index = OutlineNodesSet

---Create a new PositionSet instance
---@return OutlineNodesSet
function OutlineNodesSet.new()
	local self = setmetatable({}, OutlineNodesSet)
	self.lines = {}
	return self
end

---Extract underlying nodes to an array
---@return OutlineNode[]
function OutlineNodesSet:to_array()
	local nodes = {}
	for _, line_nodes in pairs(self.lines) do
		for _, item in pairs(line_nodes) do
			table.insert(nodes, item.node)
		end
	end
	return nodes
end

---Add position to the set.
---@param node OutlineNode
---@param conflict_priority number if an item with pos exists, but has lower priority -- append it anyway
---@return boolean true if pos was added to the set, false if it's already present
function OutlineNodesSet:add(node, conflict_priority)
	-- Dedup on the name-node position, not the definition start: a declaration
	-- and its exported twin share the same name identifier but have different
	-- definition ranges (the exported one includes the `export` keyword).
	local key = node.key_pos or node.pos
	local line = key[1]
	local col = key[2]
	if not self.lines[line] then
		self.lines[line] = {}
	end

	local existing_node = self.lines[line][col]
	if existing_node == nil or existing_node.priority < conflict_priority then
		self.lines[line][col] = {
			priority = conflict_priority,
			node = node,
		}
		return true
	else
		return false
	end
end

---Possible capture names from the t-s query. Will be suffixed with ".name" or
---".definition" for capturing name and range correspondingly.
---@enum SymbolType
local SymbolType = {
	Function = "function",
	---Function Expression assigned to a const/immutable variable
	Arrow = "arrow",
	---Function Expression assigned to a mutable variable
	VarArrow = "var_arrow",
	Class = "class",
	Method = "method",
	Constructor = "constructor",
	Getter = "getter",
	Setter = "setter",
	---Root-level immutable variables
	Const = "const",
	---Root-level callbacks
	Callback = "callback",
	Enum = "enum",
}

--- Intermediate OutlineNode meta info
---@class OutlineNode
---@field name string
---@field kind string?
---@field pos snacks.picker.Pos -- 1-indexed: [line, col]
---@field end_pos snacks.picker.Pos -- 1-indexed: [end_line, end_col]
---@field exported boolean? whether the symbol is exported
---@field key_pos snacks.picker.Pos? name-node position used as the dedup key (defaults to pos)

---Get the icon kind (for the icon) from the node
---Full list of possible kinds can be found here:
--- http://github.com/folke/snacks.nvim/blob/main/docs/picker.md#%EF%B8%8F-config
---@param symbol_type SymbolType
---@return string?
local function get_node_kind_icon(symbol_type)
	if symbol_type == SymbolType.Function then
		return "Function"
	elseif symbol_type == SymbolType.Arrow then
		return "Constant"
	elseif symbol_type == SymbolType.VarArrow then
		return "Variable"
	elseif symbol_type == SymbolType.Class then
		return "Class"
	elseif symbol_type == SymbolType.Method then
		return "Method"
	elseif symbol_type == SymbolType.Constructor then
		return "Constructor"
	elseif symbol_type == SymbolType.Getter or symbol_type == SymbolType.Setter then
		return "Property"
	elseif symbol_type == SymbolType.Const then
		return "Constant"
	elseif symbol_type == SymbolType.Callback then
		return "Function"
	elseif symbol_type == SymbolType.Enum then
		return "Enum"
	end
end

---Get capture_type conflict priority
---@param symbol_type SymbolType
---@param exported boolean? whether the symbol is exported
---@return number
local function get_node_priority(symbol_type, exported)
	local priority
	if symbol_type == SymbolType.Const then
		--- constants have lower priority to be overridden by FE assignment.
		--- export consts are still captured as a separate entity, because of the extended range
		priority = 500
	elseif symbol_type == SymbolType.Getter or symbol_type == SymbolType.Setter then
		-- getters or setters are higher priority than methods
		priority = 1200
	else
		priority = 1000
	end
	-- An exported declaration matches both the plain pattern and the @exported
	-- one (same definition node), so the exported variant must win the dedup to
	-- preserve the `exported` flag.
	if exported then
		priority = priority + 1
	end
	return priority
end

---Get the node name, that will be displayed in the picker
---@param symbol_type SymbolType
---@param captured_nodes table<string, TSNode[]>
---@param buffer_id integer
---@param exported boolean? whether the symbol is exported
---@return string name to be displayed in the snacks picker
local function get_node_name(symbol_type, captured_nodes, buffer_id, exported)
	local name_nodes = captured_nodes[symbol_type .. ".name"]
	assert(name_nodes, "Name nodes treesitter capture returned nil")
	assert(name_nodes[1], "No name nodes returned in the capture")

	local name = vim.treesitter.get_node_text(name_nodes[1], buffer_id)

	if symbol_type == SymbolType.Getter then
		name = "(get) " .. name
	elseif symbol_type == SymbolType.Setter then
		name = "(set) " .. name
	elseif
		symbol_type == SymbolType.Function
		or symbol_type == SymbolType.Arrow
		or symbol_type == SymbolType.VarArrow
		or symbol_type == SymbolType.Constructor
		or symbol_type == SymbolType.Method
	then
		name = name .. "()"
	elseif symbol_type == SymbolType.Callback then
		local args = vim.iter(captured_nodes[SymbolType.Callback .. ".args"])
			:map(function(node)
				return vim.iter(node:iter_children()):totable()
			end)
			:flatten(math.huge)
			:filter(function(node)
				return node:type() == "string"
			end)
			:map(function(node)
				return vim.treesitter.get_node_text(node, buffer_id)
			end)
			:join(", ")

		name = name .. string.format("(%s) callback", args)
	end
	if exported then
		name = "export " .. name
	end
	return name
end

---Get a map of capture name to captured nodes that we got from a query
---@param query vim.treesitter.Query
---@param match table<integer, TSNode[]>
---@return table<string, TSNode[]>
local function get_captured_nodes(query, match)
	local captured_nodes = {}
	for id, nodes in pairs(match) do
		local capture_name = query.captures[id]
		captured_nodes[capture_name] = nodes
	end
	return captured_nodes
end

---Determine "symbol type" from a map of captured_nodes -- symbol type being
---the part of capture name before the dot, e.g. "function", "var_arrow", etc.
---@param captured_nodes table<string, TSNode>
---@return string?
local function get_symbol_type(captured_nodes)
	---@type string?
	local symbol_type = nil
	for capture_name in pairs(captured_nodes) do
		if capture_name:match("%.name$") then
			symbol_type = capture_name:match("^(.+)%.name$")
			break
		end
	end
	return symbol_type
end

---Whether the matched symbol is exported, signalled by the orthogonal
---`@exported` marker capture being present in the match.
---@param captured_nodes table<string, TSNode[]>
---@return boolean
local function is_exported(captured_nodes)
	return captured_nodes["exported"] ~= nil
end

---get all "interesting" for outline nodes
---@param treesitter_language string TreeSitter language
---@param query_string string TreeSitter query for the language
---@param parser vim.treesitter.LanguageTree
---@param buffer_id number
---@return OutlineNode[]
local function get_outline_nodes(treesitter_language, query_string, parser, buffer_id)
	local tree = parser:parse()[1]
	local root = tree:root()
	local query = vim.treesitter.query.parse(treesitter_language, query_string)

	local outline_nodes = OutlineNodesSet.new()

	for _, match in query:iter_matches(root, buffer_id) do
		local captured_nodes = get_captured_nodes(query, match)
		local symbol_type = get_symbol_type(captured_nodes)

		if not symbol_type then
			goto next_match
		end

		local name_nodes = captured_nodes[symbol_type .. ".name"]
		local def_nodes = captured_nodes[symbol_type .. ".definition"]

		if not name_nodes or #name_nodes == 0 or not def_nodes or #def_nodes == 0 then
			goto next_match
		end

		local start_row, start_col, end_row, end_col = def_nodes[1]:range()
		local pos = { start_row + 1, start_col }
		local end_pos = { end_row + 1, end_col }

		local name_start_row, name_start_col = name_nodes[1]:range()
		local key_pos = { name_start_row + 1, name_start_col }

		local exported = is_exported(captured_nodes)
		local node = {
			name = get_node_name(symbol_type, captured_nodes, buffer_id, exported),
			kind = get_node_kind_icon(symbol_type),
			pos = pos,
			end_pos = end_pos,
			key_pos = key_pos,
			exported = exported,
		}
		local conflict_priority = get_node_priority(symbol_type, exported)
		outline_nodes:add(node, conflict_priority)
		::next_match::
	end
	return outline_nodes:to_array()
end

---Check if one node contains another (based on their position)
---@param parent OutlineNode
---@param child OutlineNode
---@return boolean
local function contains(parent, child)
	local starts_after = child.pos[1] > parent.pos[1]
		or (child.pos[1] == parent.pos[1] and child.pos[2] >= parent.pos[2])
	local ends_before = child.end_pos[1] < parent.end_pos[1]
		or (child.end_pos[1] == parent.end_pos[1] and child.end_pos[2] <= parent.end_pos[2])
	return starts_after and ends_before
end

---Build a hierarchical tree of items, based on the found outline nodes.
---@param outline_nodes OutlineNode[]
---@param file_path string
---@return snacks.picker.finder.Item[]
local function build_tree(outline_nodes, file_path)
	-- Sort by start position (line, then column)
	table.sort(outline_nodes, function(a, b)
		if a.pos[1] ~= b.pos[1] then
			return a.pos[1] < b.pos[1]
		end
		return a.pos[2] < b.pos[2]
	end)
	---@type snacks.picker.finder.Item[]
	local items = {}
	local file_root = { text = "", root = true }
	-- Recursively build tree structure
	local function build_structure(nodes, parent_item, parent_range)
		while #nodes > 0 do
			local current = nodes[1]
			-- if current node is not contained in parent, return to previous level
			if parent_range and not contains(parent_range, current) then
				return
			end

			-- Remove from list and create item
			table.remove(nodes, 1)
			---@type snacks.picker.finder.Item
			local item = {
				text = current.name,
				name = current.name,
				kind = current.kind,
				exported = current.exported,
				file = file_path,
				pos = current.pos,
				end_pos = current.end_pos,
				tree = true,
				parent = parent_item,
			}
			items[#items + 1] = item
			-- Recursively process children (nodes contained within current)
			build_structure(nodes, item, current)
			-- Mark as last child of parent if no more siblings
			if #nodes == 0 or (parent_range and not contains(parent_range, nodes[1])) then
				item.last = true
			end
		end
	end
	-- Build from root
	build_structure(outline_nodes, file_root, nil)
	return items
end

---Get snacks items for outline nodes for a typescript buffer with a treesitter
---query
---@param treesitter_language string
---@param query_string string TreeSitter query for the language to parse
---@return snacks.picker.finder.Item[]
return function(treesitter_language, query_string)
	local buffer_id = vim.api.nvim_get_current_buf()
	local parser = vim.treesitter.get_parser(buffer_id, treesitter_language)
	assert(parser, "Unable to retrieve parser for buffer")

	local outline_nodes = get_outline_nodes(treesitter_language, query_string, parser, buffer_id)
	local file_path = vim.api.nvim_buf_get_name(buffer_id)
	local tree = build_tree(outline_nodes, file_path)
	return tree
end
