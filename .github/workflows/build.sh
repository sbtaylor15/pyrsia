#!/usr/bin/env bash
set -x
nohup cargo build --workspace --verbose --release 1>/tmp/ws.log 2>&1 &
nohup cargo build --tests --verbose --release 1>/tmp/tests.log 2>&1 &
jobs
wait

echo cargo build --workspace --verbose --release
cat /tmp/ws.log

echo cargo build --tests --verbose --release
cat /tmp/tests.log

