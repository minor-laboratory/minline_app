# Hot Reload

Sends hot reload command to tmux session.

```bash
tmux list-sessions 2>&1 | grep -q miniline_app && tmux send-keys -t miniline_app 'r' C-m
```
