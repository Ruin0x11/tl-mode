;; -*- flycheck-disabled-checkers: (emacs-lisp-checkdoc) -*-
(load (concat (file-name-directory (or load-file-name (buffer-file-name)
                                       default-directory))
              "utils.el") nil 'nomessage 'nosuffix)

(require 'imenu)

(describe "lua-forward-sexp"
  (it "properly scans through curly braces"
    (with-lua-buffer
     (lua-insert-goto-<>
      '("local x = <>function() return {{}} end"
        ""
        "function foobar() end"))
     (lua-forward-sexp)
     (expect (looking-back (rx "x = function() return {{}} end")
                           (line-beginning-position)))))

  (it "scans through then .. end block"
    (with-lua-buffer
     (lua-insert-goto-<>
      '("if foo <>then"
        "  return bar"
        "--[[end here]] end"))
     (lua-forward-sexp)
     (expect (looking-back (rx "--[[end here]] end")
                           (line-beginning-position))))))


(describe "Check that beginning-of-defun works with "
  (it "handles differed function headers"
    (with-lua-buffer
     (lua-insert-goto-<>
      '("function foobar()"
        "<>"
        "end"))
     (beginning-of-defun)
     (expect (looking-at (rx "function foobar()"))))
    (with-lua-buffer
     (lua-insert-goto-<>
      '("local function foobar()"
        "<>"
        "end"))
     (beginning-of-defun)
     (expect (looking-at "local function foobar()")))
    (with-lua-buffer
     (lua-insert-goto-<>
      '("local foobar = function()"
        "<>"
        "end"))
     (beginning-of-defun)
     (expect (looking-at (rx "local foobar = function()"))))
    (with-lua-buffer
     (lua-insert-goto-<>
      '("foobar = function()"
        "<>"
        "end"))
     (beginning-of-defun)
     (expect (looking-at (rx "foobar = function()")))))

  (it "accepts dots and colons"
    (with-lua-buffer
     (lua-insert-goto-<>
      '("foo.bar = function (x,y,z)"
        "<>"
        "end"))
     (beginning-of-defun)
     (expect (looking-at (rx "foo.bar = function (x,y,z)"))))
    (with-lua-buffer
     (lua-insert-goto-<>
      '("function foo.bar:baz (x,y,z)"
        "<>"
        "end"))
     (beginning-of-defun)
     (expect (looking-at (rx "function foo.bar:baz (x,y,z)"))))))


(describe "lua-mode"
  (it "is derived from prog-mode"
    (with-lua-buffer
     (expect (derived-mode-p 'prog-mode)))))

(describe "imenu integration"
  (it "indexes functions"
    (with-lua-buffer
     (insert "\
function foo()
  function bar() end
  local function baz() end
  qux = function() end
  local quux = function() end
end
")
     (expect (mapcar 'car (funcall imenu-create-index-function))
             :to-equal '("foo" "bar" "baz" "qux" "quux"))))

  (it "indexes require statements"
    (with-lua-buffer
     (insert "\
foo = require (\"foo\")
local bar = require (\"bar\")
")
     (expect (mapcar (lambda (item) (cons (car item)
                                          (if (listp (cdr item))
                                              (mapcar 'car (cdr item))
                                            -1)))
                     (funcall imenu-create-index-function))
             :to-equal '(("Requires" . ("foo" "bar")))))))

