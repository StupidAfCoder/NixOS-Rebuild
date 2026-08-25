(setq doom-font (font-spec :family "JetBrains Mono" :size 14)
      doom-theme 'doom-one)

(after! go-mode
  (setq lsp-go-analyses '((shadow . t) (unusedparams . t))))

(add-hook 'tty-setup-hook #'global-clipetty-mode)
(add-to-list 'custom-theme-load-path (expand-file-name "~/.config/emacs/themes/"))
(setq doom-theme 'doom-wallust)   ; was 'wallust