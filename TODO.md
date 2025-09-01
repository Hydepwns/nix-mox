# TODO: Nushell Script Modernization & System Maintenance

## High Priority - Critical Issues

### 🔥 Immediate Actions Required

#### 1. NVIDIA Display Fix Deployment
- **Status**: Ready for deployment
- **Blocker**: Validation scripts syntax errors
- **Action**: Run `sudo nixos-rebuild switch --flake .#nixos` directly
- **ETA**: Immediate
- **Risk**: Low - configuration tested and validated

#### 2. Validation Script Modernization
- **Status**: In progress - multiple legacy syntax issues identified
- **Priority**: High (blocking safe-rebuild functionality)
- **Action**: Systematic refactoring of Nushell scripts

## Nushell Script Modernization Plan

### Phase 1: Assessment & Tooling (Week 1)

#### 1.1 Complete Script Audit
- [ ] Catalog all syntax issues across all `.nu` files
- [ ] Document Nushell version compatibility requirements
- [ ] Identify critical vs non-critical script functionality
- [ ] Create comprehensive test suite for script validation

#### 1.2 Automated Tooling Development
- [x] ✅ Research available Nushell linting tools (Result: immature ecosystem)
- [x] ✅ Create custom syntax fixer: `scripts/maintenance/fix-nushell-syntax.nu`
- [ ] Complete syntax fixer implementation with proper flag handling
- [ ] Add pattern matching for all identified syntax issues:
  - [ ] Return type syntax (`] -> type {` → `] {`)
  - [ ] Logging function calls (missing `--context` flags)
  - [ ] Environment variable syntax (`let-env` → `export-env`)
  - [ ] Boolean switch syntax in function parameters
  - [ ] Datetime arithmetic operations
  - [ ] Chain result pattern fixes
  - [ ] Validation result vs error handling format mixing

#### 1.3 Testing Infrastructure
- [ ] Create syntax validation CI/CD pipeline
- [ ] Add automated testing for all script functionality
- [ ] Set up regression testing to prevent future syntax breaks

### Phase 2: Systematic Script Refactoring (Week 2-3)

#### 2.1 Critical Path Scripts (Priority 1)
**Scripts blocking core system functionality:**

1. **validators.nu** - Core validation functionality
   - [ ] Fix chain_result closure type mismatches
   - [ ] Standardize error handling patterns (validation_result vs create_success)
   - [ ] Fix is_error function usage with proper data formats
   - [ ] Update function call syntax and parameter handling

2. **security.nu** - Security validation and logging
   - [x] ✅ Fix logging function calls (`info`/`error`/`warn` with `--context`)
   - [ ] Verify security validation logic integrity
   - [ ] Test security event logging functionality

3. **privilege-manager.nu** - Privilege management
   - [ ] Fix environment variable initialization in export-env block
   - [ ] Fix datetime arithmetic for privilege auditing
   - [ ] Update all logging calls to use --context flag
   - [ ] Test privilege validation and elevation flows

4. **secure-command.nu** - Command execution security
   - [ ] Fix input sanitization function syntax
   - [ ] Update security validation logic
   - [ ] Test command execution safeguards

#### 2.2 Supporting Scripts (Priority 2)
**Scripts that enhance functionality but aren't critical:**

5. **performance.nu** - Performance monitoring
   - [ ] Fix logging function calls
   - [ ] Update performance metric collection
   - [ ] Test monitoring and alerting functionality

6. **error-handling.nu** - Enhanced error management
   - [ ] Standardize error format across all scripts
   - [ ] Fix retry logic and fallback mechanisms
   - [ ] Test error propagation and handling

7. **error-patterns.nu** - Common error patterns
   - [ ] Update error classification logic
   - [ ] Fix pattern matching for common issues
   - [ ] Test error detection and reporting

### Phase 3: Quality Assurance & Integration (Week 4)

#### 3.1 Comprehensive Testing
- [ ] Run full test suite on all modernized scripts
- [ ] Validate safe-rebuild functionality end-to-end
- [ ] Test all validation chains and error paths
- [ ] Performance testing for script execution times

#### 3.2 Documentation & Standards
- [ ] Update CLAUDE.md with new script standards
- [ ] Create Nushell style guide for the project
- [ ] Document common patterns and best practices
- [ ] Create troubleshooting guide for future syntax issues

