#!/usr/bin/env bash
set -x
nohup cargo build --workspace --verbose --release 2>/dev/null 1>/dev/null &
nohup cargo build --tests --verbose --release 2>/dev/null 1>/dev/null &
jobs
wait

