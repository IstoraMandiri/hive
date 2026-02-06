## Build Nethermind-ETC with plugin from source
## Stage 1: Build plugin from source
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS plugin-builder

ARG PLUGIN_REPO=https://github.com/IstoraMandiri/nethermind-etc-plugin.git
ARG PLUGIN_BRANCH=main

RUN git clone --depth 1 --branch ${PLUGIN_BRANCH} ${PLUGIN_REPO} /src
WORKDIR /src
RUN dotnet publish src/Nethermind.EthereumClassic/Nethermind.EthereumClassic.csproj \
    -c Release -o /plugin

## Stage 2: Runtime image
FROM mcr.microsoft.com/dotnet/runtime-deps:9.0-noble

# Nethermind fork with PoW support restored
ARG NETHERMIND_TAG=v1.36.0-etc
ARG NETHERMIND_REPO=diega/nethermind_etc

RUN apt-get update && apt-get install -y jq curl wget unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download Nethermind binary from PoW fork
RUN DOWNLOAD_URL=$(curl -sL https://api.github.com/repos/${NETHERMIND_REPO}/releases/tags/${NETHERMIND_TAG} \
    | jq -r '.assets[] | select(.name | endswith("-linux-x64.zip")) | .browser_download_url') && \
    mkdir -p /nethermind && \
    cd /tmp && \
    wget -q "$DOWNLOAD_URL" -O nethermind.zip && \
    unzip -q nethermind.zip -d /nethermind && \
    rm nethermind.zip && \
    chmod +x /nethermind/nethermind

# Install freshly built ETC plugin
COPY --from=plugin-builder /plugin/Nethermind.EthereumClassic.dll /nethermind/plugins/

# Create version.txt
RUN /nethermind/nethermind --version \
    | head -1 | sed 's/Version:[[:space:]]*\(.*\)/\1/' > /version.txt && \
    echo " + ETC Plugin (source build)" >> /version.txt

# Add genesis mapper script, startup script, and enode URL retriever script
ADD genesis.json /genesis.json
ADD mapper.jq /mapper.jq
ADD mkconfig.jq /mkconfig.jq
ADD nethermind-etc.sh /nethermind-etc.sh
ADD enode.sh /hive-bin/enode.sh

# Set execute permissions for scripts
RUN chmod +x /nethermind-etc.sh /hive-bin/enode.sh

# Expose networking ports
EXPOSE 8545 30303 30303/udp

ENV NETHERMIND_HIVECONFIG_ENABLED=true
ENTRYPOINT ["/nethermind-etc.sh"]
