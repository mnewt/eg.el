;;; eg.el --- eg - Useful examples at the command line -*- lexical-binding: t -*-

;; Author: Matthew Newton
;; Maintainer: Matthew Newton
;; Version: 0.2
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/mnewt/eg.el
;; Keywords: cli, reference, tools, docs


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; This is an Emacs wrapper for eg (https://github.com/srsudar/eg). From the
;; main repo:

;; eg provides examples of common uses of command line tools.

;; Man pages are great. How does find work, again? man find will tell you, but
;; you'll have to pore through all the flags and options just to figure out a
;; basic usage. And what about using tar? Even with the man pages tar is
;; famously inscrutable without the googling for examples.

;; No more!

;; eg will give you useful examples right at the command line. Think of it as a
;; companion tool for man.

;; eg comes from exempli gratia, and is pronounced like the letters: "ee gee".

;; There is only one command:

;; M-x eg

;;; Code:

(defcustom eg-command "eg --no-color --pager-cmd cat"
  "The command used to invoke `eg'."
  :group 'eg
  :type 'string)

(defcustom eg-code-block-light-background-color "#BCE"
  "The color used for code blocks when the background is light."
  :group 'eg
  :type 'string)

(defcustom eg-code-block-dark-background-color "#346"
  "The color used for code blocks when the background is dark."
  :group 'eg
  :type 'string)

(defface eg-h1
  '((((class color) (background light))
     (:foreground "#ff8700" :bold t :height 2.0))
    (((class color) (background dark))
     (:foreground "#ffa722" :bold t :height 2.0)))
  "Face for Heading 1."
  :group 'eg)

(defface eg-h2
  '((((class color) (background light))
     (:foreground "#1f5bff" :bold t :height 1.2))
    (((class color) (background dark))
     (:foreground "#6faaff" :bold t :height 1.2)))
  "Face for Heading 2."
  :group 'eg)

(defface eg-h3
  '((((class color) (background light))
     (:foreground "#5a5a5a" :bold t))
    (((class color) (background dark))
     (:foreground "#d7ff87" :bold t)))
  "Face for Heading 3."
  :group 'eg)

(defface eg-code-block
  `((((class color) (background light))
     (:foreground "#555" :background ,eg-code-block-light-background-color))
    (((class color) (background dark))
     (:foreground "#eee" :background ,eg-code-block-dark-background-color)))
  "Face for code block."
  :group 'eg)

(defface eg-inline-code-block
  `((((class color) (background light))
     (:foreground "#555" :background ,eg-code-block-light-background-color))
    (((class color) (background dark))
     (:foreground "#eee" :background ,eg-code-block-dark-background-color)))
  "Face for an inline code block."
  :group 'eg)

(defface eg-button
  '((t (:inherit eg-code-block :underline t)))
  "Face for a command that `eg' knows about."
  :group 'eg)

(defvar eg-current-command nil
  "The command displayed in the current `eg-mode' buffer.")
(make-variable-buffer-local 'eg-current-command)

(defvar eg-commands
  (cl-remove-duplicates
   (let ((l (split-string (shell-command-to-string "eg --list") "\n"))
         (x ""))
     (while (and l (not (string-prefix-p "Programs supported by eg:" x)))
       (setq x (pop l)))
     (mapcar (lambda (x) (replace-regexp-in-string " .*$" "" x)) l))
   :test #'string=)
  "The list of commands in the `eg' database.")

(defvar eg-commands-regexp (format "\\_<%s\\_>" (regexp-opt eg-commands))
  "Regexp to match commands in the `eg' database.")


;;; Commands

;;;###autoload
(defun eg (command)
  "Run `eg' to look up COMMAND and display it beautifully."
  (interactive (list (completing-read
                      "eg: " eg-commands nil t
                      (let ((command (symbol-name (symbol-at-point))))
                        (when (member command eg-commands)
                          command)))))
  (let ((b (get-buffer-create (format "*eg: %s*" command))))
    (pop-to-buffer b)
    (setq-local eg-current-command command)
    (let ((buffer-read-only))
      (erase-buffer)
      (shell-command (format "%s '%s'" eg-command command) b))
    (goto-char (point-min))
    (eg-mode)))

;;;###autoload
(defun eg-at-point (pos)
  "Use `eg' to look up the command at POS."
  (interactive "d")
  (save-excursion
    (goto-char pos)
    (let ((command (symbol-name (symbol-at-point))))
      (if (member command eg-commands)
          (eg command)
        (user-error "Command not found in eg database: %s" command)))))

(defun eg-button-action (button)
  "Look up the command  when its BUTTON is clicked."
  (eg-at-point (button-start button)))


;;; Mode

(define-derived-mode eg-mode help-mode "eg"
  "Lookup commands using `eg'"
  (set (make-local-variable 'buffer-read-only) t)
  (setq revert-buffer-function (lambda (&rest _) (eg eg-current-command)))
  (font-lock-ensure))

;; Make the definition of a "word" more expansive to we don't have false matches
;; when searching for commands.
(modify-syntax-entry ?. "w" eg-mode-syntax-table)
(modify-syntax-entry ?/ "w" eg-mode-syntax-table)
(modify-syntax-entry ?- "w" eg-mode-syntax-table)

(define-button-type 'eg 'action #'eg-button-action 'face 'eg-button)

;; TODO: Figure out why this does not fontify anything and then fix it so it does.
;; (defun eg-sh-region (start end)
;;   "Fontify as `sh-mode' in region START to END."
;;   (let ((inhibit-read-only t)
;;         (inhibit-modification-hooks t))
;;     (org-src-font-lock-fontify-block 'sh start end)
;;     (add-face-text-property start end
;;                             `(:background
;;                               ,(if (eq 'light (frame-parameter nil 'background-mode))
;;                                    eg-code-block-light-background-color
;;                                  eg-code-block-dark-background-color)))))

(defvar eg-font-lock-keywords
  `(("^\\(# \\)\\(.*\\)$" (1 '(face nil invisible t)) (2 'eg-h1))
    ("^\\(## \\)\\(.*\\)$" (1 '(face nil invisible t)) (2 'eg-h2))
    ("^\\(### \\)\\(.*\\)$" (1 '(face nil invisible t)) (2 'eg-h3))
    ("^\\(    \\)\\(.*\\)$" 2 'eg-code-block t)
    ("\\(`\\)\\([^`]+\\)\\(`\\)"
     (1 '(face nil invisible t))
     (2 'eg-inline-code-block t)
     (3 '(face nil invisible t)))
    (,(format "\\_<%s\\_>" (regexp-opt eg-commands)) 0
     (progn (unless (string= (buffer-substring (match-beginning 0) (match-end 0))
                             eg-current-command)
              (make-button (match-beginning 0) (match-end 0) 'type 'eg))
            nil)))
  "Font Lock Keywords for `eg-mode'.")

(font-lock-add-keywords 'eg-mode eg-font-lock-keywords)

(provide 'eg)

;;; eg.el ends here
