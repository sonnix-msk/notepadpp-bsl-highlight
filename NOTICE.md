# NOTICE — сторонние компоненты

Этот проект распространяет и использует сторонние компоненты. Ниже — состав,
лицензии и ссылки на исходники.

## Что распространяется в дистрибутиве

### TreeSitterLexer.dll — плагин NppTreeSitter
- **Лицензия:** GPL-2.0-or-later (заявлена в README проекта).
- **Автор:** Tuomas Hietanen (github.com/Thorium).
- **Источник:** https://github.com/Thorium/NppTreeSitter
- **Что делаем:** распространяем **без изменений**, только бинарник из официального
  релиза. Полный текст лицензии: `LICENSES/GPL-2.0-or-later.txt`.
- **Условие GPL — исходный код:** исходники плагина доступны по ссылке выше
  (тег/релиз, использованный в сборке, зафиксирован в `build/versions.psd1`).
  Мы не вносим правок в плагин и не меняем его поведение.

### tree-sitter-bsl.dll — грамматика языка BSL
- **Лицензия:** MIT.
- **Автор:** Koryakin Aleksey (github.com/alkoleft).
- **Источник:** https://github.com/alkoleft/tree-sitter-bsl
- **Что делаем:** собираем из исходников (parser.c) без изменений.
  Текст лицензии: `LICENSES/tree-sitter-bsl.txt`.

### tree-sitter (runtime)
- **Лицензия:** MIT.
- **Автор:** Max Brunsfeld и участники.
- **Источник:** https://github.com/tree-sitter/tree-sitter
- **Примечание:** рантайм скомпилирован внутрь `TreeSitterLexer.dll` (плагин NppTreeSitter).
  Текст лицензии: `LICENSES/tree-sitter.txt`.

## Что является нашей работой (лицензия MIT — см. `LICENSE`)

- `src/bsl-highlights.scm` — правила подсветки (tree-sitter queries), включая
  доработки против исходной грамматики (обработка препроцессора, идентификаторы).
- `src/TreeSitterLexer.xml` — конфигурация языка и цветовых схем в Notepad++.
- `src/install.ps1`, `src/INSTALL.bat` — установщик и лаунчер.
- `build/*` — скрипты сборки грамматики и формирования дистрибутива.
- документация (`README.md`, `src/README-install.txt`, спека).

Эти файлы — самостоятельные произведения и распространяются под MIT. Они
совместимы с GPL-2.0-or-later плагина (MIT → GPL-совместимо).

## Порядок загрузки (для понимания состава)

Notepad++ загружает `TreeSitterLexer.dll` (GPL-2.0-or-later). Плагин во время
работы читает рядом лежащие данные: `TreeSitterGrammars/tree-sitter-bsl.dll`
(MIT) и `TreeSitterGrammars/bsl-highlights.scm` (MIT), а также конфигурацию
`plugins/Config/TreeSitterLexer.xml` (MIT). Это разные файлы, а не единый
скомпилированный модуль.
