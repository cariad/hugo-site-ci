#!/bin/bash -e

li="\033[1;34m•\033[0m "  # List item
nk="\033[0;31m⨯\033[0m "  # Not OK
ok="\033[0;32m✔️\033[0m "  # OK

build=1

LOCAL_IMAGE_NAME=cariad/hugo-ci:local
export LOCAL_IMAGE_NAME

while [[ ${1} = -* ]]; do
  arg=${1}
  shift

  case ${arg} in
    --image)
      build=0
      LOCAL_IMAGE_NAME="${1:?}"
      shift
      ;;

    *)
      echo "Unexpected argument: ${arg:?}"
      exit 1
      ;;
  esac
done

function clean() {
  echo -e "${li:?}Cleaning…"
  rm -f  config.toml
  rm -rf public
  rm -rf resources
  rm -rf subdirectory
}

clean

if [[ "${build:?}" == 1 ]]; then
  echo -e "${li:?}Pulling \"cariad/hugo-ci:latest\"…"
  docker pull cariad/hugo-ci:latest

  echo -e "${li:?}Building \"cariad/hugo-ci:local\"…"
  docker build                         \
    --cache-from cariad/hugo-ci:latest \
    --tag        "${image:?}"          \
    .
fi

echo -e "${li:?}Arranging tests…"
mkdir public
echo 'title = "My New Hugo Site"' > config.toml
mkdir subdirectory
echo 'title = "My New Hugo Site"' > subdirectory/config.toml

echo -e "${li:?}Starting containers…"
docker-compose up

echo -e "${li:?}Verifying results…"

expect=7

actual=$(find public | wc -l)
if [ ! "${actual:?}" -eq "${expect:?}" ]; then
  echo -e "${nk:?}Expected ${expect:?} files in ./public but found ${actual:?}."
fi

actual=$(find subdirectory/public | wc -l)
if [ ! "${actual:?}" -eq "${expect:?}" ]; then
  echo -e "${nk:?}Expected ${expect:?} files in ./subdirectory/public but found ${actual:?}."
fi

set +e
clean
set -e

echo -e "${ok:?}OK!"