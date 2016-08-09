#!/bin/bash

cd $(dirname $0)/..
# plenv exec carton exec prove -It -lv t/test.t
plenv exec carton exec prove -It -lvr t
