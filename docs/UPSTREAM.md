# Вклад в апстрим — план и тексты

Цель: чтобы поддержка грамматики BSL не висела только на этом репозитории, а жила в
первоисточниках.

## 1. PR/issue в Thorium/NppTreeSitter

Идея: добавить `tree-sitter-bsl` в список грамматик, чтобы BSL собирался штатно и попадал
в релизные пакеты плагина (`grammars/grammars.json`).

Черновик записи для `grammars/grammars.json`:

```json
{ "repo": "alkoleft/tree-sitter-bsl", "tag": "v0.1.7",
  "highlights": "grammars/bsl/queries/highlights.scm" }
```

Нюансы, которые надо проверить перед PR:
- у `tree-sitter-bsl` путь к query нестандартный (`grammars/bsl/queries/highlights.scm`,
  а не `queries/highlights.scm`) — нужен ключ `highlights`;
- в репозитории `tree-sitter.json` описывает две грамматики (`bsl` и `sdbl`) с путями
  `grammars/bsl` и `grammars/sdbl` — убедиться, что сборщик возьмёт `bsl` корректно
  (возможно, потребуется `"name": "bsl"` и/или отдельная запись для sdbl);
- собранная грамматика имеет **ABI 15** (tree-sitter 0.25.10) — совпадает с текущими
  бандловыми грамматиками плагина.

Плюс: предложить BSL в auto-detect по расширениям `.bsl`/`.os`
(в `src/dllmain.cpp`: `DetectTreeSitterLanguageForFile`, `PreferBuiltInLexerForExtension`).

Текст issue (можно превратить в PR):

> **Add 1C:Enterprise (BSL) grammar**
>
> There is a maintained tree-sitter grammar for the 1C:Enterprise language (BSL):
> https://github.com/alkoleft/tree-sitter-bsl (MIT, ABI 15, generated with tree-sitter 0.25).
> Highlighting works well with this plugin. Suggest bundling it (name `bsl`, extensions
> `bsl`/`os`) with the non-standard highlights path `grammars/bsl/queries/highlights.scm`.
> Tested with the release `v0.1.7`.

## 2. Обратная связь в alkoleft/tree-sitter-bsl

Наш опыт, полезный для грамматики/query:

- **`preprocessor` — многострочная нода.** `#Если … #КонецЕсли` оборачивается целиком,
  хотя директива однострочная. Для редакторов, которые красят по токенам, это неудобно:
  нельзя покрасить «строку директивы», не залезая в тело. Предложение/вопрос: не стоит ли
  выделять отдельную ноду на строку-директиву (или явно документировать обходной путь —
  красить прямых детей `preprocessor`).
- Условие `#Если`/`#ИначеЕсли` — прямой ребёнок `preprocessor` (нода `expression`), тело —
  отдельные `*_statement`. Это позволяет красить условие, не задевая тело.

Текст issue:

> **Preprocessor directives: per-line node or documented workaround?**
>
> `preprocessor` wraps a whole `#If…#Endif` block, but each directive is single-line.
> Editors that highlight per-token cannot color "the directive line" without leaking into the
> body. We ended up capturing the direct children of `preprocessor`
> (`PREPROC_*_KEYWORD`, `name:`, `(THEN_KEYWORD)`, `(expression)`). Would a per-line node be
> feasible, or can this workaround be documented? Our query changes (MIT) are here: <URL>.

## 3. Куда публиковать сам репозиторий

- Код: **GitVerse.ru** / **GitFlic.ru** (зеркало — GitHub).
- Анонс: **Infostart.ru** (инструмент + статья), **Хабр** (хаб 1С), профильные Telegram-каналы.
- Дистрибутив: в **Releases** (собранный `Notepad++-BSL.zip`), исходники — в git.

## 4. Чек-лист перед публикацией

- [ ] Указать себя в `LICENSE` (сейчас «The Notepad++ BSL Highlighting authors»).
- [ ] Добавить скриншот в `README.md` и в анонс.
- [ ] Проверить, что в Releases лежит zip, собранный `build/make-release.ps1`.
- [ ] В описании релиза — версии компонентов из `build/versions.psd1`.
- [ ] Убедиться, что `NOTICE.md` и `LICENSES/` попали в пакет (make-release это делает).
