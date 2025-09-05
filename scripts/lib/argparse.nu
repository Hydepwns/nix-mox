# Argument parsing module for nix-mox
# This replaces the bash argparse.sh with a more robust Nushell implementation

export def show_help [] {
    print "Usage: scripts/nix-mox [options] [script-arguments]"
    print ""
    print "Options:"
    print "  --platform <platform>    Specify platform (linux, windows, or auto)"
    print "  --script <script>        Specify script to run (default: install)"
    print "  --dry-run               Show what would be done without making changes"
    print "  --verbose, -v           Enable verbose output"
    print "  --quiet, -q             Suppress all output except errors"
    print "  --force, -f             Force execution even if conditions aren't ideal"
    print "  --log-file <file>       Write output to specified log file"
    print "  --parallel, -p          Run platform scripts in parallel (CI mode only)"
    print "  --timeout <seconds>     Set timeout for script execution (0 = no timeout)"
    print "  --retry <count>         Number of times to retry failed scripts"
    print "  --retry-delay <seconds> Delay between retries (default: 5)"
    print "  --help                  Show this help message"
}

export def parse_args [] {
    let args = $env._args
    let config0 = {
        platform: "auto"
        script: "install"
        dry_run: false
        verbose: false
        force: false
        quiet: false
        log_file: ""
        parallel: false
        timeout: 0
        retry_count: 0
        retry_delay: 5
    }
    let i0 = 0
    mut config = $config0
    mut i = $i0
    while $i < ($args | length) {
        let arg = ($args | get $i)
        let result = (
            match $arg {
                "--platform" => { [($config | upsert platform ($args | get ($i + 1))), $i + 2] }
                "--script" => { [($config | upsert script ($args | get ($i + 1))), $i + 2] }
                "--dry-run" => { [($config | upsert dry_run true), $i + 1] }
                "--verbose" | "-v" => { [($config | upsert verbose true), $i + 1] }
                "--force" | "-f" => { [($config | upsert force true), $i + 1] }
                "--quiet" | "-q" => { [($config | upsert quiet true), $i + 1] }
                "--log-file" => { [($config | upsert log_file ($args | get ($i + 1))), $i + 2] }
                "--parallel" | "-p" => { [($config | upsert parallel true), $i + 1] }
                "--timeout" => { [($config | upsert timeout ($args | get ($i + 1) | into int)), $i + 2] }
                "--retry" => { [($config | upsert retry_count ($args | get ($i + 1) | into int)), $i + 2] }
                "--retry-delay" => { [($config | upsert retry_delay ($args | get ($i + 1) | into int)), $i + 2] }
                "--help" => { show_help; exit 0 }
                _ => { print $"Unknown option: ($arg)"; exit 1 }
            }
        )
        let config = ($result | first)
        let i = ($result | get 1)
    }
    $config
}

# Export the functions
export-env {
    $env.PLATFORM = "auto"
    $env.SCRIPT = "install"
    $env.DRY_RUN = false
    $env.VERBOSE = false
    $env.FORCE = false
    $env.QUIET = false
    $env.LOG_FILE = ""
    $env.PARALLEL = false
    $env.TIMEOUT = 0
    $env.RETRY_COUNT = 0
    $env.RETRY_DELAY = 5
}

# Main function to parse arguments and update environment
def main [] {
    let config = parse_args
    $env.PLATFORM = $config.platform
    $env.SCRIPT = $config.script
    $env.DRY_RUN = $config.dry_run
    $env.VERBOSE = $config.verbose
    $env.FORCE = $config.force
    $env.QUIET = $config.quiet
    $env.LOG_FILE = $config.log_file
    $env.PARALLEL = $config.parallel
    $env.TIMEOUT = $config.timeout
    $env.RETRY_COUNT = $config.retry_count
    $env.RETRY_DELAY = $config.retry_delay
}
