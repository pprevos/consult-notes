;; -*- lexical-binding: t -*-
(require 'consult)    ;; core dependency
(require 'marginalia) ;; for faces
(require 'embark)     ;; for actions
(require 'affe)       ;; for search

(defvar consult-notes-category 'consult-note
  "Category symbol for the notes in this package.")

(defvar consult-notes-history nil
  "History variable for consult-notes.")

(defvar consult-notes-sources-data
  '(("Zettel"        ?z "~/Dropbox/Work/projects/notebook/content-org/")
    ("Org"           ?o "~/Dropbox/org-files/org-search/")
    ("Lecture Notes" ?l "~/Dropbox/Work/projects/lectures/"))
  "Sources for file search.")

(defvar consult-notes-all-notes "~/Dropbox/Work/projects/notes-all/"
  "Dir for affe-grep of all notes.")

(defun consult-notes-make-source (name char dir)
  "Return a notes source list suitable for `consult--multi'.
NAME is the source name, CHAR is the narrowing character,
and DIR is the directory to find notes. "
  (let ((idir (propertize (file-name-as-directory dir) 'invisible t)))
    `(:name     ,name
      :narrow   ,char
      :category ,consult-notes-category
      :face     consult-file
      :annotate ,(apply-partially 'consult-annotate-note name)
      :items    ,(lambda () (mapcar (lambda (f) (concat idir f))
				               ;; filter files that glob *.*
				               (directory-files dir nil "[^.].*[.].+")))
      :action   ,(lambda (f) (find-file f) (org-mode)))))
;; :action   find-file)))  ; use this if you don't want to force markdown-mode

(defun consult-annotate-note (name cand)
  "Annotate file CAND with its source name, size, and modification time."
  (let* ((attrs (file-attributes cand))
	     (fsize (file-size-human-readable (file-attribute-size attrs)))
	     (ftime (format-time-string "%b %d %H:%M" (file-attribute-modification-time attrs))))
    (put-text-property 0 (length name) 'face 'marginalia-type name)
    (put-text-property 0 (length fsize) 'face 'marginalia-size fsize)
    (put-text-property 0 (length ftime) 'face 'marginalia-date ftime)
    (format "%15s  %7s  %10s" name fsize ftime)))

;;;###autoload
(defun consult-notes ()
  "Find a file in a notes directory."
  (interactive)
  (consult--multi (mapcar #'(lambda (s) (apply 'consult-notes-make-source s))
			              consult-notes-sources-data)
		          :prompt "Notes File: "
		          :history 'consult-notes-history))

;;;###autoload
(defun consult-notes-search-all ()
  "Search all notes using affe-grep."
  (interactive)
  (affe-grep consult-notes-all-notes))


;;;; Embark support

(defun consult-notes-dired (cand)
  "Open notes directory dired with point on file CAND."
  (interactive "fNote: ")
  ;; dired-jump is in dired-x.el but is moved to dired in Emacs 28
  (dired-jump nil cand))

(defun consult-notes-marked (cand)
  "Open a notes file CAND in Marked 2."
  (interactive "fNote: ")
  ;; Marked 2 is a mac app that renders markdown
  (call-process-shell-command (format "open -a \"Marked 2\" \"%s\"" (expand-file-name cand))))

(defun consult-notes-grep (cand)
  "Run consult-ripgrep in directory of notes file CAND."
  (interactive "fNote: ")
  (consult-ripgrep (file-name-directory cand)))

(embark-define-keymap consult-notes-map
                      "Keymap for Embark notes actions."
                      :parent embark-file-map
                      ("d" consult-notes-dired)
                      ("g" consult-notes-grep)
                      ("m" consult-notes-marked))

(add-to-list 'embark-keymap-alist `(,consult-notes-category . consult-notes-map))
;; make embark-export use dired for notes
(setf (alist-get consult-notes-category embark-exporters-alist) #'embark-export-dired)


;;; Provide Consult Notes
(provide 'consult-notes)