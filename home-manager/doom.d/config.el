;;; config.el --- Personal Doom config -*- lexical-binding: t; -*-

(setq doom-font (font-spec :family "Pixel Operator Mono" :size 16))
(add-to-list 'custom-theme-load-path (expand-file-name "~/.config/emacs/themes/"))

;; UI & Visuals
(setq display-line-numbers-type 'relative
      doom-themes-padded-modeline t)
(spacious-padding-mode 1)

;; Terminal clipboard integration
(add-hook 'tty-setup-hook #'global-clipetty-mode)

;; Treemacs
(after! treemacs
  (doom-themes-treemacs-config)
  (treemacs-follow-mode +1)
  (treemacs-git-mode 'simple))

;; Formatter (Apheleia)
(after! apheleia
  (setf (alist-get 'nix-mode apheleia-mode-alist) 'nixfmt))

;;; --- NATIVE THEME HOT-RELOADING ---
(require 'filenotify)

(defun +evil-cursors-sync-with-theme-h ()
  "Sync cursor colors safely by querying the active GUI frame."
  (cl-flet ((safe-color (face fallback)
              (let* ((frame (selected-frame))
                     (c (face-attribute face :foreground frame t)))
                (if (or (null c) (eq c 'unspecified) (string= c "")) fallback c))))
    (setq evil-normal-state-cursor  (list 'box    (safe-color 'success "#a6e3a1"))
          evil-insert-state-cursor  (list 'bar    (safe-color 'error   "#f38ba8"))
          evil-visual-state-cursor  (list 'hollow (safe-color 'warning "#f9e2af"))
          evil-replace-state-cursor (list 'hbar   (safe-color 'error   "#f38ba8")))
    (evil-refresh-cursor)))

(defun +wallust-reload-theme-quietly ()
  "Safely reload the wallust theme by destroying Emacs's internal cache first."
  (let ((theme-file (expand-file-name "~/.config/emacs/themes/doom-wallust-theme.el")))
    (when (file-readable-p theme-file)
      (let ((inhibit-message t))
        ;; 1. DESTROY THE CACHE
        (put 'doom-wallust 'theme-settings nil)
        (put 'doom-wallust 'theme-feature nil)
        
        ;; 2. Unload the current state
        (disable-theme 'doom-wallust)
        
        ;; 3. Load the file fresh
        (load-file theme-file)
        (load-theme 'doom-wallust t)
        
        ;; 4. Force cursor updates on all active frames
        (mapc (lambda (f) 
                (with-selected-frame f 
                  (+evil-cursors-sync-with-theme-h)
                  (redisplay t))) 
              (frame-list))))))

;; Variable to store our debounce timer
(defvar +wallust-reload-timer nil)

(defun +wallust-file-watch-callback (event)
  "Callback for filenotify. Natively debounces the reload."
  (when (timerp +wallust-reload-timer)
    (cancel-timer +wallust-reload-timer))
  (setq +wallust-reload-timer
        (run-with-timer 0.5 nil #'+wallust-reload-theme-quietly)))

;; Hook it all up
(let ((theme-file (expand-file-name "~/.config/emacs/themes/doom-wallust-theme.el")))
  (when (file-exists-p theme-file)
    ;; Tell Emacs to natively watch the file for changes
    (file-notify-add-watch theme-file '(change) #'+wallust-file-watch-callback)))

;; Initial load
(setq doom-theme 'doom-wallust)

;;; --- LSP (EGLOT) OPTIMIZATIONS ---
(after! eglot
  (setq eglot-events-buffer-size 0      
        eglot-sync-connect nil          
        eglot-autoshutdown t))          

(add-hook 'go-mode-local-vars-hook
          (lambda ()
            (add-hook 'before-save-hook #'eglot-code-action-organize-imports nil t)))
;; Maximize GC threshold and chunk size for LSP performance
(setq gc-cons-threshold (* 100 1024 1024)
      read-process-max (* 3 1024 1024))
(after! envrc (envrc-global-mode))
;;; config.el ends here
