# Изменения

## 0.1.0
- Первый публичный выпуск.
- Подсветка BSL через tree-sitter (NppTreeSitter + tree-sitter-bsl).
- Однострочная подсветка директив препроцессора (`#Если`, `#Область`, `&НаСервере`).
- Цветовая схема: keyword/operator/строки/числа/даты/идентификаторы/comment/preprocessor.
- Установщик `INSTALL.bat` (+ `install.ps1`) с автопоиском Notepad++, UAC и бэкапом конфига.
- Поддержка x64 и x86 Notepad++.
- В `tree-sitter-bsl.dll` добавлен VERSIONINFO (метаданные) и раздел про ложные
  срабатывания антивирусов — см. README.
