import argparse
import ctypes
import sys
import time


PTX = r"""
.version 7.0
.target sm_70
.address_size 64

.visible .entry burn(
    .param .u64 data,
    .param .u32 n,
    .param .u32 iterations
)
{
    .reg .pred %p<3>;
    .reg .b32  %r<10>;
    .reg .b64  %rd<5>;
    .reg .f32  %f<12>;

    ld.param.u64 %rd1, [data];
    ld.param.u32 %r1, [n];
    ld.param.u32 %r2, [iterations];

    mov.u32 %r3, %ctaid.x;
    mov.u32 %r4, %ntid.x;
    mov.u32 %r5, %tid.x;
    mad.lo.s32 %r6, %r3, %r4, %r5;

    setp.ge.u32 %p1, %r6, %r1;
    @%p1 bra DONE;

    mul.wide.u32 %rd2, %r6, 4;
    add.s64 %rd3, %rd1, %rd2;

    ld.global.f32 %f1, [%rd3];

    mov.f32 %f2, 0f3F800001;
    mov.f32 %f3, 0f358637BD;
    mov.f32 %f4, 0f3F7FFFFF;
    mov.f32 %f5, 0f34000000;

    add.f32 %f6, %f1, %f3;
    add.f32 %f7, %f1, %f5;
    add.f32 %f8, %f1, %f3;

    mov.u32 %r7, 0;

LOOP:
    fma.rn.f32 %f1, %f1, %f2, %f3;
    fma.rn.f32 %f6, %f6, %f4, %f5;
    fma.rn.f32 %f7, %f7, %f2, %f5;
    fma.rn.f32 %f8, %f8, %f4, %f3;

    add.u32 %r7, %r7, 1;
    setp.lt.u32 %p2, %r7, %r2;
    @%p2 bra LOOP;

    add.f32 %f9, %f1, %f6;
    add.f32 %f10, %f7, %f8;
    add.f32 %f9, %f9, %f10;

    st.global.f32 [%rd3], %f9;

DONE:
    ret;
}
"""


def load_cuda():
    for path in (
        "libcuda.so.1",
        "/usr/lib/wsl/lib/libcuda.so.1"
    ):
        try:
            return ctypes.CDLL(path)
        except OSError:
            pass

    raise RuntimeError("Could not load WSL CUDA driver")


