# Вклад в апстрим — план и тексты

Цель: чтобы поддержка грамматики BSL не висела только на этом репозитории, а жила в
первоисточниках.

## 0. Отправлено

- **Issue #7 в Thorium/NppTreeSitter** — «Add 1C:Enterprise (BSL) extension mapping»
  (2026-10-14, от `sonnix-msk`): https://github.com/Thorium/NppTreeSitter/issues/7
  Просьба добавить `bsl`/`os` в таблицу авто-определения (иначе уже открытые вкладки
  не подхватываются). Файл: `не меняет ни наш, ни их репозиторий`. Если автор откажется
  или проигнорирует — альтернатива: свой форк плагина (см. ниже, п.1).
- **Issue #8 в Thorium/NppTreeSitter** — «Folding breaks when a header line contains an
  expression deeper than the body» (2026-10-15, от `sonnix-msk`):
  https://github.com/Thorium/NppTreeSitter/issues/8
  Диагноз + направление фикса (`Fold()` берёт глубину AST вместо числа объемлющих
  многострочных узлов). Готового патча в issue нет — только описание.
- Автор плагина — Tuomas Hietanen (Лондон, UK), универсальный tree-sitter-хост; BSL для
  него нишевый, поэтому ответ не гарантирован.

## 0а. Локальные фиксы, готовые к PR (форк `sonnix-msk/NppTreeSitter`)

Правим плагин у себя (ветки в личном форке, публичный дистрибутив не трогаем). Когда фикс
проверен на живом Notepad++ — **предложить его апстриму как PR**. Маркеры в коде:
`TODO(upstream)`.

| Что | Ветка форка | Issue | Статус |
|---|---|---|---|
| Авто-детект `.bsl`/`.os` | `sonnix/mapping` (`c5a59ff`) | #7 | **проверено на живом N++**, кандидат в PR |
| Стили/шрифт из XML + фикс мелкого шрифта | `sonnix/mapping` (`9f9084a`) | нет issue (баг всех языков) | **проверено на живом N++**, кандидат в PR |
| Сворачивание: уровень = вложенные многострочные узлы | `sonnix/folding` (`fba2601`) | #8 | **проверено на живом N++**, кандидат в PR |

Интеграционная ветка для личной сборки — `sonnix/personal` (объединяет mapping+folding).
Личный дистрибутив: `Notepad++-BSL\build\make-release-local.ps1` → `dist-local\Notepad++-BSL-local.zip`.

- Баг мелкого шрифта: при прямой установке лексера (авто-детект) плагин задавал только
  цвета, оставляя `STYLE_DEFAULT`-неинициализированный размер (0) → текст «в точку».
  Не специфичен для BSL — воспроизводится на любом языке. Заслуживает отдельного issue/PR.
- Фикс сворачивания — language-agnostic, тоже годится в PR независимо от BSL-изменений.

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

## 3. Подсветка языка запросов внутри строк — исследовано, отложено

Идея (частый запрос у 1С-разработчиков): красить текст запроса внутри строкового литерала
(`"ВЫБРАТЬ …"`) как код языка запросов 1С.

Что выяснено:

- В репозитории грамматики есть **вторая грамматика `sdbl`** (язык запросов) — собирается,
  ABI 15, парсит чисто. Плюс автор bsl-грамматики уже написал `grammars/bsl/queries/injections.scm`,
  который по regex (`^"…(ВЫБРАТЬ|SELECT|УНИЧТОЖИТЬ|DROP)`) объявляет строку содержимым SDBL.
- Плагин **поддерживает инъекции**: грузит `<language>-injections.scm`, разбирает вложенный
  текст и мапит подсветку обратно.
- Проверено экспериментом: SDBL **восстанавливается после ошибок** на сыром тексте строки
  (с кавычками и `|`) и токены находит; смещения байтов совпадают 1:1. То есть `#strip!`
  (не реализован плагином) — терпимо.

**Блокеры (в плагине):**
1. При **сборе** инъекций `EvaluatePredicates` не вызывается (проверено: всего 2 вызова —
   основной проход и разбор уже найденной инъекции). Значит `#match?` в `injections.scm`
   игнорируется → как есть правило подставит под SDBL **все** строки, а не только запросы.
2. Нет поддержки `injection.combined` → **конкатенацию** `"ВЫБРАТЬ … ИЗ " + ИмяТаблицы + " … "`
   склеить нельзя, а в 1С это частый случай. Даже с фиксом п.1 полноценной подсветки не выйдет.

**Вывод:** не реализуем. Простая замена — «оттенок для строки-запроса» — читаемость запроса
не повышает и отклонена. Настоящее решение (распознать выражение-склейку → собрать текст →
разобрать как SDBL → покрасить по токенам) требует иного инструмента, не этого плагина.
Задел (сборка `sdbl.dll`, инъекции) удалён, чтобы не раздувать пакет.

## 4. Куда публиковать сам репозиторий

- Код: **GitVerse.ru** / **GitFlic.ru** (зеркало — GitHub).
- Анонс: **Infostart.ru** (инструмент + статья), **Хабр** (хаб 1С), профильные Telegram-каналы.
- Дистрибутив: в **Releases** (собранный `Notepad++-BSL.zip`), исходники — в git.

## 5. Чек-лист перед публикацией

- [ ] Указать себя в `LICENSE` (сейчас «The Notepad++ BSL Highlighting authors»).
- [ ] Добавить скриншот в `README.md` и в анонс.
- [ ] Проверить, что в Releases лежит zip, собранный `build/make-release.ps1`.
- [ ] В описании релиза — версии компонентов из `build/versions.psd1`.
- [ ] Убедиться, что `NOTICE.md` и `LICENSES/` попали в пакет (make-release это делает).
