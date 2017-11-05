;;; Directory Local Variables
;;; For more information see (info "(emacs) Directory Variables")

((nil
  . ((eval . (setenv "DEVELOPER_DIR"
                     "/Applications/Xcode.app/Contents/Developer"))
     (fill-column . 80)
     (whitespace-style . (face lines indentation:space))
     (eval . (set (make-local-variable 'project-dir)
                  (file-name-directory
                   (let ((d (dir-locals-find-file ".")))
                     (if (stringp d) d (car d))))))
     (eval . (set (make-local-variable 'srcroot)
                  (expand-file-name "GSLCSVSerialization" project-dir)))))
 (objc-mode
  . ((flycheck-objc-clang-xcrun-sdk . "iphoneos11.0")
     (flycheck-objc-clang-arc . t)
     (flycheck-objc-clang-modules . t)
     (flycheck-objc-clang-archs . ("arm64" "armv7"))
     (flycheck-objc-clang-ios-version-min . "8.0")
     (eval . (set 'flycheck-objc-clang-include-paths (list srcroot)))))
 ("GSLCSVSerializationTests"
  . ((objc-mode
      . ((eval . (add-to-list
                  'flycheck-objc-clang-framework-paths
                  (expand-file-name
                   "Platforms/iPhoneOS.platform/Developer/Library/Frameworks"
                   (getenv "DEVELOPER_DIR")))))))))
