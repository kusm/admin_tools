;; -*- mode: emacs-lisp; coding: utf-8-unix; indent-tabs-mode: nil -*-
;;; init.el

;; Copyright(C) 2010 Youhei SASAKI All rights reserved.
;; $Id: $

;; Author: Youhei SASAKI <uwabami@gfd-dennou.org>
;; Keywords:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;
;;; Commentary:
;;
;;; Code:
;; -----------------------------------------------------------
;; おまじない
(eval-when-compile (require 'cl))
;; mule-ucs
;; 日本語環境設定, language-env より拝借
(when (featurep 'mule)
  ;; Mule-UCS-Unicode for emacsen 20.x and 21.x
  (when (and (>= emacs-major-version 20)
             (<= emacs-major-version 21))
    (if (fboundp 'un-define-debian)
        (un-define-debian)
      (if (locate-library "un-define")
          (require 'un-define))))
  (let ((case-fold-search t)
        locale vars cs)
    (setq vars '("LC_ALL" "LC_CTYPE" "LANG"))
    (while (and vars (not (setq locale (getenv (car vars)))))
      (setq vars (cdr vars)))
    (or locale (setq locale "C"))
    (when (string-match "^ja" locale)
      ;; prefer japanese-jisx0208 characters
      (when (and (featurep 'un-define)
                 (not (featurep 'xemacs))) ;; for Emacs 20.x and 21.x
        (require 'un-supple)
        (un-supple-enable 'jisx0221)
        (un-supple-enable 'windows))
      (when (fboundp 'utf-translate-cjk-set-unicode-range) ;; for Emacs 22.x
        (utf-translate-cjk-set-unicode-range
         '((#x00a2 . #x00a3) (#x00a7 . #x00a8) (#x00ac . #x00ac)
           (#x00b0 . #x00b1) (#x00b4 . #x00b4) (#x00b6 . #x00b6)
           (#x00d7 . #x00d7) (#x00f7 . #x00f7) (#x0370 . #x03ff)
           (#x0400 . #x04ff) (#x2000 . #x206f) (#x2100 . #x214f)
           (#x2103 . #x2103) (#x212b . #x212b) (#x2190 . #x21ff)
           (#x2200 . #x22ff) (#x2300 . #x23ff) (#x2500 . #x257f)
           (#x25a0 . #x25ff) (#x2600 . #x26ff) (#x2e80 . #xd7a3)
           (#xff00 . #xffef)
           )))
      )))
;; 日本語環境設定
;; 本当は UTF-8 を使用したいが, pTeX がまだ Unicode 未対応なので
;; しょうがなく EUC-JP にしている.
(coding-system-put 'euc-japan 'category 'euc-japan)
(set-language-environment "Japanese")
(set-language-environment-coding-systems "Japanese")
(prefer-coding-system 'euc-japan)
(set-default-coding-systems 'euc-japan)
(set-terminal-coding-system 'euc-japan)
(set-keyboard-coding-system 'euc-japan)
(set-buffer-file-coding-system 'euc-japan)
(setq default-buffer-file-coding-system 'euc-japan)
(setq default-file-name-coding-system 'euc-japan)
;; ------------------------------------
;; 起動時はホームディレクトリから
(cd "~/")
;; \C-h -> BS にする.
(global-set-key (kbd "C-h") 'backward-delete-char)
;; [HOME] と [END] でバッファーの先頭/最後へ移動
(global-set-key [home] 'beginning-of-buffer)
(global-set-key [end] 'end-of-buffer)
;; モードラインにカーソルのある行番号を表示
(line-number-mode 0)
;; モードラインにカーソルのある桁番号を表示
(column-number-mode 0)
;; 左側に行番号を表示
(when (locate-library "linum")
  (setq linum-format "%4d "))
;; カーソルのある行を強調表示しない
(global-hl-line-mode 0)
;; リージョンに色づけ.
(setq transient-mark-mode t)
;; 対応する括弧を色づけする
(show-paren-mode t)
;; ツールバーを表示しない.
(tool-bar-mode 0)
;; スクロールバーは使用しない.
(set-scroll-bar-mode nil)
;; メニューバーを表示しない.
(menu-bar-mode -1)
;; bell-mode 使用しない
(setq ring-bell-function 'ignore)
;; startup を表示しない
(setq inhibit-startup-screen t)
;; タイトルにバッファ名を表示
(setq frame-title-format "%b")
;; \C-x f で画像を表示しない(主に terminal で起動するから)
(setq auto-image-file-mode nil)
;; ファイル名とともにディレクトリも表示
(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)
(setq uniquify-min-dir-content 1)
(setq-default save-place nil)
;; .save-* を作らない
(setq auto-save-list-file-name nil)
(setq auto-save-list-file-prefix nil)
;; #* を作成しない
;;(setq auto-save-default nil)
;; *.~ を作成しない
;;(setq make-backup-files nil)
;; tab 幅4, tab での indent の停止
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)
;; 空になったファイルを尋ねず自動削除
(if (not (memq 'delete-file-if-no-contents after-save-hook))
    (setq after-save-hook
          (cons 'delete-file-if-no-contents after-save-hook)))
(defun delete-file-if-no-contents ()
  (when (and
         (buffer-file-name (current-buffer))
         (= (point-min) (point-max)))
    (delete-file
     (buffer-file-name (current-buffer)))))

;; *scratch* を殺さない設定(再生成する)
(defun my-make-scratch (&optional arg)
  (interactive)
  (progn
    ;; "*scratch*" を作成して buffer-list に放り込む
    (set-buffer (get-buffer-create "*scratch*"))
    (funcall initial-major-mode)
    (erase-buffer)
    (when (and initial-scratch-message (not inhibit-startup-message))
      (insert initial-scratch-message))
    (or arg
        (progn
          (setq arg 0)
          (switch-to-buffer "*scratch*")))
    (cond ((= arg 0) (message "*scratch* is cleared up."))
          ((= arg 1) (message "another *scratch* is created")))))
(defun my-buffer-name-list ()
  (mapcar (function buffer-name) (buffer-list)))
(add-hook 'kill-buffer-query-functions
          ;; *scratch* バッファで kill-buffer したら内容を消去するだけにする
          (function (lambda ()
                      (if (string= "*scratch*" (buffer-name))
                          (progn (my-make-scratch 0) nil)
                        t))))
(add-hook 'after-save-hook
          ;; *scratch* バッファの内容を保存したら
          ;; *scratch* バッファを新しく作る.
          (function
           (lambda ()
             (unless (member "*scratch*" (my-buffer-name-list))
               (my-make-scratch 1)))))
;;行末の無駄な空白を削除
(add-hook 'before-save-hook 'delete-trailing-whitespace)
;;; 日本語入力 -> Anthy
;;
(load-library "anthy")
(setq default-input-method "japanese-anthy")
(setq anthy-accept-timeout 1)
;;; font
;;
(when window-system
  (create-fontset-from-ascii-font "Inconsolata:size=12" nil "myfont")
  (set-fontset-font "fontset-myfont"
                    'unicode
                    (font-spec :family "IPAGothic" :size 12)
                    nil 'append)
  (dolist (charset '(
                     japanese-jisx0208
                     japanese-jisx0208-1978
                     japanese-jisx0212
                     japanese-jisx0213-1
                     japanese-jisx0213-2
                     japanese-jisx0213-a
                     japanese-jisx0213.2004-1
                     katakana-jisx0201
                     ))
    (set-fontset-font "fontset-myfont"
                      charset
                      (font-spec :family "IPAGothic" :size 12)
                      nil 'prepend))
  (setq face-font-rescale-alist
        '(("-cdac$" . 1.3)))
  (custom-set-faces
   '(variable-pitch ((t (:family "Monospace")))))
  (add-to-list 'default-frame-alist
               '(font . "fontset-myfont")))





