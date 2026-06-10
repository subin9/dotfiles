#!/bin/bash
set -e

# ============================================================
#  macOS dotfiles setup
#  - 이미 설치된 건 건너뜀 / 재실행해도 안전 (idempotent)
# ============================================================

# 이 스크립트가 들어있는 폴더 = dotfiles 폴더로 자동 인식 (repo 이름 무관)
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.config

# ── helpers ─────────────────────────────────────────────────
brew_install() {            # formula(CLI)
  if brew list --formula "$1" &>/dev/null; then
    echo "✓ $1 already installed"
  else
    echo "→ installing $1 ..."
    brew install "$1"
  fi
}
cask_install() {            # cask(GUI 앱 / 폰트)
  if brew list --cask "$1" &>/dev/null; then
    echo "✓ $1 already installed"
  else
    echo "→ installing $1 ..."
    brew install --cask "$1"
  fi
}

# ── Homebrew ────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if   [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew   ]]; then eval "$(/usr/local/bin/brew shellenv)"
fi

# ── Xcode Command Line Tools (build-essential 대체) ─────────
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install || true
  echo "설치 창이 뜨면 완료한 뒤 스크립트를 다시 실행하세요."
  exit 0
fi

# ============================================================
#  1) CLI 도구 (formula)
# ============================================================
echo "── CLI tools ──"
CLI_TOOLS=(
  git wget ripgrep fd neovim          # 기본
  starship zoxide fzf                 # 프롬프트 / 디렉터리 점프 / 퍼지 파인더
  eza bat                             # ls / cat 대체
  git-delta lazygit gh jq httpie      # git diff / git TUI / GitHub CLI / JSON / HTTP
  btop tmux tldr                      # 모니터 / 멀티플렉서 / 간단 man
  mas                                 # Mac App Store 를 CLI 로 설치
  zsh-autosuggestions zsh-syntax-highlighting  # zsh 쓸 때 플러그인
)
for pkg in "${CLI_TOOLS[@]}"; do brew_install "$pkg"; done

# Docker 를 가볍게 (Docker Desktop 대체). 필요하면 주석 해제:
# brew_install colima
# brew_install docker
# brew_install docker-compose

# ============================================================
#  2) GUI 앱 (cask)  ── 취향껏 추가/삭제
# ============================================================
echo "── GUI apps ──"
CASKS=(
  ghostty                 # 모던 터미널 (대안: iterm2)
  visual-studio-code      # 에디터
  raycast                 # Spotlight 대체 런처
  rectangle               # 창 스냅(분할)
  alt-tab                 # 윈도우식 alt-tab 창 전환
  tableplus               # DB GUI
  bitwarden               # 비밀번호 관리 (대안: 1password)
  maccy                   # 클립보드 히스토리
  stats                   # 메뉴바 시스템 모니터
  appcleaner              # 앱 깔끔 삭제
  the-unarchiver          # 압축 해제
)
for app in "${CASKS[@]}"; do cask_install "$app"; done

# 개인 취향 — 필요하면 주석 해제:
# cask_install iterm2
# cask_install google-chrome
# cask_install firefox
# cask_install slack
# cask_install discord
# cask_install obsidian
# cask_install docker            # Docker Desktop
# cask_install 1password

# ============================================================
#  3) Nerd 폰트 (starship / eza 아이콘 깨짐 방지)
# ============================================================
echo "── Nerd fonts ──"
cask_install font-jetbrains-mono-nerd-font
# cask_install font-hack-nerd-font
# cask_install font-fira-code-nerd-font
echo "  ↳ 터미널·VS Code 폰트를 'JetBrainsMono Nerd Font' 로 바꿔주세요."

# ============================================================
#  4) 셸 설정 (init + alias) → $DOTFILES/bashrc 에 1회만 추가
# ============================================================
echo "── shell config ──"
if ! grep -q "dotfiles managed block" "$DOTFILES/zshrc" 2>/dev/null; then
  cat >> "$DOTFILES/zshrc" <<'EOF'

# >>> dotfiles managed block >>>   (setup.sh 가 자동 추가 — 직접 수정 가능)
if   [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew   ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi

# 프롬프트 / 디렉터리 점프 / 퍼지 파인더
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh) 2>/dev/null

# 별칭
alias ls="eza --icons"
alias ll="eza -l  --git --icons"
alias la="eza -la --git --icons"
alias tree="eza --tree --icons"
alias lg="lazygit"
alias top="btop"
# 아래는 기존 명령을 덮어쓰니 원하면 주석 해제:
# alias cat="bat --paging=never"
# alias grep="rg"
# alias find="fd"

# zsh 플러그인 (syntax-highlighting 은 반드시 맨 마지막에 source)
BREW_PREFIX="$(brew --prefix)"
[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] \
  && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] \
  && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
# <<< dotfiles managed block <<<
EOF
  echo "✓ $DOTFILES/zshrc 에 셸 설정 추가됨"
else
  echo "✓ 셸 설정 이미 있음 (건너뜀)"
fi

# ============================================================
#  5) symlink
# ============================================================
echo "── symlinks ──"
ln -sfn "$DOTFILES/nvim"          ~/.config/nvim
ln -sfn "$DOTFILES/starship.toml" ~/.config/starship.toml
ln -sfn "$DOTFILES/zshrc"         ~/.zshrc
ln -sfn "$DOTFILES/gitconfig"     ~/.gitconfig
# bash 도 함께 쓰면 주석 해제:
# ln -sfn "$DOTFILES/bashrc"        ~/.bashrc

# git 이 delta 를 diff pager 로 쓰게 (심링크된 gitconfig 에 기록)
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true

# ============================================================
#  6) macOS 시스템 설정 (defaults)
# ============================================================
echo "── macOS defaults ──"
# 키 반복 빠르게 + 길게 눌러도 반복 (vim 쓸 때 필수)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# 파일 확장자 항상 표시
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllExtensions -bool true
# Finder: 경로 바 / 상태 바
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# Dock: 자동 숨김 + 아이콘 크기
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 48
# 네트워크/USB 에 .DS_Store 안 만들기
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
killall Dock Finder SystemUIServer 2>/dev/null || true
echo "  ↳ 일부 설정은 재로그인 후 적용됩니다."

echo ""
echo "🎉 Done!  새 터미널을 열거나  source ~/.zshrc  하세요."
