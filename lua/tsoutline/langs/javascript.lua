--- Tree-sitter query to capture functions, classes, and methods for
--- javascript and javascript react
return [[
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
  name: (identifier) @class.name
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
        name: (identifier) @const.name)
    ) @const.definition
  )
)
]]
