# CLI Reference — OpenCode Initializer v15.0.0

## Overview

OpenCode Initializer provides 141 modules organized in 8 phases. Each module exposes CLI commands via `cmd_*` functions.

## Skill Management (62-65)

### opencode skill

```bash
# Search skills in registry
opencode skill search <query>

# List installed skills
opencode skill list

# List available skills
opencode skill available [limit]

# Get skill info
opencode skill info <name>

# Install skill
opencode skill install <spec>  # e.g., code-review@1.2.0

# Uninstall skill
opencode skill uninstall <name>

# Publish skill
opencode skill publish [dir] [workspace]

# Validate skill
opencode skill validate [dir]
```

### opencode skill-manager

```bash
# Get installed version
opencode skill-manager version <name>

# Check for updates
opencode skill-manager updates [name]

# Update skill
opencode skill-manager update <name> [version]

# Rollback to previous version
opencode skill-manager rollback <name>

# List backups
opencode skill-manager backups <name>

# Show history
opencode skill-manager history [name] [limit]

# Clean old backups
opencode skill-manager cleanup [keep]
```

### opencode skill-security

```bash
# Scan skill for security issues
opencode skill-security scan [dir] [format]

# Get security score
opencode skill-security score [dir]

# Get security level
opencode skill-security level [dir]
```

### opencode skill-eval

```bash
# Run evaluation
opencode skill-eval run <name> [scenario] [format]

# Compare two skills
opencode skill-eval compare <name1> <name2>

# Calculate overall score
opencode skill-eval score <metrics...>
```

## Agent Orchestration (66-71)

### opencode orchestrator

```bash
# Run workflow
opencode orchestrator run <name> [input] [async]

# Get run status
opencode orchestrator status <name> [run_id]

# List runs
opencode orchestrator runs <name>

# List workflows
opencode orchestrator list

# Cancel workflow
opencode orchestrator cancel <name> [run_id]
```

### opencode pipeline

```bash
# Create pipeline
opencode pipeline create <name> [description]

# Add step
opencode pipeline add-step <pipeline> <name> <type>

# Run pipeline
opencode pipeline run <pipeline> [input]

# List pipelines
opencode pipeline list
```

### opencode agent-mesh

```bash
# Register agent
opencode agent-mesh register <name> <type> [endpoint] [skills]

# Unregister agent
opencode agent-mesh unregister <name>

# List agents
opencode agent-mesh list

# Find agents by type
opencode agent-mesh find <type>

# Find agents by skill
opencode agent-mesh skill <skill>

# Get agent info
opencode agent-mesh info <name>

# Check agent health
opencode agent-mesh health <name>
```

### opencode agent-protocol

```bash
# Send message
opencode agent-protocol send <to> <type> [payload]

# Receive messages
opencode agent-protocol receive <agent>

# Acknowledge message
opencode agent-protocol ack <agent> <message_id>

# Delegate task
opencode agent-protocol delegate <agent> <task>

# Report completion
opencode agent-protocol complete <agent> <task_id>

# List pending messages
opencode agent-protocol queue <agent>

# Clear processed messages
opencode agent-protocol clear <agent> [status]
```

### opencode context

```bash
# Store context
opencode context store <type> <key> <data>

# Retrieve context
opencode context retrieve <type> <key>

# Search context
opencode context search <query> [type]

# Compact old entries
opencode context compact <type> [max_age]

# Get statistics
opencode context stats [type]

# List context types
opencode context types
```

### opencode memory

```bash
# Store memory
opencode memory store <type> <key> <data> [importance]

# Retrieve memory
opencode memory retrieve <type> <key>

# Search memories
opencode memory search <query> [type] [limit]

# Write to WAL
opencode memory wal-write <operation> <data>

# Read WAL
opencode memory wal-read [limit]

# Replay WAL
opencode memory wal-replay

# Checkpoint WAL
opencode memory checkpoint

# Get statistics
opencode memory stats [type]

# List memory types
opencode memory types

# Clean old memories
opencode memory cleanup [max_age] [min_importance]
```

## Enterprise Features (72-77)

### opencode rbac

```bash
# Initialize RBAC
opencode rbac init

# Create role
opencode rbac create <name> [desc] [perms] [level]

# List roles
opencode rbac list

# Get role info
opencode rbac get <name>

# Delete role
opencode rbac delete <name>

# Check permission
opencode rbac check <role> <permission>

# Get autonomy level
opencode rbac autonomy <name>

# Create policy
opencode rbac policy-create <name> [desc] [rules]

# List policies
opencode rbac policy-list
```

### opencode governance

```bash
# Initialize governance
opencode governance init

# List rules
opencode governance rules

# Add rule
opencode governance add-rule <id> <name> [desc] [sev] [conds] [action]

# Log audit event
opencode governance audit <type> <actor> <action> [resource]

# Read audit log
opencode governance log [limit] [actor]

# Check if action allowed
opencode governance check <action> [actor]

# Run compliance check
opencode governance compliance <standard>
```

