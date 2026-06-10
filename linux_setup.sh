#!/bin/bash
set -e

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

# ── gh (GitHub CLI) → 공식 apt 저장소 ──
if ! command -v gh &>/dev/null; then
  echo "→ installing gh ..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y gh
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

# >>> dotfiles managed block >>>   (setup.sh 가 자동 추가 — 직접 수정 가능)
export PATH="$HOME/.local/bin:$PATH"

# 프롬프트 / 디렉터리 점프 / 퍼지 파인더
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
if fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)                                   # fzf 0.48+
else
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh   ] && source /usr/share/doc/fzf/examples/completion.zsh
fi

# 별칭
alias ls="eza --icons"
alias ll="eza -l  --git --icons"
alias la="eza -la --git --icons"
alias tree="eza --tree --icons"
alias lg="lazygit"
alias top="btop"
# 아래는 기존 명령을 덮어쓰니 원하면 주석 해제 (bat/fd 는 위에서 심링크해둠):
# alias cat="bat --paging=never"
# alias grep="rg"
# alias find="fd"

# zsh 플러그인 (syntax-highlighting 은 반드시 맨 마지막에 source)
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] \
  && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] \
  && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# <<< dotfiles managed block <<<
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
