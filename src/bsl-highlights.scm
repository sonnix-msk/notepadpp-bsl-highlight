; 1C:Enterprise (BSL) highlighting for NppTreeSitter.
; NOTE on priority: the plugin applies matches sorted by (start, pattern index) and
; the LAST paint wins. So generic patterns go FIRST, specific ones LAST.
; Priority order below (low -> high): generic identifier, literals/operators/keywords,
; names/annotations, then preprocessor directives (highest).

; --- Generic fallback: any identifier not matched below (variables, properties...) ---
(identifier) @type

; --- Comments ---
(line_comment) @comment

; --- Literals ---
[
  (string)
  (string_content)
] @string

(date) @constant
(number) @number

; --- Operators / punctuation ---
(operator) @operator

[
  "("
  ")"
  "["
  "]"
] @punctuation.bracket

[
  ";"
  "."
  ","
] @punctuation.delimiter

; --- Keywords (normal code) ---
[
  (ADDHANDLER_KEYWORD)
  (AND_KEYWORD)
  (ASYNC_KEYWORD)
  (AWAIT_KEYWORD)
  (BREAK_KEYWORD)
  (CONTINUE_KEYWORD)
  (DO_KEYWORD)
  (EACH_KEYWORD)
  (ELSE_KEYWORD)
  (ELSIF_KEYWORD)
  (ENDDO_KEYWORD)
  (ENDFUNCTION_KEYWORD)
  (ENDIF_KEYWORD)
  (ENDPROCEDURE_KEYWORD)
  (ENDTRY_KEYWORD)
  (EXCEPT_KEYWORD)
  (EXPORT_KEYWORD)
  (FALSE_KEYWORD)
  (FOR_KEYWORD)
  (FUNCTION_KEYWORD)
  (GOTO_KEYWORD)
  (IF_KEYWORD)
  (IN_KEYWORD)
  (NOT_KEYWORD)
  (NULL_KEYWORD)
  (OR_KEYWORD)
  (PROCEDURE_KEYWORD)
  (RAISE_KEYWORD)
  (REMOVEHANDLER_KEYWORD)
  (RETURN_KEYWORD)
  (THEN_KEYWORD)
  (TO_KEYWORD)
  (TRUE_KEYWORD)
  (TRY_KEYWORD)
  (UNDEFINED_KEYWORD)
  (VAL_KEYWORD)
  (VAR_KEYWORD)
  (WHILE_KEYWORD)
] @keyword

(NEW_KEYWORD) @constructor

; --- Names (beat the generic @type fallback) ---
(procedure_definition
  name: (identifier) @function)

(function_definition
  name: (identifier) @function)

(method_call
  name: (identifier) @function)

; --- Annotations (&НаСервере, &Перед, ...) ---
(annotation) @attribute

; ===========================================================================
; Preprocessor directives (#... and &...) - highest priority.
; Directives are single-line; the whole directive line renders as Preprocessor.
; ===========================================================================

; &-annotations are wrapped in a preprocessor node
(preprocessor
  (annotation) @attribute)

; #-directive keywords and standalone # directives
[
  (PREPROC_IF_KEYWORD)
  (PREPROC_ELSE_KEYWORD)
  (PREPROC_ELSIF_KEYWORD)
  (PREPROC_ENDIF_KEYWORD)
  (PREPROC_REGION_KEYWORD)
  (PREPROC_ENDREGION_KEYWORD)
  (preproc)
] @preproc

; #Область <Имя> / region name
(preprocessor
  name: (identifier) @preproc)

; "Тогда" on a directive line
(preprocessor
  (THEN_KEYWORD) @preproc)

; The condition expression of #Если / #ИначеЕсли (a direct child expression),
; plus its descendants so nested identifiers/operators also render as directive.
(preprocessor
  (expression) @preproc)

(preprocessor
  (expression (_) @preproc))

(preprocessor
  (expression (_ (_) @preproc)))

(preprocessor
  (expression (_ (_ (_) @preproc))))

(preprocessor
  (expression (_ (_ (_ (_) @preproc)))))

(preprocessor
  (expression (_ (_ (_ (_ (_) @preproc))))))
