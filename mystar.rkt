#lang racket

;Basic pathfind

;It's half an A* algorithm, it lacks the "open set" or "fringe set" ordered list of possible paths

;Instead, it uses a hash table for the closed set (visited points), and uses the call stack for the possible paths.

;So it doesn't always give the shortest path, but it does run nice and fast, since it doesn't have to maintain a priority queue.


; Use: [find-path map start end]

; start, end: lists of two elements, the coordinates of the start and end points
; map: an array of numbers >0, representing the cost of moving through the square.  If the cost is over 9000, that square can never
;      be crossed.  If there is no path from start to end, find-path will return an empty list

;Example:
;
; (build-array 20 20 (λ (x y) [if [> (random 101) 50] 9001 1]))

[provide find-path showmap]
(require (prefix-in arr: math/matrix))
(require math/array)
[require srfi/1]
[require rackunit]
(define (test-map-1)
  (array-map (lambda (x) [if [> x 1]
                             9001
                             1])
             (arr:matrix [
                          [1 1 1 1 1 1 1 1 1]
                          [1 1 1 1 1 1 2 1 1]
                          [1 1 1 1 2 2 2 1 1]
                          [1 2 1 1 1 1 2 1 1]
                          [1 2 2 2 2 2 2 2 2]
                          [1 2 1 1 1 1 1 1 2]
                          [1 2 1 1 1 1 1 1 1]
                          [1 2 1 1 1 1 1 1 1]
                          [1 1 1 1 1 1 1 1 1]])))

[define [test-map-3]
  (arr:build-matrix 20 20 (λ (x y) [if [> (random 101) 50] 9001 1]))
  ]

(define (test-map-2)
  (array-map (lambda (x) [if [> x 0]
                             9001
                             1])
             
             (arr:matrix [
                          [0 0 0 0]
                          [1 1 1 0]
                          [0 0 0 0]
                          [0 1 1 1]
                          [0 0 0 0]
                          ])))

