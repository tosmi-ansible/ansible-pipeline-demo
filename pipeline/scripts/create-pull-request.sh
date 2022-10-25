#!/bin/bash

set -eu -o pipefail

echo "Verbose           : ${PARAM_VERBOSE}"
echo "Source branch     : ${PARAM_SOURCE_BRANCH}"
echo "Destination branch: ${PARAM_DESTINATION_BRANCH}"
echo "Git token         : ${PARAM_GIT_TOKEN}"
echo "Git URL           : ${PARAM_GIT_URL}"

if [ "${PARAM_VERBOSE}" = "true" ] ; then
    set -x
fi

RED="\e[31m"
YELLOW="\e[33m"
BOLD="\033[1m"
NC="\e[0m"

error() {
    local MESSAGE="$1"
    local DATE

    DATE=$(date "+%d/%b/%Y:%H:%M:%S %z")

    # shellcheck disable=SC3037
    echo -e "[${DATE}] ${RED}ERROR:${NC} $MESSAGE" >&2
    exit 1
}

info() {
    local MESSAGE="$1"
    local DATE

    DATE=$(date "+%d/%b/%Y:%H:%M:%S %z")

    # shellcheck disable=SC3037
    echo -e "[${DATE}] ${YELLOW}INFO:${NC} $MESSAGE" >&2

    return 0
}

PATH=/bin:/usr/bin

HTTP_STATUS=$(/usr/bin/curl -o /dev/null -kqs -w "%{http_code}" \
               -H 'Content-Type: application/json' \
               -H "Authorization: Bearer ${PARAM_GIT_TOKEN}" \
               "${PARAM_GIT_URL}"/api/v1/repos/developer/ansible-example-collection/pulls \
               -d "
               {
                 \"base\": \"${PARAM_DESTINATION_BRANCH}\",
                 \"head\": \"${PARAM_SOURCE_BRANCH}\",
                 \"body\": \"We want to merge into ${PARAM_DESTINATION_BRANCH}.\",
                 \"title\": \"Merge into ${PARAM_DESTINATION_BRANCH}\"
               }")

case "$HTTP_STATUS" in
    "409")
	error "Pull request already exists!"
	;;
    "404")
	error "Git instance returned 404: not found!"
	;;
    "201")
	info "Pull request successfully created.!"
	;;
    *)
	error "Unkown HTTP status code ${HTTP_STATUS}"
	;;
esac
