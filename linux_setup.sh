#!/bin/bash
set -e

# sh/dash 로 실행해도 bash 로 다시 실행 (이 스크립트는 bash 문법을 사용)
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi

# ============================================================
#  Linux dotfiles setup  (Debian/Ubuntu · apt 기준)
#  - 이미 설치된 건 건너뜀 / 재실행해도 안전 (idempotent)
#  - Fedora/Arch 면 패키지 매니저·패키지명만 바꿔주세요.
# ============================================================

# 이 스크립트가 들어있는 폴더 = dotfiles 폴더로 자동 인식
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.config ~/.local/bin

if ! command -v apt-get &>/dev/null; then
  echo "이 스크립트는 apt(Debian/Ubuntu) 전용입니다."
  exit 1
fi

ARCH="$(dpkg --print-architecture)"   # amd64 / arm64

# ============================================================
#  0) yes/no 질문 헬퍼
#     - 대화형(터미널)이면 사용자에게 물어봄
#     - 비대화형(curl | bash 등 TTY 없음)이면 기본값 사용
#     - 환경변수로 미리 답할 수도 있음:
#         INSTALL_CLAUDE_CODE=1  /  INSTALL_GH=0  처럼 0/1 지정
# ============================================================
ask_yes_no() {
  # $1 = 질문 문구, $2 = 기본값(y/n), $3 = (선택) 환경변수 이름
  local prompt="$1" default="${2:-n}" envname="${3:-}" reply

  # 환경변수로 미리 답이 주어졌으면 그걸 사용 (1/y/yes = 예, 0/n/no = 아니오)
  if [ -n "$envname" ]; then
    local envval="${!envname:-}"
    case "$envval" in
      1|y|Y|yes|YES) return 0 ;;
      0|n|N|no|NO)   return 1 ;;
    esac
  fi

  # TTY 가 없으면(파이프 실행 등) 기본값으로 진행
  if [ ! -t 0 ]; then
    [ "$default" = "y" ]
    return
  fi

  if [ "$default" = "y" ]; then
    read -r -p "$prompt [Y/n] " reply || reply=""
  else
    read -r -p "$prompt [y/N] " reply || reply=""
  fi
  reply="${reply:-$default}"
  case "$reply" in
    [Yy]*) return 0 ;;
    *)     return 1 ;;
  esac
}

# ============================================================
#  1) apt 패키지 (이미 깔린 건 apt 가 알아서 건너뜀)
# ============================================================
echo "── apt packages ──"
sudo apt-get update
sudo apt-get install -y \
  build-essential git curl wget unzip gnupg \
  zsh \
  ripgrep fd-find bat \
  jq httpie btop tmux fzf tldr \
  zsh-autosuggestions zsh-syntax-highlighting

# Ubuntu 는 fd→fdfind, bat→batcat 로 깔리므로 표준 이름으로 심링크
if command -v fdfind &>/dev/null && [ ! -e "$HOME/.local/bin/fd" ]; then
  ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
if command -v batcat &>/dev/null && [ ! -e "$HOME/.local/bin/bat" ]; then
  ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# ── neovim (apt 버전은 오래되어 snap 우선) ──
if ! command -v nvim &>/dev/null; then
  if command -v snap &>/dev/null; then
    sudo snap install nvim --classic
  else
    echo "⚠ snap 없음 → apt 로 설치(구버전일 수 있음)"
    sudo apt-get install -y neovim
  fi
fi

# ============================================================
#  2) apt 에 없거나 오래된 도구 → 공식 저장소/스크립트
# ============================================================

# ── starship (프롬프트) ──
if ! command -v starship &>/dev/null; then
  echo "→ installing starship ..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# ── zoxide (cd 대체) → ~/.local/bin ──
if ! command -v zoxide &>/dev/null; then
  echo "→ installing zoxide ..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# ── eza (ls 대체) → 공식 apt 저장소 ──
if ! command -v eza &>/dev/null; then
  echo "→ installing eza ..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt-get update
  sudo apt-get install -y eza
fi

# ============================================================
#  2-A) 선택 설치 (설치할지 물어봄)
# ============================================================

# ── gh (GitHub CLI) → 공식 apt 저장소 ──
if command -v gh &>/dev/null; then
  echo "✓ gh 이미 설치됨 (건너뜀)"
