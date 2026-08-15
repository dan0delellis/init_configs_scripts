#!/bin/bash

set -xue

USER="${GH_USER:-ggml-org}"
REPO="${GH_REPO:-llama.cpp}"

clone_latest() {
	LATEST=$(curl -s https://api.github.com/repos/${USER}/${REPO}/releases/latest | /usr/bin/jq -r ".tag_name")

	if [ -z "${LATEST}" ]; then
		echo "failed to find the latest release from github.com/${USER}/${REPO}"
		exit 1
	fi

	mkdir source
	git clone -b ${LATEST} --single-branch --depth 1 https://github.com/${USER}/${REPO}.git source
}

git -C source status || clone_latest

mkdir -p source/build
