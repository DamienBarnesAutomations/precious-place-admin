You are a senior data engineer writing documentation for a technical portfolio 
project. Read every file in this repository carefully before writing anything.

Before writing anything, output a short "Repo scan" section (which will be 
deleted before publishing) that lists:
- Every file you read
- Your understanding of the data flow in one paragraph
- Any files that were ambiguous or unclear

Only proceed to write the README after completing the repo scan.

---

Write a README.md for this project that covers:

1. **What this project is** — one clear paragraph. What problem does it solve, 
   what does it demonstrate, who is the intended audience.

2. **Architecture** — Mermaid diagram showing how the components connect.
   Be specific to what actually exists in this repo, not generic.

3. **Tech stack** — table format. Component, Technology, Purpose. 
   Only include what is actually used.

4. **Project structure** — the actual folder/file tree with one line 
   explaining what each file does. No placeholder files.

5. **Quick start** — exact commands to get this running from a fresh clone. 
   Assume the reader has Docker and Git. Nothing else.

6. **How it works** — walk through the pipeline/process step by step. 
   Be specific. Reference actual file names and function names.

7. **Design decisions** — 3-5 decisions made during the build and why. 
   Each decision must reference a specific file, function, or config value 
   as evidence. Do not write a decision you cannot point to in the code. 
   These should reflect real tradeoffs, not obvious choices.

8. **What this demonstrates** — bullet points mapping each technical component 
   to the skill it proves, with a specific file or function as evidence for 
   each bullet. Written for a hiring manager or interviewer.

9. **Limitations / Out of scope** — 2-4 honest statements about what this 
   project does not do and why. This is a feature, not an apology — it signals 
   engineering judgment about scope.

Rules:
- Do not use filler phrases like "robust", "seamless", "powerful", or "cutting-edge"
- Do not invent features that don't exist in the code
- Do not add sections that have no content
- Every code block must be a real command that actually works
- Write as if the reader is a senior engineer who will verify every claim
- For sections 7 and 8, every point must cite a specific file, function, 
  or config value from the repo as evidence — no uncited claims