### opencode compliance

```bash
# Generate report
opencode compliance report <standard> [format]

# Calculate score
opencode compliance score <standard>
```

### opencode security-posture

```bash
# Run assessment
opencode security-posture assess [format]

# Scan for vulnerabilities
opencode security-posture scan [target]
```

### opencode analytics

```bash
# Track event
opencode analytics track <type> <name> [properties]

# Track skill usage
opencode analytics track-skill <name> <action>

# Track agent action
opencode analytics track-agent <name> <action>

# Count by type
opencode analytics count-type

# Count by name
opencode analytics count-name

# Get events for period
opencode analytics period <start> [end]

# Show dashboard
opencode analytics dashboard

# Export data
opencode analytics export [format] [output]
```

### opencode observability

```bash
# Initialize
opencode observability init

# Set metric
opencode observability metric-set <name> <value>

# Increment metric
opencode observability metric-incr <name> [increment]

# Get metric
opencode observability metric-get <name>

# Get all metrics
opencode observability metrics

# Create alert
opencode observability alert-create <name> <metric> <threshold> [condition] [action]

# Check alerts
opencode observability alert-check

# List alerts
opencode observability alert-list

# Show dashboard
opencode observability dashboard

# Run health check
opencode observability health
```

## Ecosystem Expansion (78-82)

### opencode marketplace

```bash
# Search marketplace
opencode marketplace search <query> [category] [limit]

# List categories
opencode marketplace categories

# Get plugin info
opencode marketplace info <name>

# Install plugin
opencode marketplace install <name> [version]

# List installed plugins
opencode marketplace list

# Uninstall plugin
opencode marketplace uninstall <name>
```

### opencode plugin

```bash
# Enable plugin
opencode plugin enable <name>

# Disable plugin
opencode plugin disable <name>

# List enabled plugins
opencode plugin enabled

# Set config
opencode plugin config-set <name> <key> <val>

# Get config
opencode plugin config-get <name> [key]

# Get info
opencode plugin info <name>
```

### opencode template

```bash
# Create template
opencode template create <name> [description]

# List templates
opencode template list

# Use template
opencode template use <name> [target_dir]

# Delete template
opencode template delete <name>
```

### opencode integration

```bash
# Register integration
opencode integration register <name> <type> [endpoint] [credentials]

# List integrations
opencode integration list

# Get info
opencode integration info <name>

# Remove integration
opencode integration remove <name>

# Setup GitHub
opencode integration github <token>

# Setup GitLab
opencode integration gitlab <token> [url]

# Setup Slack
opencode integration slack <webhook>
```

### opencode connector

```bash
# Test connector
opencode connector test <type> [endpoint]

# List connectors
opencode connector list
```

## Agent Harness (83-100)

### opencode context-engineering

```bash
# Optimize context
opencode context-engineering optimize <file> [budget] [strategy]

# Build SCEI prompt
opencode context-engineering scei <system> <context> <examples> <input>

# Analyze context
opencode context-engineering analyze <file>
```

### opencode learning

```bash
# Record feedback
opencode learning feedback <task> <agent> <rating> [comment]

# Get summary
opencode learning summary

# Update model
opencode learning update <skill> <improvement>

# Get recommendations
opencode learning recommend

# Analyze skill
opencode learning analyze <skill>
```

### opencode automation

```bash
# Create automation
opencode automation create <name> <trigger> <action> [schedule]

# List automations
opencode automation list

# Run automation
opencode automation run <name>

# Enable automation
opencode automation enable <name>

# Disable automation
opencode automation disable <name>

# Delete automation
opencode automation delete <name>
```

### opencode sandbox

```bash
# Create sandbox
opencode sandbox create <name> [isolation] [policy]

# List sandboxes
opencode sandbox list

# Start sandbox
opencode sandbox start <name>

# Stop sandbox
opencode sandbox stop <name>

# Delete sandbox
opencode sandbox delete <name>

# Get info
opencode sandbox info <name>
```

### opencode cicd

```bash
# List pipelines
opencode cicd list [type]

# Trigger pipeline
opencode cicd trigger <pipeline> [branch] [type]

# Get status
opencode cicd status <pipeline> [type]
```

### opencode workflow-engine

```bash
# Create workflow
opencode workflow-engine create <name> [description]

# Add step
opencode workflow-engine add-step <workflow> <name> <type>

# Run workflow
opencode workflow-engine run <workflow> [input]

# List workflows
opencode workflow-engine list
```

### opencode security-policy

```bash
# Create policy
opencode security-policy create <name> [description] [rules]

# List policies
opencode security-policy list

# Check compliance
opencode security-policy check <action> [resource]

# Enable policy
opencode security-policy enable <name>

# Disable policy
opencode security-policy disable <name>
```

### opencode secrets

