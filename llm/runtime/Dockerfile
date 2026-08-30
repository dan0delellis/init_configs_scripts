ARG DEB_FE="noninteractive"
ARG GUY="dandelellis/custom-llama-herd:latest"

FROM ${GUY} AS custom_llama_herd
#cuda runtime guy
	FROM nvidia/cuda:13.3.1-runtime-ubuntu26.04 AS runner-cuda

	ARG DEB_FE
	RUN apt-get update && apt install -y libgomp1

	COPY --from=custom_llama_herd /app /app
	ADD includes/llama-wrapper /app/bin/llama-wrapper
	RUN chmod +x /app/bin/llama-wrapper
# end cuda runtime guy

#runtime guy
	FROM ubuntu:26.04 as runner-general
	ENV DEBIAN_FRONTEND=noninteractive

	# Copy isolated build output files and any misc files that may be needed
	COPY --from=custom_llama_herd /app /app

	#deploy wrapper script for easy backend swapping
	ADD includes/llama-wrapper /app/bin/llama-wrapper
	RUN chmod +x /app/bin/llama-wrapper

	# install the intel repo and bleeding-edge mesa ppa
	RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends wget gpg ca-certificates && \
		wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
			| gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null && \
		echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
			| tee /etc/apt/sources.list.d/oneAPI.list && \
		wget -qO- 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xeb8b81e14da65431d7504ea8f63f0f2b90935439' \
			| gpg --dearmor --output /usr/share/keyrings/mesa.gpg && \
		echo "deb [signed-by=/usr/share/keyrings/mesa.gpg] https://ppa.launchpadcontent.net/kisak/kisak-mesa/ubuntu resolute main " \
			| tee /etc/apt/sources.list.d/mesa.list && \
		apt-get update


	# Install what discovery logic found (Minimal isolated runtimes + drivers)
	RUN ONEAPI=$(cat /app/misc/found_packages.txt) && apt-get install -y --no-install-recommends \
		libze-intel-gpu1 \
		libze1 \
		libgomp1 \
		intel-opencl-icd \
		$ONEAPI \
		libvulkan1 clinfo mesa-vulkan-drivers wget gnupg

	RUN rm -rf /var/lib/apt/lists/*

	WORKDIR /app

	CMD ["/bin/bash"]
#end of runtime guy
