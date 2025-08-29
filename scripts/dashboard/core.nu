#!/usr/bin/env nu
# Core dashboard functionality
# Main dashboard orchestration and routing

use ../lib/logging.nu *
use ../lib/platform.nu *
use ../lib/script-template.nu *
use data-collectors.nu *
use displays.nu *

# ──────────────────────────────────────────────────────────
# MAIN DASHBOARD FUNCTIONS
# ──────────────────────────────────────────────────────────

export def overview_dashboard [refresh: int, watch: bool, output: string, format: string] {
    if $watch {
        loop {
            clear
            let data = (collect_overview_data)
            display_overview $data $format
            if $output != "" {
                save_dashboard_data $data $output
            }
            sleep ($refresh | into duration --unit sec)
        }
    } else {
        let data = (collect_overview_data)
        display_overview $data $format
        if $output != "" {
            save_dashboard_data $data $output
        }
    }
}

export def system_dashboard [refresh: int, watch: bool, output: string, format: string] {
    if $watch {
        loop {
            clear
            let data = (collect_system_data)
            display_system $data $format
            if $output != "" {
                save_dashboard_data $data $output
            }
            sleep ($refresh | into duration --unit sec)
            let data = (collect_system_data)
        }
    } else {
        let data = (collect_system_data)
        display_system $data $format
        if $output != "" {
            save_dashboard_data $data $output
        }
    }
}

export def performance_dashboard [refresh: int, watch: bool, output: string, format: string] {
    if $watch {
        loop {
            clear
            let data = (collect_performance_data)
            display_performance $data $format
            if $output != "" {
                save_dashboard_data $data $output
            }
            sleep ($refresh | into duration --unit sec)
            let data = (collect_performance_data)
        }
    } else {
        let data = (collect_performance_data)
        display_performance $data $format
        if $output != "" {
            save_dashboard_data $data $output
        }
    }
}

export def testing_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_testing_data)
    display_testing $data $format
    if $output != "" {
        save_dashboard_data $data $output
    }
}

export def coverage_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_coverage_data)
    display_coverage $data $format
    if $output != "" {
        save_dashboard_data $data $output
    }
}

export def security_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_security_data)
    display_security $data $format
    if $output != "" {
        save_dashboard_data $data $output
    }
}

export def gaming_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_gaming_data)
    display_gaming $data $format
    if $output != "" {
        save_dashboard_data $data $output
    }
}

export def analysis_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_analysis_data)
    display_analysis $data $format
    if $output != "" {
        save_dashboard_data $data $output
    }
}

export def size_analysis_dashboard [refresh: int, watch: bool, output: string, format: string] {
    if $watch {
        loop {
            clear
            let data = (collect_size_analysis_data)
            display_size_analysis $data $format
            if $output != "" {
                save_dashboard_data $data $output
            }
            sleep ($refresh | into duration --unit sec)
            let data = (collect_size_analysis_data)
        }
    } else {
        let data = (collect_size_analysis_data)
        display_size_analysis $data $format
        if $output != "" {
            save_dashboard_data $data $output
        }
    }
}

export def project_status_dashboard [refresh: int, watch: bool, output: string, format: string] {
    if $watch {
        loop {
            clear
            let data = (collect_project_status_data)
            display_project_status $data $format
            if $output != "" {
                save_dashboard_data $data $output
            }
            sleep ($refresh | into duration --unit sec)
            let data = (collect_project_status_data)
        }
    } else {
        let data = (collect_project_status_data)
        display_project_status $data $format
        if $output != "" {
            save_dashboard_data $data $output
        }
    }
}