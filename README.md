## installation

install https://crystal-lang.org/ and run `make install`

## usage

```sh
$ cat domains.txt
google.com
qwueyiqw.com
github.com
qoiwpuewqe.net
$ dchecker < domains.txt > available.txt # or cat domains.txt | dchecker > available.txt
$ cat available.txt
qwueyiqw.com
qoiwpuewqe.net
```
