#! /bin/bash



global_var="$(dirname "$0")"
. "$global_var/global_var.sh"

SCOUT_OUT=scout_dep
SCOUT_OUT_FOLDER=$MYPWD/$SCOUT_OUT

LIBPOSTAL_FOLDER=pkg-libpostal
LIBPOSTAL_BUILD=libpostal
LIBPOSTAL_GIT="https://github.com/rinigus/pkg-libpostal.git"

LIBMARISA_FOLDER=marisa-trie
LIBMARISA_BUILD=
LIBMARISA_GIT="https://github.com/s-yata/marisa-trie.git"

LIBOSMSCOUT_FOLDER=libosmscout
LIBOSMSCOUT_BUILD=libosmscout
LIBOSMSCOUTMAP_BUILD=libosmscout-map
LIBOSMSCOUT_GIT="https://github.com/rinigus/libosmscout.git"
