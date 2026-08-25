(doom! :input

       :completion
       (vertico +icons)
       (corfu +icons)

       :ui
       doom
       doom-dashboard
       modeline
       ophints
       (popup +defaults)
       vc-gutter
       vi-tilde-fringe
       workspaces
       treemacs

       :editor
       (evil +everywhere +easymotion)
       file-templates
       fold
       (format +onsave)
       multiple-cursors
       snippets

       :emacs
       dired
       electric
       undo
       vc

       :checkers
       syntax
       (spell +flyspell)

       :tools
       (eval +overlay)
       (lookup +docsets)
       (lsp +eglot)
       magit
       tree-sitter

       :lang
       (go +lsp +tree-sitter)
       (cc +lsp +tree-sitter)
       (sh +tree-sitter)
       markdown
       yaml
       (json +tree-sitter)

       :config
       (default +bindings +smartparens))