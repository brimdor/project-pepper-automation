# project-pepper-automation

Keeps issues in [Project Pepper](https://github.com/users/aftrmusicbooking-bot/projects/2)
aligned with their project status:

- `Done` closes the issue.
- Any other status, including no status, reopens the issue.
- Closed issues remain in the project and visible in the `Done` swimlane.

GitHub's built-in **Auto-close issue** workflow handles the immediate close.
The scheduled workflow reconciles both directions every five minutes because
user-owned GitHub Projects do not emit an Actions event when an item changes
status.
