---
name: explain
description: Explain how a piece of code works, tracing through its execution and dependencies.
---

# Explain Code

Provide a clear, thorough explanation of code specified by the user, tracing through its execution
and dependencies.

## When This Skill Applies

- User asks to explain a function, class, or code block
- User asks "how does X work?"
- User wants to understand code flow or dependencies

## Explanation Structure

### 1. High-Level Overview

Start with a 1-2 sentence summary of what this code does and its purpose in the larger system.

### 2. Execution Flow

Walk through the code step-by-step:

- What happens when this code is called/executed?
- What are the inputs and outputs?
- What side effects does it have?

### 3. Key Dependencies

Identify and briefly explain:

- What other modules/functions does this code depend on?
- What external services or APIs does it interact with?
- What data structures does it use?

### 4. Important Details

Highlight any:

- Non-obvious behavior
- Edge cases handled
- Error handling patterns
- Performance considerations
- Security implications

### 5. Usage Examples

If applicable, show how this code is typically used or called.

## Guidelines

- Use clear, jargon-free language where possible
- Reference specific line numbers when explaining complex logic
- If the code is part of a larger pattern, explain the pattern
- If there are potential improvements or issues, note them briefly at the end
