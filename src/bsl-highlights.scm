; 1C:Enterprise (BSL) highlighting for NppTreeSitter.
; NOTE on priority: the plugin paints matches sorted by (start, pattern index);
; LAST paint wins. A nested token (later start) overrides an enclosing one, so
; every token we want colored must be matched explicitly. Generic rules go FIRST,
; specific ones LAST.
; Priority (low -> high): generic identifier, literals/keywords/punct,
; names/annotations, preprocessor directives (incl. broken/ERROR states).

; --- Generic fallback: any identifier (do not overwrite specific rules) ---
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

; `Новый` is a keyword in 1C, not a function-like constructor.
(NEW_KEYWORD) @keyword

; Member after a dot (Запрос.Параметры) is an identifier aliased as `property`.
(property) @type

; --- Names ---
(procedure_definition
  name: (identifier) @function)

(function_definition
  name: (identifier) @function)

(method_call
  name: (identifier) @function)

; --- Annotations (&НаСервере, &Перед, ...) ---
(annotation) @attribute

; ===========================================================================
; Preprocessor directives (#... and &...): the whole directive line.
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

; #Область <Имя>
(preprocessor
  name: (identifier) @preproc)

; "Тогда" on a directive line
(preprocessor
  (THEN_KEYWORD) @preproc)

; Condition of #Если / #ИначеЕсли, plus nested descendants.
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

; ===========================================================================
; Broken / still-being-typed directives parse as (ERROR ...).
; Mirror the rules above so the directive line stays colored while typing.
; ===========================================================================

; A lone #/&-directive with no recognizable nodes yet: color it if the text
; starts with # or & (after optional spaces) and does not span lines.
((ERROR) @preproc
  (#match? @preproc "^[ \t]*[#&]")
  (#not-match? @preproc "\n"))

(ERROR
  (PREPROC_IF_KEYWORD) @preproc)
(ERROR
  (PREPROC_ELSIF_KEYWORD) @preproc)
(ERROR
  (PREPROC_ELSE_KEYWORD) @preproc)
(ERROR
  (PREPROC_ENDIF_KEYWORD) @preproc)
(ERROR
  (PREPROC_REGION_KEYWORD) @preproc)
(ERROR
  (PREPROC_ENDREGION_KEYWORD) @preproc)
(ERROR
  (preproc) @preproc)

(ERROR
  (annotation) @attribute)

; condition tokens inside a broken directive
(ERROR
  (PREPROC_IF_KEYWORD)
  (expression) @preproc)
(ERROR
  (PREPROC_ELSIF_KEYWORD)
  (expression) @preproc)
(ERROR
  (PREPROC_IF_KEYWORD)
  (expression (_) @preproc))
(ERROR
  (PREPROC_ELSIF_KEYWORD)
  (expression (_) @preproc))
(ERROR
  (PREPROC_IF_KEYWORD)
  (expression (_ (_) @preproc)))
(ERROR
  (PREPROC_IF_KEYWORD)
  (expression (_ (_ (_) @preproc))))
(ERROR
  (PREPROC_IF_KEYWORD)
  (expression (_ (_ (_ (_) @preproc)))))
(ERROR
  (PREPROC_IF_KEYWORD)
  (AND_KEYWORD) @preproc)
(ERROR
  (PREPROC_IF_KEYWORD)
  (NOT_KEYWORD) @preproc)
(ERROR
  (PREPROC_IF_KEYWORD)
  (OR_KEYWORD) @preproc)
(ERROR
  (PREPROC_IF_KEYWORD)
  (THEN_KEYWORD) @preproc)
