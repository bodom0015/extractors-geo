#!/bin/sh

# variables that can be set
# DEBUG   : set to echo to print command and not execute
# PUSH    : set to push to push, anthing else not to push. If not set
#           the program will push if master or develop.
# PROJECT : the project to add to the image, default is clowder
# VERSION : the list of tags to use, if not set this will be based on
#           the branch name.

# DEBUG=echo

# set default for clowder
PROJECT=${PROJECT:-"clowder"}

# find out version and if we should push
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
VERSION=${VERSION:-""}
if [ "$VERSION" = "" ]; then
  if [ "$BRANCH" = "master" ]; then
    PUSH=${PUSH:-"push"}
    VERSION="${VERSION} latest"
  elif [ "$BRANCH" = "develop" ]; then
    PUSH=${PUSH:-"push"}
    VERSION="${VERSION} develop"
  elif [ "$( echo $BRANCH | sed -e 's#^release/.*$#release#')" = "release" ]; then
    # PUSH=${PUSH:-"push"}
    VERSION="$( echo $BRANCH | sed -e 's#^release/\(.*\)$#\1#' )"
  else
    PUSH=${PUSH:-""}
  fi
else
  PUSH=${PUSH:-""}
fi

# keep track of which latest amde
LATEST=""

# helper to create the docker container
# $1 - folder that contains the Dockerfile
# $2 - name of docker image
# $3 - name of Dockerfile
create() {
  if [ -z "$1" ]; then echo "Missing repo/Dockerfile name."; exit -1; fi
  if [ -z "$2" ]; then echo "Missing name for $1."; exit -1; fi
  if [ -z "$3" ]; then echo "Missing dockerfile for $2."; exit -1; fi

  # create image using temp id
  local ID=$(uuidgen)
  ${DEBUG} docker build  --tag $$ --file $1/$3 $1
  if [ $? -ne 0 ]; then
    echo "FAILED build of $1/Dockerfile"
    exit -1
  fi

  # tag all versions
  for v in $VERSION; do
    if [ "$PROJECT" = "" ]; then
      ${DEBUG} docker tag $$ ${2}:${v}
    else
      for p in ${PROJECT}; do
        NAME=$2
        ${DEBUG} docker tag $$ ${p}/${NAME}:${v}
        if [ "$PUSH" = "push" ]; then
          ${DEBUG} docker push ${p}/${NAME}:${v}
        fi
        ${DEBUG} docker rmi ${p}/${NAME}:${v}
      done
    fi
  done

  # tag version as latest, but don't push
  if [ ! "$BRANCH" = "master" ]; then
    if [ "$PROJECT" = "" ]; then
      ${DEBUG} docker tag $$ ${2}:latest
      LATEST="$LATEST ${2}:latest"
    else
      for p in ${PROJECT}; do
        NAME=$2
        ${DEBUG} docker tag $$ ${p}/${NAME}:latest
        LATEST="$LATEST ${p}/${NAME}:latest"
      done
    fi
  fi

  # delete image with temp id
  ${DEBUG} docker rmi $$
}

# Create the docker containers
create "./metadata.geotiff"   "extractors-geotiff-metadata" "Dockerfile"
create "./preview.geotiff"     "extractors-geotiff-preview"  "Dockerfile"
create "./preview.geoshp"     "extractors-geoshp-preview"   "Dockerfile"
create "./pycsw.extractor"    "extractors-pycsw" "Dockerfile"
create "./geoserver"    "geoserver" "Dockerfile"
create "./pycsw"	"pycsw" "Dockerfile"

# remove latest tags
for r in $LATEST; do
  ${DEBUG} docker rmi ${r}
done
