#!/usr/bin/env bash

# Download and install sccache in the Linux specific cargo directories
mkdir -p /home/runner/.cargo/bin 2>/dev/null
curl -o- -sSLf https://github.com/mozilla/sccache/releases/download/v0.2.15/sccache-v0.2.15-x86_64-unknown-linux-musl.tar.gz | tar xzf -
mv sccache-v0.2.15-x86_64-unknown-linux-musl/sccache /home/runner/.cargo/bin/sccache 
chmod 755 /home/runner/.cargo/bin/sccache
