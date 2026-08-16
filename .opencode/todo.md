# Mission: Integrate External Harnesses & Skills + Test Coverage + Documentation

## M1: Critical Bug Fixes | status: completed
### T1.1: Fix LOG_FILE unbound variable | agent:Worker
- [x] S1.1.1: Fix setup.sh:682 LOG_FILE→SETUP_LOG
- [x] S1.1.2: Fix helpers.sh:102 LOG_FILE→SETUP_LOG
- [x] S1.1.3: Fix 19-finalize.sh:225 LOG_FILE→SETUP_LOG
- [x] S1.1.4: Fix dev.sh chmod +x

### T1.2: Fix test_dryrun_dns.sh | agent:Worker
- [x] S1.2.1: Replace hardcoded line numbers with dynamic detection
- [x] S1.2.2: Verify all 11 tests pass

## M2: Test Coverage Expansion | status: completed
### T2.1: Test coverage audit | agent:Planner
- [x] S2.1.1: Analyze 52 modules vs existing tests
- [x] S2.1.2: Create test-coverage-audit.md

### T2.2: Create missing unit tests | agent:Worker
- [x] S2.2.1: test_hooks.sh (25 assertions)
- [x] S2.2.2: test_security.sh (16 assertions)
- [x] S2.2.3: test_version_check.sh (12 assertions)
- [x] S2.2.4: test_just.sh (14 assertions)
- [x] S2.2.5: test_lynis.sh (21 assertions)
- [x] S2.2.6: test_auditd.sh (31 assertions)
- [x] S2.2.7: test_autoupdate.sh (31 assertions)
- [x] S2.2.8: test_pii_guard.sh (18 assertions)
- [x] S2.2.9: test_pre_session_check.sh (31 assertions)
- [x] S2.2.10: test_webui_service.sh (24 assertions)
- [x] S2.2.11: test_shokunin.sh (20 assertions)
- [x] S2.2.12: test_devbox.sh (17 assertions)
- [x] S2.2.13: test_project.sh (100 assertions)

### T2.3: Deepen thin tests | agent:Worker
- [x] S2.3.1: test_websearch.sh (14→50 assertions)
- [x] S2.3.2: test_model_router.sh (36→52 assertions)

## M3: Documentation RU/EN Parity | status: completed
### T3.1: Docs audit | agent:Planner
- [x] S3.1.1: Analyze 77 docs for RU/EN parity
- [x] S3.1.2: Create docs-audit.md

### T3.2: Fix documentation gaps | agent:Worker
- [x] S3.2.1: Fix index.ru.md Node Exporter (6→7 services)
- [x] S3.2.2: Create README.ru.md + language switcher
- [x] S3.2.3: Translate 3 guides to Russian
- [x] S3.2.4: Translate 2 compliance docs to Russian

## M4: External Tools Integration | status: completed
### T4.1: DeepSeek Harness | agent:Worker
- [x] S4.1.1: Create 49-deepseek-harness.sh module
- [x] S4.1.2: Create test_deepseek_harness.sh (34 assertions)

### T4.2: Sandcastle | agent:Worker
- [x] S4.2.1: Create 50-sandcastle.sh module
- [x] S4.2.2: Create test_sandcastle.sh (41 assertions)

### T4.3: Matt Pocock Skills | agent:Worker
- [x] S4.3.1: Install 17 engineering skills
- [x] S4.3.2: Verify all SKILL.md files present

### T4.4: OpenCode Desktop | agent:Worker
- [x] S4.4.1: Create 51-opencode-desktop.sh module
- [x] S4.4.2: Create test_opencode_desktop.sh

### T4.5: Documentation for new tools | agent:Worker
- [x] S4.5.1: Create deepseek-harness-guide.md (EN)
- [x] S4.5.2: Create deepseek-harness-guide.ru.md (RU)
- [x] S4.5.3: Create sandcastle-guide.md (EN)
- [x] S4.5.4: Create sandcastle-guide.ru.md (RU)
- [x] S4.5.5: Update AGENTS.md with new modules
- [x] S4.5.6: Update README.md/README.ru.md

## M5: Final Verification | status: in_progress
### T5.1: Full test suite verification | agent:Reviewer
- [x] S5.1.1: Run all 63 unit tests
- [x] S5.1.2: Verify all tests pass
- [x] S5.1.3: Verify git clean + pushed
