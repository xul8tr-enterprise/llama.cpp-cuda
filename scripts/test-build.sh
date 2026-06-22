#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CUDA_VERSION=${1:-"12.9.2"}
LLAMA_TAG=${2:-"latest"}

echo -e "${GREEN}llama.cpp CUDA Build Test${NC}"
echo "================================"
echo "CUDA Version: $CUDA_VERSION"
echo "llama.cpp Tag: $LLAMA_TAG"
echo ""

case $CUDA_VERSION in
    12.9.2)
        CUDA_TAG="12.9.2-cudnn-devel-ubuntu24.04"
        ARCHITECTURES="60;61;62;70;72"
        ;;
    13.3.0)
        CUDA_TAG="13.3.0-cudnn-devel-ubuntu24.04"
        ARCHITECTURES="75;80;86;89;90;100;103;110;120;121"
        ;;
    *)
        echo -e "${RED}Error: Unsupported CUDA version $CUDA_VERSION${NC}"
        echo "Supported versions: 12.9.2, 13.3.0"
        exit 1
        ;;
esac

if [ "$LLAMA_TAG" = "latest" ]; then
    echo -e "${YELLOW}Fetching latest llama.cpp release...${NC}"
    LLAMA_TAG=$(curl -s https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    RELEASE_HASH=$(curl -s https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | grep '"target_commitish":' | sed -E 's/.*"([^"]+)".*/\1/')
    echo "Latest release: $LLAMA_TAG (${RELEASE_HASH:0:8})"
else
    RELEASE_HASH=$(curl -s "https://api.github.com/repos/ggml-org/llama.cpp/git/refs/tags/$LLAMA_TAG" | grep '"sha":' | sed -E 's/.*"([^"]+)".*/\1/')
fi

echo ""
echo -e "${YELLOW}Building with:${NC}"
echo "  Docker Image: nvidia/cuda:$CUDA_TAG"
echo "  Architectures: $ARCHITECTURES"
echo ""

rm -rf binaries test-build
mkdir -p binaries/cuda-$CUDA_VERSION

echo -e "${GREEN}Starting Docker build...${NC}"
docker run --rm -v $PWD:/workspace \
    nvidia/cuda:$CUDA_TAG \
    bash -c "
        set -e
        cd /workspace

        echo '=> Installing dependencies...'
        apt-get update -qq
        apt-get install -y -qq git cmake build-essential > /dev/null

        echo '=> Cloning llama.cpp...'
        git clone https://github.com/ggml-org/llama.cpp.git test-build
        cd test-build
        git checkout $RELEASE_HASH

        echo '=> Configuring build...'
        mkdir -p build
        cd build

        cmake .. \
            -DGGML_CUDA=ON \
            -DCMAKE_CUDA_ARCHITECTURES='$ARCHITECTURES' \
            -DCMAKE_BUILD_TYPE=Release \
            -DGGML_NATIVE=OFF \
            -DGGML_BACKEND_DL=ON \
            -DGGML_CPU_ALL_VARIANTS=ON > /dev/null

        echo '=> Building (this may take several minutes)...'
        cmake --build . --config Release -j\$(nproc)

        echo '=> Copying binaries...'
        cd /workspace
        cp -r test-build/build/bin/* binaries/cuda-$CUDA_VERSION/ 2>/dev/null || true
        cp test-build/build/ggml/src/libggml.so binaries/cuda-$CUDA_VERSION/ 2>/dev/null || true
        cp test-build/build/src/libllama.so binaries/cuda-$CUDA_VERSION/ 2>/dev/null || true

        if [ -d test-build/build/lib ]; then
            find test-build/build/lib -name '*.so*' -exec cp {} binaries/cuda-$CUDA_VERSION/ \; 2>/dev/null || true
        fi

        echo '=> Bundling CUDA runtime libraries...'
        cd /workspace/test-build/build/bin
        for f in *; do
            if [ -f \"\$f\" ]; then
                ldd \"\$f\" 2>/dev/null | grep /usr/local/cuda | awk '{print \$3}' >> /tmp/cuda_libs.txt
            fi
        done 2>/dev/null || true
        sort -u /tmp/cuda_libs.txt 2>/dev/null | while read lib; do
            if [ -n \"\$lib\" ] && [ -f \"\$lib\" ]; then
                cp -v \"\$lib\" /workspace/binaries/cuda-$CUDA_VERSION/
            fi
        done 2>/dev/null || true

        echo '=> Creating version info...'
        cat > binaries/cuda-$CUDA_VERSION/VERSION.txt << EOF
llama.cpp version: $LLAMA_TAG
CUDA version: $CUDA_VERSION
Architectures: $ARCHITECTURES
Build date: \$(date -u +%Y-%m-%d)
Build hash: $RELEASE_HASH
EOF

        echo '=> Build complete!'
    "

echo ""
echo -e "${GREEN}Creating tarball...${NC}"
cd binaries
tar -czf llama.cpp-$LLAMA_TAG-cuda-$CUDA_VERSION.tar.gz cuda-$CUDA_VERSION
cd ..

echo ""
echo -e "${GREEN}✓ Build successful!${NC}"
echo ""
echo "Binaries location: binaries/cuda-$CUDA_VERSION/"
echo "Tarball: binaries/llama.cpp-$LLAMA_TAG-cuda-$CUDA_VERSION.tar.gz"
echo ""
echo "Built binaries:"
ls -lh binaries/cuda-$CUDA_VERSION/

rm -rf test-build

echo ""
echo -e "${GREEN}Test build complete!${NC}"
