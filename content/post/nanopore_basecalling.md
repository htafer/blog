+++
title = "Nanopore Basecalling"
author = ["htafer"]
date = 2018-02-20
tags = ["genomics", "metagenomics", "ONT", "nanopore", "sequencing", "bioinformatics", "tutorial", "albacore", "guppy"]
draft = false
weight = 1003
+++

## Context {#context}

We are currently sequencing old (500-1500 years old) statues,
manuscripts and parchments in order to assess which microorganisms
grow/grew on them. To this aim illumina, torrent and now nanopore
sequencing are being used. Nanopore sequencing is being done in our
lab. The main problem once we got the fast5 data is to basecall them
and do further processing. The next few paragraph present an overview
of the step we are doing:


## Basecalling on CPU {#basecalling-on-cpu}

Until recently Albacore was the official basecaller from ONT. This is
now archived and guppy is the new preferred software for everything
basecalling. Guppy can run both on the CPU and GPU (Nvidia only).
Installation under ubuntu 16.04 is relatively easy and well explained
[here](https://community.nanoporetech.com/protocols/Guppy-protocol-preRev/v/gpb%5F2003%5Fv1%5Frevg%5F14dec2018). Since we do not have access to a GPU we will install the
CPU-based guppy.

```bash
sudo apt-get update
sudo apt-get install wget lsb-release
export PLATFORM=$(lsb_release -cs)
wget -O- https://mirror.oxfordnanoportal.com/apt/ont-repo.pub | sudo apt-key add -
echo "deb http://mirror.oxfordnanoportal.com/apt ${PLATFORM}-stable non-free" | sudo tee /etc/apt/sources.list.d/nanoporetech.sources.list
sudo apt-get update
sudo apt install ont-guppy-cpu
```

Guppy has preconfigured configuration scripts that can be specified by setting the
--flow-cell and --kit on the command line:

```bash
guppy_basecaller -r \ #recursive search for fast5 files
		 --input_path /media/htafer/backup8TB/nanopore/20181003_1027_/fast5/ \ # input directory
		 --save_path . \ #output directory
		 --flowcell FLO-MIN106 \ # Flow cell type
		 --kit SQK-LSK108 \ #kit used during sequencing
		 --cpu_threads_per_caller 8 #thread number
```

A 6 years old AMD AMD FX-8370E is basecalling approx. 5-10 reads/s,
approximately the speed of a laptop with a 2018 i7-8550.


## Basecalling on MX150 Nvidia {#basecalling-on-mx150-nvidia}


## Basecalling on a G3 instance {#basecalling-on-a-g3-instance}
