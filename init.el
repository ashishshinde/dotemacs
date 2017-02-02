;-------------------------------------------------------
;;; Package management
(require 'package)
(dolist (source '(("marmalade" . "http://marmalade-repo.org/packages/")
                  ("elpa" . "http://tromey.com/elpa/")
                  ;; TODO: Maybe, use this after emacs24 is released
                  ;; (development versions of packages)
                  ("melpa" . "http://melpa.milkbox.net/packages/")
                  ))
  (add-to-list 'package-archives source t))
(package-initialize)

;;; Required packages
;;; everytime emacs starts, it will automatically check if those packages are
;;; missing, it will install them automatically
(when (not package-archive-contents)
  (package-refresh-contents))
(defvar tmtxt/packages
  '(ecb))
(dolist (p tmtxt/packages)
  (when (not (package-installed-p p))
    (package-install p)))

;; external package
(add-to-list 'load-path "~/.emacs.d/external/")

;;-------------------------------------------------------
;;; General setting
(savehist-mode 1)

(setq column-number-mode t)

(set-default-font "Noto Mono-11")

;; remove trailing whitespace
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; allow using ctrl-z to suspend in multi-term shells.
(defun term-send-ctrl-z ()
  "Allow using ctrl-z to suspend in multi-term shells."
  (interactive)
  (term-send-raw-string ""))

(add-hook 'term-mode-hook
       (lambda ()
          (add-to-list 'term-bind-key-alist '("C-z z" . term-send-ctrl-z))))

;; unicode handling
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
;; backwards compatibility as default-buffer-file-coding-system
;; is deprecated in 23.2.
(if (boundp 'buffer-file-coding-system)
    (setq-default buffer-file-coding-system 'utf-8)
  (setq default-buffer-file-coding-system 'utf-8))

;; Treat clipboard input as UTF-8 string first; compound text next, etc.
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))
(add-hook 'term-exec-hook
          (function
           (lambda ()
             (set-buffer-process-coding-system 'utf-8-unix 'utf-8-unix))))


;;; UNDO - REDO
;; increase the undo limit
(setq undo-limit 10000)

;; theme
(load-theme 'gotham t)

;; dot-mode on
(require 'dot-mode)
(add-hook 'find-file-hooks 'dot-mode-on)
(eval-after-load 'dot-mode
  '(progn
     (define-key dot-mode-map (kbd "C-M-.") nil)))

;; backup versions
(setq make-backup-files t
      vc-make-backup-files t
      version-control t
      kept-new-versions 256
      kept-old-versions 0
      delete-old-versions t
      backup-by-copying t)
(setq backup-dir (concat user-emacs-directory "backup/"))
(if (not (file-exists-p backup-dir))
    (make-directory backup-dir))
(add-to-list 'backup-directory-alist
             `(".*" . ,backup-dir))
(defun force-backup-of-buffer ()
  (setq buffer-backed-up nil))
(add-hook 'before-save-hook 'force-backup-of-buffer)
;; this is what tramp uses
(setq tramp-backup-directory-alist backup-directory-alist)

;; don't show scrollbars
(scroll-bar-mode -1)
(menu-bar-mode -1)
(tool-bar-mode -1)

;; start fullscreen
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
	("6914241d1ce18ca2487d0d5af56b79397e5c39b311495301d2f25aa91dd1497b" "2d7e4feac4eeef3f0610bf6b155f613f372b056a2caae30a361947eab5074716" default)))
 '(ecb-options-version "2.40")
 '(initial-frame-alist (quote ((fullscreen . maximized)))))


;; for some reasin this binding is not working reapply
(global-set-key (kbd "C-M-a") 'beginning-of-defun)

;; search related
(define-key isearch-mode-map (kbd "C-d")
  'xah-search-current-word)
(defun xah-search-current-word ()
  "Call `isearch' on current word or text selection.
“word” here is A to Z, a to z, and hyphen 「-」 and underline 「_」, independent of syntax table.
URL `http://ergoemacs.org/emacs/modernization_isearch.html'
Version 2015-04-09"
  (interactive)
  (let ( ξp1 ξp2 )
    (if (use-region-p)
        (progn
          (setq ξp1 (region-beginning))
          (setq ξp2 (region-end)))
      (save-excursion
        (skip-chars-backward "-_A-Za-z0-9")
        (setq ξp1 (point))
        (right-char)
        (skip-chars-forward "-_A-Za-z0-9")
        (setq ξp2 (point))))
    (setq mark-active nil)
    (when (< ξp1 (point))
      (goto-char ξp1))
    (isearch-mode t)
    (isearch-yank-string (buffer-substring-no-properties ξp1 ξp2))))

;; wrap search around
(defadvice isearch-repeat (after isearch-no-fail activate)
  (unless isearch-success
    (ad-disable-advice 'isearch-repeat 'after 'isearch-no-fail)
    (ad-activate 'isearch-repeat)
    (isearch-repeat (if isearch-forward 'forward))
    (ad-enable-advice 'isearch-repeat 'after 'isearch-no-fail)
    (ad-activate 'isearch-repeat)))

(ad-activate 'isearch-repeat)

;; wrap query replace around
; advise the new version to repeat the search after it
;; finishes at the bottom of the buffer the first time:
(defadvice query-replace-repeat
  (around replace-wrap
          (FROM-STRING TO-STRING &optional DELIMITED START END))
  "Execute a query-replace, wrapping to the top of the buffer
   after you reach the bottom"
  (save-excursion
    (let ((start (point)))
      ad-do-it
      (beginning-of-buffer)
      (ad-set-args 4 (list (point-min) start))
      ad-do-it)))

;; Turn on the advice
(ad-activate 'query-replace-repeat)


;; set up anzu
(anzu-mode +1)
(global-anzu-mode +1)
(global-set-key (kbd "M-%") 'anzu-query-replace)
(global-set-key (kbd "C-M-%") 'anzu-query-replace-regexp)

;; parenthesis matching
(show-paren-mode 1)
(setq show-paren-delay 0)

(defadvice show-paren-function
  (after show-matching-paren-offscreen activate)
  "If the matching paren is offscreen, show the matching line in the
    echo area. Has no effect if the character before point is not of
    the syntax class ')'."
  (interactive)
  (let* ((cb (char-before (point)))
         (matching-text (and cb
                             (char-equal (char-syntax cb) ?\) )
                             (blink-matching-open))))
    (when matching-text (message matching-text))))



(defun move-forward-paren (&optional arg)
 "Move forward parenthesis"
  (interactive "P")
  (if (looking-at ")") (forward-char 1))
  (while (not (looking-at ")")) (forward-char 1))
)

(defun move-backward-paren (&optional arg)
 "Move backward parenthesis"
  (interactive "P")
  (if (looking-at "(") (forward-char -1))
  (while (not (looking-at "(")) (backward-char 1))
)

(defun move-forward-sqrParen (&optional arg)
 "Move forward square brackets"
  (interactive "P")
  (if (looking-at "]") (forward-char 1))
  (while (not (looking-at "]")) (forward-char 1))
)

(defun move-backward-sqrParen (&optional arg)
 "Move backward square brackets"
  (interactive "P")
  (if (looking-at "[[]") (forward-char -1))
  (while (not (looking-at "[[]")) (backward-char 1))
)

(defun move-forward-curlyParen (&optional arg)
 "Move forward curly brackets"
  (interactive "P")
  (if (looking-at "}") (forward-char 1))
  (while (not (looking-at "}")) (forward-char 1))
  )

(defun move-backward-curlyParen (&optional arg)
 "Move backward curly brackets"
  (interactive "P")
  (if (looking-at "{") (forward-char -1))
  (while (not (looking-at "{")) (backward-char 1))
  )

;; rainbow delimiters
(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

(global-set-key (kbd "M-)")           (quote move-forward-paren))
(global-set-key (kbd "M-(")           (quote move-backward-paren))

(global-set-key (kbd "M-]")           (quote move-forward-sqrParen))
(global-set-key (kbd "M-[")           (quote move-backward-sqrParen))

(global-set-key (kbd "M-}")           (quote move-forward-curlyParen))
(global-set-key (kbd "M-{")           (quote move-backward-curlyParen))

(global-set-key (kbd "C-M-/") 'my-expand-file-name-at-point)
(defun my-expand-file-name-at-point ()
  "Use hippie-expand to expand the filename"
  (interactive)
  (let ((hippie-expand-try-functions-list '(try-complete-file-name-partially try-complete-file-name)))
    (call-interactively 'hippie-expand)))

;; switching buffers
(global-set-key (kbd "C-x C-b") 'bs-show)

;; highlight symbol
(require 'highlight-symbol)
(global-set-key [(control f3)] 'highlight-symbol)
(global-set-key [f3] 'highlight-symbol-next)
(global-set-key [(shift f3)] 'highlight-symbol-prev)
(global-set-key [(meta f3)] 'highlight-symbol-query-replace)

(windmove-default-keybindings 'meta)

(global-set-key (kbd "C-c C-<left>")  'windmove-left)
(global-set-key (kbd "C-c C-<right>") 'windmove-right)
(global-set-key (kbd "C-c C-<up>")    'windmove-up)
(global-set-key (kbd "C-c C-<down>")  'windmove-down)

;; jump around
(require 'jumpc)
(jumpc)
(jumpc-bind-vim-key)

;; compilation
(setq compilation-scroll-output 'first-error)

(defun replace-word-at-point (from to)
  "Replace word at point."
  (interactive (let ((from (word-at-point)))
		 (list from (query-replace-read-to from "Replace" nil))))
  (query-replace from to))

(global-set-key (kbd "C-c C-r") 'replace-word-at-point)

(require 'find-file-in-repository)
(require 'ido)
(require 'ido-ubiquitous)
(require 'ido-vertical-mode)
(global-set-key (kbd "C-x f") 'find-file-in-repository)
(ido-ubiquitous-mode 1)
(ido-vertical-mode)
(setq ido-vertical-define-keys 'C-n-C-p-up-down-left-right)


;; multi-term
(defadvice ansi-term (after advise-ansi-term-coding-system)
    (set-buffer-process-coding-system 'utf-8-unix 'utf-8-unix))
(ad-activate 'ansi-term)

(add-hook 'term-exec-hook
          (function
           (lambda ()
             (set-buffer-process-coding-system 'utf-8-unix 'utf-8-unix))))


(when (require 'multi-term nil t)
  (global-set-key (kbd "<f5>") 'multi-term)
  (global-set-key (kbd "<C-next>") 'multi-term-next)
  (global-set-key (kbd "<C-prior>") 'multi-term-prev)
  (setq multi-term-buffer-name "term"
        multi-term-program "/bin/zsh")
  (setq multi-term-scroll-to-bottom-on-output t)
  )

(when (require 'term nil t) ; only if term can be loaded..
  (setq term-bind-key-alist
        (list (cons "C-c C-c" 'term-interrupt-subjob)
              (cons "C-p" 'previous-line)
              (cons "C-n" 'next-line)
              (cons "M-f" 'term-send-forward-word)
              (cons "M-b" 'term-send-backward-word)
              (cons "C-c C-j" 'term-line-mode)
              (cons "C-c C-k" 'term-char-mode)
              (cons "M-DEL" 'term-send-backward-kill-word)
              (cons "M-d" 'term-send-forward-kill-word)
              (cons "<C-left>" 'term-send-backward-word)
              (cons "<C-right>" 'term-send-forward-word)
              (cons "C-r" 'term-send-reverse-search-history)
              (cons "M-p" 'term-send-raw-meta)
              (cons "M-y" 'term-send-raw-meta)
              (cons "C-y" 'term-send-raw))))

(when (require 'term nil t)
  (defun term-handle-ansi-terminal-messages (message)
    (while (string-match "\eAnSiT.+\n" message)
      ;; Extract the command code and the argument.
      (let* ((start (match-beginning 0))
             (command-code (aref message (+ start 6)))
             (argument
              (save-match-data
                (substring message
                           (+ start 8)
                           (string-match "\r?\n" message
                                         (+ start 8))))))
        ;; Delete this command from MESSAGE.
        (setq message (replace-match "" t t message))

        (cond ((= command-code ?c)
               (setq term-ansi-at-dir argument))
              ((= command-code ?h)
               (setq term-ansi-at-host argument))
              ((= command-code ?u)
               (setq term-ansi-at-user argument))
              ((= command-code ?e)
               (save-excursion
                 (find-file-other-window argument)))
              ((= command-code ?x)
               (save-excursion
                 (find-file argument))))))

    (when (and term-ansi-at-host term-ansi-at-dir term-ansi-at-user)
      (setq buffer-file-name
            (format "%s@%s:%s" term-ansi-at-user term-ansi-at-host term-ansi-at-dir))
      (set-buffer-modified-p nil)
        (setq default-directory (if (string= term-ansi-at-host (system-name))
                                    (concatenate 'string term-ansi-at-dir "/")
                                  (format "/%s@%s:%s/" term-ansi-at-user term-ansi-at-host term-ansi-at-dir))))
    message))

(add-hook 'term-mode-hook (lambda()
        (setq yas-dont-activate t)))


;; window layout stacking
(defvar winstack-stack '()
  "A Stack holding window configurations.
Use `winstack-push' and
`winstack-pop' to modify it.")

(defun winstack-push()
  "Push the current window configuration onto `winstack-stack'."
  (interactive)
  (if (and (window-configuration-p (first winstack-stack))
         (compare-window-configurations (first winstack-stack) (current-window-configuration)))
      (message "Current config already pushed")
    (progn (push (current-window-configuration) winstack-stack)
           (message (concat "pushed " (number-to-string
                                       (length (window-list (selected-frame)))) " frame config")))))

(defun winstack-pop()
  "Pop the last window configuration off `winstack-stack' and apply it."
  (interactive)
  (if (first winstack-stack)
      (progn (set-window-configuration (pop winstack-stack))
             (message "popped"))
    (message "End of window stack")))

(global-set-key (kbd "C-c C-u") 'winstack-push)
(global-set-key (kbd "C-c C-o") 'winstack-pop)

;;; be transparent. good advice in general as well
;;(set-frame-parameter (selected-frame) 'alpha '(<active> [<inactive>]))
;; (set-frame-parameter (selected-frame) 'alpha '(95 85))
;; (add-to-list 'default-frame-alist '(alpha 95 85))

(eval-when-compile (require 'cl))
 (defun toggle-transparency ()
   (interactive)
   (if (/=
        (cadr (frame-parameter nil 'alpha))
        100)
       (set-frame-parameter nil 'alpha '(100 100))
     (set-frame-parameter nil 'alpha '(95 85))))
(global-set-key (kbd "C-c t") 'toggle-transparency)


;; revert / reload file without confirmation
(defun revert-buffer-no-confirm ()
  "Revert buffer without confirmation."
  (interactive) (revert-buffer t t))

(global-set-key (kbd "C-M-z") 'revert-buffer-no-confirm)


;-------------------------------------------------------
;;; C/C++ related
(require 'cc-mode)

(add-hook 'c-mode-common-hook '(lambda () (c-set-style "bsd")))


;;; srspeedbar related
(require 'sr-speedbar)
(global-set-key (kbd "s-b") 'sr-speedbar-toggle)

;;; activate ecb
(require 'ecb)
;;(require 'ecb-autoloads)
(setq ecb-layout-name "as-methods-only")
(setq ecb-compile-window-height 12)

;;; activate and deactivate ecb
(global-set-key (kbd "C-x C-;") 'ecb-activate)
(global-set-key (kbd "C-x C-'") 'ecb-deactivate)
;;; show/hide ecb window
(global-set-key (kbd "C-;") 'ecb-show-ecb-windows)
(global-set-key (kbd "C-'") 'ecb-hide-ecb-windows)
;;; quick navigation between ecb windows
(global-set-key (kbd "C-)") 'ecb-goto-window-edit1)
(global-set-key (kbd "C-!") 'ecb-goto-window-directories)
(global-set-key (kbd "C-@") 'ecb-goto-window-sources)
(global-set-key (kbd "C-#") 'ecb-goto-window-methods)
(global-set-key (kbd "C-$") 'ecb-goto-window-compilation)


;;; replacement for built-in ecb-deactive, ecb-hide-ecb-windows and
;;; ecb-show-ecb-windows functions
;;; since they hide/deactive ecb but not restore the old windows for me
(defun tmtxt/ecb-deactivate ()
  "deactive ecb and then split emacs into 2 windows that contain 2 most recent buffers"
  (interactive)
  (ecb-deactivate)
  (split-window-right)
  (switch-to-next-buffer)
  (other-window 1))
(defun tmtxt/ecb-hide-ecb-windows ()
  "hide ecb and then split emacs into 2 windows that contain 2 most recent buffers"
  (interactive)
  (ecb-hide-ecb-windows)
  (split-window-right)
  (switch-to-next-buffer)
  (other-window 1))
(defun tmtxt/ecb-show-ecb-windows ()
  "show ecb windows and then delete all other windows except the current one"
  (interactive)
  (ecb-show-ecb-windows)
  (delete-other-windows))

(global-set-key (kbd "C-x C-'") 'tmtxt/ecb-deactivate)
(global-set-key (kbd "C-;") 'tmtxt/ecb-show-ecb-windows)
(global-set-key (kbd "C-'") 'tmtxt/ecb-hide-ecb-windows)

(setq-default c-basic-offset 4 c-default-style "linux")
(setq-default tab-width 4 indent-tabs-mode t)
(define-key c-mode-base-map (kbd "RET") 'newline-and-indent)

(global-set-key (kbd "C-M-/") 'my-expand-file-name-at-point)
(defun my-expand-file-name-at-point ()
  "Use hippie-expand to expand the filename"
  (interactive)
  (let ((hippie-expand-try-functions-list '(try-complete-file-name-partially try-complete-file-name)))
    (call-interactively 'hippie-expand)))

(require 'autopair)
(autopair-global-mode 1)
(setq autopair-autowrap t)

(require 'auto-complete-clang)
(define-key c++-mode-map (kbd "C-`") 'ac-complete-clang)
(define-key c-mode-base-map (kbd "C-`") 'ac-complete-clang)
;; replace C-S-<return> with a key binding that you want

;; complete headers
(defun my:ac-c-header-init ()
  (require 'auto-complete-c-headers)
  (add-to-list 'ac-sources 'ac-source-c-headers)
)
; now let's call this function from c/c++ hooks
(add-hook 'c++-mode-hook 'my:ac-c-header-init)
(add-hook 'c-mode-hook 'my:ac-c-header-init)

;; flymake
(require 'flymake)
(add-hook 'find-file-hook 'flymake-find-file-hook)

;;; yasnippet
;;; should be loaded before auto complete so that they can work together
(require 'yasnippet)
(yas-global-mode 1)

;;; auto complete mod
;;; should be loaded after yasnippet so that they can work together
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
(ac-config-default)
;;; set the trigger key so that it can work together with yasnippet on tab key,
;;; if the word exists in yasnippet, pressing tab will cause yasnippet to
;;; activate, otherwise, auto-complete will
(ac-set-trigger-key "TAB")
(ac-set-trigger-key "<tab>")

; Fix iedit bug in Mac
(define-key global-map (kbd "C-c ;") 'iedit-mode)

; turn on Semantic
(semantic-mode 1)
; let's define a function which adds semantic as a suggestion backend to auto complete
; and hook this function to c-mode-common-hook
(defun my:add-semantic-to-autocomplete()
  (add-to-list 'ac-sources 'ac-source-semantic)
)
(add-hook 'c-mode-common-hook 'my:add-semantic-to-autocomplete)
; turn on ede mode
(global-ede-mode 1)
; create a project for our program.
;(ede-cpp-root-project "my project" :file "~/demos/my_program/src/main.cpp"
;		      :include-path '("/../my_inc"))
; you can use system-include-path for setting up the system header file locations.
										; turn on automatic reparsing of open buffers in semantic
(global-semanticdb-minor-mode 1)
(global-semantic-idle-scheduler-mode 1)

(require 'riti)
(setq-default riti-on-save nil)
(setq-default riti-cfg-file "/home/ashish/.riti.xml")
(global-set-key [C-M-tab] 'riti)
(require 'clang-format)


;; gtags related
(require 'gtags)

(defun gtags-update-single(filename)
  "Update Gtags database for changes in a single file"
  (interactive)
  (start-process "update-gtags" "update-gtags" "bash" "-c" (concat "cd " (gtags-root-dir) " ; gtags --single-update " filename )))

(defun gtags-update-current-file()
  (interactive)
  (defvar filename)
  (setq filename (replace-regexp-in-string (gtags-root-dir) "." (buffer-file-name (current-buffer))))
  (gtags-update-single filename)
  (message "Gtags updated for %s" filename))

(defun gtags-update-hook()
  "Update GTAGS file incrementally upon saving a file"
  (when gtags-mode
    (when (gtags-root-dir)
      (gtags-update-current-file))))

(add-hook 'after-save-hook 'gtags-update-hook)

(defun ww-next-gtag ()
  "Find next matching tag, for GTAGS."
  (interactive)
  (let ((latest-gtags-buffer
         (car (delq nil  (mapcar (lambda (x) (and (string-match "GTAGS SELECT" (buffer-name x)) (buffer-name x)) )
                                 (buffer-list)) ))))
    (cond (latest-gtags-buffer
           (switch-to-buffer latest-gtags-buffer)
           (forward-line)
           (gtags-select-it nil))
          ) ))


(global-set-key "\M-;" 'ww-next-gtag)   ;; M-; cycles to next result, after doing M-. C-M-. or C-M-,
(global-set-key "\M-." 'gtags-find-tag) ;; M-. finds tag
(global-set-key [(control meta .)] 'gtags-find-rtag)   ;; C-M-. find all references of tag
(global-set-key [(control meta \,)] 'gtags-find-symbol) ;; C-M-, find all usages of symbol.

;; gdb related
(eval-after-load "gud"
  '(progn
     (define-key gud-mode-map (kbd "<up>") 'comint-previous-input)
     (define-key gud-mode-map (kbd "<down>") 'comint-next-input)))

;; function args
(require 'function-args)
(fa-config-default)

(eval-after-load "function-args"
  '(let ((map function-args-mode-map))

	(define-key map (kbd "C-M-j") 'moo-jump-local)
(define-key map  [(control tab)] 'moo-complete)
(define-key map  [(control tab)] 'moo-complete)
(define-key map (kbd "M-o")  'fa-show)
(define-key map (kbd "M-o")  'fa-show)

  ))


;; function name in header
(which-function-mode 1)

;;-------------------------------------------------------------
;; git related
(require 'git)
(require 'git-blame)
(setq vc-follow-symlinks nil)


;;-------------------------------------------------------------
;; aerospike specific
(setq inhibit-splash-screen t)
(setq default-directory "/home/ashish/workspace/" )

;; file search
(global-set-key [C-M-F] 'find-grep)
(setq grep-find-command
      "grep -rnHI --exclude=\\*.{hg,log,o,a} --exclude=\\..\\* --exclude=\\#.\\* --include=\\*.{c,cpp,h} --include=-e 'pattern' /home/ashish/workspace/*")

(setenv "CLIENTREPO" "/home/ashish/workspace/aerospike-client-c/")
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;;--------------------------------------------------------------------
;; Javascript related
(add-hook 'js-mode-hook 'js2-minor-mode)
(add-hook 'js2-mode-hook 'ac-js2-mode)

(setq js2-highlight-level 3)

(eval-after-load "js2-mode"
  '(progn
     (setq js2-missing-semi-one-line-override t)
     (setq-default js2-basic-offset 2)))

;; tern
(autoload 'tern-mode "tern.el" nil t)
(add-hook 'js-mode-hook (lambda () (tern-mode t)))


;;--------------------------------------------------------------------
;; Guess style

(autoload 'guess-style-set-variable "guess-style" nil t)
(autoload 'guess-style-guess-variable "guess-style")
(autoload 'guess-style-guess-all "guess-style" nil t)


;;--------------------------------------------------------------------
;; Json mode
(setq auto-mode-alist (cons '("\\.json\\'" . json-mode) auto-mode-alist))

;;--------------------------------------------------------------------
;; Gradle mode
(require 'gradle-mode)
(gradle-mode 1)


;;--------------------------------------------------------------------
;; Crontab
(require 'with-editor)

(defun crontab-e ()
    (interactive)
    (with-editor-async-shell-command "crontab -e"))

;;--------------------------------------------------------------------
;; deal with large files
(defun my-find-file-check-make-large-file-read-only-hook ()
  "If a file is over a given size, make the buffer read only."
  (when (> (buffer-size) (* 1024 1024))
    (setq buffer-read-only t)
    (buffer-disable-undo)
    (fundamental-mode)))

(add-hook 'find-file-hook 'my-find-file-check-make-large-file-read-only-hook)

;;--------------------------------------------------------------------
;; clojure related
(add-hook 'clojure-mode-hook 'turn-on-eldoc-mode)
(setq nrepl-popup-stacktraces nil)
(add-to-list 'same-window-buffer-names "<em>nrepl</em>")

;; ac-nrepl (Auto-complete for the nREPL)
(require 'ac-nrepl)
(add-hook 'cider-mode-hook 'ac-nrepl-setup)
(add-hook 'cider-repl-mode-hook 'ac-nrepl-setup)
(add-to-list 'ac-modes 'cider-mode)
(add-to-list 'ac-modes 'cider-repl-mode)

;; Poping-up contextual documentation
(eval-after-load "cider"
  '(define-key cider-mode-map (kbd "C-c C-d") 'ac-nrepl-popup-doc))

(add-hook 'clojure-mode-hook 'paredit-mode)

;; Show parenthesis mode
(show-paren-mode 1)

(global-set-key [f8] 'other-frame)
(global-set-key [f7] 'paredit-mode)
(global-set-key [f9] 'cider-jack-in)
(global-set-key [f11] 'speedbar)
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