[define [test-map-4]
  (array-map (lambda (x) [if [equal? x #\*]
                             9001
                             1])
  
             [arr:list->matrix 21 22 [string->list
                                      "
*********************
  *   *   *   *   * *
* * * * * * * * * * *
* * * * * * *   * * *
* * * *** * ***** * *
* * * *   * *     * *
* * * * *** * ***** *
*   * *   * * *   * *
*** * * * * * *** * *
*   *   *   *     * *
* ***************** *
*       * *         *
* ***** * * ***** ***
* *     *   *   * * *
*** * ******* *** * *
*   * *   *     *   *
* *** * * *** * * * *
*   * * *   * * * * *
*** * * *** * * * * *
*   *     *   *   *  
*********************"]
                               ])]


[define [moveTo a b c]
  ;[printf "Moving from ~a to ~a, step ~a~n" a b c]
  [if  [< [* [- a b] [- a b]] c]
       b
       [if [< a b]
           [+ a c]
           [- a c]]
       ]]

[define [lineRec start end]
  [displayln start]
  [if [equal? start end]
      [list end]
      [cons start [lineRec [list [moveTo [car start] [car end] 1] [moveTo [second start] [second end] 1]]end]]
      ]]

[define [basicLine start end]
  [lineRec start end]]

[define [square x] [* x x]]
[define [lineScore scoremap path end]
  ;[printf "linscore ~a: ~a~n" path
  ; [+  [square [- [caar path] [car end]]] [square [- [second [first path]] [second end]]] 
  ;     [fold + 0 [map [lambda [e] [array-ref scoremap [vector [car e] [second e]]]] path]]]]
  
  [+  [square [- [caar path] [car end]]] [square [- [second [first path]] [second end]]] 
      [fold + 0 [map [lambda [e] [array-ref scoremap [vector [car e] [second e]]]] path]]]
  ]

[define [mapScore scoremap path end]
  ;[printf "mapscore ~a: ~a~n" path [+
  ;[sqrt [+  [square [- [caar path] [car end]]] [square [- [second [first path]] [second end]]] ]]
  ;]]
  [+
   [sqrt [+  [square [- [caar path] [car end]]] [square [- [second [first path]] [second end]]] ]]
   ]
  ]

;[basicLine start end]
;[printf "Score: ~a~n" [lineScore [make-map] [basicLine start end] end] ]

[define [improvePath smap path]
  [if [empty? path]
      path
      [if [equal? [car path] [list 5 5]]
          [append [list '[ 10 10] '[11 11]] [improvePath smap [cdr path]]]
          [cons [car path] [improvePath smap [cdr path]]]]
      ]
  ]

;[define [neighbour-list] '[(-1 0) (1 0) (0 -1) (0 1) (-1 -1) (-1 1) (1 -1) (1 1)]]
[define [neighbour-list] '[(-1 0) (1 0) (0 -1) (0 1) ]]

;[improvePath [make-map] [basicLine start end]]


[define [generate-new-paths path neighbours]
  [map [lambda [n]
         [cons [map + n [car path]] path]]
       neighbours]]

[define [doThing smap path start return closed]
  [hash-set! closed [car path] 1]
  ;[showmap smap path closed][displayln ""]
  
  ;[printf "Score: ~a, path: ~a~n"  [lineScore smap path start] path]
  [if [equal? [car path] start ]
      [return path]
      [let [[new-paths [filter [lambda [e]
                                 ;[printf "Position (~a,~a)~n"[caar e] [second [first e]]]
                                 [not
                                  [or
                                   [hash-ref closed [car e] #f]
                                   
                                   [not [< [caar e] [arr:matrix-num-rows smap]]]
                                   [not [< [second [first e]] [arr:matrix-num-cols smap]]]
                                   [< [caar e] 0]
                                   [< [second [first e]] 0]
                                   [> [array-ref smap [vector [caar e] [second [first e]] ]] 9000]
                                   ]]] [generate-new-paths path [neighbour-list]]]]]
   
        [if [empty? new-paths]
            '[]
            [map [lambda [a-path] [doThing smap a-path start return closed]] [sort  new-paths < #:key [lambda [l] [+ [lineScore smap l start] [/ [mapScore smap l start] 1000000]]]]]
            ]]]]



[define [showmap bmap path closed]
  [let [[amap [mutable-array-copy bmap]]]
    [map [lambda [p] [array-set! amap [apply vector p] -1]] path]
    [if [not [empty? path]]
        [begin
          [array-set! amap [apply vector [car [reverse path]]] -2]
          [array-set! amap [apply vector [car path]] -2]]
        [hash-map closed [lambda [k v] [array-set! amap [apply vector k] -2]] path]
        ]
    [map [lambda [x]
           [map [lambda [y]
                  [begin
                    [if [equal? -2 [array-ref amap [vector x y]]]
                        [display "!"]
                        [begin
                          [when [< [array-ref amap [vector x y]]0]
                            [display "┼"]]
                          [when [> [array-ref amap [vector x y]]9000]
                            [display "*"]]
                          [when [and [<= [array-ref amap [vector x y]]9000] [>= [array-ref amap [vector x y]]0]]
                            [display "."]]]]]]
                [iota [arr:matrix-num-cols amap]
                      ]]
           [displayln ""]]
         [iota [arr:matrix-num-rows amap]]]
    ]]

[define [out-of-bounds smap e]
  
                                  [or
                                   
                                   [>= [car e] [arr:matrix-num-rows smap]]
                                   [>= [second  e] [arr:matrix-num-cols smap]]
                                   [< [car e] 0]
                                   [< [second  e] 0]]]
[define [find-path smap start end]
  [printf "Navigating matrix of size ~ax~a from ~a to ~a~n" [arr:matrix-num-cols smap] [arr:matrix-num-rows smap] start end]
  [if [or [equal? start end] [out-of-bounds smap start] [out-of-bounds smap end]] 
      [begin
        [printf "Invalid input~n"]
        '[]]
  [let [[closed [make-hash]]]
  [letrec [
           [path [call/cc [lambda [return] [doThing smap [list [reverse start]] [reverse end] return closed]]]]] ;reverse for row-column addressing format
    ;[displayln "calculated path"]
    
    ;[showmap smap path closed]
    ;[not [empty? path]]
    path]]]]


'[
[check-equal? [find-path [array->mutable-array [test-map-2]] '[3 4] '[0 0]] '((0 0) (0 1) (0 2) (0 3) (1 3) (2 3) (2 2) (2 1) (2 0) (3 0) (4 0) (4 1) (4 2) (4 3)) "Check a simple map"]
;[find-path [array->mutable-array [test-map-1]] '[7 7] '[1 1]]
;[find-path [array->mutable-array [test-map-3]] '[19 19] '[0 0]]
[check-equal? [find-path [array->mutable-array [test-map-4]] '[19 19] '[0 0]] '((0 0)
  (1 0)
  (1 1)
  (1 2)
  (2 2)
  (3 2)
  (4 2)
  (5 2)
  (6 2)
  (7 2)
  (7 3)
  (7 4)
  (8 4)
  (9 4)
  (9 3)
  (9 2)
  (10 2)
  (11 2)
  (11 3)
  (11 4)
  (11 5)
  (11 6)
  (11 7)
  (11 8)
  (12 8)
  (13 8)
  (13 7)
  (13 6)
  (14 6)
  (15 6)
  (16 6)
  (17 6)
  (18 6)
  (19 6)
  (19 7)
  (19 8)
  (18 8)
  (17 8)
  (16 8)
  (15 8)
  (15 9)
  (15 10)
  (16 10)
  (17 10)
  (17 11)
  (17 12)
  (18 12)
  (19 12)
  (19 13)
  (19 14)
  (18 14)
  (17 14)
  (16 14)
  (15 14)
  (15 15)
  (15 16)
  (16 16)
  (17 16)
  (18 16)
  (19 16)
  (19 17)
  (19 18)
  (19 19)) "Check a big maze"]
]