;;; chip8-mode.el --- mode for editing Chip-8 assembly

;; Copyright 2018 Ian Johnson

;; This program is free software: you can redistribute it and/or modify
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

;; This is a major mode for editing Chip-8 assembly source files.  The syntax
;; of these source files is described in more detail in the manual for the
;; Chip-8 project.

;;; Code:

(defgroup chip8-mode ()
  "Mode for editing Chip-8 assembler code."
  :group 'languages)

(defgroup chip8-mode-faces ()
  "Faces used in `chip8-mode'."
  :group 'chip8-mode)

(defface chip8-constants
  '((t :inherit (font-lock-constant-face)))
  "Face for constants (e.g. numeric literals)."
  :group 'chip8-mode-faces)

(defface chip8-identifiers
  '((t :inherit (font-lock-variable-name-face)))
  "Face for label names used in expressions."
  :group 'chip8-mode-faces)

(defface chip8-labels
  '((t :inherit (font-lock-function-name-face)))
  "Face for label names used to mark a line."
  :group 'chip8-mode-faces)

(defface chip8-operations
  '((t :inherit (font-lock-builtin-face)))
  "Face for operations."
  :group 'chip8-mode-faces)

(defface chip8-pseudo-operations
  '((t :inherit (font-lock-preprocessor-face)))
  "Face for pseudo-operations."
  :group 'chip8-mode-faces)

(defface chip8-registers
  '((t :inherit (font-lock-keyword-face)))
  "Face for registers."
  :group 'chip8-mode-faces)

(defconst chip8-operations
  '("SCD" "CLS" "RET" "SCR" "SCL" "EXIT" "LOW" "HIGH" "JP" "CALL" "SE" "SNE"
    "LD" "ADD" "OR" "AND" "XOR" "SUB" "SHR" "SUBN" "SHL" "RND" "DRW" "SKP"
    "SKNP")
  "List of operations used in Chip-8 assembly.")

(defconst chip8-pseudo-operations
  '("DB" "DW" "IFDEF" "ELSE" "ENDIF")
  "List of pseudo-operations used in Chip-8 assembly.")

(defconst chip8-registers
  '("V0" "V1" "V2" "V3" "V4" "V5" "V6" "V7"
    "V8" "V9" "VA" "VB" "VC" "VD" "VE" "VF"
    "DT" "ST" "I" "F" "HF")
  "List of registers used in Chip-8 assembly.")

(defconst chip8-number-regexp
  "\\(\\_<\\(:?[0-9]+\\|#[[:xdigit:]]+\\|\\$[01]+\\)\\_>\\)"
  "Regexp that matches a numeric literal in Chip-8 assembly.")

(defconst chip8-identifier-regexp
  "\\(\\_<[A-Za-z_][A-Za-z0-9_]*\\_>\\)"
  "Regexp that matches all valid identifiers in Chip-8 assembly.")

(defconst chip8-assignment-regexp
  (concat "^\\s-*" chip8-identifier-regexp "\\s-*=")
  "Regexp that matches all assignment statements.")

(defconst chip8-label-regexp
  (concat "^\\s-*" chip8-identifier-regexp ":")
  "Regexp that matches all label names which are used to mark a line.")

(defconst chip8-operation-regexp
  (regexp-opt chip8-operations 'symbols)
  "Regexp that matches all Chip-8 operations.")

(defconst chip8-pseudo-operation-regexp
  (regexp-opt chip8-pseudo-operations 'symbols)
  "Regexp that matches all Chip-8 pseudo-operations.")

(defconst chip8-register-regexp
  (regexp-opt chip8-registers 'symbols)
  "Regexp that matches all Chip-8 registers.")

(defconst chip8-font-lock-keywords
  `((,chip8-label-regexp . (1 'chip8-labels))
    (,chip8-operation-regexp . 'chip8-operations)
    (,chip8-pseudo-operation-regexp . 'chip8-pseudo-operations)
    (,chip8-number-regexp . 'chip8-constants)
    (,chip8-register-regexp . 'chip8-registers)
    (,chip8-identifier-regexp . 'chip8-identifiers))
  "Font lock keywords for `chip8-mode'.")

(defvar chip8-mode-syntax-table
  (with-syntax-table (make-syntax-table)
    (modify-syntax-entry ?\; "<")
    (modify-syntax-entry ?\n ">")
    (modify-syntax-entry ?# "_")
    (modify-syntax-entry ?$ "_")
    (modify-syntax-entry ?| ".")
    (modify-syntax-entry ?^ ".")
    (modify-syntax-entry ?& ".")
    (modify-syntax-entry ?> ".")
    (modify-syntax-entry ?< ".")
    (modify-syntax-entry ?+ ".")
    (modify-syntax-entry ?- ".")
    (modify-syntax-entry ?* ".")
    (modify-syntax-entry ?/ ".")
    (modify-syntax-entry ?% ".")
    (modify-syntax-entry ?~ ".")
    (syntax-table))
  "Syntax table used in Chip-8 mode.")

(defvar chip8-instruction-column 8
  "Default column to use for indenting instructions.")

(defun chip8-back-to-instruction ()
  "Move point to the start of the instruction on this line."
  (interactive)
  (beginning-of-line)
  (re-search-forward (concat chip8-label-regexp "\\s-*")
                     nil t))

(defun chip8-back-to-indentation ()
  "Move point to the start of the instruction on this line.
If point is already at the start of the instruction, it is
instead moved to the position of the first non-whitespace
character on the line (the behavior of `back-to-indentation')."
  (interactive)
  (let ((old-point (point)))
    (chip8-back-to-instruction)
    (when (= old-point (point))
      (back-to-indentation))))

(defun chip8-indent-line ()
  "Indent the current line as Chip-8 assembly.
This function will attempt to position the label (if present) at
column 0 and the instruction at the column specified by
`chip8-instruction-column'."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (if (looking-at "^\\(\\s-*\\);;;")
        ;; Put section comments at the beginning of the line.
        (replace-match "" nil nil nil 1)
      ;; Move the label (if any) to column 0.
      (when (re-search-forward chip8-label-regexp nil t)
        (delete-region (match-beginning 0) (match-beginning 1)))
      ;; Attempt to move the operation to `chip8-instruction-column', or to one
      ;; space after the end of the label (whichever is furthest to the right).
      (when (looking-at "\\s-*")
        (let* ((columns (- chip8-instruction-column
                           (current-column)))
               (indent (max columns 1)))
          (replace-match (make-string indent ?\s))))))
  (when (< (current-column) (save-excursion
                              (chip8-back-to-instruction)
                              (current-column)))
    (chip8-back-to-instruction)))

(defconst chip8-electric-indent-chars '(?: ?\;)
  "Characters to add to `electric-indent-chars' in `chip8-mode'.")

(define-derived-mode chip8-mode prog-mode "Chip8"
  "TODO: fill in the docstring."
  :group 'chip8-mode
  :syntax-table chip8-mode-syntax-table
  ;; The t at the end of `font-lock-defaults' will enable case folding (so add
  ;; and ADD will both be recognized as operations).
  (setq font-lock-defaults '(chip8-font-lock-keywords nil t))
  (setq-local comment-start "; ")
  (setq-local comment-end "")
  (setq imenu-generic-expression `((nil ,chip8-label-regexp 1)
                                   ("Constants" ,chip8-assignment-regexp 1)))
  (setq imenu-case-fold-search t)
  (define-key chip8-mode-map
    [remap back-to-indentation] 'chip8-back-to-indentation)
  (setq indent-line-function 'chip8-indent-line)
  (setq-local electric-indent-chars (append electric-indent-chars
                                            chip8-electric-indent-chars)))

(provide 'chip8-mode)

;;; chip8-mode.el ends here
