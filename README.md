# freverse

**Autor: Jan Ciecierski**

## Opis

`freverse` to wysoce wydajny program narzędziowy napisany w czystym asemblerze x86-64 (NASM) dla systemu Linux. Program służy do odwracania zawartości dowolnego pliku "w miejscu" (in-place).

Program przyjmuje jeden argument: ścieżkę do pliku, który ma zostać odwrócony.

## Jak to działa?

Aby osiągnąć maksymalną wydajność i zminimalizować liczbę wywołań systemowych, program wykorzystuje mapowanie pliku do pamięci (`mmap`):

1.  **Walidacja:** Program sprawdza, czy otrzymał poprawną liczbę argumentów (oczekuje nazwy programu i jednej nazwy pliku).
2.  **Otwarcie pliku:** Otwiera podany plik w trybie do odczytu i zapisu (`OPEN_READ_WRITE`).
3.  **Pomiar rozmiaru:** Używa wywołania `SYS_LSEEK` z opcją `SEEK_END`, aby błyskawicznie ustalić całkowity rozmiar pliku.
4.  **Mapowanie Pamięci:** Cała zawartość pliku jest mapowana do pamięci procesu za pomocą `SYS_MMAP`. Pozwala to na traktowanie pliku jak zwykłej tablicy w pamięci, eliminując potrzebę buforowania i wielokrotnych wywołań `SYS_READ`/`SYS_WRITE`.
5.  **Logika odwracania:**
    * Program używa dwóch wskaźników: jednego na początku (`r8`) i jednego na końcu (`r9`) zamapowanego regionu.
    * **Etap 1 (Szybkie bloki 16-bajtowe):** Główna pętla (`petla_obracania`) odwraca plik w 16-bajtowych porcjach. Pobiera 8 bajtów (`qword`) z początku i 8 bajtów z końca, odwraca kolejność bajtów w każdym z nich za pomocą instrukcji `bswap`, a następnie zamienia je miejscami. Jest to powtarzane, aż wskaźniki spotkają się w połowie pliku.
    * **Etap 2 (Odwracanie reszty):** Jeśli rozmiar pliku nie był wielokrotnością 16 bajtów, pozostałe bajty w środku są odwracane pojedynczo przez pętlę `.petla_po_bajtach`.
6.  **Sprzątanie:** Zmiany są automatycznie zapisywane z powrotem do pliku podczas odmapowywania pamięci (`SYS_MUNMAP`). Następnie program zamyka deskryptor pliku (`SYS_CLOSE`) i kończy działanie (`SYS_EXIT`).

Program zawiera również solidną obsługę błędów – jeśli którekolwiek z wywołań systemowych (np. otwarcie pliku) się nie powiedzie, program posprząta po sobie (np. zamknie otwarty plik, jeśli to konieczne) i zakończy się z kodem błędu 1.
make.
