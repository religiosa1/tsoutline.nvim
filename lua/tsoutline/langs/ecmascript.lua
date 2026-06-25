--- Tree-sitter query to capture functions, classes, and methods for
--- typescript/javascript and their react variants
---@param opts { is_js: boolean? } use javascript grammar (identifier for class names instead of type_identifier)
---@return string
return function(opts)
	local is_js = (opts and opts.is_js)
	local class_name_node = is_js and "(identifier)" or "(type_identifier)"
	local query = [[
;;*** functions and fe assigned to a variable *** ;;

(function_declaration
  name: (identifier) @function.name
) @function.definition

(lexical_declaration
  kind: "const"
  (variable_declarator
    name: (identifier) @arrow.name
    value: [(arrow_function) (function_expression)])
) @arrow.definition


((lexical_declaration
  kind: _ @kind
  (variable_declarator
    name: (identifier) @var_arrow.name
    value: [(arrow_function) (function_expression)]))
  (#not-eq? @kind "const")
) @var_arrow.definition

(variable_declaration
  (variable_declarator
    name: (identifier) @var_arrow.name
    value: [(arrow_function) (function_expression)])
) @var_arrow.definition

;; *** root-level callbacks *** ;;

; Callbacks in direct function calls at root level
(program
  (expression_statement
    (call_expression
      function: (identifier) @callback.name
      arguments: (arguments
        (arrow_function) @callback.definition) @callback.args)))

;; Callbacks in an object with intermediate function calls - capture only the property as name
(program
  (expression_statement
    (call_expression
      function: (member_expression
        object: (call_expression)
        property: (property_identifier) @callback.name)
      arguments: (arguments
        (arrow_function) @callback.definition
      ) @callback.args
    )
  )
)

;; Callbacks in an object with optional prop access only - capture the entire member_expression
(program
  (expression_statement
    (call_expression
      function: (member_expression
        object: [(identifier) (member_expression)]
        property: (property_identifier)) @callback.name
      arguments: (arguments
        (arrow_function) @callback.definition
      ) @callback.args
    )
  )
)

;;*** classes *** ;;

(class_declaration
  name: ]] .. class_name_node .. [[ @class.name
) @class.definition

(method_definition
  "get"
  name: (property_identifier) @getter.name
) @getter.definition

(method_definition
  "set"
  name: (property_identifier) @setter.name
) @setter.definition

(method_definition
  name: (property_identifier) @constructor.name
  (#eq? @constructor.name "constructor")
) @constructor.definition

; general class methods
(method_definition
  name: [(property_identifier) (private_property_identifier)] @method.name
  (#not-eq? @method.name "constructor")
) @method.definition

;;*** constants *** ;;

; non-exported root-level constants
(program
  (lexical_declaration
    kind: "const"
    (variable_declarator
      name: (identifier) @const.name)
  ) @const.definition
)

; exported root-level constants
(program
  (export_statement
    declaration: (lexical_declaration
      kind: "const"
      (variable_declarator
        name: (identifier) @const.name))
  ) @const.definition @exported
)

;;*** exported declarations ***;;
;; These overlap their plain twins above: they share the same name identifier
;; (the dedup key), but the @<type>.definition here is the whole export_statement
;; so the highlighted range covers the `export` keyword too. The @exported marker
;; rides along and the higher conflict priority makes these win the dedup.

(export_statement
  declaration: (function_declaration
    name: (identifier) @function.name)
) @function.definition @exported

(export_statement
  declaration: (lexical_declaration
    kind: "const"
    (variable_declarator
      name: (identifier) @arrow.name
      value: [(arrow_function) (function_expression)]))
) @arrow.definition @exported

(export_statement
  declaration: ((lexical_declaration
    kind: _ @kind
    (variable_declarator
      name: (identifier) @var_arrow.name
      value: [(arrow_function) (function_expression)]))
    (#not-eq? @kind "const"))
) @var_arrow.definition @exported

(export_statement
  declaration: (variable_declaration
    (variable_declarator
      name: (identifier) @var_arrow.name
      value: [(arrow_function) (function_expression)]))
) @var_arrow.definition @exported

(export_statement
  declaration: (class_declaration
    name: ]] .. class_name_node .. [[ @class.name)
) @class.definition @exported
]]
	if not is_js then
		query = query .. [[
;;*** enums *** ;;

(enum_declaration name: (identifier) @enum.name) @enum.definition

(export_statement
  declaration: (enum_declaration name: (identifier) @enum.name)
) @enum.definition @exported
]]
	end
	return query
end
