v() {
  # --- NEON COLOR PALETTE ---
  local CYAN='\033[1;96m'
  local MAGENTA='\033[1;95m'
  local GREEN='\033[1;92m'
  local YELLOW='\033[1;93m'
  local RED='\033[1;91m'
  local BOLD='\033[1m'
  local NC='\033[0m'

  # --- ASCII BANNER ---
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

  # --- HELPER FUNCTION: STATUS BOX ---
  _v_status() {
    local py_v=$(python -V 2>&1 | awk '{print $2}')
    local branch=$(git branch --show-current 2>/dev/null)
    local venv_size=$(du -sh venv 2>/dev/null | cut -f1)

    echo -e "${MAGENTA}╭───────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}📂 PROJECT:${NC}  ${BOLD}$(basename "$PWD")${NC}"
    [[ -n "$branch" ]] && echo -e "${MAGENTA}│${NC} ${MAGENTA}🌿 BRANCH:${NC}   ${BOLD}$branch${NC}"
    echo -e "${MAGENTA}│${NC} ${GREEN}🐍 PYTHON:${NC}   ${BOLD}$py_v${NC} (venv: ${venv_size:-N/A})"
    echo -e "${MAGENTA}╰───────────────────────────────────────────────────${NC}"
  }

  # --- NEW FUNCTION: DETAILED INFO ---
  _v_info() {
    if [[ ! -d "venv" ]]; then
      echo -e "${RED}✖ ERROR:${NC} No venv directory in the current location."
      return 1
    fi

    local py_v=$(python -V 2>&1 | awk '{print $2}')
    local py_path=$(which python 2>/dev/null || echo "N/A")
    local venv_size=$(du -sh venv 2>/dev/null | cut -f1)
    local venv_size_bytes=$(du -sb venv 2>/dev/null | cut -f1)
    local branch=$(git branch --show-current 2>/dev/null)
    local git_remote=$(git remote get-url origin 2>/dev/null || echo "none")

    # venv creation date (pyvenv.cfg or directory)
    local created_date="N/A"
    if [[ -f "venv/pyvenv.cfg" ]]; then
      created_date=$(stat -c "%y" venv/pyvenv.cfg 2>/dev/null ||
        stat -f "%Sm" venv/pyvenv.cfg 2>/dev/null ||
        echo "N/A")
      created_date=$(echo "$created_date" | cut -d'.' -f1)
    fi

    # Package count (excluding pip/setuptools/wheel)
    local pkg_count=0
    if [[ -n "$VIRTUAL_ENV" ]]; then
      pkg_count=$(pip list --format=columns 2>/dev/null |
        grep -vE "^Package|^---|^pip |^setuptools |^wheel " |
        wc -l | tr -d ' ')
    else
      # Attempt to count without activation via site-packages
      local site_pkg=$(find venv -type d -name "site-packages" 2>/dev/null | head -1)
      if [[ -n "$site_pkg" ]]; then
        pkg_count=$(ls "$site_pkg" 2>/dev/null |
          grep -vE "pip|setuptools|wheel|__pycache__|\.dist-info$|\.data$" |
          grep -c "\.dist-info" 2>/dev/null || echo "?")
        # Count .dist-info directories as packages
        pkg_count=$(ls "$site_pkg" 2>/dev/null |
          grep -c "\.dist-info$" 2>/dev/null || echo "?")
      fi
    fi

    # Python used to create the venv
    local venv_py_bin=$(cat venv/pyvenv.cfg 2>/dev/null |
      grep "^home" | awk -F'= ' '{print $2}')

    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}📊 DETAILED ENVIRONMENT INFORMATION${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}📂 Project:${NC}        ${BOLD}$(basename "$PWD")${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}📍 Path:${NC}        ${BOLD}$PWD${NC}"
    [[ -n "$branch" ]] &&
      echo -e "${MAGENTA}│${NC} ${MAGENTA}🌿 Git branch:${NC}     ${BOLD}$branch${NC}"
    [[ "$git_remote" != "none" ]] &&
      echo -e "${MAGENTA}│${NC} ${MAGENTA}🔗 Git remote:${NC}     ${BOLD}$git_remote${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${GREEN}🐍 Python (active):${NC} ${BOLD}$py_v${NC}"
    echo -e "${MAGENTA}│${NC} ${GREEN}📌 Python path:${NC}  ${BOLD}$py_path${NC}"
    [[ -n "$venv_py_bin" ]] &&
      echo -e "${MAGENTA}│${NC} ${GREEN}🏗 Venv base Python:${NC} ${BOLD}$venv_py_bin${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${YELLOW}📦 Packages (excluding base):${NC} ${BOLD}$pkg_count${NC}"
    echo -e "${MAGENTA}│${NC} ${YELLOW}💾 venv size:${NC}      ${BOLD}$venv_size${NC}"
    echo -e "${MAGENTA}│${NC} ${YELLOW}📅 Created:${NC}         ${BOLD}$created_date${NC}"

    # Whether the environment is active
    if [[ -n "$VIRTUAL_ENV" ]]; then
      echo -e "${MAGENTA}│${NC} ${GREEN}✔  Status:${NC}           ${BOLD}${GREEN}ACTIVE${NC}"
    else
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸  Status:${NC}           ${BOLD}${YELLOW}INACTIVE${NC}"
    fi

    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
  }

  # --- NEW FUNCTION: HEALTH CHECK ---
  _v_health() {
    if [[ ! -d "venv" ]]; then
      echo -e "${RED}✖ ERROR:${NC} No venv directory in the current location."
      return 1
    fi

    local errors=0
    local warnings=0

    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}🩺 VENV ENVIRONMENT HEALTH CHECK${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"

    # 1. Check the activate file
    echo -en "${MAGENTA}│${NC} ${BOLD}[1/6]${NC} Activation script ...           "
    if [[ -f "venv/bin/activate" ]]; then
      echo -e "${GREEN}✔ OK${NC}"
    else
      echo -e "${RED}✖ MISSING${NC}"
      ((errors++))
    fi

    # 2. Check whether the Python binary exists
    echo -en "${MAGENTA}│${NC} ${BOLD}[2/6]${NC} Python/Python3 executable ...   "
    if [[ -f "venv/bin/python" || -f "venv/bin/python3" ]]; then
      echo -e "${GREEN}✔ OK${NC}"
    else
      echo -e "${RED}✖ MISSING${NC}"
      ((errors++))
    fi

    # 3. Check whether the Python binary is executable (not a broken symlink)
    echo -en "${MAGENTA}│${NC} ${BOLD}[3/6]${NC} Python symlink works ...   "
    local py_bin="venv/bin/python"
    [[ ! -f "$py_bin" ]] && py_bin="venv/bin/python3"
    if [[ -x "$py_bin" ]] && "$py_bin" --version &>/dev/null; then
      echo -e "${GREEN}✔ OK${NC}  ($("$py_bin" --version 2>&1))"
    else
      echo -e "${RED}✖ BROKEN SYMLINK${NC}"
      ((errors++))
    fi

    # 4. Check pip
    echo -en "${MAGENTA}│${NC} ${BOLD}[4/6]${NC} pip available ...            "
    if [[ -f "venv/bin/pip" ]] && venv/bin/pip --version &>/dev/null; then
      local pip_ver=$(venv/bin/pip --version 2>&1 | awk '{print $2}')
      echo -e "${GREEN}✔ OK${NC}  (pip $pip_ver)"
    else
      echo -e "${YELLOW}⚠ MISSING${NC}"
      ((warnings++))
    fi

    # 5. Dependency conflicts (only when venv is active)
    echo -en "${MAGENTA}│${NC} ${BOLD}[5/6]${NC} Dependency conflicts ...    "
    if [[ -n "$VIRTUAL_ENV" ]]; then
      local conflicts=$(pip check 2>&1)
      if echo "$conflicts" | grep -q "No broken requirements"; then
        echo -e "${GREEN}✔ NO CONFLICTS${NC}"
      else
        echo -e "${RED}✖ CONFLICTS DETECTED:${NC}"
        echo "$conflicts" | while read -r line; do
          echo -e "${MAGENTA}│${NC}    ${RED}↳${NC} $line"
        done
        ((errors++))
      fi
    else
      echo -e "${YELLOW}⚠ SKIP${NC} (activate venv to check)"
      ((warnings++))
    fi

    # 6. Check pyvenv.cfg
    echo -en "${MAGENTA}│${NC} ${BOLD}[6/6]${NC} pyvenv.cfg file ...         "
    if [[ -f "venv/pyvenv.cfg" ]]; then
      local cfg_home=$(grep "^home" venv/pyvenv.cfg | awk -F'= ' '{print $2}')
      if [[ -d "$cfg_home" ]]; then
        echo -e "${GREEN}✔ OK${NC}  (home: $cfg_home)"
      else
        echo -e "${YELLOW}⚠ WARNING${NC}  (original Python path does not exist: $cfg_home)"
        ((warnings++))
      fi
    else
      echo -e "${YELLOW}⚠ MISSING${NC}"
      ((warnings++))
    fi

    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"

    # Summary
    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
      echo -e "${MAGENTA}│${NC} ${GREEN}${BOLD}✔ RESULT: Environment is fully operational!${NC}"
    elif [[ $errors -eq 0 ]]; then
      echo -e "${MAGENTA}│${NC} ${YELLOW}${BOLD}⚠ RESULT: $warnings warnings; the environment is working.${NC}"
    else
      echo -e "${MAGENTA}│${NC} ${RED}${BOLD}✖ RESULT: $errors errors, $warnings warnings.${NC}"
      echo -e "${MAGENTA}│${NC} ${YELLOW}  Consider: ${BOLD}v --remove${NC}${YELLOW} and ${BOLD}v --create${NC}${YELLOW} to rebuild venv.${NC}"
    fi

    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
  }

  # --- NEW FUNCTION: PROJECT LIST BY SIZE ---
  _v_size() {
    echo -e "${CYAN}⏳ Calculating venv sizes in ~/Coding/ ...${NC}"
    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}💾 PROJECTS SORTED BY VENV SIZE${NC}"
    echo -e "${MAGENTA}├────────────────────┬────────────┬────────────────────────${NC}"
    printf "${MAGENTA}│${NC} ${BOLD}%-18s${NC} ${MAGENTA}│${NC} ${BOLD}%-10s${NC} ${MAGENTA}│${NC} ${BOLD}%-22s${NC}\n" \
      "PROJECT" "SIZE" "PATH"
    echo -e "${MAGENTA}├────────────────────┼────────────┼────────────────────────${NC}"

    # Collect data and sort by size (bytes)
    local tmp_data=()
    while IFS= read -r venv_path; do
      local project_path=$(dirname "$venv_path")
      local project_name=$(basename "$project_path" | cut -c1-18)
      local size_human=$(du -sh "$venv_path" 2>/dev/null | cut -f1)
      local size_bytes=$(du -sb "$venv_path" 2>/dev/null | cut -f1)
      local short_path=$(echo "$project_path" | sed "s|$HOME/||" | cut -c1-22)
      tmp_data+=("${size_bytes}|${project_name}|${size_human}|${short_path}")
    done < <(find ~/Coding -maxdepth 3 -type d -name "venv" -exec test -e "{}/bin/activate" \; -print)

    # Sort in descending order by size
    local sorted
    sorted=$(printf '%s\n' "${tmp_data[@]}" | sort -t'|' -k1 -rn)

    local total_bytes=0
    local rank=1
    while IFS='|' read -r size_bytes project_name size_human short_path; do
      # Set the color based on size
      local color="$GREEN"
      [[ $size_bytes -gt 524288000 ]] && color="$RED"                                 # > 500MB
      [[ $size_bytes -gt 104857600 && $size_bytes -le 524288000 ]] && color="$YELLOW" # 100-500MB

      printf "${MAGENTA}│${NC} ${color}%-18s${NC} ${MAGENTA}│${NC} ${color}%-10s${NC} ${MAGENTA}│${NC} %-22s\n" \
        "$project_name" "$size_human" "$short_path"
      ((total_bytes += size_bytes))
      ((rank++))
    done <<<"$sorted"

    # Total
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
    echo -e "${MAGENTA}│${NC} ${CYAN}📊 Projects:${NC} ${BOLD}$((rank - 1))${NC}   ${CYAN}|  Total venv size:${NC} ${BOLD}${total_human}${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}🟢 < 100MB   🟡 100-500MB   🔴 > 500MB${NC}"
  }

  # --- FLAG HANDLING (LOGIC) ---
  case "$1" in
  -h | --help)
    _v_banner
    echo -e "${CYAN}${BOLD}     VENV ENVIRONMENT MANAGEMENT SYSTEM${NC}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}USAGE:${NC}"
    echo -e "  ${GREEN}v${NC}               ${BOLD}»${NC} Activate venv in the current directory"
    echo -e "  ${GREEN}v [folder]${NC}       ${BOLD}»${NC} Go to ${BOLD}~/Coding/[folder]${NC} and activate"
    echo -e ""
    echo -e "${BOLD}OPTIONS:${NC}"
    echo -e "  ${YELLOW}-l, --list${NC}      ${BOLD}»${NC} List all projects with venv"
    echo -e "  ${YELLOW}-p, --pips${NC}      ${BOLD}»${NC} List installed packages (pip list)"
    echo -e "  ${YELLOW}-u, --update${NC}    ${BOLD}»${NC} Update pip, setuptools, and wheel"
    echo -e "  ${YELLOW}-c, --create${NC}    ${BOLD}»${NC} Create a new project (interactive wizard)"
    echo -e "  ${YELLOW}-rm, --remove${NC}   ${BOLD}»${NC} Remove the venv directory (safely)"
    echo -e "  ${YELLOW}-f, --find${NC}      ${BOLD}»${NC} Find a project (requires fzf)"
    echo -e ""
    echo -e "${BOLD}📦 DEPENDENCIES:${NC}"
    echo -e "  ${YELLOW}-sy, --sync${NC}     ${BOLD}»${NC} Synchronize venv with requirements.txt"
    echo -e ""
    echo -e "${BOLD}📁 MANAGEMENT:${NC}"
    echo -e "  ${YELLOW}-rn, --rename${NC}   ${BOLD}»${NC} Rename the project (rebuilds venv)"
    echo -e "  ${YELLOW}-mv, --move${NC}     ${BOLD}»${NC} Move the project to another location"
    echo -e ""
    echo -e "${BOLD}📊 STATISTICS:${NC}"
    echo -e "  ${YELLOW}-i, --info${NC}      ${BOLD}»${NC} Detailed status: size, packages, dates"
    echo -e "  ${YELLOW}-H, --health${NC}    ${BOLD}»${NC} Venv health check (symlinks, conflicts)"
    echo -e "  ${YELLOW}-s, --size${NC}      ${BOLD}»${NC} Projects sorted by venv size"
    echo -e ""
    echo -e "${BOLD}SHORTCUTS:${NC}"
    echo -e "  ${CYAN}v-q${NC}             ${BOLD}»${NC} Exit venv (deactivate)"
    return 0
    ;;

  -l | --list)
    echo -e "${CYAN}🔍 Scanning ~/Coding/...${NC}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────${NC}"
    find ~/Coding -maxdepth 3 -type d -name "venv" -exec test -e "{}/bin/activate" \; -print |
      sed "s|$HOME/Coding/||; s|/venv||" | column -c 80
    echo -e "${MAGENTA}──────────────────────────────────────────────────────${NC}"
    return 0
    ;;

  -p | --pips)
    if [[ -z "$VIRTUAL_ENV" ]]; then
      echo -e "${RED}✖ ERROR:${NC} Activate venv first!"
      return 1
    fi
    echo -e "${CYAN}📦 Packages in this environment:${NC}"
    pip list --format=columns | grep -vE "Package|---|pip|setuptools|wheel"
    return 0
    ;;

  -u | --update)
    if [[ -z "$VIRTUAL_ENV" ]]; then
      echo -e "${RED}✖ ERROR:${NC} Activate venv first!"
      return 1
    fi
    echo -e "${CYAN}🔄 Updating core tools...${NC}"
    pip install --upgrade pip setuptools wheel
    return 0
    ;;

  -c | --create)
    # ── STEP 1: Project name ──────────────────────────────
    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}🛠  NEW VENV PROJECT WIZARD${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
    echo -en "${CYAN}[1/4]${NC} Enter project name: ${BOLD}"
    read project_name
    echo -en "${NC}"
    if [[ -z "$project_name" ]]; then
      echo -e "${RED}✖ ERROR:${NC} Project name cannot be empty."
      return 1
    fi

    # ── STEP 2: Location ─────────────────────────────────
    echo -e ""
    echo -e "${CYAN}[2/4]${NC} Choose the project location:"
    echo -e "  ${BOLD}1)${NC} ${GREEN}~/Coding/${project_name}${NC}  ${YELLOW}(default)${NC}"
    echo -e "  ${BOLD}2)${NC} ${GREEN}$(pwd)/${project_name}${NC}  ${YELLOW}(current directory)${NC}"
    echo -e "  ${BOLD}3)${NC} ${GREEN}Custom path...${NC}"
    echo -en "${CYAN}Selection [1/2/3]:${NC} "
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
      echo -en "${CYAN}Enter the full path: ${NC}"
      read custom_path
      project_dir="${custom_path%/}/$project_name"
      ;;
    *)
      echo -e "${RED}✖ Invalid selection.${NC}"
      return 1
      ;;
    esac

    echo -e "${MAGENTA}│${NC} 📍 Project will be created in: ${BOLD}$project_dir${NC}"

    # ── STEP 3: Git init ────────────────────────────────────
    echo -e ""
    echo -en "${CYAN}[3/4]${NC} Initialize git + .gitignore? ${BOLD}(y/n):${NC} "
    read -n 1 do_git
    echo ""

    # ── STEP 4: requirements.txt ────────────────────────────
    echo -en "${CYAN}[4/4]${NC} Create an empty requirements.txt? ${BOLD}(y/n):${NC} "
    read -n 1 do_req
    echo ""

    # ── CREATION ───────────────────────────────────────────
    echo -e ""
    echo -e "${MAGENTA}──────────────────────────────────────────────────────${NC}"

    # Create the project directory
    if [[ -d "$project_dir" ]]; then
      echo -e "${YELLOW}⚠  Directory already exists:${NC} $project_dir"
    else
      mkdir -p "$project_dir" &&
        echo -e "${GREEN}✔${NC} Created directory: ${BOLD}$project_dir${NC}"
    fi

    cd "$project_dir" || return 1

    # Check whether venv already exists
    if [[ -d "venv" ]]; then
      echo -e "${YELLOW}⚠  Venv already exists in this directory — skipping creation.${NC}"
    else
      echo -en "${CYAN}⏳ Creating venv...${NC} "
      python3 -m venv venv && echo -e "${GREEN}✔${NC}"
      source venv/bin/activate
      echo -en "${CYAN}⏳ Updating pip...${NC} "
      pip install --upgrade pip --quiet && echo -e "${GREEN}✔${NC}"
    fi

    # Git init
    if [[ "$do_git" == "y" || "$do_git" == "Y" ]]; then
      if [[ -d ".git" ]]; then
        echo -e "${YELLOW}⚠  Git repository already exists — skipping.${NC}"
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
        echo -e "${GREEN}✔${NC} .gitignore created"
      fi
    fi

    # requirements.txt
    if [[ "$do_req" == "y" || "$do_req" == "Y" ]]; then
      if [[ ! -f "requirements.txt" ]]; then
        touch requirements.txt && echo -e "${GREEN}✔${NC} requirements.txt created"
      else
        echo -e "${YELLOW}⚠  requirements.txt already exists — skipping.${NC}"
      fi
    fi

    echo -e "${MAGENTA}──────────────────────────────────────────────────────${NC}"
    _v_status
    return 0
    ;;

  -rm | --remove)
    if [[ ! -d "venv" ]]; then
      echo -e "${RED}✖ ERROR:${NC} There is no venv directory here."
      return 1
    fi
    echo -en "${RED}❗ Are you sure you want to remove venv in this directory? (y/n): ${NC}"
    read -n 1 answer
    echo ""
    if [[ "$answer" == "y" ]]; then
      [[ -n "$VIRTUAL_ENV" ]] && deactivate
      rm -rf venv && echo -e "${GREEN}🗑 Removed.${NC}"
    fi
    return 0
    ;;

  -f | --find)
    if ! command -v fzf &>/dev/null; then
      echo -e "${RED}✖ ERROR:${NC} Install fzf!"
      return 1
    fi
    local choice=$(find ~/Coding -maxdepth 3 -type d -name "venv" |
      sed "s|$HOME/Coding/||; s|/venv||" |
      fzf --height 40% --reverse --prompt="🚀 Jump to: ")
    [[ -n "$choice" ]] && v "$choice"
    return 0
    ;;

  # ── NEW FLAGS ────────────────────────────────────────────

  -sy | --sync)
    if [[ -z "$VIRTUAL_ENV" ]]; then
      echo -e "${RED}✖ ERROR:${NC} Activate venv first!"
      return 1
    fi
    if [[ ! -f "requirements.txt" ]]; then
      echo -e "${RED}✖ ERROR:${NC} No requirements.txt file in this directory."
      return 1
    fi
    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}🔄 SYNCHRONIZATION WITH requirements.txt${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"

    # Required packages according to the file
    local required=$(grep -vE '^\s*#|^\s*$' requirements.txt | sed 's/[>=<!].*//' | tr '[:upper:]' '[:lower:]' | sort)
    # Installed packages (excluding base packages)
    local installed=$(pip list --format=freeze 2>/dev/null |
      grep -vE "^pip==|^setuptools==|^wheel==" |
      sed 's/==.*//' | tr '[:upper:]' '[:lower:]' | sort)

    # To install (listed in requirements.txt but missing from venv)
    local to_install=$(comm -23 <(echo "$required") <(echo "$installed"))
    # To remove (installed in venv but missing from requirements.txt)
    local to_remove=$(comm -13 <(echo "$required") <(echo "$installed"))

    if [[ -z "$to_install" && -z "$to_remove" ]]; then
      echo -e "${MAGENTA}│${NC} ${GREEN}✔ Environment is synchronized — no changes needed.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 0
    fi

    if [[ -n "$to_install" ]]; then
      echo -e "${MAGENTA}│${NC} ${GREEN}➕ To install:${NC}"
      echo "$to_install" | while read -r pkg; do
        echo -e "${MAGENTA}│${NC}    ${GREEN}↳${NC} $pkg"
      done
    fi
    if [[ -n "$to_remove" ]]; then
      echo -e "${MAGENTA}│${NC} ${RED}➖ To remove (not in requirements.txt):${NC}"
      echo "$to_remove" | while read -r pkg; do
        echo -e "${MAGENTA}│${NC}    ${RED}↳${NC} $pkg"
      done
    fi

    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -en "${MAGENTA}│${NC} ${CYAN}Apply changes? (y/n):${NC} "
    read -n 1 sync_answer
    echo ""
    if [[ "$sync_answer" == "y" || "$sync_answer" == "Y" ]]; then
      [[ -n "$to_install" ]] && pip install -r requirements.txt --quiet &&
        echo -e "${MAGENTA}│${NC} ${GREEN}✔ Installed missing packages.${NC}"
      if [[ -n "$to_remove" ]]; then
        echo "$to_remove" | xargs pip uninstall -y --quiet 2>/dev/null
        echo -e "${MAGENTA}│${NC} ${GREEN}✔ Removed extra packages.${NC}"
      fi
    else
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸ Cancelled.${NC}"
    fi
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
    return 0
    ;;

  -rn | --rename)
    local current_dir="$PWD"
    local current_name=$(basename "$current_dir")
    local parent_dir=$(dirname "$current_dir")

    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}✏️  RENAME PROJECT${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}Current name:${NC} ${BOLD}$current_name${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}Location:${NC}  ${BOLD}$parent_dir${NC}"
    echo -en "${MAGENTA}│${NC} ${CYAN}New name:${NC}   ${BOLD}"
    read new_name
    echo -en "${NC}"

    if [[ -z "$new_name" ]]; then
      echo -e "${MAGENTA}│${NC} ${RED}✖ New name cannot be empty.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 1
    fi
    if [[ "$new_name" == "$current_name" ]]; then
      echo -e "${MAGENTA}│${NC} ${YELLOW}⚠ Same name — no changes made.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 0
    fi

    local new_dir="$parent_dir/$new_name"
    if [[ -d "$new_dir" ]]; then
      echo -e "${MAGENTA}│${NC} ${RED}✖ Directory '$new_name' already exists in $parent_dir${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 1
    fi

    echo -e "${MAGENTA}│${NC} ${YELLOW}⚠  The following action will be performed:${NC}"
    echo -e "${MAGENTA}│${NC}    ${BOLD}$current_dir${NC}  →  ${BOLD}$new_dir${NC}"
    echo -en "${MAGENTA}│${NC} ${CYAN}Confirm? (y/n):${NC} "
    read -n 1 rn_answer
    echo ""
    if [[ "$rn_answer" != "y" && "$rn_answer" != "Y" ]]; then
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸ Cancelled.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 0
    fi

    # Deactivate if active
    if [[ -n "$VIRTUAL_ENV" ]]; then
      deactivate
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸ Deactivated venv.${NC}"
    fi

    mv "$current_dir" "$new_dir" &&
      echo -e "${MAGENTA}│${NC} ${GREEN}✔ Renamed directory.${NC}"

    # Enter the new directory and rebuild venv if it exists
    cd "$new_dir" || return 1
    if [[ -d "venv" ]]; then
      echo -e "${MAGENTA}│${NC} ${CYAN}🔁 Rebuilding venv (paths have changed)...${NC}"
      local has_req=false
      [[ -f "requirements.txt" ]] && has_req=true
      rm -rf venv
      python3 -m venv venv
      source venv/bin/activate
      pip install --upgrade pip --quiet
      if $has_req; then
        pip install -r requirements.txt --quiet &&
          echo -e "${MAGENTA}│${NC} ${GREEN}✔ Installed packages from requirements.txt.${NC}"
      fi
      echo -e "${MAGENTA}│${NC} ${GREEN}✔ Venv is ready.${NC}"
    fi
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${GREEN}${BOLD}✔ Project renamed: ${current_name} → ${new_name}${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
    return 0
    ;;

  -mv | --move)
    local current_dir="$PWD"
    local current_name=$(basename "$current_dir")

    echo -e "${MAGENTA}╭──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}${BOLD}📦 MOVE PROJECT${NC}"
    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}Project:${NC}    ${BOLD}$current_name${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}Current loc.:${NC} ${BOLD}$current_dir${NC}"
    echo -e ""
    echo -e "${CYAN}[1/2]${NC} Choose the destination:"
    echo -e "  ${BOLD}1)${NC} ${GREEN}~/Coding/${NC}  ${YELLOW}(default)${NC}"
    echo -e "  ${BOLD}2)${NC} Custom path..."
    echo -en "${CYAN}Selection [1/2]:${NC} "
    read -n 1 mv_loc
    echo ""

    local target_parent=""
    case "$mv_loc" in
    1 | "")
      target_parent="$HOME/Coding"
      ;;
    2)
      echo -en "${CYAN}Enter the full destination path: ${NC}"
      read target_parent
      target_parent="${target_parent%/}"
      ;;
    *)
      echo -e "${RED}✖ Invalid selection.${NC}"
      return 1
      ;;
    esac

    local target_dir="$target_parent/$current_name"

    if [[ "$target_dir" == "$current_dir" ]]; then
      echo -e "${MAGENTA}│${NC} ${YELLOW}⚠ Project is already in this location.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 0
    fi
    if [[ -d "$target_dir" ]]; then
      echo -e "${MAGENTA}│${NC} ${RED}✖ A directory named '$current_name' already exists at the destination.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 1
    fi

    echo -e "${MAGENTA}│${NC} ${YELLOW}⚠  The following action will be performed:${NC}"
    echo -e "${MAGENTA}│${NC}    ${BOLD}$current_dir${NC}"
    echo -e "${MAGENTA}│${NC}    ${BOLD}→ $target_dir${NC}"
    echo -en "${MAGENTA}│${NC} ${CYAN}Confirm? (y/n):${NC} "
    read -n 1 mv_answer
    echo ""
    if [[ "$mv_answer" != "y" && "$mv_answer" != "Y" ]]; then
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸ Cancelled.${NC}"
      echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────${NC}"
      return 0
    fi

    # Deactivate if active
    if [[ -n "$VIRTUAL_ENV" ]]; then
      deactivate
      echo -e "${MAGENTA}│${NC} ${YELLOW}⏸ Deactivated venv.${NC}"
    fi

    mkdir -p "$target_parent"
    mv "$current_dir" "$target_dir" &&
      echo -e "${MAGENTA}│${NC} ${GREEN}✔ Moved project directory.${NC}"

    cd "$target_dir" || return 1

    # Rebuild venv if it exists (venv paths are absolute)
    if [[ -d "venv" ]]; then
      echo -e "${MAGENTA}│${NC} ${CYAN}🔁 Rebuilding venv (new paths)...${NC}"
      local has_req=false
      [[ -f "requirements.txt" ]] && has_req=true
      rm -rf venv
      python3 -m venv venv
      source venv/bin/activate
      pip install --upgrade pip --quiet
      if $has_req; then
        pip install -r requirements.txt --quiet &&
          echo -e "${MAGENTA}│${NC} ${GREEN}✔ Installed packages from requirements.txt.${NC}"
      fi
      echo -e "${MAGENTA}│${NC} ${GREEN}✔ Venv is ready.${NC}"
    fi

    echo -e "${MAGENTA}├──────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} ${GREEN}${BOLD}✔ Project moved to: $target_dir${NC}"
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

  # --- MAIN LOGIC (ACTIVATION) ---
  local target_dir="."
  [[ -n "$1" ]] && target_dir="$HOME/Coding/$1"

  if [[ -d "$target_dir" ]]; then
    cd "$target_dir" || return
    if [[ -f "venv/bin/activate" ]]; then
      source venv/bin/activate
      _v_status
    else
      echo -e "${YELLOW}⚠ No venv in directory:${NC} ${BOLD}$(basename "$PWD")${NC}"
      echo -en "${CYAN}Create a new environment here? (y/n): ${NC}"
      read -n 1 answer
      echo ""
      if [[ "$answer" == "y" ]]; then
        v --create
      fi
    fi
  else
    echo -e "${RED}✖ ERROR:${NC} Project ${BOLD}'$1'${NC} does not exist in ~/Coding/"
    echo -e "Use ${YELLOW}v -l${NC} to view the list."
  fi
}
