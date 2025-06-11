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
    let args = $in
    let mut config = {
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

    let mut i = 0
    while $i < ($args | length) {
        let arg = $args[$i]
        match $arg {
            "--platform" => {
                $config.platform = $args[$i + 1]
                $i = $i + 2
            }
            "--script" => {
                $config.script = $args[$i + 1]
                $i = $i + 2
            }
            "--dry-run" => {
                $config.dry_run = true
                $i = $i + 1
            }
            "--verbose" | "-v" => {
                $config.verbose = true
                $i = $i + 1
            }
            "--force" | "-f" => {
                $config.force = true
                $i = $i + 1
            }
            "--quiet" | "-q" => {
                $config.quiet = true
                $i = $i + 1
            }
            "--log-file" => {
                $config.log_file = $args[$i + 1]
                $i = $i + 2
            }
            "--parallel" | "-p" => {
                $config.parallel = true
                $i = $i + 1
            }
            "--timeout" => {
                $config.timeout = ($args[$i + 1] | into int)
                $i = $i + 2
            }
            "--retry" => {
                $config.retry_count = ($args[$i + 1] | into int)
                $i = $i + 2
            }
            "--retry-delay" => {
                $config.retry_delay = ($args[$i + 1] | into int)
                $i = $i + 2
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
    let config = parse_args $in
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