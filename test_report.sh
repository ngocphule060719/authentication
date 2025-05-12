#!/usr/bin/env bash

# For MacOS
if ! brew list | grep -q 'lcov'; then
    echo "==============> run : brew install lcov"
    brew install lcov
fi

echo "==============> run : flutter test --coverage"
fvm flutter test --coverage

path="test_report"

echo "==============> run : genhtml coverage/lcov.info"
genhtml coverage/lcov.info -o $path

echo "==============> open report"
open $path/index.html