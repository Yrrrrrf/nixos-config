#!/usr/bin/env nu
# tests/bench-disk.nu — SSD benchmarking

const TEST_SIZE = "2G"
const RUNTIME_SEC = 10

def is-tmpfs [dir: string]: nothing -> bool {
    (^df --output=fstype $dir | lines | last | str trim) == "tmpfs"
}

def first-nvme []: nothing -> string {
    ls /dev | get name | where ($it =~ 'nvme\dn\d$') | first
}

def fio-run [
    name: string
    rw: string
    bs: string
    iodepth: int
    test_file: string
    --numjobs: int = 1
]: nothing -> record {
    let raw = (
        ^fio $"--name=($name)" $"--rw=($rw)" $"--bs=($bs)" $"--size=($TEST_SIZE)"
             $"--iodepth=($iodepth)" $"--numjobs=($numjobs)"
             $"--runtime=($RUNTIME_SEC)" --time_based
             --direct=1 --group_reporting
             --ioengine=io_uring
             $"--filename=($test_file)"
             --output-format=json
        | from json
    )
    let job = $raw.jobs.0
    let op = if ($rw | str contains "read") { $job.read } else { $job.write }
    {
        test:    $name
        "MB/s":  (($op.bw_bytes / 1_000_000) | math round)
        IOPS:    ($op.iops | math round)
        "lat_µs": (($op.lat_ns.mean / 1000) | math round --precision 1)
    }
}

def main [
    --quick                                       # Skip QD32 tests
    --path: string = "~/.fio_ssd_test"            # Test file location
    --keep                                        # Do not delete test file
] {
    if (which fio | is-empty) {
        print $"(ansi red)fio not found.(ansi reset)"
        exit 1
    }

    let test_file = ($path | path expand)
    let test_dir = ($test_file | path dirname)

    if (is-tmpfs $test_dir) {
        print $"(ansi red)($test_dir) is tmpfs. Use a path on the SSD.(ansi reset)"
        exit 1
    }

    print $"(ansi cyan_bold)━━ Sequential \(1MB, QD32\) ━━(ansi reset)"
    [
        (fio-run "seq_read"  "read"  "1M" 32 $test_file)
        (fio-run "seq_write" "write" "1M" 32 $test_file)
    ] | table | print

    print $"\n(ansi cyan_bold)━━ Random 4K — QD1 ━━(ansi reset)"
    [
        (fio-run "rand_read_qd1"  "randread"  "4k" 1 $test_file)
        (fio-run "rand_write_qd1" "randwrite" "4k" 1 $test_file)
    ] | table | print

    if not $quick {
        print $"\n(ansi cyan_bold)━━ Random 4K — QD32 x 4 ━━(ansi reset)"
        [
            (fio-run "rand_read_qd32"  "randread"  "4k" 32 $test_file --numjobs 4)
            (fio-run "rand_write_qd32" "randwrite" "4k" 32 $test_file --numjobs 4)
        ] | table | print
    }

    if not $keep { rm -f $test_file }
}
