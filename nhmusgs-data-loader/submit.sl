#!/bin/bash
#SBATCH -N 1
#SBATCH -A wbeep
#SBATCH --image=nhmusgs/data-loader:latest

srun -n 1 shifter --volume=/caldera/projects/usgs/water/impd/nhm:/nhm /usr/local/bin/nhm
