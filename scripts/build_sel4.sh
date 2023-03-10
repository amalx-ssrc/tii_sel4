#! /bin/sh

set -e

# shellcheck disable=SC1091
. "$(pwd)/.config"

# Detect whether should enter container:
#   docker     -> '/.dockerenv' file exists
#   lxc/podman -> 'container' variable is set to runtime name.
#
# With 'container' variable we support native builds too:
# export container="skip", or similar, before calling make, and entering
# container is skipped.
if [ -z "${container}" ] && [ ! -f /.dockerenv ]; then
  # shellcheck disable=SC2068
  exec docker/enter_container.sh "$(pwd)" scripts/build_sel4.sh $@
fi

BUILDDIR=$1
shift

SRCDIR=$1

rm -rf "${BUILDDIR}"
mkdir -p "${BUILDDIR}"

ln -rs tools/seL4/cmake-tool/init-build.sh "${BUILDDIR}"
ln -rs "${SRCDIR}/easy-settings.cmake" "${BUILDDIR}"

cd "${BUILDDIR}" || exit 2

if [ "x${SEL4_TRACE}" = "xON" ]; then
  TRACE="-DKernelArmExportPMUUser=ON -DKernelBenchmarks=track_kernel_entries"
fi

# shellcheck disable=SC2068
./init-build.sh \
  -B . \
  -DAARCH64=1 \
  -DPLATFORM="${PLATFORM}" \
  -DCROSS_COMPILER_PREFIX="${CROSS_COMPILE}" \
  ${TRACE} \
  $@

ninja

echo "Here are your binaries in ${BUILDDIR}/images: "
ls -l ./images
