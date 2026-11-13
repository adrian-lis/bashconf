v() {
  # --- PALETA NEONOWA ---
  local CYAN='\033[1;96m'
  local MAGENTA='\033[1;95m'
  local GREEN='\033[1;92m'
  local YELLOW='\033[1;93m'
  local RED='\033[1;91m'
  local BOLD='\033[1m'
  local NC='\033[0m'

  # --- BANER ASCII ---
  _v_banner() {
    echo -e "${MAGENTA}"
    echo -e " ____   ____                  "
    echo -e " \\   \\ /   /____   _______  __"
    echo -e "  \\   Y   // __ \\ /    \\  \\/ /"
    echo -e "   \\     /\\  ___/|   |  \\   / "
    echo -e "    \\___/  \\___  >___|  /\\_/  "
    echo -e "               \\/     \\/      "
    echo -e "${NC}"
  }

  # --- FUNKCJA POMOCNICZA: STATUS BOX ---
  _v_status() {
    local py_v=$(python -V 2>&1 | awk '{print $2}')
    local branch=$(git branch --show-current 2>/dev/null)
    local venv_size=$(du -sh venv 2>/dev/null | cut -f1)

    echo -e "${MAGENTA}╭───────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}📂 PROJEKT:${NC}  ${BOLD}$(basename "$PWD")${NC}"
    [[ -n "$branch" ]] && echo -e "${MAGENTA}│${NC} ${MAGENTA}🌿 BRANCH:${NC}   ${BOLD}$branch${NC}"
    echo -e "${MAGENTA}│${NC} ${GREEN}🐍 PYTHON:${NC}   ${BOLD}$py_v${NC} (venv: ${venv_size:-N/A})"
    echo -e "${MAGENTA}╰───────────────────────────────────────────────────${NC}"
  }

  # --- NOWA FUNKCJA: ROZSZERZONY INFO ---
  _v_info() {
    if [[ ! -d "venv" ]]; then
      echo -e "${RED}✖ BŁĄD:${NC} Brak folderu venv w tym miejscu."
      return 1
    fi

    local py_v=$(python -V 2>&1 | awk '{print $2}')
    local py_path=$(which python 2>/dev/null || echo "N/A")
    local venv_size=$(du -sh venv 2>/dev/null | cut -f1)
    local venv_size_bytes=$(du -sb venv 2>/dev/null | cut -f1)
    local branch=$(git branch --show-current 2>/dev/null)
    local git_remote=$(git remote get-url origin 2>/dev/null || echo "brak")

    # Data utworzenia venv (pyvenv.cfg lub katalog)
    local created_date="N/A"
    if [[ -f "venv/pyvenv.cfg" ]]; then
      created_date=$(stat -c "%y" venv/pyvenv.cfg 2>/dev/null ||
        stat -f "%Sm" venv/pyvenv.cfg 2>/dev/null ||
        echo "N/A")
      created_date=$(echo "$created_date" | cut -d'.' -f1)
    fi

    # Liczba pakietów (bez pip/setuptools/wheel)
    local pkg_count=0
    if [[ -n "$VIRTUAL_ENV" ]]; then
      pkg_count=$(pip list --format=columns 2>/dev/null |
        grep -vE "^Package|^---|^pip |^setuptools |^wheel " |
        wc -l | tr -d ' ')
    else
      # Próba policzenia bez aktywacji przez site-packages
      local site_pkg=$(find venv -type d -name "site-packages" 2>/dev/null | head -1)
      if [[ -n "$site_pkg" ]]; then
        pkg_count=$(ls "$site_pkg" 2>/dev/null |
          grep -vE "pip|setuptools|wheel|__pycache__|\.dist-info$|\.data$" |
          grep -c "\.dist-info" 2>/dev/null || echo "?")
        # Liczenie .dist-info jako pakiety
        pkg_count=$(ls "$site_pkg" 2>/dev/null |
          grep -c "\.dist-info$" 2>/dev/null || echo "?")
      fi
    fi

    # Python użyty do stworzenia venv
    local venv_py_bin=$(cat venv/pyvenv.cfg 2>/dev/null |
      grep "^home" | awk -F'= ' '{print $2}')

    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}📊 SZCZEGÓŁOWE INFORMACJE O ŚRODOWISKU${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}📂 Projekt:${NC}        ${BOLD}$(basename "$PWD")${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}📍 Ścieżka:${NC}        ${BOLD}$PWD${NC}"
    [[ -n "$branch" ]] &&
      echo -e "${MAGENTA}│${NC} ${MAGENTA}🌿 Git branch:${NC}     ${BOLD}$branch${NC}"
    [[ "$git_remote" != "brak" ]] &&
      echo -e "${MAGENTA}│${NC} ${MAGENTA}🔗 Git remote:${NC}     ${BOLD}$git_remote${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${GREEN}🐍 Python (aktywny):${NC} ${BOLD}$py_v${NC}"
    echo -e "${MAGENTA}│${NC} ${GREEN}📌 Ścieżka Python:${NC}  ${BOLD}$py_path${NC}"
    [[ -n "$venv_py_bin" ]] &&
      echo -e "${MAGENTA}│${NC} ${GREEN}🏗 Python (venv z):${NC} ${BOLD}$venv_py_bin${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${YELLOW}📦 Pakiety (bez base):${NC} ${BOLD}$pkg_count${NC}"
    echo -e "${MAGENTA}│${NC} ${YELLOW}💾 Rozmiar venv:${NC}      ${BOLD}$venv_size${NC}"
    echo -e "${MAGENTA}│${NC} ${YELLOW}📅 Utworzono:${NC}         ${BOLD}$created_date${NC}"

    # Czy aktywny
    if [[ -n "$VIRTUAL_ENV" ]]; then
      echo -e "${MAGENTA}│${NC} ${GREEN}✔  Status:${NC}           ${BOLD}${GREEN}AKTYWNY${NC}"
    else
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸  Status:${NC}           ${BOLD}${YELLOW}NIEAKTYWNY${NC}"
    fi

    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
  }

  # --- NOWA FUNKCJA: HEALTH CHECK ---
  _v_health() {
    if [[ ! -d "venv" ]]; then
      echo -e "${RED}✖ BŁĄD:${NC} Brak folderu venv w tym miejscu."
      return 1
    fi

    local errors=0
    local warnings=0

    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}🩺 DIAGNOSTYKA ŚRODOWISKA VENV${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"

    # 1. Sprawdź plik activate
    echo -en "${MAGENTA}│${NC} ${BOLD}[1/6]${NC} Plik activate ...           "
    if [[ -f "venv/bin/activate" ]]; then
      echo -e "${GREEN}✔ OK${NC}"
    else
      echo -e "${RED}✖ BRAK${NC}"
      ((errors++))
    fi

    # 2. Sprawdź czy python binary istnieje
    echo -en "${MAGENTA}│${NC} ${BOLD}[2/6]${NC} Binary python/python3 ...   "
    if [[ -f "venv/bin/python" || -f "venv/bin/python3" ]]; then
      echo -e "${GREEN}✔ OK${NC}"
    else
      echo -e "${RED}✖ BRAK${NC}"
      ((errors++))
    fi

    # 3. Sprawdź czy python binary jest wykonywalny (nie zepsuty symlink)
    echo -en "${MAGENTA}│${NC} ${BOLD}[3/6]${NC} Symlink python działa ...   "
    local py_bin="venv/bin/python"
    [[ ! -f "$py_bin" ]] && py_bin="venv/bin/python3"
    if [[ -x "$py_bin" ]] && "$py_bin" --version &>/dev/null; then
      echo -e "${GREEN}✔ OK${NC}  ($("$py_bin" --version 2>&1))"
    else
      echo -e "${RED}✖ ZEPSUTY SYMLINK${NC}"
      ((errors++))
    fi

    # 4. Sprawdź pip
    echo -en "${MAGENTA}│${NC} ${BOLD}[4/6]${NC} pip dostępny ...            "
    if [[ -f "venv/bin/pip" ]] && venv/bin/pip --version &>/dev/null; then
      local pip_ver=$(venv/bin/pip --version 2>&1 | awk '{print $2}')
      echo -e "${GREEN}✔ OK${NC}  (pip $pip_ver)"
    else
      echo -e "${YELLOW}⚠ BRAK${NC}"
      ((warnings++))
    fi

    # 5. Konflikty zależności (tylko gdy venv aktywny)
    echo -en "${MAGENTA}│${NC} ${BOLD}[5/6]${NC} Konflikty zależności ...    "
    if [[ -n "$VIRTUAL_ENV" ]]; then
      local conflicts=$(pip check 2>&1)
      if echo "$conflicts" | grep -q "No broken requirements"; then
        echo -e "${GREEN}✔ BRAK KONFLIKTÓW${NC}"
      else
        echo -e "${RED}✖ WYKRYTO KONFLIKTY:${NC}"
        echo "$conflicts" | while read -r line; do
          echo -e "${MAGENTA}│${NC}    ${RED}↳${NC} $line"
        done
        ((errors++))
      fi
    else
      echo -e "${YELLOW}⚠ POMIŃ${NC} (aktywuj venv aby sprawdzić)"
      ((warnings++))
    fi

    # 6. Sprawdź pyvenv.cfg
    echo -en "${MAGENTA}│${NC} ${BOLD}[6/6]${NC} Plik pyvenv.cfg ...         "
    if [[ -f "venv/pyvenv.cfg" ]]; then
      local cfg_home=$(grep "^home" venv/pyvenv.cfg | awk -F'= ' '{print $2}')
      if [[ -d "$cfg_home" ]]; then
        echo -e "${GREEN}✔ OK${NC}  (home: $cfg_home)"
      else
        echo -e "${YELLOW}⚠ UWAGA${NC}  (oryginalne Python path nie istnieje: $cfg_home)"
        ((warnings++))
      fi
    else
      echo -e "${YELLOW}⚠ BRAK${NC}"
      ((warnings++))
    fi

    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"

    # Podsumowanie
    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
      echo -e "${MAGENTA}│${NC} ${GREEN}${BOLD}✔ WYNIK: Środowisko w pełni sprawne!${NC}"
    elif [[ $errors -eq 0 ]]; then
      echo -e "${MAGENTA}│${NC} ${YELLOW}${BOLD}⚠ WYNIK: $warnings ostrzeżeń, środowisko działa.${NC}"
    else
      echo -e "${MAGENTA}│${NC} ${RED}${BOLD}✖ WYNIK: $errors błędów, $warnings ostrzeżeń.${NC}"
      echo -e "${MAGENTA}│${NC} ${YELLOW}  Rozważ: ${BOLD}v --remove${NC}${YELLOW} i ${BOLD}v --create${NC}${YELLOW} aby odbudować venv.${NC}"
    fi

    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
  }

  # --- NOWA FUNKCJA: LISTA PROJEKTÓW WG ROZMIARU ---
  _v_size() {
    echo -e "${CYAN}⏳ Obliczanie rozmiarów venv w ~/Coding/ ...${NC}"
    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}💾 PROJEKTY POSORTOWANE PO ROZMIARZE VENV${NC}"
    echo -e "${MAGENTA}├────────────────────┬────────────┬────────────────────────${NC}"
    printf "${MAGENTA}│${NC} ${BOLD}%-18s${NC} ${MAGENTA}│${NC} ${BOLD}%-10s${NC} ${MAGENTA}│${NC} ${BOLD}%-22s${NC}\n" \
      "PROJEKT" "ROZMIAR" "ŚCIEŻKA"
    echo -e "${MAGENTA}├────────────────────┼────────────┼────────────────────────${NC}"

    # Zbierz dane i posortuj po rozmiarze (bajtach)
    local tmp_data=()
    while IFS= read -r venv_path; do
      local project_path=$(dirname "$venv_path")
      local project_name=$(basename "$project_path" | cut -c1-18)
      local size_human=$(du -sh "$venv_path" 2>/dev/null | cut -f1)
      local size_bytes=$(du -sb "$venv_path" 2>/dev/null | cut -f1)
      local short_path=$(echo "$project_path" | sed "s|$HOME/||" | cut -c1-22)
      tmp_data+=("${size_bytes}|${project_name}|${size_human}|${short_path}")
    done < <(find ~/Coding -maxdepth 3 -type d -name "venv" -exec test -e "{}/bin/activate" \; -print)

    # Sortuj malejąco po rozmiarze
    local sorted
    sorted=$(printf '%s\n' "${tmp_data[@]}" | sort -t'|' -k1 -rn)

    local total_bytes=0
    local rank=1
    while IFS='|' read -r size_bytes project_name size_human short_path; do
      # Koloruj w zależności od rozmiaru
      local color="$GREEN"
      [[ $size_bytes -gt 524288000 ]] && color="$RED"                                 # > 500MB
      [[ $size_bytes -gt 104857600 && $size_bytes -le 524288000 ]] && color="$YELLOW" # 100-500MB

      printf "${MAGENTA}│${NC} ${color}%-18s${NC} ${MAGENTA}│${NC} ${color}%-10s${NC} ${MAGENTA}│${NC} %-22s\n" \
        "$project_name" "$size_human" "$short_path"
      ((total_bytes += size_bytes))
      ((rank++))
    done <<<"$sorted"

    # Suma
    local total_human
    if command -v numfmt &>/dev/null; then
      total_human=$(numfmt --to=iec-i --suffix=B "$total_bytes" 2>/dev/null)
    else
      total_human=$(echo "$total_bytes" | awk '{
                if ($1 >= 1073741824) printf "%.1fG", $1/1073741824
                else if ($1 >= 1048576) printf "%.1fM", $1/1048576
                else if ($1 >= 1024) printf "%.1fK", $1/1024
                else printf "%dB", $1
            }')
    fi

    echo -e "${MAGENTA}├────────────────────┴────────────┴────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}📊 Projektów:${NC} ${BOLD}$((rank - 1))${NC}   ${CYAN}|  Łącznie venv:${NC} ${BOLD}${total_human}${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}🟢 < 100MB   🟡 100-500MB   🔴 > 500MB${NC}"
  }

  # --- OBSŁUGA FLAG (LOGIKA) ---
  case "$1" in
  -h | --help)
    _v_banner
    echo -e "${CYAN}${BOLD}     SYSTEM ZARZĄDZANIA ŚRODOWISKIEM VENV${NC}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}UŻYCIE:${NC}"
    echo -e "  ${GREEN}v${NC}               ${BOLD}»${NC} Aktywuj venv w bieżącym folderze"
    echo -e "  ${GREEN}v [folder]${NC}       ${BOLD}»${NC} Skocz do ${BOLD}~/Coding/[folder]${NC} i aktywuj"
    echo -e ""
    echo -e "${BOLD}OPCJE:${NC}"
    echo -e "  ${YELLOW}-l, --list${NC}      ${BOLD}»${NC} Lista wszystkich projektów z venv"
    echo -e "  ${YELLOW}-p, --pips${NC}      ${BOLD}»${NC} Lista zainstalowanych pakietów (pip list)"
    echo -e "  ${YELLOW}-u, --update${NC}    ${BOLD}»${NC} Aktualizuj pip, setuptools i wheel"
    echo -e "  ${YELLOW}-c, --create${NC}    ${BOLD}»${NC} Kreator nowego projektu (interaktywny)"
    echo -e "  ${YELLOW}-rm, --remove${NC}   ${BOLD}»${NC} Usuń folder venv (bezpiecznie)"
    echo -e "  ${YELLOW}-f, --find${NC}      ${BOLD}»${NC} Szukaj projektu (wymaga fzf)"
    echo -e ""
    echo -e "${BOLD}📦 ZALEŻNOŚCI:${NC}"
    echo -e "  ${YELLOW}-sy, --sync${NC}     ${BOLD}»${NC} Synchronizuj venv z requirements.txt"
    echo -e ""
    echo -e "${BOLD}📁 ZARZĄDZANIE:${NC}"
    echo -e "  ${YELLOW}-rn, --rename${NC}   ${BOLD}»${NC} Zmień nazwę projektu (odbudowuje venv)"
    echo -e "  ${YELLOW}-mv, --move${NC}     ${BOLD}»${NC} Przenieś projekt w inne miejsce"
    echo -e ""
    echo -e "${BOLD}📊 STATYSTYKI:${NC}"
    echo -e "  ${YELLOW}-i, --info${NC}      ${BOLD}»${NC} Rozszerzony status: rozmiar, pakiety, daty"
    echo -e "  ${YELLOW}-H, --health${NC}    ${BOLD}»${NC} Diagnostyka venv (symlinki, konflikty)"
    echo -e "  ${YELLOW}-s, --size${NC}      ${BOLD}»${NC} Projekty posortowane po rozmiarze venv"
    echo -e ""
    echo -e "${BOLD}SKRÓTY:${NC}"
    echo -e "  ${CYAN}v-q${NC}             ${BOLD}»${NC} Wyjście z venv (deactivate)"
    return 0
    ;;

  -l | --list)
    echo -e "${CYAN}🔍 Skanowanie ~/Coding/...${NC}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────${NC}"
    find ~/Coding -maxdepth 3 -type d -name "venv" -exec test -e "{}/bin/activate" \; -print |
      sed "s|$HOME/Coding/||; s|/venv||" | column -c 80
    echo -e "${MAGENTA}──────────────────────────────────────────────────────${NC}"
    return 0
    ;;

  -p | --pips)
    if [[ -z "$VIRTUAL_ENV" ]]; then
      echo -e "${RED}✖ BŁĄD:${NC} Najpierw aktywuj venv!"
      return 1
    fi
    echo -e "${CYAN}📦 Pakiety w tym środowisku:${NC}"
    pip list --format=columns | grep -vE "Package|---|pip|setuptools|wheel"
    return 0
    ;;

  -u | --update)
    if [[ -z "$VIRTUAL_ENV" ]]; then
      echo -e "${RED}✖ BŁĄD:${NC} Najpierw aktywuj venv!"
      return 1
    fi
    echo -e "${CYAN}🔄 Aktualizacja narzędzi bazowych...${NC}"
    pip install --upgrade pip setuptools wheel
    return 0
    ;;

  -c | --create)
    # ── KROK 1: Nazwa projektu ──────────────────────────────
    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}🛠  KREATOR NOWEGO PROJEKTU VENV${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
    echo -en "${CYAN}[1/4]${NC} Podaj nazwę projektu: ${BOLD}"
    read project_name
    echo -en "${NC}"
    if [[ -z "$project_name" ]]; then
      echo -e "${RED}✖ BŁĄD:${NC} Nazwa projektu nie może być pusta."
      return 1
    fi

    # ── KROK 2: Lokalizacja ─────────────────────────────────
    echo -e ""
    echo -e "${CYAN}[2/4]${NC} Wybierz lokalizację projektu:"
    echo -e "  ${BOLD}1)${NC} ${GREEN}~/Coding/${project_name}${NC}  ${YELLOW}(domyślna)${NC}"
    echo -e "  ${BOLD}2)${NC} ${GREEN}$(pwd)/${project_name}${NC}  ${YELLOW}(bieżący folder)${NC}"
    echo -e "  ${BOLD}3)${NC} ${GREEN}Inna ścieżka...${NC}"
    echo -en "${CYAN}Wybór [1/2/3]:${NC} "
    read -n 1 loc_choice
    echo ""

    local project_dir=""
    case "$loc_choice" in
    1 | "")
      project_dir="$HOME/Coding/$project_name"
      ;;
    2)
      project_dir="$(pwd)/$project_name"
      ;;
    3)
      echo -en "${CYAN}Podaj pełną ścieżkę: ${NC}"
      read custom_path
      project_dir="${custom_path%/}/$project_name"
      ;;
    *)
      echo -e "${RED}✖ Nieprawidłowy wybór.${NC}"
      return 1
      ;;
    esac

    echo -e "${MAGENTA}│${NC} 📍 Projekt zostanie utworzony w: ${BOLD}$project_dir${NC}"

    # ── KROK 3: Git init ────────────────────────────────────
    echo -e ""
    echo -en "${CYAN}[3/4]${NC} Inicjalizować git + .gitignore? ${BOLD}(y/n):${NC} "
    read -n 1 do_git
    echo ""

    # ── KROK 4: requirements.txt ────────────────────────────
    echo -en "${CYAN}[4/4]${NC} Stworzyć pusty requirements.txt? ${BOLD}(y/n):${NC} "
    read -n 1 do_req
    echo ""

    # ── TWORZENIE ───────────────────────────────────────────
    echo -e ""
    echo -e "${MAGENTA}──────────────────────────────────────────────────────${NC}"

    # Utwórz katalog projektu
    if [[ -d "$project_dir" ]]; then
      echo -e "${YELLOW}⚠  Folder już istnieje:${NC} $project_dir"
    else
      mkdir -p "$project_dir" &&
        echo -e "${GREEN}✔${NC} Utworzono folder: ${BOLD}$project_dir${NC}"
    fi

    cd "$project_dir" || return 1

    # Sprawdź czy venv już jest
    if [[ -d "venv" ]]; then
      echo -e "${YELLOW}⚠  Venv już istnieje w tym folderze — pomijam tworzenie.${NC}"
    else
      echo -en "${CYAN}⏳ Tworzenie venv...${NC} "
      python3 -m venv venv && echo -e "${GREEN}✔${NC}"
      source venv/bin/activate
      echo -en "${CYAN}⏳ Aktualizacja pip...${NC} "
      pip install --upgrade pip --quiet && echo -e "${GREEN}✔${NC}"
    fi

    # Git init
    if [[ "$do_git" == "y" || "$do_git" == "Y" ]]; then
      if [[ -d ".git" ]]; then
        echo -e "${YELLOW}⚠  Repozytorium git już istnieje — pomijam.${NC}"
      else
        git init --quiet && echo -e "${GREEN}✔${NC} Git init"
        cat >.gitignore <<'EOF'
