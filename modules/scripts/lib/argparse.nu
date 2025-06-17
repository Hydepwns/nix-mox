# Argument parsing module for nix-mox
# This replaces the bash argparse.sh with a more robust Nushell implementation

def show_help [] {
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

def parse_args [] {
    let args = $env._args
    $env.config = {
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

    $env.i = 0
    while $env.i < ($args | length) {
        let arg = ($args | get $env.i)
        match $arg {
            "--platform" => {
                $env.config.platform = ($args | get ($env.i + 1))
                $env.i = $env.i + 2
            }
            "--script" => {
                $env.config.script = ($args | get ($env.i + 1))
                $env.i = $env.i + 2
            }
            "--dry-run" => {
                $env.config.dry_run = true
                $env.i = $env.i + 1
            }
            "--verbose" | "-v" => {
                $env.config.verbose = true
                $env.i = $env.i + 1
            }
            "--force" | "-f" => {
                $env.config.force = true
                $env.i = $env.i + 1
            }
            "--quiet" | "-q" => {
                $env.config.quiet = true
                $env.i = $env.i + 1
            }
            "--log-file" => {
                $env.config.log_file = ($args | get ($env.i + 1))
                $env.i = $env.i + 2
            }
            "--parallel" | "-p" => {
                $env.config.parallel = true
                $env.i = $env.i + 1
            }
            "--timeout" => {
                $env.config.timeout = ($args | get ($env.i + 1) | into int)
                $env.i = $env.i + 2
            }
            "--retry" => {
                $env.config.retry_count = ($args | get ($env.i + 1) | into int)
                $env.i = $env.i + 2
            }
            "--retry-delay" => {
                $env.config.retry_delay = ($args | get ($env.i + 1) | into int)
                $env.i = $env.i + 2
            }
            "--help" => {
                show_help
                exit 0
            }
            _ => {
                print $"Unknown option: ($arg)"
                show_help
                exit 1
            }
        }
    }
    $env.config
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
    parse_args
    $env.PLATFORM = $env.config.platform
    $env.SCRIPT = $env.config.script
    $env.DRY_RUN = $env.config.dry_run
    $env.VERBOSE = $env.config.verbose
    $env.FORCE = $env.config.force
    $env.QUIET = $env.config.quiet
    $env.LOG_FILE = $env.config.log_file
    $env.PARALLEL = $env.config.parallel
    $env.TIMEOUT = $env.config.timeout
    $env.RETRY_COUNT = $env.config.retry_count
    $env.RETRY_DELAY = $env.config.retry_delay
} 