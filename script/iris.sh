#!/bin/bash

cd $(dirname $0)/..
plenv exec carton exec perl -Ilib script/iris.pl
