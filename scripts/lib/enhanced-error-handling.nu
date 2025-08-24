# Enhanced error handling for nix-mox scripts
# COMPATIBILITY WRAPPER - This file now re-exports from unified-error-handling.nu
# 
# DEPRECATED: Use unified-error-handling.nu directly for new code
# This file is maintained for backward compatibility only

# Re-export everything from unified-error-handling.nu
export use ./unified-error-handling.nu *

# Legacy compatibility note
export def __deprecation_warning [] {
    print "(ansi yellow)⚠️  WARNING: unified-error-handling.nu is deprecated.(ansi reset)"
    print "   Please use unified-error-handling.nu directly for new code."
    print "   This file is maintained for backward compatibility only."
}

# Override handle_error to show deprecation warning on first use
export def handle_error [error: record, context: string = ""] {
    __deprecation_warning
    # Call the unified version
    (./unified-error-handling.nu handle_error $error $context)
} 