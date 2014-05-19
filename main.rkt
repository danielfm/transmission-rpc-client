#lang racket/base

(require racket/contract
         racket/port
         json
         net/url
         net/head)

(provide (struct-out transmission-session)
         (contract-out
          [transmission-request!            (->* (transmission-session? string? jsexpr?)
                                                 (number?)
                                                 jsexpr?)]
          [transmission-request-successful? (-> jsexpr? boolean?)]
          [transmission-response-args       (-> jsexpr? jsexpr?)]
          [transmission-response-arg        (-> jsexpr? symbol? jsexpr?)]))

;; Session ID header field used by Transmission in order to avoid CSRF
(define session-id-field-name "X-Transmission-Session-Id")

;; Transmission RPC session data
(struct transmission-session (url [id #:mutable #:auto]))

;; Returns the Transmission RPC endpoint URL
(define (transmission-rpc-url session)
  (string->url (transmission-session-url session)))

;; Returns the bytestring of a new Transmission RPC request
(define (transmission-request-bytes method args tag)
  (let ([req (hash 'method method 'arguments args)])
    (jsexpr->bytes
     (if tag
         (hash-set req 'tag tag)
         req))))

;; Returns the HTTP headers for the given Transmission session
(define (transmission-session-headers session)
  (let ([session-id (transmission-session-id session)])
    (if session-id
        (list (format "~a: ~a" session-id-field-name session-id))
        null)))

;; Returns whether the request was rejected due to invalid session id
(define (transmission-request-denied? response-header-str)
  (not (eq? #f (regexp-match #rx" 409 " response-header-str))))

;; Updates the session id using header data
(define (transmission-update-session-id! session header-str)
  (let ([new-id (extract-field session-id-field-name header-str)])
    (when new-id
      (set-transmission-session-id! session new-id))))

;; Sends a RPC request and returns the jsexpr response object
(define (transmission-request! session method args [tag #f])
  (call/cc
   (lambda (return)
     (let* ([url     (transmission-rpc-url session)]
            [headers (transmission-session-headers session)]
            [post    (transmission-request-bytes method args tag)]
            [resp    (post-impure-port url post headers)]
            [headers (purify-port resp)])
       (when (transmission-request-denied? headers)
         (transmission-update-session-id! session headers)
         (return (transmission-request! session method args tag)))
       (bytes->jsexpr (port->bytes resp))))))

;; Returns whether a RPC request was successful
(define (transmission-request-successful? response)
  (equal? "success" (hash-ref response 'result)))

;; Returns the response arguments of a RPC request
(define (transmission-response-args response)
  (hash-ref response 'arguments))

;; Returns a particular response argument of a RPC request
(define (transmission-response-arg response arg)
  (hash-ref (transmission-response-args response) arg))