elif ask_yes_no "GitHub CLI(gh) 를 설치할까요?" y INSTALL_GH; then
  echo "→ installing gh ..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y gh
  echo "  ↳ 로그인:  gh auth login"
else
  echo "⊘ gh 설치 건너뜀"
fi

# ── Claude Code → 공식 네이티브 설치 스크립트 (Node.js 불필요, ~/.local/bin 에 설치) ──
if command -v claude &>/dev/null; then
  echo "✓ claude code 이미 설치됨 (건너뜀)"
elif ask_yes_no "Claude Code 를 설치할까요?" y INSTALL_CLAUDE_CODE; then
  echo "→ installing Claude Code ..."
  # set -e 상태에서 설치 실패가 전체 스크립트를 중단시키지 않도록 보호
  if curl -fsSL https://claude.ai/install.sh | bash; then
    echo "  ↳ 설치 완료. 새 셸에서:  claude --version  /  첫 실행 시 브라우저로 로그인"
  else
    echo "⚠ Claude Code 설치 실패 → 수동 설치:  curl -fsSL https://claude.ai/install.sh | bash"
  fi
else
  echo "⊘ Claude Code 설치 건너뜀"
fi

# ── lazygit (apt 에 없음) → GitHub 릴리스 ──
if ! command -v lazygit &>/dev/null; then
  echo "→ installing lazygit ..."
  case "$ARCH" in
    amd64) LG_ARCH="x86_64" ;;
    arm64) LG_ARCH="arm64"  ;;
    *)     LG_ARCH="x86_64" ;;
  esac
  LG_VER=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo /tmp/lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_${LG_ARCH}.tar.gz"
  tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin
  rm -f /tmp/lazygit /tmp/lazygit.tar.gz
fi

# ── git-delta (diff pager) ──
if ! command -v delta &>/dev/null; then
  if apt-cache show git-delta &>/dev/null; then
    sudo apt-get install -y git-delta
  else
    echo "⚠ git-delta 가 apt 에 없음 → https://github.com/dandavison/delta/releases 에서 .deb 설치 권장"
  fi
fi

# ============================================================
#  3) 셸 설정 (init + alias) → $DOTFILES/zshrc 에 1회만 추가
# ============================================================
echo "── shell config ──"
if ! grep -q "dotfiles managed block" "$DOTFILES/zshrc" 2>/dev/null; then
  cat >> "$DOTFILES/zshrc" <<'EOF'

<
EOF
  echo "✓ $DOTFILES/zshrc 에 셸 설정 추가됨"
else
  echo "✓ 셸 설정 이미 있음 (건너뜀)"
fi

# ============================================================
#  4) symlink
# ============================================================
echo "── symlinks ──"
ln -sfn "$DOTFILES/nvim"          ~/.config/nvim
ln -sfn "$DOTFILES/starship.toml" ~/.config/starship.toml
ln -sfn "$DOTFILES/zshrc"         ~/.zshrc
ln -sfn "$DOTFILES/gitconfig"     ~/.gitconfig
# bash 도 함께 쓰면 주석 해제:
# ln -sfn "$DOTFILES/bashrc"        ~/.bashrc

# git 이 delta 를 diff pager 로 쓰게
if command -v delta &>/dev/null; then
  git config --global core.pager "delta"
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
fi

# ============================================================
#  5) 기본 셸을 zsh 로 변경
# ============================================================
if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
  echo "── 기본 셸을 zsh 로 변경 (비밀번호를 물어볼 수 있어요) ──"
  chsh -s "$(command -v zsh)" || echo "⚠ chsh 실패 → 수동:  chsh -s $(command -v zsh)"
fi

# ============================================================
#  (선택) 데스크탑 GUI 앱 — 환경에 따라 주석 해제
#   * Raycast/Rectangle/AltTab/Maccy 등은 macOS 전용이라 제외
# ============================================================
# sudo snap install --classic code        # VS Code
# sudo snap install ghostty --classic      # 터미널 (배포에 따라 flatpak/소스빌드)
# flatpak install -y flathub com.bitwarden.desktop

echo ""
echo "🎉 Done!  로그아웃 후 다시 로그인하거나, 새 zsh 를 실행하세요:  exec zsh"
echo "    (Nerd Font 는 터미널 설정에서 'JetBrainsMono Nerd Font' 로 지정해야 아이콘이 보입니다)"
