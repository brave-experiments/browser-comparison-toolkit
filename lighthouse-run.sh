#!/usr/bin/env bash

iteration=$1

lighthouse-batch --file scenarios/fullset.txt \
	--out lighthouse/opera/$iteration/ \
	--params "--max-wait-for-load 200000 --preset perf --emulated-form-factor desktop --throttling-method provided --chrome-flags=\"--disable-sync --disable-background-networking\" "
