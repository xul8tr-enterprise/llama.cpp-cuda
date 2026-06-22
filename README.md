# llama.cpp CUDA Builds

> **Fork of** [ai-dock/llama.cpp-cuda](https://github.com/ai-dock/llama.cpp-cuda)

This repository automatically builds [llama.cpp](https://github.com/ggml-org/llama.cpp) with CUDA support for multiple NVIDIA GPU architectures and CUDA versions.

**Changes from original:**
- Dual CUDA version builds — CUDA 12.9 (legacy GPUs) and CUDA 13.3 (modern GPUs), splitting GPU architectures by version
- Uses `ubuntu-slim` runner (amd64) for faster CI
- Bundles CUDA runtime libraries directly into tarball (libcudart, libcublas, etc.)
- CPU multi-architecture dispatch via `GGML_CPU_ALL_VARIANTS=ON` (runtime CPU feature detection)
- Conditional `maximize-build-space` (arm64 only)

## Why This Repository?

The official llama.cpp repository does not provide pre-built CUDA binaries. This repository fills that gap by:

- Building llama.cpp with CUDA support for multiple CUDA toolkit versions
- Supporting a wide range of NVIDIA GPU architectures (compute capability 6.0+)
- Automatically tracking upstream llama.cpp releases
- Providing ready-to-use binaries via GitHub releases

## Supported Configurations

### CUDA Versions

| CUDA | GPU Architectures | Min. Driver |
|------|------------------|-------------|
| 12.9 | sm_60, sm_61, sm_62, sm_70, sm_72 | >= 575.51.03 |
| 13.3 | sm_75, sm_80, sm_86, sm_89, sm_90, sm_100, sm_103, sm_110, sm_120, sm_121 | >= 610.43.02 |

### Host CPU Architectures

Each release publishes one tarball per combination of CUDA version and host CPU architecture:

| Suffix | Linux platform | Typical hosts |
|--------|----------------|---------------|
| `-amd64` | x86_64 | Most desktops, servers, cloud VMs |
| `-arm64` | aarch64 | Grace Hopper, Grace Blackwell, DGX Spark, Ampere Altra |

### GPU Architectures

#### CUDA 12.9 (legacy GPUs)

| Compute Capability | GPU Examples |
|-------------------|--------------|
| 6.0 | Pascal GP100 (Tesla P100) |
| 6.1 | Titan XP, Tesla P40, GTX 10xx |
| 6.2 | Tesla P40, GTX 10xx |
| 7.0 | Tesla V100 |
| 7.2 | Tegra Xavier |

#### CUDA 13.3 (modern GPUs)

| Compute Capability | GPU Examples |
|-------------------|--------------|
| 7.5 | Tesla T4, RTX 2000 series, Quadro RTX |
| 8.0 | A100 |
| 8.6 | RTX 3000 series |
| 8.9 | RTX 4000 series, L4, L40 |
| 9.0 | H100, H200, GH200 |
| 10.0 | B200, GB200 |
| 10.3 | GB300 |
| 11.0 | DGX Spark (Grace Blackwell) |
| 12.0 | RTX Pro 6000, RTX 5000 series |
| 12.1 | RTX 5000 series |

## Choosing a CUDA Version

- Use **CUDA 12.9** if you have a GPU with compute capability 6.0+ (Pascal, Volta — Tesla P100, GTX 10xx, Tesla V100, etc.). These architectures were removed from CUDA 13.
- Use **CUDA 13.3** if you have a GPU with compute capability 7.5+ (most modern GPUs from T4 onwards).

Both versions can coexist on the same system as long as your NVIDIA driver meets the minimum requirement for the version you use.

## Usage

### Download

1. Go to the [Releases](../../releases) page
2. Download the tarball matching your CUDA version and host CPU architecture. Filename format: `llama.cpp-bXXXX-cuda-<cuda>-<arch>.tar.gz`
3. Extract the archive:

```bash
# amd64 host, CUDA 13.3
tar -xzf llama.cpp-bXXXX-cuda-13.3-amd64.tar.gz
cd cuda-13.3
# aarch64 host, CUDA 12.9
tar -xzf llama.cpp-bXXXX-cuda-12.9-arm64.tar.gz
cd cuda-12.9
```

Each tarball includes the necessary CUDA runtime libraries (libcudart, libcublas, etc.) so no additional CUDA toolkit installation is required — just the NVIDIA driver.

### Run

```bash
./llama-cli --help
./llama-server --help
./llama-bench
./llama-quantize
./llama-embedding
```

### Check Version

Each release includes a `VERSION.txt` file:

```bash
cat VERSION.txt
```

## System Requirements

- NVIDIA GPU with appropriate compute capability (see table above)
- NVIDIA driver:
  - CUDA 12.9: Driver >= 575.51.03
  - CUDA 13.3: Driver >= 610.43.02
- Linux x86_64 or aarch64 (Ubuntu 24.04 compatible)

## Build Process

Builds are triggered automatically:
- Daily at 00:00 UTC
- Only if a new llama.cpp release is detected
- Can be manually triggered via GitHub Actions

Each build:
1. Checks for new llama.cpp releases
2. Clones llama.cpp at the exact release commit
3. Builds with CMake using CUDA Docker images on optimized runners
4. Bundles CUDA runtime libraries directly into the tarball
5. Creates a GitHub release with all build artifacts

### Build variants

For each upstream llama.cpp release, four tarballs are produced:
- `cuda-12.9-amd64` — CUDA 12.9 for legacy GPUs on x86_64
- `cuda-12.9-arm64` — CUDA 12.9 for legacy GPUs on aarch64
- `cuda-13.3-amd64` — CUDA 13.3 for modern GPUs on x86_64
- `cuda-13.3-arm64` — CUDA 13.3 for modern GPUs on aarch64

## CPU Optimization

Builds use multi-architecture CPU dispatch (`GGML_CPU_ALL_VARIANTS=ON`, `GGML_BACKEND_DL=ON`): multiple CPU backend variants are included and the optimal one is loaded at runtime based on CPU feature detection.

## Manual Building

```bash
git clone https://github.com/ai-dock/llama.cpp-cuda
cd llama.cpp-cuda
./scripts/test-build.sh 12.9.2
# or
./scripts/test-build.sh 13.3.0
```

## License

This repository contains build scripts only. The llama.cpp binaries are subject to the [llama.cpp MIT License](https://github.com/ggml-org/llama.cpp/blob/master/LICENSE).

## Links

- **Upstream llama.cpp**: https://github.com/ggml-org/llama.cpp
- **CUDA Toolkit**: https://developer.nvidia.com/cuda-toolkit
- **NVIDIA Driver Downloads**: https://www.nvidia.com/download/index.aspx

## Support

For issues with:
- **Build process or binaries**: Open an issue in this repository
- **llama.cpp functionality**: Open an issue in the [upstream repository](https://github.com/ggml-org/llama.cpp/issues)

## Credits

- [llama.cpp](https://github.com/ggml-org/llama.cpp) by Georgi Gerganov and contributors
- Original repository by [ai-dock](https://github.com/ai-dock/llama.cpp-cuda)
