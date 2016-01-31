;;; peep-dired-extension.el --- exteinsions for peep-dired.el -*- lexical-binding: t; -*-

;; Copyright (C) 2016  ril

;; Author: ril
;; Created: 2016-01-30 17:19:00
;; Last Modified: 2016-01-31 13:15:17
;; Version: 0.1
;; Keywords: extensions
;; URL: https://github.com/fenril058/peep-dired-extension

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Small extensions for peep-dired.el <https://github.com/asok/peep-dired>
;; This file make it possible to
;; 1. bowse html
;; 2. open associate application
;; 3. use xdoc2txt which depends on `xdoc2txt.el'

;;; Code:

(require 'dired)
(require 'peep-dired)
(require 'xdoc2txt)

(define-key peep-dired-mode-map (kbd "j") 'peep-dired-toggle-browse-altenative)

(defun peep-dired-open-assosiciate-apl ()
  "open file with associated aplicateion"
  (let ((fname (dired-get-filename)))
    (cond ((eq system-type 'windows-nt)
           (w32-shell-execute "open" fname))
          ((executable-find "open")
           (shell-command "open" fname))
          (t
           (message "open command not exists")
           ))))

;;; html-browser
(defcustom peep-dired-html-extensions
  '("html" "htm" "xml")
  "extensions that"
  :group 'peep-dired
  :type 'list)

(defun peep-dired-browse-html ()
  "open file with `browse-url-browser-function'"
  (interactive)
  (let ((tem (dired-get-filename t t)))
    (save-selected-window
     (select-window (get-buffer-window tem))
     (browse-url-of-file (expand-file-name tem)))))

;;;###autoload
(defun peep-dired-toggle-browse-altenative ()
  (interactive)
  (let ((file-extension (file-name-extension
                         (dired-file-name-at-point))))
    (cond ((member file-extension peep-dired-html-extensions)
           (peep-dired-browse-html))
          (t
           (peep-dired-open-assosiciate-apl))
          )))

;;; xdoc2txt
(defvar peep-direde-use-xdoc2txt xdoc2txt-binary-use-xdoc2txt
  "If non-nil use xdoc2txt."
  )

(defvar peep-dired-xdoc2txt-buffers nil)

(defun peep-dired-browse-xdoc2txt (file)
  "open file with xdoc2txt"
  (interactive)
  (let ((dummy-buff-name
         (concat "xdoc2txt:" (file-name-nondirectory file)))
        (dummy-buff))
    (when (get-buffer dummy-buff-name)
      (kill-buffer dummy-buff-name))
    (setq dummy-buff (get-buffer-create dummy-buff-name))
    (with-current-buffer (current-buffer)
      (set-buffer dummy-buff)
      (xdoc2txt-make-format file)
      ;; (setq buffer-read-only t)
      )
    (add-to-list 'peep-dired-xdoc2txt-buffers
                 (window-buffer (display-buffer dummy-buff t))
                 )))

(defun peep-dired-display-file-other-window-advice ()
  (let ((entry-name (dired-file-name-at-point)))
    (unless (member (file-name-extension entry-name)
                    peep-dired-ignored-extensions)
      (if (and peep-direde-use-xdoc2txt
               (member (file-name-extension entry-name)
                       xdoc2txt-extensions))
          (peep-dired-browse-xdoc2txt entry-name)
        (add-to-list 'peep-dired-peeped-buffers
                     (window-buffer
                      (display-buffer
                       (if (file-directory-p entry-name)
                           (peep-dired-dir-buffer entry-name)
                         (or
                          (find-buffer-visiting entry-name)
                          (find-file-noselect entry-name)))
                       t))))
      ))
  'override)

(advice-add 'peep-dired-display-file-other-window
            :override 'peep-dired-display-file-other-window-advice)

(defun peep-dired-xdoc2txt-buffers-cleanup ()
  (interactive)
  (when peep-dired-cleanup-on-disable
    (mapc 'kill-buffer peep-dired-xdoc2txt-buffers))
  (setq peep-dired-xdoc2txt-buffers ())
  'after)

(advice-add 'peep-dired-disable
            :after 'peep-dired-xdoc2txt-buffers-cleanup)

(provide 'peep-dired-extension)
;;; peep-dired-extension.el ends here
