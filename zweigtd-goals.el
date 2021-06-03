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

(require 's)
(require 'dash)
(require 'org)
(require 'org-capture)
(require 'org-agenda)

(eval-when-compile
  (defvar org-tag-faces)
  (defvar org-tag-persistent-alist))

(defgroup zweigtd-goals nil
  "Customization for 'zweigtd-goals' package."
  :group 'org
  :prefix "zweigtd-goals-")

(defconst zweigtd-goals--key-preference-order-list
  '(?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9 ?0
       ?a ?b ?c ?d ?e ?f ?g ?h ?i ?j ?k ?l ?m
       ?n ?o ?p ?q ?r ?s ?t ?u ?v ?w ?x ?y ?z)
  "Preference order for auto-selecting keys for goals.")

;; TODO: Change defvars to defcustoms

(defconst zweigtd-goals--start-tag-group '(:startgroup "goal")
  "")

(defconst zweigtd-goals--end-tag-group '(:endgroup "goal")
  "")

(defvar zweigtd-goals--hashtable (make-hash-table :test 'equal)
  "Hash table with GOALSTRING as key, plist '(numkey ?# colorstring STRING) as values.")

(defvar zweigtd-goals-remain-in-buffer nil
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
       (zweigtd-goals--sync-and-check-goals)
       (save-buffer))
     (when zweigtd-goals-remain-in-buffer
       (switch-to-buffer zweigtd-goals-file))))

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

(defun zweigtd-goals--insert-subheading (&optional text)
  "TEXT"
  (if (fboundp '+org/insert-item-below)
      (progn (+org/insert-item-below 1)
             (org-demote-subtree))
    (org-insert-subheading t))
  (when text
    (org-edit-headline text)))

(defun zweigtd-goals--sync-and-check-goals ()
  "Makes sure all goals listed are present under top level 'Goals' heading. Make
sure each goal heading has a priority subheading."
  (goto-char (point-min))
  (search-forward zweigtd-goals-top-level-heading)
  (maphash
   (lambda (goal startprops)
     (let ((props startprops))
       ;; find subheading with tag mentioned
       (save-excursion
         ;; create the heading if it doesn't exist
         (unless (search-forward goal nil t) ; point @ top heading if not found
           ;; insert at end of list
           (zweigtd-goals--insert-subheading)
           (org-set-tags goal))
         ;; Currently at goal headline, add info to hash table
         (setq props (plist-put props :desc (substring-no-properties
                                             (org-get-heading t t t t))))
         ;; make sure there is at least one subheading, add if not
         (unless (org-goto-first-child)
           (zweigtd-goals--insert-subheading (concat "Priority for " goal))
           (org-todo "TODO"))
         ;; go to first sibling that isn't done/killed
         (while (and (org-entry-is-done-p) (org-goto-sibling)))
         ;; add first subheading as priority to hash table
         (setq props (plist-put props :priority (substring-no-properties
                                                 (org-get-heading t t t t))))
         (let ((schedule (org-get-scheduled-time (point)))
               (deadline (org-get-deadline-time (point))))
           ;; add any scheduling info of priority to hash table
           (when schedule
             (setq props (plist-put props :schedule schedule)))
           ;; add any deadline info of priority to hash table
           (when deadline
             (setq props (plist-put props :deadline deadline))))
         (puthash goal props zweigtd-goals--hashtable))))
   zweigtd-goals--hashtable))

(defun zweigtd-goals--string-to-color (str)
  "Outputs hex color string in format '#000000' based on hash of STR."
  (let ((hash 0)
        (colstring "#")
        (i 0)
        colsub)
    (mapcar (lambda (v)
              (setq hash (+ v (- (ash hash 5) hash))))
            str)
    (dotimes (i 3)
      (setq colsub (logand (ash hash (* i -8)) 255))
      (setq colstring (concat colstring
                              (s-right 2 (concat "00" (format "%X" colsub))))))
    colstring))

(defun zweigtd-goals--bootstrap-hashtable (goals)
  ""
  (clrhash zweigtd-goals--hashtable)
  ;; Get hotkeys selected by user to exclude from autofill
  (let ((keylist (mapcar (lambda (v) (plist-get v :key)) goals))
        (available-keys (-copy zweigtd-goals--key-preference-order-list))
        goal)
    (let ((unique-keylist (-distinct keylist)))
      (unless (= (length keylist) (length unique-keylist))
        (error "Don't use duplicate hotkeys for goals")))
    (setq available-keys
          (-difference zweigtd-goals--key-preference-order-list keylist))
    (dolist (goal goals)
      (let* ((goalname (plist-get goal :name))
             (goalkey (or (plist-get goal :key)
                          (let ((key (car available-keys)))
                            (setq available-keys (cdr available-keys))
                            key)))
             (goalcolor (or (plist-get goal :color)
                            (zweigtd-goals--string-to-color goalname))))
        (puthash goalname
                 `(:key ,goalkey :color ,goalcolor)
                 zweigtd-goals--hashtable)))))


(defun zweigtd-goals--bootstrap-tags ()
  ""
  (when (and (member zweigtd-goals--end-tag-group org-tag-persistent-alist)
             (member zweigtd-goals--start-tag-group org-tag-persistent-alist))
    (let ((start-index (-elem-index zweigtd-goals--start-tag-group
                                    org-tag-persistent-alist))
          (end-index (1+ (-elem-index zweigtd-goals--end-tag-group
                                      org-tag-persistent-alist))))
      (setq org-tag-persistent-alist (-concat (-take start-index
                                                     org-tag-persistent-alist)
                                              (-drop end-index
                                                     org-tag-persistent-alist)))))
  (let (alltags
        goaltags)
    (push zweigtd-goals--end-tag-group alltags)
    (maphash
     (lambda (k v)
       (push (cons k (plist-get v :key))
             goaltags))
     zweigtd-goals--hashtable)
    (setq alltags (-concat (nreverse goaltags) alltags))
    (push zweigtd-goals--start-tag-group alltags)
    (setq org-tag-persistent-alist (-concat org-tag-persistent-alist alltags)))
  )

(defun zweigtd-goals--bootstrap-tag-faces ()
  ""
  (maphash
   (lambda (k v)
     (let ((face (cons k (list ':foreground (plist-get v :color) ':weight 'bold))))
       (unless (member face org-tag-faces)
         (push face org-tag-faces))))
   zweigtd-goals--hashtable))

;;;###autoload
(defun zweigtd-goals-init (goals)
  "GOALS" ; TODO document inputs, what's optional, what's not
  ;; Make sure you document that it should be after tag declarations
  (zweigtd-goals--bootstrap-hashtable goals)
  (zweigtd-goals--bootstrap-tags)
  (zweigtd-goals--bootstrap-tag-faces)
  (let ((zweigtd-goals-remain-in-buffer nil))
    (zweigtd-goals-with-goals-file)))

;; TODO side-window:
;;      - view each goal and each priority + scheduling/deadline (highlight upcoming)
;;              - change how each is viewed based on keypress -- sort by key, sort by deadline, sort by schedule
;;      - currently misusing scheduling, should switch to deadline and update agenda
;;              - deadline for time priority should be done
;;              - scheduling = start working
;;      - CMD then KEY to do something with each goal (using narrowed buffer)
;;              - edit goal description
;;              - edit priority text, todo, scheduling, date
;;              - change priority by changing tree
;;      - similar to treemacs, use display-buffer-in-side-window

;;;###autoload
(defun zweigtd-goals-get-goals ()
  "Returns goal names as list."
  (let ((zweigtd-goals-remain-in-buffer nil))
    (zweigtd-goals-with-goals-file)) ; TODO oversyncing
  (hash-table-keys zweigtd-goals--hashtable))

(defun zweigtd-goals-get-prop (goal prop)
  "Return :PROP based on GOAL. Error if goal not found, nil if prop not found."
  (let ((zweigtd-goals-remain-in-buffer nil))
    (zweigtd-goals-with-goals-file)) ; TODO oversyncing
  (let ((data (gethash goal zweigtd-goals--hashtable)))
    (unless data
      (error (concat goal " goal not found")))
    (plist-get data prop)))

(provide 'zweigtd-goals)

;; Local Variables:
;; coding: utf-8
;; flycheck-disabled-checkers: 'emacs-lisp-elsa
;; End:

;;; zweigtd-goals.el ends here
