;;; zweigtd-goals.el --- WIP-*-lexical-binding:t-*-

;; Copyright (C) 2021, Zweihänder <zweidev@zweihander.me>
;;
;; Author: Zweihänder
;; Keywords: org-mode
;; Homepage: https://github.com/Zweihander-Main/zweigtd-goals
;; Version: 0.0.1

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published
;; by the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; WIP
;;
;;; Code:

(require 'org)
(require 'org-capture)
(require 'org-agenda)

(defgroup zweigtd-goals nil
  "Customization for 'zweigtd-goals' package."
  :group 'org
  :prefix "zweigtd-goals-")

(defvar zweigtd-goals--hashtable (make-hash-table :test 'equal)
  "Hash table with GOALSTRING as key, plist '(numkey ?# colorstring STRING) as values.")

(defvar zweigtd-goals-goals nil
  "")

(defvar zweigtd-goals-file "goals.org"
  "")

(defvar zweigtd-goals-top-level-heading "* Goals"
  "")

(defmacro zweigtd-goals-with-goals-file (&rest body)
  "Execute the forms in BODY to update the `zweigtd-goals-file'
Creates the file if it does not already exist.
"
  (declare (indent defun) (debug t))
  `(let ((zweigtd-goals-buffer (find-file-noselect zweigtd-goals-file)))
     (with-current-buffer zweigtd-goals-buffer
       (zweigtd-goals--init-goals-buffer)
       (zweigtd-goals--check-file-top-structure)
       (zweigtd-goals--sync-and-check-goals)
       ,@body
       (save-buffer))
     (switch-to-buffer zweigtd-goals-file)))

(defun zweigtd-goals--init-goals-buffer ()
  "Prepares the goals buffer for use.
If the file already exists, goes to the beginning of the buffer.
Otherwise inserts the initial file content."
  (if (file-exists-p zweigtd-goals-file)
      (goto-char (point-min))
    (insert "#+TITLE: Goals\n"
            "#+STARTUP: content\n\n"
            "#+TODO: TODO | DONE KILL\n")))

(defun zweigtd-goals--check-file-top-structure ()
  "Checks file to make sure there is top layer 'Goals' heading. Adds it if not."
  (goto-char (point-min))
  (unless (search-forward zweigtd-goals-top-level-heading nil t)
    (goto-char (point-max))
    (insert "\n" zweigtd-goals-top-level-heading)))

(defun zweigtd-goals--sync-and-check-goals ()
  "Makes sure all goals listed are present under top level 'Goals' heading. Make
sure each goal heading has a priority subheading."
  (goto-char (point-min))
  (search-forward zweigtd-goals-top-level-heading)
  (maphash (lambda (goal)
             (save-excursion
                                        ; find subheading with tag mentioned
               (unless (search-forward goal) ;; TODO make sure heading
                                        ; if hit end of list, insert heading at the end of the list
                                        ; add to hash table
                                        ; add
                 )
               (unless
                                        ; make sure there is at least one subheading
                                        ; add one if there isn't
                                        ; add first subheading as priority to hash table
                                        ; add any scheduling information to hash table
                   )
               )) zweigtd-goals--hashtable))

;; TODO function to get all keys
;; TODO functions to get various metadata
;; TODO init function based on config
;; TODO view goals in minibuffer quickly
;; TODO generate agenda views in real time?
;; TODO check off priorities anywhere


(clrhash zwei/org-tag-goal-table)
(puthash "1#PHYSICAL" '(numkey ?1 colorstring "#CC2200") zwei/org-tag-goal-table)
(puthash "2#MENTAL" '(numkey ?2 colorstring "#008F40") zwei/org-tag-goal-table)
(puthash "3#CODING" '(numkey ?3 colorstring "#42A5F5") zwei/org-tag-goal-table)
(puthash "4#AUTOMATION" '(numkey ?4 colorstring "#00FF33") zwei/org-tag-goal-table)
(puthash "5#BUSINESS" '(numkey ?5 colorstring "#F5C400") zwei/org-tag-goal-table)
(puthash "6#WANKER" '(numkey ?6 colorstring "#6A3B9F") zwei/org-tag-goal-table)

(defun zweigtd-goals-init ()
  ""
  (clrhash zweigtd-goals--hashtable)
  )

(provide 'zweigtd-goals)

;; Local Variables:
;; coding: utf-8
;; End:

;;; zweigtd-goals.el ends here
