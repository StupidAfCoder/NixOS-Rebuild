;;; init.el -*- lexical-binding: t; -*-
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
       (dired +dirvish)
       electric
       undo
       vc
       
       :checkers
       syntax
       (spell +flyspell)
       
       :tools
       (eval +overlay)
       (lookup +docmets)
       (lsp +eglot)
       (debugger +lsp)
       magit
       tree-sitter
       
       :term
       vterm
       
       :lang
       (go +tree-sitter)
       (cc +tree-sitter)
       (nix +tree-sitter)
       (sh +tree-sitter)
       markdown
       yaml
       (json +tree-sitter)
       
       :config
       (default +bindings +smartparens))