```bash
# Store secret
opencode secrets store <key> <value> [description]

# Get secret
opencode secrets get <key>

# List secrets
opencode secrets list

# Delete secret
opencode secrets delete <key>

# Rotate secret
opencode secrets rotate <key> <new_value>

# Export as env vars
opencode secrets export
```

## Harness Core (91-100)

### opencode harness

```bash
# Initialize harness
opencode harness init

# Run TAO loop
opencode harness run <task> [max_iter]

# Get status
opencode harness status
```

### opencode harness-tools

```bash
# Register tool
opencode harness-tools register <name> <type> <desc> <cmd>

# List tools
opencode harness-tools list

# Run tool
opencode harness-tools run <name> [args...]

# Enable tool
opencode harness-tools enable <name>

# Disable tool
opencode harness-tools disable <name>
```

### opencode harness-memory

```bash
# Store in memory
opencode harness-memory store <level> <key> <data>

# Retrieve from memory
opencode harness-memory retrieve <level> <key>

# Search memory
opencode harness-memory search <query> [level]

# List levels
opencode harness-memory levels
```

### opencode harness-context

```bash
# Build context
opencode harness-context build <task> [files] [max_tokens]

# Compact context
opencode harness-context compact <context> [target_size]
```

### opencode harness-prompt

```bash
# Build SCEI prompt
opencode harness-prompt scei <system> <context> <examples> <input>

# Build hierarchical prompt
opencode harness-prompt hierarchical <system> <tools> <memory> <history> <input>
```

### opencode harness-state

```bash
# Save state
opencode harness-state save <session_id> <state>

# Load state
opencode harness-state load <session_id>

# List states
opencode harness-state list
```

### opencode harness-errors

```bash
# Classify error
opencode harness-errors classify <error>

# Handle error
opencode harness-errors handle <type> <message> [retries]
```

### opencode harness-guardrails

```bash
# Check input guardrail
opencode harness-guardrails input <input> [rules]

# Check output guardrail
opencode harness-guardrails output <output>

# Check tool guardrail
opencode harness-guardrails tool <name> [args]
```

### opencode harness-verify

```bash
# Verify with tests
opencode harness-verify tests <command>

# Verify with linter
opencode harness-verify lint <command>

# Verify with type checker
opencode harness-verify types <command>
```

### opencode harness-subagents

```bash
# Create subagent
opencode harness-subagents create <name> <type> <task>

# List subagents
opencode harness-subagents list

# Get status
opencode harness-subagents status <name>

# Update status
opencode harness-subagents update <name> <status>
```

## PLA & RAG (101-110)

### opencode pla

```bash
# Create PLA pipeline
opencode pla create <name> [description]

# Run PLA pipeline
opencode pla run <pipeline> [input]

# List PLA pipelines
opencode pla list
```

### opencode pla-extract

```bash
# Extract from file
opencode pla-extract file <file> [pattern]

# Extract structured data
opencode pla-extract structured <file> [format]
```

### opencode pla-analyze

```bash
# Analyze code
opencode pla-analyze code <file>

# Analyze dependencies
opencode pla-analyze deps <dir>
```

### opencode pla-verify

```bash
# Verify format
opencode pla-verify format <data> <format>

# Verify completeness
opencode pla-verify complete <data> <required_fields>
```

### opencode pla-synthesize

```bash
# Synthesize report
opencode pla-synthesize report <title> <data> [format]

# Synthesize summary
opencode pla-synthesize summary <data> [max_length]
```

### opencode pla-coordinate

```bash
# Coordinate flow
opencode pla-coordinate flow <pipeline> <current> <next>

# Branch flow
opencode pla-coordinate branch <condition> <true> <false>
```

### opencode rag

```bash
# Hybrid search
opencode rag search <query> [limit]
```

### opencode rag-bm25

```bash
# BM25 search
opencode rag-bm25 search <query> [limit]

# Index document
opencode rag-bm25 index <file>
```

### opencode rag-vector

```bash
# Vector search
opencode rag-vector search <query> [limit]

# Store vector
opencode rag-vector store <file> [collection]
```

### opencode rag-fusion

```bash
# Calculate RRF score
opencode rag-fusion score <rank> [k]

# Fuse results
opencode rag-fusion fuse <bm25_results> <vector_results> [limit]
```

## Production Hardening (111-116)

### opencode perf

```bash
# Run benchmark
opencode perf benchmark [target] [iterations]

# Optimize performance
opencode perf optimize [target]
```

### opencode cache

```bash
# Clear cache
opencode cache clear [type]

# Get cache size
opencode cache size [type]

# List cache contents
opencode cache list
```

### opencode security-hardening

```bash
# Run security hardening
opencode security-hardening run
```

### opencode vuln-scan

```bash
# Scan for vulnerabilities
opencode vuln-scan scan [target]
```

### opencode scalability

```bash
# Check scalability
opencode scalability check
```

### opencode lb

```bash
# Check load balancer status
opencode lb status
```

---

*CLI Reference for OpenCode Initializer v15.0.0*  
*141 modules, 102 features*
