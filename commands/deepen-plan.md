---
description: Enhance an existing plan with parallel research agents for depth, best practices, and implementation details
argument-hint: [path/to/plan.md]
---

# Deepen Plan

This command takes an existing plan and enhances each section with parallel research. Each major element gets dedicated research to find:
- Best practices and industry patterns
- Performance optimizations
- Quality enhancements and edge cases
- Real-world implementation examples

The result is a deeply grounded, production-ready plan with concrete implementation details.

## Plan File

<plan_path>$ARGUMENTS</plan_path>

**If no plan path provided:**
1. Check for recent plans: `ls -la plans/ 2>/dev/null || ls -la *.md`
2. Ask the user: "Which plan would you like to deepen? Please provide the path."

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

**CRITICAL: Launch ALL research in parallel using the Task tool.**

For each plan section, spawn research agents:

```
Task Explore: "Research best practices for: [section topic].
Find:
- Industry standards and conventions
- Performance considerations
- Common pitfalls to avoid
- Documentation and tutorials
Return concrete, actionable recommendations."
```

**Also search the web for current best practices:**

Use WebSearch for recent articles and documentation on technologies in the plan.

### 5. Run Review Agents

Discover and run all available review agents:

```bash
# Find all agent definitions
find ~/.claude -path "*/agents/*.md" 2>/dev/null
find .claude/agents -name "*.md" 2>/dev/null
```

Launch ALL review agents in parallel against the plan:

```
Task [agent-type]: "Review this plan using your expertise. Apply all checks and patterns.

Plan content:
[full plan content]"
```

**Rules:**
- Run ALL discovered agents, don't filter by "relevance"
- Launch ALL agents in a SINGLE message with multiple Task calls
- Each agent may catch something others miss

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

```markdown
## [Original Section Title]

[Original content preserved]

### Research Insights

**Best Practices:**
- [Concrete recommendation 1]
- [Concrete recommendation 2]

**Performance Considerations:**
- [Optimization opportunity]
- [Benchmark or metric to target]

**Implementation Details:**
```[language]
// Concrete code example
```

**Edge Cases:**
- [Edge case 1 and handling]
- [Edge case 2 and handling]

**References:**
- [Documentation URL 1]
- [Documentation URL 2]
```

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
```

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

## Example Enhancement

**Before:**
```markdown
## Technical Approach

Use React Query for data fetching with optimistic updates.
```

**After:**
```markdown
## Technical Approach

Use React Query for data fetching with optimistic updates.

### Research Insights

**Best Practices:**
- Configure `staleTime` and `cacheTime` based on data freshness requirements
- Use `queryKey` factories for consistent cache invalidation
- Implement error boundaries around query-dependent components

**Performance Considerations:**
- Enable `refetchOnWindowFocus: false` for stable data
- Use `select` option to transform and memoize data
- Consider `placeholderData` for instant perceived loading

**Implementation Details:**
```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      retry: 2,
      refetchOnWindowFocus: false,
    },
  },
});
```

**Edge Cases:**
- Handle race conditions with `cancelQueries` on unmount
- Implement retry logic for transient network failures

**References:**
- https://tanstack.com/query/latest/docs/react/guides/optimistic-updates
```

## Important

**NEVER write code during this command.** Only research and enhance the plan with findings.
