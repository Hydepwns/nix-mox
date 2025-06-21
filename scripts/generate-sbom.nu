#!/usr/bin/env nu

# nix-mox SBOM Generator
# Generates Software Bill of Materials for compliance and security auditing

def log_info [message: string] {
    print $"📋 ($message)"
}

def log_success [message: string] {
    print $"✅ ($message)"
}

def log_warning [message: string] {
    print $"⚠️  ($message)"
}

def log_error [message: string] {
    print $"❌ ($message)"
}

# List of supported systems
let supported_systems = ["x86_64-linux", "aarch64-linux"]

# List of packages
let available_packages = ["proxmox-update", "vzdump-backup", "zfs-snapshot", "nixos-flake-update", "install", "uninstall"]

def get_package_info [system: string, package_name: string] {
    try {
        let out_path = (nix eval .#packages.($system).($package_name).outPath --raw | complete | get stdout | str trim)
        if ($out_path == "") {
            log_warning $"Package ($package_name) not available for ($system)"
            return {
                system: $system
                name: $package_name
                version: "unavailable"
                description: "Package not available for this system"
                license: "unknown"
                source: ""
                dependencies: 0
                raw_size: 0
                size: "0 B"
                hash: ""
                build_inputs: 0
            }
        }
        let package_info = (nix show-derivation $out_path | from json | values | get 0)
        let closure = (nix path-info --closure-size $out_path --json | from json)
        let raw_size = ($closure | get size | math sum)
        {
            system: $system
            name: $package_name
            version: ($package_info | get env | get version | default "unknown")
            description: ($package_info | get env | get description | default "")
            license: ($package_info | get env | get license | default "unknown")
            source: ($package_info | get env | get src | default "")
            dependencies: ($closure | length)
            raw_size: $raw_size
            size: ($raw_size | into filesize)
            hash: ($package_info | get outputHash | default "")
            build_inputs: ($package_info | get inputSrcs | length)
        }
    } catch {
        log_warning $"Could not get info for package ($package_name) on ($system)"
        {
            system: $system
            name: $package_name
            version: "unknown"
            description: "Package not available"
            license: "unknown"
            source: ""
            dependencies: 0
            raw_size: 0
            size: "0 B"
            hash: ""
            build_inputs: 0
        }
    }
}

def generate_spdx_sbom [packages: list] {
    let timestamp = (date now | format date "%Y-%m-%dT%H:%M:%SZ")
    let sbom_id = $"SPDXRef-DOCUMENT-($timestamp | str replace ":" "-" | str replace "T" "-" | str replace "Z" "")"
    
    let spdx_header = {
        spdxVersion: "SPDX-2.3"
        dataLicense: "CC0-1.0"
        SPDXID: $sbom_id
        documentName: "nix-mox Software Bill of Materials"
        documentNamespace: $"https://github.com/Hydepwns/nix-mox/sbom/($timestamp)"
        creator: "Tool: nix-mox-sbom-generator"
        created: $timestamp
        documentComment: "Generated automatically by nix-mox SBOM generator"
    }
    
    let package_elements = ($packages | each { |pkg|
        let pkg_id = $"SPDXRef-Package-($pkg.name | str replace "-" "_")"
        {
            SPDXID: $pkg_id
            packageName: $pkg.name
            packageVersion: $pkg.version
            packageDescription: $pkg.description
            packageLicenseConcluded: $pkg.license
            packageLicenseDeclared: $pkg.license
            packageDownloadLocation: $pkg.source
            packageSize: $pkg.size
            packageChecksum: {
                algorithm: "SHA256"
                checksumValue: $pkg.hash
            }
            packageVerificationCode: {
                packageVerificationCodeValue: $pkg.hash
            }
            packageHomePage: $"https://github.com/Hydepwns/nix-mox"
            packageSupplier: "Organization: Hydepwns"
            packageOriginator: "Organization: Hydepwns"
        }
    })
    
    {
        header: $spdx_header
        packages: $package_elements
    }
}

def generate_cyclonedx_sbom [packages: list] {
    let timestamp = (date now | format date "%Y-%m-%dT%H:%M:%SZ")
    let bom_ref = $"nix-mox-bom-($timestamp | str replace ":" "-" | str replace "T" "-" | str replace "Z" "")"
    
    let metadata = {
        timestamp: $timestamp
        tools: [{
            vendor: "nix-mox"
            name: "sbom-generator"
            version: "1.0.0"
        }]
        component: {
            type: "application"
            name: "nix-mox"
            version: "1.0.0"
            description: "A comprehensive NixOS configuration framework"
            bomRef: $bom_ref
        }
    }
    
    let components = ($packages | each { |pkg|
        {
            type: "library"
            name: $pkg.name
            version: $pkg.version
            description: $pkg.description
            licenses: [{
                license: {
                    id: $pkg.license
                }
            }]
            bomRef: $"pkg-($pkg.name | str replace "-" "_")"
            properties: [
                {
                    name: "size"
                    value: $pkg.size
                }
                {
                    name: "dependencies"
                    value: ($pkg.dependencies | into string)
                }
                {
                    name: "build_inputs"
                    value: ($pkg.build_inputs | into string)
                }
            ]
        }
    })
    
    {
        bomFormat: "CycloneDX"
        specVersion: "1.5"
        version: 1
        metadata: $metadata
        components: $components
    }
}

def generate_csv_report [packages: list] {
    let headers = "Name,Version,Description,License,Size,Dependencies,Build Inputs,Source"
    let rows = ($packages | each { |pkg|
        $"($pkg.name),($pkg.version),($pkg.description),($pkg.license),($pkg.size),($pkg.dependencies | into string),($pkg.build_inputs | into string),($pkg.source)"
    })
    
    $headers | append $rows | str join "\n"
}

def main [] {
    log_info "Generating Software Bill of Materials for nix-mox..."
    
    log_info "Collecting package information..."
    let packages = ($supported_systems | each { |system|
        $available_packages | each { |pkg| get_package_info $system $pkg }
    } | flatten)
    
    mkdir sbom
    
    log_info "Generating SPDX format SBOM..."
    let spdx_sbom = (generate_spdx_sbom $packages)
    $spdx_sbom | to json --indent 2 | save --force sbom/nix-mox.spdx.json
    
    log_info "Generating CycloneDX format SBOM..."
    let cyclonedx_sbom = (generate_cyclonedx_sbom $packages)
    $cyclonedx_sbom | to json --indent 2 | save --force sbom/nix-mox.cyclonedx.json
    
    log_info "Generating CSV report..."
    let csv_report = (generate_csv_report $packages)
    $csv_report | save --force sbom/nix-mox-packages.csv
    
    let total_packages = ($packages | length)
    let total_size = ($packages | get raw_size | math sum | into filesize)
    let total_dependencies = ($packages | get dependencies | math sum)
    
    let summary = {
        generated_at: (date now | format date "%Y-%m-%d %H:%M:%S")
        total_packages: $total_packages
        total_size: $total_size
        total_dependencies: $total_dependencies
        formats: ["SPDX", "CycloneDX", "CSV"]
        files: [
            "sbom/nix-mox.spdx.json"
            "sbom/nix-mox.cyclonedx.json"
            "sbom/nix-mox-packages.csv"
        ]
    }
    
    $summary | to json --indent 2 | save --force sbom/sbom-summary.json
    
    log_success "SBOM generation completed!"
    log_info $"Generated ($total_packages) package-system pairs with ($total_dependencies) total dependencies"
    log_info $"Total size: ($total_size)"
    log_info "Files saved to sbom/ directory:"
    print "  - nix-mox.spdx.json (SPDX format)"
    print "  - nix-mox.cyclonedx.json (CycloneDX format)"
    print "  - nix-mox-packages.csv (CSV report)"
    print "  - sbom-summary.json (Summary)"
}

# Run main function if script is executed directly
if ($env | get -i SCRIPT_NAME | default "" | str contains "generate-sbom.nu") {
    main
}

export def run [] {
    main
} 