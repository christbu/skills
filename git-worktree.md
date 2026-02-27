### GIT Worktree

# in the main repo checkout
git config extensions.worktreeconfig true
# then in the worktree
hooks="$(git rev-parse --git-common-dir)/hooks"
git config --worktree core.hookspath "$hooks"

