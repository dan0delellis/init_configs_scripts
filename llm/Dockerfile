ARG ARCH="-march=x86-64-v3"
ARG SOURCEDIR="/work/source"
ARG OUTDIR="/work/output"
ARG BINDIR="/work/bin"

##FETCHER
	FROM ubuntu:26.04 as fetcher

	ARG OUTDIR
	ARG BINDIR

	WORKDIR /work
	RUN mkdir -p $OUTDIR $BINDIR

	RUN apt-get update

	RUN apt-get install -y \
		curl \
		git \
		jq

	RUN rm -rf /var/lib/apt/lists/*

	ADD includes/clone_latest.sh /work/bin/clone_latest.sh

	RUN bash /work/bin/clone_latest.sh
## end of fetcher

## start build-sycl
	FROM intel/oneapi-toolkit:2026.1.0-devel-ubuntu26.04 AS builder-sycl

	ARG ARCH
	ARG SOURCEDIR
	ARG OUTDIR

	RUN mkdir -p $OUTDIR $SOURCEDIR

	WORKDIR /work/source

	RUN apt-get update && apt-get upgrade -y

	COPY --from=fetcher /work/source /work/source

	RUN ( set -a && \
	 unset CC CXX SYCL_ROOT FLAGS SETVARS_COMPLETED && \
	 . /opt/intel/oneapi/setvars.sh --force && \
	 cmake -B build-sycl \
	   -DGGML_SYCL=ON \
	   -DGGML_BACKEND_DL=ON \
	   -DGGML_NATIVE=OFF \
	   -DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
	   -DCMAKE_INSTALL_RPATH="\$ORIGIN" \
	   -DCMAKE_C_COMPILER=icx \
	   -DCMAKE_CXX_COMPILER=icpx \
	   -DCMAKE_C_FLAGS="-march=${TARGET_MARCH}" \
	   -DCMAKE_CXX_FLAGS="-march=${TARGET_MARCH}" \
	   -DCMAKE_BUILD_TYPE=Release && \
	 cmake --build build-sycl --config Release -j $(nproc) \
	)

	# the llama.cpp devs do some spoony shit overriding what end users do
	# this makes cmake --install copy binaries so some default path
	# even if it was called with a specific install point

	# find all compiled binaries and copy them to /work/output
	RUN find build-sycl/bin/ -maxdepth 1 -type f -exec cp -vP {} /work/output \;

	# find all compiled/linked modules in the build directory and copy those too
	RUN find build-sycl/ -name "*.so*" -exec cp -P {} /work/output \;

	#intel keeps fucking around with module names and shit so we're gonna just brute force our way into finding dependencies

	# might be worth exporting this to a script
	# search for packages which provide files discovered in the output of:
	# reading every string in the compiled binaries
	# that ends in .so or .so.X
	# with duplicates filtered out
	# ignore the errors from dpkg -S (ex: 'libllama.so' is not from a package)
	# remove lines that have more than one word (ex: 'replaced by...')
	# and print out just the package name
	# and write the unique results to a tmpfile

	RUN dpkg -S \
	 $(strings /work/output/*  | egrep '\.so(\..+)?$' | sort | uniq ) 2>/dev/null \
	 | awk -F ":" {'print $1'} | egrep -v '\s[^\s]+\s' | sort | uniq > /tmp/found_packages.txt

	RUN test -s /tmp/found_packages.txt

#end of build-sycl

#build-vulkan
	FROM ubuntu:26.04 as builder-vulkan
	ARG ARCH
	ARG SOURCEDIR
	ARG OUTDIR

	RUN mkdir -p $OUTDIR $SOURCEDIR

	WORKDIR /work/source

	RUN apt-get update && apt-get install -y \
		build-essential \
		cmake \
		curl \
		git \
		glslang-tools \
		glslc \
		jq \
		libvulkan-dev \
		pkg-config  \
		spirv-headers \
		vulkan-tools

	COPY --from=fetcher /work/source /work/source

	RUN cmake -B build-vulkan \
		-DGGML_VULKAN=ON \
		-DGGML_BACKEND_DL=ON \
		-DGGML_NATIVE=OFF \
		-DCMAKE_INSTALL_RPATH="\$ORIGIN" \
		-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
		-DCMAKE_C_FLAGS="${ARCH}" \
		-DCMAKE_CXX_FLAGS="${ARCH}" \
		-DCMAKE_BUILD_TYPE=Release && \
		cmake --build build-vulkan --config Release -j $(nproc)

	RUN find build-vulkan/bin -maxdepth 1 -type f -executable -exec cp -vP {} /work/output/ \;

	RUN find build-vulkan -name "*.so*" -exec cp -vP {} /work/output/ \;

#runtime guy
	FROM ubuntu:26.04 as final
	ENV DEBIAN_FRONTEND=noninteractive

	# install the intel repo and bleeding-edge mesa ppa
	RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends wget gpg ca-certificates && \
		wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
			| gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null && \
		echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
			| tee /etc/apt/sources.list.d/oneAPI.list && \
		wget -qO- 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xeb8b81e14da65431d7504ea8f63f0f2b90935439' && \
			| gpg --dearmor --output /etc/apt/keyrings/mesa.gpg && \
		echo "deb [signed-by=/usr/share/keyrings/mesa.gpg] deb https://ppa.launchpadcontent.net/kisak/kisak-mesa/ubuntu resolute main " \
			| tee /etc/apt/sources.list.d/mesa.list && \
		apt-get update

	# get the discovered packages
	COPY --from=builder-sycl /tmp/found_packages.txt /tmp/found_packages.txt
	# Install what discovery logic found (Minimal isolated runtimes + drivers)
	RUN apt-get install -y --no-install-recommends \
		libze-intel-gpu1 \
		libze1 \
		libgomp1 \
		intel-opencl-icd \
		$(cat /tmp/found_packages.txt) \
		libvulkan1 clinfo mesa-vulkan-drivers wget gnupg

	RUN rm -rf /var/lib/apt/lists/*

	#deploy wrapper script for easy backend swapping
	ADD includes/llama-wrapper /app/bin/llama-wrapper
	RUN chmod +x /app/bin/llama-wrapper

	# Copy isolated build output files
	COPY --from=builder-sycl /work/output /app/sycl

	COPY --from=builder-vulkan /work/output /app/vulkan

	WORKDIR /app

	CMD ["/bin/bash"]
#end of runtime guy
