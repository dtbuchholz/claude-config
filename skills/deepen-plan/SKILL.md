---
name: deepen-plan
description:
  Enhance an existing plan with parallel research agents for depth, best practices, and
  implementation details.
---

# Deepen Plan

Takes an existing plan and enhances each section with parallel research. Each major element gets
dedicated research to find best practices, performance optimizations, quality enhancements, and
real-world examples.

## When This Skill Applies

- User has an existing plan file they want to enhance
- User asks to "deepen" or "research" a plan
- User wants implementation details for a plan

## Plan File

The user should provide a path to the plan file. If not provided:

1. Check Claude Code's plan mode location first (most recent plans):
   ```bash
   ls -lt ~/.claude/plans/*.md 2>/dev/null | head -5
   ```
2. Check for local plans:
   ```bash
   ls -la plans/ 2>/dev/null || ls -la *.md
   ```
3. If multiple plans found, show the user and ask which one to deepen
4. If no plans found, ask the user: "Which plan would you like to deepen? Please provide the path."

Do not proceed until you have a valid plan file path.

## Workflow

### 1. Parse Plan Structure

Read the plan file and extract:

- Overview/Problem Statement
- Proposed Solution sections
- Technical Approach/Architecture
- Implementation phases/steps
- Code examples and file references
- Acceptance criteria
- UI/UX components mentioned
- Technologies/frameworks mentioned
- Domain areas (data models, APIs, UI, security, performance, etc.)

Create a section manifest:

```
Section 1: [Title] - [Brief description of what to research]
Section 2: [Title] - [Brief description of what to research]
...
```

### 2. Discover Available Skills

Check all skill sources and match to plan content:

```bash
# Project-local skills
ls .claude/skills/ 2>/dev/null

# User's global skills
ls ~/.claude/skills/ 2>/dev/null

# Plugin skills
find ~/.claude/plugins -type d -name "skills" 2>/dev/null
```

For each discovered skill:

1. Read its SKILL.md to understand what it does
2. Check if any plan sections match the skill's domain
3. If matched, spawn a sub-agent to apply that skill's knowledge

### 3. Discover Documented Learnings

Check for previously solved problems:

```bash
# Project learnings
find docs/solutions -name "*.md" -type f 2>/dev/null

# Alternative locations
find .claude/docs -name "*.md" -type f 2>/dev/null
```

For each learning file:

1. Read frontmatter (title, category, tags, module)
2. Filter by relevance to plan technologies/domains
3. Spawn sub-agents for relevant learnings

### 4. Launch Parallel Research Agents

**CRITICAL: Launch ALL research in a SINGLE message with multiple Task tool calls.**

Based on the plan's technologies and sections, spawn these agents IN PARALLEL:

```
Task (model: haiku, subagent_type: Explore): "Research best practices for: [technology 1]
Find: industry standards, performance tips, common pitfalls, documentation.
Return concrete, actionable recommendations."

Task (model: haiku, subagent_type: Explore): "Research best practices for: [technology 2]
..."

Task (model: haiku, subagent_type: Explore): "Research implementation patterns for: [section topic]
..."
```

**Spawn one agent per:**

- Each major technology mentioned (React, Rails, PostgreSQL, etc.)
- Each architectural concern (caching, auth, API design, etc.)
- Each domain area (data models, UI components, etc.)

**Also use WebSearch** for recent documentation on each technology.

### 5. Run Review Agents

Discover available review agents:

```bash
# Find all agent definitions
find ~/.claude -path "*/agents/*.md" 2>/dev/null
find .claude/agents -name "*.md" 2>/dev/null
```

**Launch ALL review agents in a SINGLE message with multiple Task tool calls.**

Use `model: haiku` for each reviewer to keep costs low:

```
Task (model: haiku, subagent_type: general-purpose): "ARCHITECTURE REVIEW
Review this plan for architectural concerns:
- Scalability issues
- Coupling problems
- Missing components
Plan: [content]"

Task (model: haiku, subagent_type: general-purpose): "SECURITY REVIEW
Review this plan for security concerns:
- Auth/authz gaps
- Data exposure risks
- Input validation
Plan: [content]"

Task (model: haiku, subagent_type: general-purpose): "SIMPLICITY REVIEW
Review this plan for over-engineering:
- Unnecessary complexity
- Simpler alternatives
- YAGNI violations
Plan: [content]"

Task (model: haiku, subagent_type: general-purpose): "TESTABILITY REVIEW
Review this plan for testing concerns:
- Hard-to-test patterns
- Missing test strategies
- Edge cases to cover
Plan: [content]"
```

**Rules:**

- Launch ALL agents in a SINGLE message
- Each agent catches different issues
- Don't filter by "relevance" - run them all

### 6. Synthesize Findings

Wait for ALL parallel agents to complete, then collect:

From skill agents:

- [ ] Code patterns and examples
- [ ] Framework-specific recommendations

From research agents:

- [ ] Best practices and documentation
- [ ] Performance considerations
- [ ] Real-world examples

From review agents:

- [ ] Architecture feedback
- [ ] Security considerations
- [ ] Simplicity recommendations

From learnings:

- [ ] Past solutions that apply
- [ ] Mistakes to avoid

**Deduplicate and prioritize:**

- Merge similar recommendations
- Prioritize by impact
- Flag conflicting advice
- Group by plan section

### 7. Enhance Plan Sections

For each section, add research insights:

````markdown
## [Original Section Title]

[Original content preserved]

### Research Insights

**Best Practices:**

- [Concrete recommendation 1]
- [Concrete recommendation 2]

**Performance Considerations:**

- [Optimization opportunity]
- [Benchmark or metric to target]

**Implementation Details:** ```[language] // Concrete code example
````

**Edge Cases:**

- [Edge case 1 and handling]
- [Edge case 2 and handling]

**References:**

- [Documentation URL 1]
- [Documentation URL 2]

````

### 8. Add Enhancement Summary

At the top of the enhanced plan:

```markdown
## Enhancement Summary

**Deepened on:** [Date]
**Sections enhanced:** [Count]
**Research sources:** [List agents/skills used]

### Key Improvements

1. [Major improvement 1]
2. [Major improvement 2]
3. [Major improvement 3]

### New Considerations Discovered

- [Important finding 1]
- [Important finding 2]
````

### 9. Write Enhanced Plan

Update the plan file in place, or create `[original-name]-deepened.md` if user prefers.

## Quality Checks

Before finalizing:

- [ ] All original content preserved
- [ ] Research insights clearly marked
- [ ] Code examples are syntactically correct
- [ ] Links are valid and relevant
- [ ] No contradictions between sections

## Post-Enhancement

After writing the enhanced plan, ask the user:

**"Plan deepened. What next?"**

Options:

1. **View diff** - Show what was added
2. **Review** - Get feedback from `/review`
3. **Implement** - Start working on the plan
4. **Deepen further** - Research specific sections more

## Important

**NEVER write code during this skill.** Only research and enhance the plan with findings.