def main():

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--duration",
        type=int,
        default=60
    )

    parser.add_argument(
        "--memory-mb",
        type=int,
        default=64
    )

    parser.add_argument(
        "--iterations",
        type=int,
        default=2048
    )

    args = parser.parse_args()

    cuda = load_cuda()

    CUdevice = ctypes.c_int
    CUcontext = ctypes.c_void_p
    CUmodule = ctypes.c_void_p
    CUfunction = ctypes.c_void_p
    CUdeviceptr = ctypes.c_uint64

    def bind(name, argtypes):

        fn = getattr(cuda, name)

        fn.restype = ctypes.c_int
        fn.argtypes = argtypes

        return fn

    cuInit = bind(
        "cuInit",
        [ctypes.c_uint]
    )

    cuDeviceGet = bind(
        "cuDeviceGet",
        [ctypes.POINTER(CUdevice), ctypes.c_int]
    )

    cuDeviceGetName = bind(
        "cuDeviceGetName",
        [ctypes.c_void_p, ctypes.c_int, CUdevice]
    )

    cuCtxCreate = bind(
        "cuCtxCreate_v2",
        [ctypes.POINTER(CUcontext), ctypes.c_uint, CUdevice]
    )

    cuCtxDestroy = bind(
        "cuCtxDestroy_v2",
        [CUcontext]
    )

    cuModuleLoadData = bind(
        "cuModuleLoadData",
        [ctypes.POINTER(CUmodule), ctypes.c_void_p]
    )

    cuModuleUnload = bind(
        "cuModuleUnload",
        [CUmodule]
    )

    cuModuleGetFunction = bind(
        "cuModuleGetFunction",
        [
            ctypes.POINTER(CUfunction),
            CUmodule,
            ctypes.c_char_p
        ]
    )

    cuMemAlloc = bind(
        "cuMemAlloc_v2",
        [
            ctypes.POINTER(CUdeviceptr),
            ctypes.c_size_t
        ]
    )

    cuMemFree = bind(
        "cuMemFree_v2",
        [CUdeviceptr]
    )

    cuMemsetD32 = bind(
        "cuMemsetD32_v2",
        [
            CUdeviceptr,
            ctypes.c_uint,
            ctypes.c_size_t
        ]
    )

    cuLaunchKernel = bind(
        "cuLaunchKernel",
        [
            CUfunction,

            ctypes.c_uint,
            ctypes.c_uint,
            ctypes.c_uint,

            ctypes.c_uint,
            ctypes.c_uint,
            ctypes.c_uint,

            ctypes.c_uint,

            ctypes.c_void_p,

            ctypes.POINTER(ctypes.c_void_p),
            ctypes.POINTER(ctypes.c_void_p)
        ]
    )

    cuCtxSynchronize = bind(
        "cuCtxSynchronize",
        []
    )

    def check(result, name):

        if result != 0:
            raise RuntimeError(
                f"{name} failed with CUDA error {result}"
            )

    ctx = CUcontext()
    module = CUmodule()
    dptr = CUdeviceptr()

    try:

        check(
            cuInit(0),
            "cuInit"
        )

        device = CUdevice()

        check(
            cuDeviceGet(
                ctypes.byref(device),
                0
            ),
            "cuDeviceGet"
        )

        name = ctypes.create_string_buffer(256)

        check(
            cuDeviceGetName(
                name,
                len(name),
                device
            ),
            "cuDeviceGetName"
        )

        check(
            cuCtxCreate(
                ctypes.byref(ctx),
                0,
                device
            ),
            "cuCtxCreate"
        )

        ptx_buffer = ctypes.create_string_buffer(
            PTX.encode("ascii")
        )

        check(
            cuModuleLoadData(
                ctypes.byref(module),
                ctypes.cast(
                    ptx_buffer,
                    ctypes.c_void_p
                )
            ),
            "cuModuleLoadData"
        )

        function = CUfunction()

        check(
            cuModuleGetFunction(
                ctypes.byref(function),
                module,
                b"burn"
            ),
            "cuModuleGetFunction"
        )

        memory_bytes = (
            args.memory_mb *
            1024 *
            1024
        )

        elements = memory_bytes // 4

        check(
            cuMemAlloc(
                ctypes.byref(dptr),
                memory_bytes
            ),
            "cuMemAlloc"
        )

        check(
            cuMemsetD32(
                dptr,
                0x3F800000,
                elements
            ),
            "cuMemsetD32"
        )

        threads = 256

        blocks = (
            elements +
            threads -
            1
        ) // threads

        dptr_arg = CUdeviceptr(
            dptr.value
        )

        elements_arg = ctypes.c_uint(
            elements
        )

        iterations_arg = ctypes.c_uint(
            args.iterations
        )

        params = (
            ctypes.c_void_p * 3
        )(
            ctypes.cast(
                ctypes.byref(dptr_arg),
                ctypes.c_void_p
            ),

            ctypes.cast(
                ctypes.byref(elements_arg),
                ctypes.c_void_p
            ),

            ctypes.cast(
                ctypes.byref(iterations_arg),
                ctypes.c_void_p
            )
        )

        print(
            f"GPU: {name.value.decode()} | "
            f"VRAM: {args.memory_mb} MiB | "
            f"Iterations: {args.iterations} | "
            f"Duration: {args.duration}s",
            flush=True
        )

        end_time = (
            time.monotonic() +
            args.duration
        )

        launches = 0

        while time.monotonic() < end_time:

            check(
                cuLaunchKernel(
                    function,

                    blocks,
                    1,
                    1,

                    threads,
                    1,
                    1,

                    0,

                    None,

                    params,
                    None
                ),
                "cuLaunchKernel"
            )

            check(
                cuCtxSynchronize(),
                "cuCtxSynchronize"
            )

            launches += 1

        print(
            f"Completed {launches} GPU kernel launches.",
            flush=True
        )

    finally:

        if dptr.value:
            cuMemFree(dptr)

        if module.value:
            cuModuleUnload(module)

        if ctx.value:
            cuCtxDestroy(ctx)


if __name__ == "__main__":

    try:
        main()

    except Exception as exc:

        print(
            f"ERROR: {exc}",
            file=sys.stderr
        )

        sys.exit(1)