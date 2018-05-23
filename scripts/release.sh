#!/bin/bash

set -e

TAG=$1
SOFT=${2:-$(basename $(pwd))}
SOFTAG="${SOFT}-${TAG}"
[[ $# -gt 2 ]] && SOFTAG="${SOFTAG}r$2"

echo Releasing $SOFTAG

rm -vf *.tar* /tmp/*.tar*

if $(grep -q "v$TAG" <<< $(git tag))
then
    echo -e "\n!!! Ce tag existe !!!\n"
    git checkout "v$TAG"
    git submodule update --init
else
    git tag -s "v$TAG" -m "Release v$TAG"
fi

if [[ -d cmake && -x cmake/git-archive-all.sh ]]
then
    ./cmake/git-archive-all.sh --prefix "${SOFTAG}/" -v "${SOFTAG}.tar"
else
    git archive --format=tar --prefix="${SOFTAG}/" HEAD > ${SOFTAG}.tar
fi

echo $TAG > .version
tar rf "${SOFTAG}.tar" --transform "s=.=${SOFTAG}/.="   .version
gzip "${SOFTAG}.tar"

gpg --armor --detach-sign "${SOFTAG}.tar.gz"

echo -e "git push --tags"
TAGS=$(git tag -l|tail -n2|sed ':a;N;$!ba;s/\n/../g')
echo -e "git log --grep='Merge pull request #' --date-order --pretty='format:- %b' $TAGS"
echo -e "# Draft new release"
