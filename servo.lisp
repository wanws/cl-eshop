;;;; servo.lisp
;;;;
;;;; This file is part of the cl-eshop project,
;;;; See file COPYING for details.
;;;;
;;;; Author: Glukhov Michail aka Rigidus <i.am.rigidus@gmail.com>

(in-package #:eshop)


(defmacro with-sorted-paginator (get-products body)
  `(let* ((products ,get-products)
          (sorting  (getf (request-get-plist) :sort))
          (sorted-products   (cond ((string= sorting "pt")
                                    (product-sort products #'< #'price))
                                   ((string= sorting "pb")
                                    (product-sort products #'> #'price))
                                   ((string= sorting "pt1") products)
                                   (t products))))
     (multiple-value-bind (paginated pager)
         (paginator (request-get-plist) sorted-products)
       ,body)))


(defmacro sorts ()
  `(let ((variants '(:pt "увеличению цены" :pb "уменьшению цены")))
     (loop :for sort-field :in variants :by #'cddr :collect
        (if (string= (string-downcase (format nil "~a" sort-field))
                     (getf (request-get-plist) :sort))
            (list :key (string-downcase (format nil "~a" sort-field))
                  :name (getf variants sort-field)
                  :active t)
            (list :key (string-downcase (format nil "~a" sort-field))
                  :name (getf variants sort-field))))))


(defmacro rightblocks ()
  `(list (catalog:rightblock1)
         (catalog:rightblock2)
         (catalog:rightblock3)))


(defmacro tradehits ()
  `(catalog:tradehits (list :reviews (list *trade-hits-1*
                                           *trade-hits-2*
                                           *trade-hits-1*
                                           *trade-hits-2*))))


(defmacro with-option (product optgroup-name option-name body)
  `(mapcar #'(lambda (optgroup)
               (if (string= (name optgroup) ,optgroup-name)
                   (let ((options (options optgroup)))
                     (mapcar #'(lambda (option)
                                 (if (string= (name option) ,option-name)
                                     ,body))
                             options))))
           (optgroups ,product)))


(defun get-date-time ()
  (multiple-value-bind (second minute hour date month year) (get-decoded-time)
    (declare (ignore second))
    (format nil
            "~d-~2,'0d-~2,'0d ~2,'0d:~2,'0d"
            year
            month
            date
            hour
            minute)))


(defun paginator-page-line (request-get-plist start stop current)
  (loop :for i from start :to stop :collect
     (let ((plist request-get-plist)
           (is-current-page nil))
       (setf (getf plist :page) (format nil "~a" i))
       (setf is-current-page (= current i))
       (format nil "<a href=\"?~a\">~:[~;<big><b>~]~a~:[~;</b></big>~]</a>"
               (make-get-str plist)
               is-current-page
               i
               is-current-page))))

(defun paginator (request-get-plist sequence &optional (pagesize 15))
  (let ((page (getf request-get-plist :page))
        (page-count (ceiling (length sequence) pagesize)))
    (when (null page)
      (setf page "1"))
    (setf page (parse-integer page :junk-allowed t))
    (unless (and (numberp page)
                 (plusp page))
      (setf page 1))
    (if (> page page-count)
        (setf page page-count))
    (let* ((result (let ((tmp (ignore-errors (subseq sequence (* pagesize (- page 1))))))
                     (when (> (length tmp) pagesize)
                       (setf tmp (subseq tmp 0 pagesize)))
                     tmp))
           (start-page-line nil)
           (cur-page-line nil)
           (stop-page-line nil)
           (start-number 1)
           (stop-number page-count)
           (page-line-string ""))
      (if (> page 5)
          (progn
            (setf start-number (- page 2))
            (setf start-page-line (paginator-page-line request-get-plist 1 2 0))))
      (if (> (- page-count page) 5)
          (progn
            (setf stop-number (+ page 2))
            (setf stop-page-line (paginator-page-line request-get-plist (- page-count 1) page-count 0))))
      (setf cur-page-line (paginator-page-line request-get-plist start-number stop-number page))
      (if (> page-count 1)
          (setf page-line-string
                (format nil "~@[~{~a~}...~] ~{~a ~} ~@[...~{~a~}~]"
                        start-page-line
                        cur-page-line
                        stop-page-line)))
      (values result page-line-string)
      )))


    ;; (loop :for elt :in sequence :do
    ;;    (if (< i (* (- page 1) pagesize))
    ;;        (progn
    ;;          (setf head (cdr head))
    ;;          (incf i))
    ;;        (return)))
    ;; (setf i 0)
    ;; (loop :for elt :in head :do
    ;;    (if (> pagesize i)
    ;;        (progn
    ;;          (push elt ret)
    ;;          (incf i))
    ;;        (return)))
    ;; (let* ((size (floor (length sequence) pagesize))
    ;;        (show-pages
    ;;         (sort
    ;;          (remove-if #'(lambda (x)
    ;;                         (or (not (plusp x))
    ;;                             (< size  x)))
    ;;                     (remove-duplicates
    ;;                      (append '(1 2 3) (list (- page 1) page (+ page 1)) (list (- size 2) (- size 1) size))))
    ;;          #'(lambda (a b)
    ;;              (< a b))))
    ;;        (tmp 0)
    ;;        (res))
    ;;   (loop :for i :in show-pages :do
    ;;      (let ((plist request-get-plist))
    ;;        (when (not (equal tmp (- i 1)))
    ;;          (push "<span>&hellip;</span>" res))
    ;;        (setf tmp i)
    ;;        (setf (getf plist :page) (format nil "~a" i))
    ;;        (push (if (equal page i)
    ;;                  (format nil "<a class=\"active\" href=\"?~a\">~a</a>"
    ;;                          (make-get-str plist)
    ;;                          i)
    ;;                  ;; else
    ;;                  (format nil "<a href=\"?~a\">~a</a>"
    ;;                          (make-get-str plist)
    ;;                          i))
    ;;              res)))
    ;;   (values
    ;;    (reverse ret)
    ;;    (format nil "~{~a&nbsp;&nbsp;&nbsp;&nbsp;~}" (reverse res))
    ;;    ))))


(defun menu-sort (a b)
  (if (or (null (order a))
          (null (order b)))
      nil
      ;; else
      (< (order a)
         (order b))))


(defun menu (&optional current-object)
  (let ((root-groups)
        (current-key (let* ((breadcrumbs (breadcrumbs current-object))
                            (first       (getf (car (getf breadcrumbs :breadcrumbelts)) :key)) )
                       (if (not (null first))
                           first
                           (getf (getf breadcrumbs :breadcrumbtail) :key)
                           ))))
    (maphash #'(lambda (key val)
                 (when (and
                        (equal 'group (type-of val))
                        (null (parent val))
                        (active val)
                        (not (empty val)))
                   (push val root-groups)))
             *storage*)
    (let ((src-lst (mapcar #'(lambda (val)
                               (if (string= (format nil "~a" current-key) (key val))
                                   ;; This is current
                                   (leftmenu:selected
                                    (list :key (key val)
                                          :name (name val)
                                          :subs (loop
                                                   :for child
                                                   :in (sort
                                                        (remove-if #'(lambda (g)
                                                                       (or
                                                                        (empty g)
                                                                        (not (active g)) ))
                                                                   (childs val)) #'menu-sort)
                                                   :collect
                                                   (list :key  (key child) :name (name child)))
                                          ))
                                   ;; else - this is ordinal
                                   (leftmenu:ordinal (list :key  (key val) :name (name val)))
                                   ))
                           (sort root-groups #'menu-sort)
                           ;; root-groups
                           )))
      (leftmenu:main (list :elts src-lst)))))


(defun breadcrumbs (in &optional out)
  (cond ((equal (type-of in) 'product)
         (progn
           (push (list :key (articul in) :val (name in)) out)
           (setf in (parent in))))
        ((equal (type-of in) 'group)
         (progn
           (push (list :key (key in) :val (name in)) out)
           (setf in (parent in))))
        ((equal (type-of in) 'filter)
         (progn
           (push (list :key (key in) :val (name in)) out)
           (setf in (parent in))))
        (t (if (null in)
               ;; Конец рекурсии
               (return-from breadcrumbs
                 (list :breadcrumbelts (butlast out)
                       :breadcrumbtail (car (last out))))
               ;; else - Ищем по строковому значению
               (let ((parent (gethash in *storage*)))
                 (cond ((equal 'group (type-of parent)) (setf in parent))
                       ((null parent) (return-from breadcrumbs (list :breadcrumbelts (butlast out)
                                                                     :breadcrumbtail (car (last out)))))
                       (t (error "breadcrumb link error")))))))
  (breadcrumbs in out))



(defun default-page (&optional (content nil) &key keywords description title)
  (root:main (list :keywords keywords
                   :description description
                   :title title
                   :header (root:header (list :logged (root:notlogged)
                                              :cart (root:cart)))
                   :footer (root:footer)
                   :content (if content
                                content
                                (format nil "<pre>'~a' ~%'~a' ~%'~a'</pre>"
                                        (request-str)
                                        (hunchentoot:request-uri *request*)
                                        (hunchentoot:header-in* "User-Agent"))))))


(defun checkout-page (&optional (content nil))
  (root:main (list :header (root:shortheader)
                   :footer (root:footer)
                   :content (if content
                                content
                                "test page"))))


(defun static-page ()
  (let ((∆ (find-package (intern (string-upcase (subseq (request-str) 1)) :keyword))))
    (default-page
        (static:main
         (list :menu (menu)
               :breadcrumbs (funcall (find-symbol (string-upcase "breadcrumbs") ∆))
               :subcontent  (funcall (find-symbol (string-upcase "subcontent") ∆))
               :rightblock  (funcall (find-symbol (string-upcase "rightblock") ∆)))))))


(defun request-str ()
  (let* ((request-full-str (hunchentoot:request-uri hunchentoot:*request*))
         (request-parted-list (split-sequence:split-sequence #\? request-full-str))
         (request-str (string-right-trim "\/" (car request-parted-list)))
         (request-list (split-sequence:split-sequence #\/ request-str))
         (request-get-plist (if (null (cadr request-parted-list))
                                nil
                                ;; else
                                (let ((result))
                                  (loop :for param :in (split-sequence:split-sequence #\& (cadr request-parted-list)) :do
                                     (let ((split (split-sequence:split-sequence #\= param)))
                                       (setf (getf result (intern (string-upcase (car split)) :keyword))
                                             (if (null (cadr split))
                                                 ""
                                                 (cadr split)))))
                                  result))))
    (values request-str request-list request-get-plist)))


(defun request-get-plist ()
  (multiple-value-bind (request-str request-list request-get-plist)
      (request-str)
    request-get-plist))


(defun request-list ()
  (multiple-value-bind (request-str request-list request-get-plist)
      (request-str)
    request-list))



(defun make-get-str (request-get-plist)
  (format nil "~{~a~^&~}"
          (loop :for cursor :in request-get-plist by #'cddr collect
             (string-downcase (format nil "~a=~a" cursor (getf request-get-plist cursor))))))



(defun parse-id (id-string)
  (let ((group_id (handler-bind ((SB-INT:SIMPLE-PARSE-ERROR
								  #'(lambda (c)
									  (declare (ignore c))
									  (invoke-restart 'set-nil)))
								 (TYPE-ERROR
								  #'(lambda (c)
									  (declare (ignore c))
									  (invoke-restart 'set-nil)))
								 )
					(restart-case (parse-integer id-string)
					  (set-nil ()
						nil)))))
	group_id))

(defun strip ($string)
  (cond ((vectorp $string) (let (($ret nil))
							 (loop
								for x across $string collect x
								do (if (not
										(or
										 (equal x #\')
										 (equal x #\")
										 (equal x #\!)
										 (equal x #\%)
										 (equal x #\\)
										 (equal x #\/)
										 ))
									   (push x $ret)))
							 (coerce (reverse $ret) 'string)))
		((listp $string)   (if (null $string)
							   ""
							   $string))))

(defun stripper ($string)
  (cond ((vectorp $string) (let (($ret nil))
							 (loop
								for x across $string collect x
								do (if (not
										(or
										 (equal x #\')
										 (equal x #\")
										 (equal x #\\)
                                         (equal x #\~)
										 ))
									   (push x $ret)))
                             (let ((ret (coerce (reverse $ret) 'string)))
                               (when (equal 0 (length ret))
                                 (return-from stripper ""))
                               ret)))))


(defun replace-all (string part replacement &key (test #'char=))
  "Returns a new string in which all the occurences of the part
is replaced with replacement."
  (with-output-to-string (out)
    (loop with part-length = (length part)
       for old-pos = 0 then (+ pos part-length)
       for pos = (search part string
                         :start2 old-pos
                         :test test)
       do (write-string string out
                        :start old-pos
                        :end (or pos (length string)))
       when pos do (write-string replacement out)
       while pos)))


(defun merge-plists (a b)
  (let* ((result (copy-list a)))
	(loop while (not (null b)) do
		 (setf (getf result (pop b)) (pop b)))
	result))


(defun reverse-plist (inlist)
  (let ((result))
    (loop :for i :in inlist by #'cddr do
       (setf (getf result i) (getf inlist i)))
    result))


(defun numerizable (param)
  (coerce (loop for i across param when (parse-integer (string i) :junk-allowed t) collect i) 'string))


(defun slice (cnt lst)
  (let ((ret))
    (tagbody re
       (push (loop
                :for elt :in lst
                :repeat cnt
                :collect
                (pop lst)) ret)
       (unless (null lst)
         (go re)))
    (reverse ret)))


(defun cut (cnt lst)
  (values (loop
             :for elt :in lst
             :repeat cnt
             :collect
             (pop lst))
          lst))




(defun get-procent (base real)
  (when (equal 0 base)
    (return-from get-procent (values 0 0)))
  (if (or (null base) (null real))
	  (return-from get-procent 0))
  (values (format nil "~$"  (- base real))
          (format nil "~1$" (- 100 (/ (* real 100) base)))))


(defun get-pics (articul)
  (let ((path (format nil "~a/big/~a/*.jpg" *path-to-pics* articul)))
    (loop
       :for pic
       :in (ignore-errors (directory path))
       :collect (format nil "~a.~a"
                        (pathname-name pic)
                        (pathname-type pic)))))


(defmethod get-keyoptions ((object product))
  (let ((parent (parent object)))
    (when (null parent)
      (return-from get-keyoptions nil))
    (mapcar #'(lambda (pair)
                (let ((optgroup (getf pair :optgroup))
                      (optname  (getf pair :optname))
                      (optvalue))
                  (mapcar #'(lambda (option)
                              (if (string= (name option) optgroup)
                                  (let ((options (options option)))
                                    (mapcar #'(lambda (opt)
                                                (if (string= (name opt) optname)
                                                    (setf optvalue (value opt))))
                                            options))))
                          (optgroups object))
                  (list :optgroup optgroup
                        :optname optname
                        :optvalue optvalue)
                  ))
            (keyoptions parent))))


(defmethod view ((object product))
  (let ((pics (get-pics (articul object))))
    (let ((group (parent object)))
      ;; (when (not (null group))
      (list :articul (articul object)
            :name (realname object)
            :groupname (if (null group)
                           "group not found"
                           (name group))
            :groupkey  (if (null group)
                           ""
                           (key  group))
            :price (price object)
            :firstpic (car pics)
            ))))





(defparameter *trade-hits-1*
  (list :pic "/img/temp/s1.jpg"
        :name "Lenovo E43-4S-B"
        :price 19990
        :ico "/img/temp/u2.jpg"
        :user "Борис"
        :text "Отличный ноутбук для работы, здорово помогает! Главное - мощная батарея, хватает на 4 часа"
        :more "Еще 12 отзывов о ноутбуке"))

(defparameter *trade-hits-2*
  (list :pic "/img/temp/s3.jpg"
        :name "ASUS UL30Vt"
        :price 32790
        :ico "/img/temp/u3.jpg"
        :user "Тамара"
        :text "Не плохой ноутбук, рабочая лошадка. Хорошие углы обзора, шустрый проц, без подзарядки работает часа 3, легкий и удобный в переноске. В общем, советую."
        :more "Еще 12 отзывов о ноутбуке"))




(defun product-sort (products operation getter)
  (sort (copy-list products) #'(lambda (a b)
                                 (if (funcall operation
                                              (funcall getter a)
                                              (funcall getter b))
                                     t
                                     nil))))


(defmethod filter-controller ((object group) request-get-plist)
  (let ((functions (mapcar #'(lambda (elt)
                               (eval (car (last elt))))
                           (base (fullfilter object)))))
    (mapcar #'(lambda (filter-group)
                (let ((advanced-filters (cadr filter-group)))
                  (mapcar #'(lambda (advanced-filter)
                              (nconc functions (list (eval (car (last advanced-filter))))))
                          advanced-filters)))
            (advanced(fullfilter object)))
    (mapcar #'(lambda (filter-group)
                (let ((advanced-filters (cadr filter-group)))
                  (mapcar #'(lambda (advanced-filter)
                              (nconc functions (list (eval (car (last advanced-filter))))))
                          advanced-filters)))
            (advanced (fullfilter object)))
    ;; processing
    (let ((result-products))
      (mapcar #'(lambda (product)
                  (when (loop
                           :for function :in functions
                           :finally (return t)
                           :do (unless (funcall function product request-get-plist)
                                 (return nil)))
                    (push product result-products)))
              (remove-if-not #'(lambda (product)
                                 (active product))
                             (get-recursive-products object)))
      result-products)))


(defmethod filter-test ((object group) url)
  (let* ((request-full-str url)
         (request-parted-list (split-sequence:split-sequence #\? request-full-str))
         (request-get-plist (let ((result))
                              (loop :for param :in (split-sequence:split-sequence #\& (cadr request-parted-list)) :do
                                 (let ((split (split-sequence:split-sequence #\= param)))
                                   (setf (getf result (intern (string-upcase (car split)) :keyword))
                                         (if (null (cadr split))
                                             ""
                                             (cadr split)))))
                              result)))
    (filter-controller object request-get-plist)))


(defun filter-element (elt request-get-plist)
  (let* ((key (string-downcase (format nil "~a" (nth 0 elt))))
         (name (nth 1 elt))
         (contents
          (cond ((equal :range (nth 2 elt))
                 (fullfilter:range
                  (list :unit (nth 3 elt)
                        :key key
                        :name name
                        :from (getf request-get-plist
                                    (intern (string-upcase (format nil "~a-f" key)) :keyword))
                        :to (getf request-get-plist
                                  (intern (string-upcase (format nil "~a-t" key)) :keyword)))))
                ((equal :radio (nth 2 elt))
                 (fullfilter:box
                  (list :key key
                        :name name
                        :elts (let ((elts (nth 3 elt)))
                                (loop :for nameelt :in elts
                                   :for i from 0 :collect
                                   (fullfilter:radioelt
                                    (list :key key
                                          :value i
                                          :name nameelt
                                          :checked (string= (format nil "~a" i)
                                                            (getf request-get-plist (intern
                                                                                     (string-upcase key)
                                                                                     :keyword)))
                                          )))))))
                ((equal :checkbox (nth 2 elt))
                 (fullfilter:box
                  (list :key key
                        :name name
                        :elts (let ((values (nth 3 elt)))
                                (loop :for value :in values
                                   :for i from 0 :collect
                                   (fullfilter:checkboxelt
                                    (list :value value
                                          :key key
                                          :i i
                                          :checked (string= "1" (getf request-get-plist (intern
                                                                                         (string-upcase
                                                                                          (format nil "~a-~a" key i))
                                                                                         :keyword)))
                                          )))))))
                (t ""))))
    (if (search '(:hidden) elt)
        (fullfilter:hiddencontainer (list :key key
                                          :name name
                                          :contents contents))
        contents)))



(defmethod vendor-controller ((object group) request-get-plist)
  (let* ((result-products))
    (mapcar #'(lambda (product)
                (let ((vendor))
                  (mapcar #'(lambda (optgroup)
                              (if (string= (name optgroup) "Общие характеристики")
                                  (let ((options (options optgroup)))
                                    (mapcar #'(lambda (opt)
                                                (if (string= (name opt) "Производитель")
                                                    (setf vendor (value opt))))
                                            options))))
                          (optgroups product))
                  ;; (format t "~%[~a] : [~a] : [~a]"
                  ;;         (string-downcase (string-trim '(#\Space #\Tab #\Newline) vendor))
                  ;;         (string-downcase (ppcre:regex-replace-all "%20" (getf request-get-plist :vendor) " "))
                  ;;         ;; (loop :for ch :across (ppcre:regex-replace-all "%20" (getf request-get-plist :vendor) " ") :do
                  ;;         ;;    (format t "~:c." ch))
                  ;;         )
                  ;; vendor (getf request-get-plist :vendor))
                  (if (string=
                       (string-downcase
                        (string-trim '(#\Space #\Tab #\Newline) vendor))
                       (string-downcase
                        (string-trim '(#\Space #\Tab #\Newline)
                                     (ppcre:regex-replace-all "%20" (getf request-get-plist :vendor) " "))))
                      (push product result-products))))
            (remove-if-not #'(lambda (product)
                               (active product))
                           (get-recursive-products object)))
    result-products))