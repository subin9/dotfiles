# zshrc — cross-platform (macOS / Linux)
# >>> dotfiles managed block >>>
export PATH="$HOME/.local/bin:$PATH"

# Homebrew (macOS / Linuxbrew) — 있을 때만
if   [ -x /opt/homebrew/bin/brew ];              then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ];                 then eval "$(/usr/local/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# 프롬프트 / 디렉터리 점프 / 퍼지 파인더 — 각각 설치돼 있을 때만
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
if command -v fzf >/dev/null; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh; do
      [ -f "$f" ] && source "$f" && break
    done
  fi
fi

# 별칭 — 도구가 있을 때만
if command -v eza >/dev/null; then
  alias ls="eza --icons"
  alias ll="eza -l  --git --icons"
  alias la="eza -la --git --icons"
  alias tree="eza --tree --icons"
fi
command -v lazygit >/dev/null && alias lg="lazygit"
command -v btop    >/dev/null && alias top="btop"

# zsh 플러그인 (brew → /usr/share 순으로 탐색, syntax-highlighting 은 맨 마지막)
for d in "${HOMEBREW_PREFIX:-/usr}/share" /usr/share /home/linuxbrew/.linuxbrew/share; do
  [ -f "$d/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$d/zsh-autosuggestions/zsh-autosuggestions.zsh" && break
done
for d in "${HOMEBREW_PREFIX:-/usr}/share" /usr/share /home/linuxbrew/.linuxbrew/share; do
  [ -f "$d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" && break
done
# <<< dotfiles managed block <<<
