# Transmission RPC Client for Racket

This library provides a simple [Transmission RPC](https://trac.transmissionbt.com/wiki/rpc)
client for Racket.

## Installation

This package is not yet available for download via [PLaneT](http://planet.racket-lang.org/).
Just hang in there!

## Usage

To import the library:

````racket

(require transmission-rpc-client)
````

In the next example, we'll send a `session-stats` request and fetched the number
of currently active torrents.

````racket

;; First, create a session that points to the desired Transmission RPC endpoint
(define url "http://localhost:9091/transmission/rpc")
(define session (transmission-session url))

;; Returns a jsexpr with current session stats
(define stats (transmission-request! session "session-stats" null))

;; Retrieving a specific response argument
(transmission-response-arg stats 'torrentCount)
````

And here's how we get the progress of all active torrents along with their name:

````racket

;; Assuming we already have a session...

;; Sends a request with tag number = 1234
(define progress
  (transmission-request! session "torrent-get"
                         (hash 'fields '("name" "percentDone"))
                         1234))

;; Returns a list where each entry is a hash containing the keys
;; 'name (string) and 'percentDone (number 0 < n < 1)
(transmission-response-arg progress 'torrents)

;; The response tag number should match the one sent in the request (1234)
(transmission-response-tag progress)
````

## License

Copyright (C) Daniel Martins

Distributed under the New BSD License. See LICENSE for further details.
