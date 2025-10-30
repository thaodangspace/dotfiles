;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:

;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; Fonts: Use IBM Plex Mono for all faces
(setq doom-font (font-spec :family "IBM Plex Mono" :size 16 :weight 'regular))
(setq doom-variable-pitch-font (font-spec :family "IBM Plex Mono" :size 16))
(setq doom-big-font (font-spec :family "IBM Plex Mono" :size 20))
(setq doom-symbol-font (font-spec :family "IBM Plex Mono"))
(setq doom-serif-font (font-spec :family "IBM Plex Mono"))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'catppuccin)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Browser configuration
;; Set EWW as the default browser for URLs opened from Emacs
(setq browse-url-browser-function 'eww-browse-url)

;; Custom keybindings
(map! :leader

     :desc "Find files" "e" #'find-file
      :desc "Open URL in EWW" "w" #'eww
      :desc "Open URL in external browser" "W" #'browse-url)

;; Emacs server for local and remote (SSH) workflows
;; - Give each host a unique server name so its socket can be forwarded over SSH
;; - Start the server automatically if it's not already running
(require 'server)
;; Use a predictable socket directory per-user for easier SSH forwarding
(defvar my/server-socket-dir
  (expand-file-name (format "/tmp/emacs-%s" (user-uid)))
  "Directory where the Emacs server socket will be created.")
(setq server-socket-dir my/server-socket-dir)
(setq server-name (format "server-%s" (system-name)))
(unless (server-running-p)
  (server-start))

;; TRAMP/SSH tuning for large remote codebases
(with-eval-after-load 'tramp
  (setq tramp-default-method "ssh"
        tramp-verbose 1
        tramp-connection-timeout 10
        ;; Disable SSH ControlMaster in TRAMP to avoid format character issues
        tramp-use-ssh-controlmaster-options nil
        tramp-completion-reread-directory-timeout 300
        tramp-persistency-file-name (expand-file-name "tramp.eld" user-emacs-directory))
  ;; Ensure remote PATH includes common locations without relying on special symbols
  (dolist (dir '("~/.local/bin" "/usr/local/sbin" "/usr/local/bin" "/opt/homebrew/bin"))
    (add-to-list 'tramp-remote-path dir t))
  ;; Avoid expensive VC checks on remote files
  (setq vc-ignore-dir-regexp
        (format "%s\\|%s" vc-ignore-dir-regexp tramp-file-name-regexp))
  ;; Keep backups and autosaves locally for remote files
  (setq tramp-auto-save-directory (expand-file-name "tramp-autosaves/" user-emacs-directory))
  (ignore-errors (make-directory tramp-auto-save-directory t))
  (let ((tramp-backups (expand-file-name "tramp-backups/" user-emacs-directory)))
    (ignore-errors (make-directory tramp-backups t))
    (add-to-list 'backup-directory-alist (cons tramp-file-name-regexp tramp-backups)))
  (let ((tramp-autosaves (expand-file-name "tramp-autosaves/" user-emacs-directory)))
    (add-to-list 'auto-save-file-name-transforms (list tramp-file-name-regexp tramp-autosaves t))))

;; Ensure JSX/TSX files use the proper major modes
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . js-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . typescript-mode))

;; Enable tree-sitter for JavaScript/TypeScript files when available
(after! js-mode
  (when (and (fboundp 'treesit-available-p)
             (treesit-available-p))
    (add-to-list 'major-mode-remap-alist '(js-mode . js-ts-mode))
    (add-to-list 'major-mode-remap-alist '(javascript-mode . js-ts-mode))))

(after! typescript-mode
  (when (and (fboundp 'treesit-available-p)
             (treesit-available-p))
    (add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode))))

;; Ensure syntax highlighting works for remote files
(add-hook 'find-file-hook
  (lambda ()
    (when (file-remote-p default-directory)
      ;; Force font-lock refresh for remote files
      (font-lock-ensure))))
