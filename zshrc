
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
