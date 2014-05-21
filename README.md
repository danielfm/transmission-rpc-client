# Transmission RPC Client for Racket

This library provides a simple [Transmission RPC](https://trac.transmissionbt.com/wiki/rpc)
client for Racket.

## Installation

To install this library from github:

````bash

$ raco pkg install git://github.com/danielfm/transmission-rpc-client
````

## Usage

To import the library:

````racket

(require transmission-rpc-client)
````

In the next example, we'll send a `session-stats` request and fetch the current
number of active torrents.

````racket

;; First, create a session that points to the desired Transmission RPC endpoint
(define url "http://localhost:9091/transmission/rpc")
(define session (transmission-session url))

;; Returns a jsexpr with current session stats
(define stats (transmission-request! session "session-stats" null))

;; Retrieves a specific response argument
(transmission-response-arg stats 'torrentCount)
````

And here's how we get the progress of all active torrents along with their name:

````racket

;; Sends a request with tag number = 1234
(define progress
  (transmission-request! session "torrent-get"
                         (hash 'fields '("name" "percentDone"))
                         1234))

;; Returns a list where each entry is a hash containing the keys
;; 'name (string) and 'percentDone (number 0 < n < 1)
(define torrents (transmission-response-arg progress 'torrents))

;; Fetches the first torrent's progress
(hash-ref (first torrents) 'percentDone)

;; The response tag number should match the one sent in the request (1234)
(transmission-response-tag progress)
````

Please read the [Transmission RFC spec](https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt)
to know the supported requests, their parameters and response.

## License

Copyright (C) Daniel Martins

Distributed under the New BSD License. See LICENSE for further details.
