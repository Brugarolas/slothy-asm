#!/usr/bin/env sh
set -e

echo "* tutorial-3a.py (Straightline optimization)"
python3 tutorial-3a.py >/dev/null

echo "* tutorial-3b.py (Clean code)"
python3 tutorial-3b.py >/dev/null

echo "* tutorial-4.py (Software pipelining)"
python3 tutorial-4.py >/dev/null

echo "* tutorial-5.py (Running SLOTHY with LLVM-MCA)"
python3 tutorial-5.py >/dev/null

echo "* tutorial-6.py (Optimizing a full Neon NTT)"
python3 tutorial-6.py >/dev/null

echo "* tutorial-7.py (Optimizing larger pieces of code)"
python3 tutorial-7.py >/dev/null

echo "Done :-)"
