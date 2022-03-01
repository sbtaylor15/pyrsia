#!/usr/bin/env bash
set -x
nohup cargo build --workspace --verbose --release &
nohup cargo build --tests --verbose --release 1>/tmp/tests.log 2>&1 &
jobs
wait

echo cargo build --tests --verbose --release
cat /tmp/tests.log

