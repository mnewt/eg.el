;;; eg.el --- eg - Useful examples at the command line -*- lexical-binding: t -*-

;; Author: Matthew Newton
;; Maintainer: Matthew Newton
;; Version: 0.1
;; Package-Requires: ((emacs "24.3"))
;; Homepage: https://github.com/mnewt/eg
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

(define-derived-mode eg-mode help-mode "eg"
  "Lookup commands using `eg'"
  (set (make-local-variable 'buffer-read-only) t))

(defface eg-h1
  '((((class color) (background light))
     (:foreground "#ff8700" :bold t :height 2.0))
    (((class color) (background dark))
     (:foreground "#ffa722" :bold t :height 2.0)))
  "Title"
  :group 'eg)

(defface eg-h2
  '((((class color) (background light))
     (:foreground "#1f5bff" :bold t :height 1.2))
    (((class color) (background dark))
     (:foreground "#6faaff" :bold t :height 1.2)))
  "Subtitle"
  :group 'eg)

(defface eg-h3
  '((((class color) (background light))
     (:foreground "#5a5a5a" :bold t))
    (((class color) (background dark))
     (:foreground "#d7ff87" :bold t)))
  "Section Title"
  :group 'eg)

(defface eg-code-block
  '((((class color) (background light))
     (:foreground "#555" :background "#d7ff87"))
    (((class color) (background dark))
     (:foreground "#eee" :background "#5a5a5a")))
  "Code block"
  :group 'eg)

;;; Autoloads

;;;###autoload
(defun eg (command)
  "Run `eg' to look up COMMAND and display it in a fancy way.

Requires eg to be installed, e.g. by:

    pip install eg

https://github.com/srsudar/eg"
  (interactive
   (list (completing-read
          "eg: "
          (let ((l (split-string (shell-command-to-string "eg --list"))))
            (nthcdr (1+ (position "eg:" l :test #'string=)) l)))))
  (pop-to-buffer (get-buffer-create (concat "*eg: " command "*")))
  (eg-mode)
  (let ((buffer-read-only))
    (insert
     (mapconcat (lambda (line)
                  (cond
                   ((equal "" line)
                    "")
                   ((string-prefix-p "# " line)
                    (propertize (substring line 2) 'face 'eg-h1))
                   ((string-prefix-p "## " line)
                    (propertize (substring line 3) 'face 'eg-h2))
                   ((string-prefix-p "### " line)
                    (propertize (substring line 4) 'face 'eg-h3))
                   ((string-prefix-p "    " line)
                    (concat "    " (propertize (substring line 4) 'face 'eg-code-block)))
                   (t line)))
                (split-string
                 (shell-command-to-string
                  (format "eg --no-color --pager-cmd cat '%s'" command))
                 "\n")
                "\n")))
  (goto-char (point-min)))

(provide 'eg)

;;; eg.el ends here