#### 3.3 CI/CD Integration
- [ ] Add Nushell syntax checking to pre-commit hooks
- [ ] Set up automated testing for all script changes
- [ ] Create deployment pipeline that validates scripts before system changes

### Phase 4: Long-term Maintenance (Ongoing)

#### 4.1 Monitoring & Maintenance
- [ ] Set up alerts for script execution failures
- [ ] Regular Nushell version compatibility checks
- [ ] Quarterly script performance audits
- [ ] Monthly syntax validation runs

#### 4.2 Future Enhancements
- [ ] Investigate official Nushell formatting tools as they mature
- [ ] Consider migration to more mature shell scripting if needed
- [ ] Evaluate integration with external linting tools
- [ ] Develop advanced error handling and recovery mechanisms

## Risk Assessment & Mitigation

### High Risk Items
1. **System Rebuild Functionality**: Critical for system maintenance
   - **Mitigation**: Direct rebuild commands documented in CLAUDE.md
   - **Backup Plan**: Manual validation steps before any system changes

2. **Security Validation**: Critical for safe script execution
   - **Mitigation**: Manual security reviews during transition
   - **Backup Plan**: Disable automated security features temporarily if needed

3. **Script Dependency Chain**: Complex interdependencies between scripts
   - **Mitigation**: Careful ordering of refactoring work
   - **Backup Plan**: Revert to basic functionality if issues arise

### Medium Risk Items
1. **Performance Impact**: Script modernization may affect performance
   - **Mitigation**: Benchmark before/after performance
   - **Monitoring**: Track script execution times

2. **Feature Regression**: Risk of losing functionality during refactoring
   - **Mitigation**: Comprehensive testing at each phase
   - **Rollback**: Git-based versioning for all changes

## Success Metrics

### Technical Metrics
- [ ] All `.nu` files pass `nu --check` syntax validation
- [ ] `make safe-rebuild` executes without syntax errors
- [ ] All validation chains complete successfully
- [ ] Script execution time remains under previous benchmarks
- [ ] Zero security validation false positives/negatives

### Functional Metrics
- [ ] System rebuild process works reliably
- [ ] All safety checks and validations function correctly
- [ ] Error reporting and logging works as expected
- [ ] Performance monitoring operates without issues
- [ ] Security validation catches real threats

## Dependencies & Blockers

### External Dependencies
- **Nushell Version**: Ensure consistent version across development/production
- **System Tools**: Verify all external command dependencies
- **File Permissions**: Ensure proper access to all script directories

### Internal Dependencies
- **Git Configuration**: Scripts directory in .gitignore - may need adjustment
- **Development Environment**: Nix flake environment setup
- **Testing Data**: Need sample data for comprehensive testing

## Timeline & Milestones

### Week 1: Foundation
- **Day 1-2**: Complete audit and tooling setup
- **Day 3-5**: Automated syntax fixer completion and testing

### Week 2: Critical Scripts
- **Day 1-3**: validators.nu and security.nu refactoring
- **Day 4-5**: privilege-manager.nu and secure-command.nu

### Week 3: Supporting Scripts & Testing
- **Day 1-2**: performance.nu and error-handling.nu
- **Day 3-5**: Comprehensive testing and bug fixes

### Week 4: Integration & Documentation
- **Day 1-2**: CI/CD integration and final testing
- **Day 3-5**: Documentation and deployment

## Notes & Lessons Learned

### Current Status (2025-09-01)
- **NVIDIA Fix**: Ready for deployment, blocked by script syntax
- **Script Issues**: Extensive legacy syntax needs systematic refactoring
- **Tooling Gap**: Nushell ecosystem lacks mature linting tools
- **Custom Solution**: Created custom syntax fixer as interim solution

### Key Insights
1. **Nushell Evolution**: Rapid language evolution created compatibility issues
2. **Validation Criticality**: Script validation blocks critical system operations
3. **Technical Debt**: Legacy scripts accumulated significant syntax debt
4. **Priority Ordering**: System functionality must take precedence over script perfection

### Future Considerations
- **Alternative Approaches**: Consider hybrid shell script approach for critical paths
- **Vendor Lock-in**: Evaluate long-term viability of Nushell for system scripts
- **Maintenance Burden**: Factor ongoing maintenance costs into technical decisions