venv/
__pycache__/
*.pyc
*.pyo
*.pyd
.env
.DS_Store
*.egg-info/
dist/
build/
.pytest_cache/
.mypy_cache/
EOF
        echo -e "${GREEN}✔${NC} .gitignore utworzony"
      fi
    fi

    # requirements.txt
    if [[ "$do_req" == "y" || "$do_req" == "Y" ]]; then
      if [[ ! -f "requirements.txt" ]]; then
        touch requirements.txt && echo -e "${GREEN}✔${NC} requirements.txt utworzony"
      else
        echo -e "${YELLOW}⚠  requirements.txt już istnieje — pomijam.${NC}"
      fi
    fi

    echo -e "${MAGENTA}──────────────────────────────────────────────────────${NC}"
    _v_status
    return 0
    ;;

  -rm | --remove)
    if [[ ! -d "venv" ]]; then
      echo -e "${RED}✖ BŁĄD:${NC} Nie ma tu folderu venv."
      return 1
    fi
    echo -en "${RED}❗ Czy na pewno usunąć venv w tym folderze? (y/n): ${NC}"
    read -n 1 answer
    echo ""
    if [[ "$answer" == "y" ]]; then
      [[ -n "$VIRTUAL_ENV" ]] && deactivate
      rm -rf venv && echo -e "${GREEN}🗑 Usunięto.${NC}"
    fi
    return 0
    ;;

  -f | --find)
    if ! command -v fzf &>/dev/null; then
      echo -e "${RED}✖ BŁĄD:${NC} Zainstaluj fzf!"
      return 1
    fi
    local choice=$(find ~/Coding -maxdepth 3 -type d -name "venv" |
      sed "s|$HOME/Coding/||; s|/venv||" |
      fzf --height 40% --reverse --prompt="🚀 Skocz do: ")
    [[ -n "$choice" ]] && v "$choice"
    return 0
    ;;

  # ── NOWE FLAGI ────────────────────────────────────────────

  -sy | --sync)
    if [[ -z "$VIRTUAL_ENV" ]]; then
      echo -e "${RED}✖ BŁĄD:${NC} Najpierw aktywuj venv!"
      return 1
    fi
    if [[ ! -f "requirements.txt" ]]; then
      echo -e "${RED}✖ BŁĄD:${NC} Brak pliku requirements.txt w tym folderze."
      return 1
    fi
    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}🔄 SYNCHRONIZACJA Z requirements.txt${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"

    # Pakiety wymagane wg pliku
    local required=$(grep -vE '^\s*#|^\s*$' requirements.txt | sed 's/[>=<!].*//' | tr '[:upper:]' '[:lower:]' | sort)
    # Pakiety zainstalowane (bez base)
    local installed=$(pip list --format=freeze 2>/dev/null |
      grep -vE "^pip==|^setuptools==|^wheel==" |
      sed 's/==.*//' | tr '[:upper:]' '[:lower:]' | sort)

    # Do instalacji (są w requirements, nie ma w venv)
    local to_install=$(comm -23 <(echo "$required") <(echo "$installed"))
    # Do usunięcia (są w venv, nie ma w requirements)
    local to_remove=$(comm -13 <(echo "$required") <(echo "$installed"))

    if [[ -z "$to_install" && -z "$to_remove" ]]; then
      echo -e "${MAGENTA}│${NC} ${GREEN}✔ Środowisko zsynchronizowane — brak zmian.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 0
    fi

    if [[ -n "$to_install" ]]; then
      echo -e "${MAGENTA}│${NC} ${GREEN}➕ Do instalacji:${NC}"
      echo "$to_install" | while read -r pkg; do
        echo -e "${MAGENTA}│${NC}    ${GREEN}↳${NC} $pkg"
      done
    fi
    if [[ -n "$to_remove" ]]; then
      echo -e "${MAGENTA}│${NC} ${RED}➖ Do usunięcia (nie ma w requirements.txt):${NC}"
      echo "$to_remove" | while read -r pkg; do
        echo -e "${MAGENTA}│${NC}    ${RED}↳${NC} $pkg"
      done
    fi

    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -en "${MAGENTA}│${NC} ${CYAN}Zastosować zmiany? (y/n):${NC} "
    read -n 1 sync_answer
    echo ""
    if [[ "$sync_answer" == "y" || "$sync_answer" == "Y" ]]; then
      [[ -n "$to_install" ]] && pip install -r requirements.txt --quiet &&
        echo -e "${MAGENTA}│${NC} ${GREEN}✔ Zainstalowano brakujące pakiety.${NC}"
      if [[ -n "$to_remove" ]]; then
        echo "$to_remove" | xargs pip uninstall -y --quiet 2>/dev/null
        echo -e "${MAGENTA}│${NC} ${GREEN}✔ Usunięto nadmiarowe pakiety.${NC}"
      fi
    else
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸ Anulowano.${NC}"
    fi
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
    return 0
    ;;

  -rn | --rename)
    local current_dir="$PWD"
    local current_name=$(basename "$current_dir")
    local parent_dir=$(dirname "$current_dir")

    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}✏️  ZMIANA NAZWY PROJEKTU${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}Obecna nazwa:${NC} ${BOLD}$current_name${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}Lokalizacja:${NC}  ${BOLD}$parent_dir${NC}"
    echo -en "${MAGENTA}│${NC} ${CYAN}Nowa nazwa:${NC}   ${BOLD}"
    read new_name
    echo -en "${NC}"

    if [[ -z "$new_name" ]]; then
      echo -e "${MAGENTA}│${NC} ${RED}✖ Nowa nazwa nie może być pusta.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 1
    fi
    if [[ "$new_name" == "$current_name" ]]; then
      echo -e "${MAGENTA}│${NC} ${YELLOW}⚠ Taka sama nazwa — brak zmian.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 0
    fi

    local new_dir="$parent_dir/$new_name"
    if [[ -d "$new_dir" ]]; then
      echo -e "${MAGENTA}│${NC} ${RED}✖ Folder '$new_name' już istnieje w $parent_dir${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 1
    fi

    echo -e "${MAGENTA}│${NC} ${YELLOW}⚠  Zostanie wykonane:${NC}"
    echo -e "${MAGENTA}│${NC}    ${BOLD}$current_dir${NC}  →  ${BOLD}$new_dir${NC}"
    echo -en "${MAGENTA}│${NC} ${CYAN}Potwierdzasz? (y/n):${NC} "
    read -n 1 rn_answer
    echo ""
    if [[ "$rn_answer" != "y" && "$rn_answer" != "Y" ]]; then
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸ Anulowano.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 0
    fi

    # Deaktywuj jeśli aktywny
    if [[ -n "$VIRTUAL_ENV" ]]; then
      deactivate
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸ Deaktywowano venv.${NC}"
    fi

    mv "$current_dir" "$new_dir" &&
      echo -e "${MAGENTA}│${NC} ${GREEN}✔ Zmieniono nazwę folderu.${NC}"

    # Wejdź do nowego folderu i odbuduj venv jeśli istnieje
    cd "$new_dir" || return 1
    if [[ -d "venv" ]]; then
      echo -e "${MAGENTA}│${NC} ${CYAN}🔁 Odbudowuję venv (ścieżki się zmieniły)...${NC}"
      local has_req=false
      [[ -f "requirements.txt" ]] && has_req=true
      rm -rf venv
      python3 -m venv venv
      source venv/bin/activate
      pip install --upgrade pip --quiet
      if $has_req; then
        pip install -r requirements.txt --quiet &&
          echo -e "${MAGENTA}│${NC} ${GREEN}✔ Zainstalowano pakiety z requirements.txt.${NC}"
      fi
      echo -e "${MAGENTA}│${NC} ${GREEN}✔ Venv gotowy.${NC}"
    fi
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${GREEN}${BOLD}✔ Projekt przemianowany: ${current_name} → ${new_name}${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
    return 0
    ;;

  -mv | --move)
    local current_dir="$PWD"
    local current_name=$(basename "$current_dir")

    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}📦 PRZENOSZENIE PROJEKTU${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}Projekt:${NC}    ${BOLD}$current_name${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}Obecna lok.:${NC} ${BOLD}$current_dir${NC}"
    echo -e ""
    echo -e "${CYAN}[1/2]${NC} Wybierz cel przeniesienia:"
    echo -e "  ${BOLD}1)${NC} ${GREEN}~/Coding/${NC}  ${YELLOW}(domyślna)${NC}"
    echo -e "  ${BOLD}2)${NC} Inna ścieżka..."
    echo -en "${CYAN}Wybór [1/2]:${NC} "
    read -n 1 mv_loc
    echo ""

    local target_parent=""
    case "$mv_loc" in
    1 | "")
      target_parent="$HOME/Coding"
      ;;
    2)
      echo -en "${CYAN}Podaj pełną ścieżkę docelową: ${NC}"
      read target_parent
      target_parent="${target_parent%/}"
      ;;
    *)
      echo -e "${RED}✖ Nieprawidłowy wybór.${NC}"
      return 1
      ;;
    esac

    local target_dir="$target_parent/$current_name"

    if [[ "$target_dir" == "$current_dir" ]]; then
      echo -e "${MAGENTA}│${NC} ${YELLOW}⚠ Projekt już jest w tym miejscu.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 0
    fi
    if [[ -d "$target_dir" ]]; then
      echo -e "${MAGENTA}│${NC} ${RED}✖ W miejscu docelowym już istnieje folder '$current_name'.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 1
    fi

    echo -e "${MAGENTA}│${NC} ${YELLOW}⚠  Zostanie wykonane:${NC}"
    echo -e "${MAGENTA}│${NC}    ${BOLD}$current_dir${NC}"
    echo -e "${MAGENTA}│${NC}    ${BOLD}→ $target_dir${NC}"
    echo -en "${MAGENTA}│${NC} ${CYAN}Potwierdzasz? (y/n):${NC} "
    read -n 1 mv_answer
    echo ""
    if [[ "$mv_answer" != "y" && "$mv_answer" != "Y" ]]; then
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸ Anulowano.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 0
    fi

    # Deaktywuj jeśli aktywny
    if [[ -n "$VIRTUAL_ENV" ]]; then
      deactivate
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸ Deaktywowano venv.${NC}"
    fi

    mkdir -p "$target_parent"
    mv "$current_dir" "$target_dir" &&
      echo -e "${MAGENTA}│${NC} ${GREEN}✔ Przeniesiono folder projektu.${NC}"

    cd "$target_dir" || return 1

    # Odbuduj venv jeśli istnieje (ścieżki w venv są bezwzględne)
    if [[ -d "venv" ]]; then
      echo -e "${MAGENTA}│${NC} ${CYAN}🔁 Odbudowuję venv (nowe ścieżki)...${NC}"
      local has_req=false
      [[ -f "requirements.txt" ]] && has_req=true
      rm -rf venv
      python3 -m venv venv
      source venv/bin/activate
      pip install --upgrade pip --quiet
      if $has_req; then
        pip install -r requirements.txt --quiet &&
          echo -e "${MAGENTA}│${NC} ${GREEN}✔ Zainstalowano pakiety z requirements.txt.${NC}"
      fi
      echo -e "${MAGENTA}│${NC} ${GREEN}✔ Venv gotowy.${NC}"
    fi

    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${GREEN}${BOLD}✔ Projekt przeniesiony do: $target_dir${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
    return 0
    ;;

  -i | --info)
    _v_info
    return 0
    ;;

  -H | --health)
    _v_health
    return 0
    ;;

  -s | --size)
    _v_size
    return 0
    ;;

  esac

  # --- LOGIKA GŁÓWNA (AKTYWACJA) ---
  local target_dir="."
  [[ -n "$1" ]] && target_dir="$HOME/Coding/$1"

  if [[ -d "$target_dir" ]]; then
    cd "$target_dir" || return
    if [[ -f "venv/bin/activate" ]]; then
      source venv/bin/activate
      _v_status
    else
      echo -e "${YELLOW}⚠ Brak venv w folderze:${NC} ${BOLD}$(basename "$PWD")${NC}"
      echo -en "${CYAN}Utworzyć nowe środowisko tutaj? (y/n): ${NC}"
      read -n 1 answer
      echo ""
      if [[ "$answer" == "y" ]]; then
        v --create
      fi
    fi
  else
    echo -e "${RED}✖ BŁĄD:${NC} Projekt ${BOLD}'$1'${NC} nie istnieje w ~/Coding/"
    echo -e "Użyj ${YELLOW}v -l${NC} aby zobaczyć listę."
  fi
}
