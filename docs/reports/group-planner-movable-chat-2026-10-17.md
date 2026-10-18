# Movable Group Planner chat

The open chat panel can be dragged by its title/grip handle instead of staying
in its initial corner. The floating Chat & Polls button on other tabs is also
draggable; dragging it does not accidentally open or close the chat.

- Mouse and touch pointer input use capture so a drag continues outside the handle.
- A focused handle/button supports arrow keys; Shift moves in larger steps.
- Panel and launcher placements are remembered locally and fitted back inside
  the visible screen when it resizes, rotates or the mobile keyboard changes it.
- Reset chat position returns the panel to its initial corner. Closing/reopening
  retains placement. Message inputs, scrollable history, menus and close/reset
  controls are separate from the drag handle. Drafts survive movement.
- Preference storage is optional; missing or malformed values do not break chat.

Validation: 9 targeted frontend tests passed, including chat state regressions.
ESLint, TypeScript and the production build passed. The existing large-chunk
build advisory remains. Isolated demo browser checks cover mouse and touch
dragging, the floating launcher, persisted position after reload, draft retention,
keyboard movement, reset and mobile screen bounds, with no page errors or real
user-data mutations. Screenshots and logs are retained in ignored
`.tripraft/test-temp/group-planner-ui/`.

Saved locally in Interactive Smartlog with the `group-planner-movable-chat`
bookmark. Only this task's files are included; unrelated workspace edits remain
outside the checkpoint. No push or deployment was performed.
