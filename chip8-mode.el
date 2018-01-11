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
  "Regexp that matches all valid identifiers (label names) in Chip-8 assembly.")

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

(define-derived-mode chip8-mode prog-mode "Chip8"
  "TODO: fill in the docstring."
  :group 'chip8-mode
  :syntax-table chip8-mode-syntax-table
  ;; The t at the end of `font-lock-defaults' will enable case folding (so add
  ;; and ADD will both be recognized as operations).
  (setq font-lock-defaults '(chip8-font-lock-keywords nil t))
  (setq-local comment-start "; ")
  (setq-local comment-end ""))

(provide 'chip8-mode)

;;; chip8-mode.el ends here
