+++
title = "Nanopore Basecalling"
author = ["htafer"]
date = 2019-02-08
tags = ["genomics", "metagenomics", "ONT", "nanopore", "sequencing", "bioinformatics", "tutorial", "albacore", "guppy", "nvidia", "MX150", "IGP", "CUDA", "CUDNN", "docker"]
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

I have a laptop with an intel integraded graphics and a MX150 video
card.  Before using the MX150 for basecalling, I configured my system
to use the integrated for display and the nvidia card for
compute. Base Ubuntu configuration for the t480 was taken from the
great [Luca's Blog](https://www.aqu.lu/2018/08/15/t480-configs.html). Since I have Ubuntu 18.04 but Guppy's GPU-version
is currently only working in Ubuntu under Ubuntu 16.04 I followed the
same path as the recently blog post of [Winston Koh](https://medium.com/@kepler%5F00/nanopore-gpu-basecalling-using-guppy-on-ubuntu-18-04-and-nvidia-docker-v2-with-a-rtx-2080-d875945e5c8d).  He uses a nvidia
docker image with cuda and CNN under Ubuntu 16 and subsequently
installs guppy via the dpkg installer.

We first configured the Nvidia/Intel dual GPU system as reported in
[alexlee-gk gist](https://gist.github.com/alexlee-gk/76a409f62a53883971a18a11af93241b).

A list of annotated command is found below:

```bash
# Download nvidia driver https://www.nvidia.com/Download/index.aspx?lang=en-us
sudo bash ./NVIDIA-Linux-x86_64-410.93.run --no-opengl-files
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 1</span>:
  Driver installation in the laptop
</div>

The Nvidia-Docker installation is covered by [SH Tsang Blog Post](https://medium.com/@sh.tsang/docker-tutorial-5-nvidia-docker-2-0-installation-in-ubuntu-18-04-cb80f17cac65).
Since I had an older version of docker I had to purge it first

```bash
sudo apt purge docker*
sudo apt-get remove docker docker-engine docker.io containerd runc
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 2</span>:
  Deinstallation of older docker version
</div>

Next step was the installation of docker and the needed image

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
apt-cache madison nvidia-docker2 nvidia-container-runtime
sudo apt-get install nvidia-docker2=2.0.3+docker18.09.2-1
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 3</span>:
  Installation and setting of Nvidia-docker
</div>

A test of the docker image with nvidia-smi returns the expected image:

{{< figure src="/img/nvidia-smi.png" caption="Figure 1: Output of `sudo docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi`" >}}

We then pull the image containg cuda, cudnn and ubuntu-16.04 and start it

```bash
sudo docker pull nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
sudo docker run --runtime=nvidia --name guppy_gpu -i -t -v /home/htafer/work/zenity/fast5/:/fast5 \
nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04 /bin/bash
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 4</span>:
  Pulling a ubuntu-16.04 image with nvidia,cuda and cudnn pre-configured, starting it and mounting the data on the directory /fast5  in the image
</div>

Inside the container, we install the gpu-enable guppy version

```bash
wget -q https://mirror.oxfordnanoportal.com/s1oftware/analysis/ont_guppy_cpu_2.3.3-1~xenial_amd64.deb
dpkg -i ont_guppy_2.3.1-1~xenial_amd64.deb --ignore-depends=nvidia-384,libcuda1-384
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 5</span>:
  Installation of guppy in the container
</div>

Finally we can start the basecalling on cpu and gpu

```bash
#CPU
guppy_basecaller --input_path . --save_path . --flowcell FLO-MIN106 --kit SQK-LSK109
#GPU
guppy_basecaller --input_path . --save_path . --flowcell FLO-MIN106 --kit SQK-LSK109 -x cuda:0
```

<div class="src-block-caption">
  <span class="src-block-number">Code Snippet 6</span>:
  CPU/GPU-based basecalling with guppy
</div>

Basecalling on the MX150 is approximately **6-8x faster than on my laptop i7-8550**. Champagne!
