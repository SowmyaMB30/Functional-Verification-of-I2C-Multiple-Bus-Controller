#!/bin/bash
make clean
make compile
make run_cli GEN_TRANS_TYPE=i2cmb_generator TEST_SEED=random
make merge_coverage
make view_coverage