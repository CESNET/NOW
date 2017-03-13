#! /bin/sh -xe

if test -z "$1"; then
  echo "Usage: $0 VERSION"
  exit 1
fi

v="$1"

sed -e "/VERSION/ s/'[^']*'/'${v}'/" -i version.rb
vim NOTICE

git commit -a -m "Release ${v}"
git tag -a v${v} -m "Release ${v}."
git push --tags origin HEAD
