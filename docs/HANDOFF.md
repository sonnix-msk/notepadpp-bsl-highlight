# HANDOFF — состояние проекта (для продолжения работы)

Документ для восстановления контекста. Полные детали — в спеке
`../notepad++-bsl-подсветка-СПЕКА.md` (в родительской папке `D:\OpenCode\Скрипты\`).

## Что это

Подсветка языка 1С:Предприятие (BSL) в Notepad++ на базе tree-sitter (не UDL).
Плагин-хост `Thorium/NppTreeSitter` + грамматика `alkoleft/tree-sitter-bsl` + наши
правила раскраски и установщик.

## Где что лежит

- **Репозиторий (git):** `D:\OpenCode\Скрипты\Notepad++-BSL` (вложенный репо внутри
  `D:\OpenCode\Скрипты`, НЕ путать с родительским).
- **Спека:** `D:\OpenCode\Скрипты\notepad++-bsl-подсветка-СПЕКА.md` (вне репо).
- **Индекс проекта:** `D:\OpenCode\Скрипты\README-СКРИПТЫ.md` (раздел «Подсветка BSL»).
- **Собранный дистрибутив (Standard):** `Notepad++-BSL\dist\Notepad++-BSL.zip`.
- **Личный форк плагина:** `D:\OpenCode\Форки\NppTreeSitter` (см. отдельный раздел ниже);
  сборка Extended — `Notepad++-BSL\build\make-release-extended.ps1`.
- **Рабочие инструменты (temp):** `C:\Users\SSOLNT~1\AppData\Local\Temp\opencode\ts-bsl\`.

## Две вариации дистрибутива

Один репозиторий, **два артефакта** (вариант задаётся сборочным скриптом, не git-ветками —
`.scm`/грамматика/установщик общие, один источник истины):

| Вариация | Сборка | Артефакт | Что внутри |
|---|---|---|---|
| **Standard** | `build\make-release.ps1` | `dist\Notepad++-BSL.zip` | стоковый лексер Thorium (как публичный релиз) |
| **Extended** (авторская) | `build\make-release-extended.ps1` | `dist-extended\Notepad++-BSL-extended.zip` | пропатченный лексер из форка: фиксы #7/#8/шрифт + подсветка запросов SDBL (фрагменты в строках `.bsl` и отдельные `.sdbl`/`.1cquery`) |

Публичный релиз на GitHub/GitFlic — это **Standard**. Extended существует для личного
использования **и опубликован как релиз форка**:
https://github.com/sonnix-msk/NppTreeSitter/releases/tag/v0.1.0-extended
(ассет `notepadpp-bsl-extended-0.1.0.zip`, SHA256 `207A7493…B57CE1A`; версия 0.1.0 — как у
Standard). В нём — только наша DLL из форка вместо стоковой.
По мере влития PR #9/#10/#11 в апстрим Extended «худеет» (остаётся только своя, не-апстрим
часть — SDBL-фрагменты/язык запроса).
**Extended** автоматически кладёт `tree-sitter-sdbl.dll` + `sdbl-highlights.scm` в
`TreeSitterGrammars` (сборка — `build-sdbl-grammar.ps1`, воспроизводимо, x64+x86; флаг
`-SkipSdbl` пропускает) и стили `QUERY *` (14..24) — в `src/TreeSitterLexer.xml`.
**Обязательно** вместе с ними кладётся `src/bsl-query-fragments.json` (лексикон скорера):
лексер читает его из `TreeSitterGrammars\` по одному на архитектуру и **только один раз**
(после замены нужен перезапуск N++). Если файла нет — подсветка **фрагментов в строках**
молча не работает (отдельные `.sdbl`/`.1cquery` при этом работают).
**Лицензия Extended:** GPL-2.0-or-later (строке README апстрима; в апстриме нет файла LICENSE,
а `vcxproj` заявляет Unlicense — выбрана строгая трактовка). В форке добавлены `LICENSE` и
`FORK-NOTICE.md`, дефолтная ветвь форка — `sonnix/personal`. Публикация релиза на форке
закрывает GPL (исходники рядом с бинарником).

## Личный форк плагина (фиксы #7/#8, позже — инъекции)

Все три личные задачи (детект уже открытых файлов, сворачивание, подсветка запросов)
живут в **плагине** `NppTreeSitter`, а не в грамматике и не в наших `.scm`. Поэтому заведён
личный форк плагина; публичный дистрибутив при этом нетронут — он качает стоковый плагин
из релиза Thorium (`build/versions.psd1`).

- **Форк:** https://github.com/sonnix-msk/NppTreeSitter (fork of `Thorium/NppTreeSitter`).
- **Локально:** `D:\OpenCode\Форки\NppTreeSitter` (клон с сабмодулем `external/tree-sitter`).
- **Ремоуты:** `origin` = наш форк, `upstream` = Thorium.
- **Ветки:** `master` — зеркало апстрима (не редактируем); `sonnix/bsl-detect` — авто-детект
  `.bsl`/`.os` → [PR #11](https://github.com/Thorium/NppTreeSitter/pull/11); `sonnix/styles` —
  фикс мелкого шрифта → [PR #10](https://github.com/Thorium/NppTreeSitter/pull/10);
  `sonnix/folding` — сворачивание (#8) → [PR #9](https://github.com/Thorium/NppTreeSitter/pull/9);
  `sonnix/mapping` — bsl-детект + локальная XML-палитра (в апстрим не ушло);
  `sonnix/injections` — подсветка фрагментов запросов SDBL внутри строк BSL (+ своя палитра);
  `sonnix/sdbl` — отдельный язык `treesitter.sdbl` для `.sdbl`/`.1cquery` (та же палитра);
  `sonnix/personal` — **интеграция всех наших фиксов** (из неё собирается Extended).
  `injections`/`sdbl` вливаются в `sonnix/personal` по мере готовности.
- **Где что править:** #7 — `src/dllmain.cpp` (`DetectTreeSitterLanguageForFile`,
  `PreferBuiltInLexerForExtension`); #8 — `Fold()` в `src/TreeSitterLexer.cpp`; стили — там же
  (`LoadPaletteFromConfigXml`/`ApplyTreeSitterStyleColors`); инъекции — там же
  (сбор инъекций не вызывает `EvaluatePredicates`, `#match?` игнорируется).
- **Локальные фиксы — кандидаты в PR апстриму.** В коде помечены `TODO(upstream)`; таблица
  статусов и issue — в `docs/UPSTREAM.md` §0а. Когда проверено на живом Notepad++ — предложить
  Thorium отдельными PR (фикс сворачивания language-agnostic, не завязан на BSL).
- **Проверка сворачивания без Notepad++:** симулятор `…\Temp\opencode\ts-bsl\out\fold_fix.exe`
  `<grammar.dll> tree_sitter_bsl <file.bsl>` печатает `OK/DEAD` по заголовкам (старый алгоритм —
  `fold_sim.exe <file>`). На `fold_test.bsl`: старый `dead=6/7`, новый `visible=6 dead=0`.
- **Сборка плагина (MSBuild, не CMake):**
  `MSBuild NppTreeSitter.vcxproj -p:Configuration=Release -p:Platform=x64` (и `Win32`).
  Выход: `build\x64\Release\TreeSitterLexer.dll`, `build\Win32\Release\TreeSitterLexer.dll`.
  Тулсет `v145` (VS «18» BuildTools, путь через `vswhere`).
- **Обновление из апстрима:** `git fetch upstream` → `git rebase upstream/master sonnix/<ветка>`.
- **Сборка Extended:** `build\make-release-extended.ps1` вызывает публичный `make-release.ps1`
  (он НЕ меняется), подменяет DLL на собранные из форка и кладёт
  `dist-extended\Notepad++-BSL-extended.zip`.
  Флаги: `-BuildPlugin` (собрать плагин из форка), `-ForkDir <путь>`.
- **Лицензия:** NppTreeSitter — GPL-2.0-or-later. Для личного использования публиковать не обязан;
  при раздаче своей DLL исходники должны быть доступны (публичный форк это закрывает).

## Опубликовано

- GitHub (origin, публичный): https://github.com/sonnix-msk/notepadpp-bsl-highlight
- GitFlic (зеркало): https://gitflic.ru/project/sonnix/notepadpp-bsl-highlight
- `origin` настроен пушить в **оба** (два push-url). `git push origin main` → оба зеркала.
  Отдельный remote `gitflic` — для fetch/точечных операций.
- Ветка `main` (`26fbbc6`), тег `v0.1.0` → тот же коммит (в обоих зеркалах tag-object `c02885b`).
- **Релизы `v0.1.0`** на обеих площадках с `Notepad++-BSL.zip` (547225 байт,
  SHA256 `0DBF0FF0…31ED696`). GitHub release id `413695166`, GitFlic release id
  `465be0ad-33e5-459c-a6e8-70573793e4e2`. Скачивание проверено.
- **Анонс НЕ опубликован** (тексты готовы).

## Готовое к публикации

- `docs/ANNOUNCE.md` — три готовых текста: Infostart (инструмент+статья), Хабр
  (техстатья с рамкой про AI-ассистента), Telegram (короткий пост). Ссылки на релиз вписаны.
- `docs/UPSTREAM.md` — теория апстрима, отправленные issue, исследование SDBL.
- `docs/QUERY-FRAGMENTS.md` — **перенесён в форк** (`sonnix/injections`, `NppTreeSitter/docs/`),
  т.к. фича требует пропатченного лексера. Здесь только указатель.
- Скриншот для статей — **ждём от пользователя** (он делает сам).

## Что сделано (по темам)

### Сборка/дистрибутив
- `build/build-grammar.ps1` — сборка `tree-sitter-bsl.dll` (x64+x86) через MSVC,
  флаги **`/Brepro /d1nodatetime`** (воспроизводимая сборка, стабильный SHA256).
- `build/grammar.rc` — VERSIONINFO (метаданные DLL, снижает FP антивируса).
- `build/make-release.ps1` — собирает `dist\Notepad++-BSL\` + zip. Нужен MSVC Build Tools.
- `build/versions.psd1` — закреплённые версии: NppTreeSitter 1.4.3, tree-sitter-bsl 0.1.7.
- Установщик: `src/install.ps1` + `src/INSTALL.bat`. Ищет Notepad++ (реестр → типовые пути →
  ручной ввод), определяет разрядность (PE-заголовок), UAC, бэкап конфига. Поддержка x64+x86.
- Лицензии: `LICENSE` (MIT, © Stanislav Solntsev), `NOTICE.md`, `LICENSES/`
  (важно: **NppTreeSitter — GPL-2.0-or-later**, грамматика и runtime — MIT).

### Подсветка (`src/bsl-highlights.scm`, `src/TreeSitterLexer.xml`)
- Препроцессор (`#Если`, `#Область`, `&НаСервере`) — целиком однострочно, ВКЛЮЧАЯ
  недопечатанные директивы (парсятся как `(ERROR)`).
- `Новый` → keyword; свойства после точки (`Запрос.Параметры`) → идентификатор.
- Цвета: keyword `E00000`, operator `A00000`, string/number/дата `000000`,
  идентификаторы `0000FF`, comment `008000`, preprocessor `963200`.

### Ключевые инженерные находки (в спеке, раздел 6)
- **Приоритет правил:** побеждает больший `start` (вложенный узел), не номер паттерна.
- `property` ≠ `identifier` (члены после точки).
- `NEW_KEYWORD` мапился в Function (синий) → выглядел идентификатором.
- `preprocessor` — многострочная нода, красятся её прямые дети.
- Сворачивание ломается на вложенном выражении в заголовке (issue #8) — не наш баг.

## Апстрим (issues отправлены, ждём ответа)

- **#7** https://github.com/Thorium/NppTreeSitter/issues/7 — добавить `bsl`/`os` в
  авто-определение (иначе уже открытые вкладки не подхватываются).
- **#8** https://github.com/Thorium/NppTreeSitter/issues/8 — сворачивание ломается, когда
  заголовок содержит выражение глубже тела. Репро на Python (бандловая грамматика),
  причина — `Fold()` берёт глубину AST. **Направление фикса предложено, патч НЕ писали.**

## Отклонено осознанно

- **Подсветка языка запросов внутри строк** (`"ВЫБРАТЬ …"`). Причина: плагин игнорирует
  `#match?` при сборе инъекций, нет поддержки конкатенации (`"…" + Имя + "…"`).
  Задел (`sdbl.dll`, инъекции) удалён, исследование в `docs/UPSTREAM.md` §3.

## Напоминания по безопасности

Пользователь присылал в чат открытым текстом: пароль GitHub, логин/пароль прокси,
токены GitFlic. **Нужно сменить/отозвать** (токены GitFlic — удалить в «Профиль → API токены»).

## Рабочие инструменты (temp: `…\Temp\opencode\ts-bsl\`)

Симуляторы (пересобираются из `.c` там же; нужен MSVC и `rt\tree-sitter-0.25.10`):
- `qtest.exe` — проверить, что `.scm` компилируется (паттерны/капчуры).
- `paint.exe` — симулятор раскраски плагина (С вычислением предикатов `#match?`).
- `fold_vis.exe` / `fold_fix.exe` / `fold_dump.exe` — симуляторы `Fold()` (текущий / с фиксом).
- `fold_dll.exe` — сворачивание для произвольной грамматики (`<dll> <symbol> <file>`).
- `abiprobe.exe`/`abiprobe32.exe` — ABI+имя грамматики.
- `hl2.exe` — список совпадений query со спанами.

Исходники грамматики: `src\tree-sitter-bsl-0.1.7\`, рантайм: `rt\tree-sitter-0.25.10\`,
дистрибутив плагина: `NppTreeSitter\`.

## Установлено в живом Notepad++

Плагин `TreeSitterLexer`, грамматики `bsl`, `python`, `markdown`, `markdown_inline`.
(bsl — наш; остальные добавлены для тестов.)

## Холодный старт (после сжатия контекста)

1. Прочитать `docs/HANDOFF.md` (этот файл) и спеку `../notepad++-bsl-подсветка-СПЕКА.md`.
2. Репозиторий: `D:\OpenCode\Скрипты\Notepad++-BSL`. Проверить `git status`, `git log`.
3. **Сборка пакета:** `powershell -File build\make-release.ps1` (нужен MSVC Build Tools;
   каталог `dist\` пересобирается). Перед сборкой закрыть Notepad++.
   Расширенная (авторская) вариация — `build\make-release-extended.ps1 -BuildPlugin`
   (→ `dist-extended\`), см. раздел «Две вариации дистрибутива».
4. **Публикация:** `git push origin main` (уходит в оба зеркала — GitHub + GitFlic).
5. **GitHub API** (релизы/issues) — токен уже сохранён в Git Credential Manager, получить так:
   ```powershell
   $env:PATH="C:\Program Files\Git\ucrt64\bin;$env:PATH"
   $tok = ((("protocol=https`nhost=github.com`n`n" | git credential fill 2>&1) |
            Where-Object { $_ -like "password=*" }) -replace '^password=','')
   ```
   Заголовок: `@{ Authorization="token $tok"; 'User-Agent'='oc' }`. Права: `repo`.
6. **GitFlic API** — нужен свежий токен от пользователя (старые он отзывает). База
   `https://api.gitflic.ru`, заголовок `Authorization: token <token>` (детали в спеке §7).
7. **Заново собрать инструменты-симуляторы** (если temp очистили) — из `…\Temp\opencode\ts-bsl\`,
   `vcvarsall.bat x64` + `cl`; ключевые include-пути:
   ```
   /I rt\tree-sitter-0.25.10\lib\include  /I src\tree-sitter-bsl-0.1.7\grammars\bsl\src
   /I rt\tree-sitter-0.25.10\lib\src   (плюс lib\src\lib.c и parser.c в линковку)
   ```
   `paint`/`fold_*` — C++ (`/EHsc`), нужен `extern "C"` для `tree_sitter_bsl`.

## Где остановились / следующие шаги

1. **Ждём скриншот** от пользователя → вставить в `docs/ANNOUNCE.md` (`<СКРИНШОТ>`).
2. **Опубликовать анонс** (Infostart + Хабр + Telegram), ссылки уже в текстах.
3. При желании — зеркало на GitVerse.ru.
4. **PR в апстрим отправлены** (2026-10-16): [#9 сворачивание](https://github.com/Thorium/NppTreeSitter/pull/9),
   [#10 шрифт](https://github.com/Thorium/NppTreeSitter/pull/10),
   [#11 bsl-детект](https://github.com/Thorium/NppTreeSitter/pull/11) — все `mergeable`.
   Детали и ветки — `docs/UPSTREAM.md` §0а. Следить за ответами автора.
   Слежение: `powershell -File D:\OpenCode\Скрипты\bsl-upstream-watch.ps1` (состояние PR/issue и
   новые комментарии; повторный запуск показывает только изменения).
5. **Подсветка запросов SDBL** — это фича **авторской вариации** (нужен пропатченный лексер),
   поэтому её дизайн и харнесс лежат **в форке**: `NppTreeSitter/docs/QUERY-FRAGMENTS.md` и
   `NppTreeSitter/tools/query-fragments/` (ветка `sonnix/injections`). Порог 0.30, лексикон из
   грамматики SDBL, проверено на корпусе. Корпус для замеров: `D:\OpenCode\Скрипты\Tmp\bsl`
   (7 модулей, 15 МБ — **реальная конфигурация, вне репо; сырые отчёты с текстом модулей
   нигде публично не коммитить**).
6. Мелкие незакрытые хотелки пользователя: фон/тёмная тема и шрифт — уже настраиваются через
   XML (`<LexerType name="treesitter.bsl">`, `fontName`/`fontSize`/`bgColor`), правки без
   пересборки; `=` в присваивании сейчас Default (в грамматике — анонимный литерал, не `(operator)`).
7. **Лицензия плагина** — уточнить у автора (GPL vs Unlicense), см. «⚠ Открытые вопросы».

## ⚠ Открытые вопросы (не забыть!)

- **Лицензия плагина NppTreeSitter — решено (GPL-трактовка), ответ автора ждём справочно.**
  - `README.md` апстрима → `GPL-2.0-or-later`; `NppTreeSitter.vcxproj` → `Unlicense`/Public
    Domain; файла `LICENSE` в апстриме **нет**. GitHub лицензию не определяет (NONE).
  - **Выбрано:** исходим из **GPL-2.0-or-later** — строже, безопасно при любой трактовке;
    наш форк публичен (исходники рядом с бинарником) — GPL закрыт. В форке добавлены
    `LICENSE` + `FORK-NOTICE.md`; Extended опубликован релизом на форке (см. выше).
  - Вопрос Tuomas (github.com/Thorium) можно задать справочно — **публикацию не блокирует**;
    придёт ответ — уточним формулировку `FORK-NOTICE.md`/`NOTICE.md`.
  - На Standard-вариацию (стоковая DLL) не влияет.

## Правила перевыпуска релиза (важно, дорого наступать повторно)

- **GitFlic не даёт двигать тег под релизом.** Порядок: удалить релиз (API) → удалить тег →
  запушить тег → пересоздать релиз + залить файл.
- **GitHub после force-обновления тега отвязывает релиз** (страница открывается, скачивание 404).
  Лечение: удалить релиз и создать заново на текущем теге.
- **Касперский блокирует перезапись `tree-sitter-bsl.dll`** при сборке (`LNK1104`) —
  удалить залоченный файл и пересобрать; исключения помогают не всегда. Notepad++ тоже держит
  загруженную DLL — закрывать перед сборкой.
- До анонса (0 скачиваний) перевыпуск под тем же тегом допустим; после анонса — только `0.1.1+`.
