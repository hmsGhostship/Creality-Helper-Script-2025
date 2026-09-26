#!/usr/bin/env python3
"""Offline checks for scripts/tools.sh — no printer, no daemons.

    python3 -m pytest -q tests/

WHY THIS FILE EXISTS
--------------------
helper.sh sets `set -e` once and sources every scripts/*.sh into that same
shell, so any command in a menu action that exits non-zero terminates the
whole helper: the user is dumped to a bare prompt with no menu to return to.
tests/test_retire_nexusp.py documents the same contract for retire_nexusp.sh.

The case pinned here was reported by a user: "Clear cache" printed

    ERROR: unknown command "cache" - maybe you meant "check"

and the helper exited. The printer's stock /usr/bin/pip is 19.3.1 (verified on
a K1C 2025), which predates the `pip cache` subcommand (pip 20.1). A newer pip
fails the same step differently: the function has just removed /root/.cache,
where pip keeps its cache, so `pip cache purge` reports "No matching packages"
and exits 1 too (verified with pip 21.2.4 against an empty PIP_CACHE_DIR).

The same errexit contract is pinned for the two lines above the pip step:
`git gc` on a corrupted checkout exits 128 (now reported, and the action
carries on), and `read` returns non-zero when stdin hits end-of-input (now
treated as "no", the contract test_retire_nexusp.py pins for its prompt).

Each test sources the real tools.sh under `set -e`, shims the commands the
action would otherwise run for real (rm, git, pip), answers the confirmation
prompt, and checks that control comes back to the caller.

⚠ Add cases as `test_*` functions. A file named test_*.py whose assertions live
in a hand-rolled runner gets collected and runs nothing while reporting green.
"""
import os
import shutil
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(REPO, "scripts", "tools.sh")
# Resolved now, with the real PATH: run_sh hands bash a PATH holding only an
# empty directory, and subprocess looks the executable up in the PATH it is
# GIVEN, not ours.
BASH = shutil.which("bash")

# What pip 19.3.1 prints for `pip cache purge`, verbatim from a K1C 2025.
PIP_19_3_1 = (
    'pip() { echo "ERROR: unknown command \\"cache\\" - maybe you meant '
    '\\"check\\"" >&2; return 1; }'
)
# What pip >= 20.1 prints when the cache directory is already gone.
PIP_MODERN_EMPTY_CACHE = 'pip() { echo "ERROR: No matching packages" >&2; return 1; }'
# What pip >= 20.1 prints when it actually has something to purge.
PIP_MODERN_POPULATED_CACHE = 'pip() { echo "Files removed: 12"; return 0; }'
# The git gc step succeeds unless a test says otherwise.
DEFAULT_GIT_SHIM = 'git() { echo "git $*"; }'
# What a corrupted object store or a zip-installed checkout prints for git gc.
GIT_GC_FAILS = 'git() { echo "fatal: not a git repository" >&2; return 128; }'


def run_sh(body, tmp_path, pip_shim=None, git_shim=None):
    """Source tools.sh with side-effecting commands shimmed, then run `body`.

    `set -e` is on, exactly as helper.sh has it, because that is the condition
    these tests exist to check. rm and git are shell functions so nothing here
    can touch /root/.cache or run git gc on a real checkout; git_shim replaces
    the always-succeeding default. pip is whichever shim the test asks for, or
    absent from PATH entirely when None.
    """
    env = dict(os.environ)
    bindir = tmp_path / "bin"
    bindir.mkdir(exist_ok=True)
    # PATH is one empty directory: builtins (echo, read, cd) still work, and
    # an unshimmed external command fails with 127 instead of running for real.
    env["PATH"] = str(bindir)
    preamble = f"""
set -e
white=; yellow=; cyan=; green=; darkred=; red=
error_msg() {{ echo "ERR: $1"; }}
ok_msg() {{ echo "OK: $1"; }}
rm() {{ echo "rm $*"; }}
{git_shim or DEFAULT_GIT_SHIM}
{pip_shim or ''}
HELPER_SCRIPT_FOLDER={tmp_path}
. {SCRIPT}
"""
    return subprocess.run([BASH, "-c", preamble + body],
                          capture_output=True, text=True, env=env, cwd=REPO)


CLEAR_CACHE = """
echo y | clear_cache
echo SURVIVED
"""


def test_clear_cache_survives_a_pip_without_the_cache_subcommand(tmp_path):
    """The reported crash: pip 19.3.1 has no `cache` command. The helper must
    finish the action and return to its menu, not exit."""
    r = run_sh(CLEAR_CACHE, tmp_path, pip_shim=PIP_19_3_1)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "SURVIVED" in r.stdout, r.stdout + r.stderr
    assert "OK: Cache has been cleared!" in r.stdout, r.stdout
    # The confusing pip error is not shown to the user either.
    assert "unknown command" not in r.stdout + r.stderr, r.stdout + r.stderr


def test_clear_cache_survives_a_modern_pip_with_an_empty_cache(tmp_path):
    """A pip that does know `cache` still exits 1 here, because the function
    removed the cache directory one step earlier. Same contract."""
    r = run_sh(CLEAR_CACHE, tmp_path, pip_shim=PIP_MODERN_EMPTY_CACHE)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "SURVIVED" in r.stdout, r.stdout + r.stderr


def test_clear_cache_survives_no_pip_at_all(tmp_path):
    """No pip on PATH (127). The other cache steps already ran; missing pip is
    not a reason to abandon the menu."""
    r = run_sh(CLEAR_CACHE, tmp_path, pip_shim=None)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "SURVIVED" in r.stdout, r.stdout + r.stderr


def test_clear_cache_still_runs_the_other_steps(tmp_path):
    """The guard must only soften the pip step. The cache directory removal
    and git gc still happen, in that order."""
    r = run_sh(CLEAR_CACHE, tmp_path, pip_shim=PIP_19_3_1)
    out = r.stdout
    i_rm = out.find("rm -rf /root/.cache")
    i_gc = out.find("gc --aggressive --prune=all")
    assert i_rm != -1 and i_gc != -1, out
    assert i_rm < i_gc, out


def test_declining_clear_cache_returns_to_the_caller(tmp_path):
    """Answering n must cancel without exiting the helper."""
    r = run_sh("""
echo n | clear_cache
echo SURVIVED
""", tmp_path, pip_shim=PIP_19_3_1)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "ERR: Clearing cache canceled!" in r.stdout, r.stdout
    assert "rm -rf" not in r.stdout, r.stdout


def test_clear_cache_with_a_working_pip_is_quiet_and_still_succeeds(tmp_path):
    """pip exiting 0 is the one case the old code handled; the guard must not
    break it. Its stdout is now discarded along with its stderr, so the user
    sees the helper's own Info line and then the ok_msg, not pip's chatter."""
    r = run_sh(CLEAR_CACHE, tmp_path, pip_shim=PIP_MODERN_POPULATED_CACHE)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "SURVIVED" in r.stdout, r.stdout + r.stderr
    assert "OK: Cache has been cleared!" in r.stdout, r.stdout
    assert "Files removed" not in r.stdout + r.stderr, r.stdout + r.stderr
    assert "Info: Clearing pip cache..." in r.stdout, r.stdout


def test_clear_cache_still_invokes_pip_cache_purge_after_git_gc(tmp_path):
    """`|| true` and the redirects must not turn the pip step into a no-op.
    pip's own output is discarded, so the shim records its invocation in a
    file instead; the Info lines carry the ordering."""
    log = tmp_path / "pip.log"
    shim = f'pip() {{ echo "pip $*" >> "{log}"; return 1; }}'
    r = run_sh(CLEAR_CACHE, tmp_path, pip_shim=shim)
    assert r.returncode == 0, r.stdout + r.stderr
    assert log.read_text().splitlines() == ["pip cache purge"], log.read_text()
    i_gc = r.stdout.find("Info: Clearing git cache...")
    i_pip = r.stdout.find("Info: Clearing pip cache...")
    assert -1 < i_gc < i_pip, r.stdout


def test_clear_cache_reprompts_on_an_invalid_answer(tmp_path):
    """Anything but y/n re-asks rather than exiting or proceeding; a y on the
    next line then runs the action."""
    r = run_sh("""
printf 'x\\ny\\n' | clear_cache
echo SURVIVED
""", tmp_path, pip_shim=PIP_19_3_1)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "ERR: Please select a correct choice!" in r.stdout, r.stdout
    assert "OK: Cache has been cleared!" in r.stdout, r.stdout
    assert "SURVIVED" in r.stdout, r.stdout


def test_clear_cache_survives_a_failing_git_gc(tmp_path):
    """git gc is the step right before pip and was just as unguarded under
    helper.sh's global set -e. A power-cut-corrupted .git must not kill the
    helper; the user is told and the action carries on."""
    r = run_sh(CLEAR_CACHE, tmp_path, pip_shim=PIP_19_3_1, git_shim=GIT_GC_FAILS)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "SURVIVED" in r.stdout, r.stdout + r.stderr
    assert "ERR: Git cache could not be cleared" in r.stdout, r.stdout
    assert "OK: Cache has been cleared, except the git cache!" in r.stdout, r.stdout
    assert "OK: Cache has been cleared!" not in r.stdout, r.stdout


def test_a_closed_stdin_cancels_clear_cache_rather_than_killing_the_helper(tmp_path):
    """`read` returns non-zero on EOF, and under helper.sh's global set -e that
    exits the whole helper with no message. EOF is a no, not a yes: the same
    contract test_retire_nexusp.py pins for its confirmation prompt."""
    r = run_sh("""
clear_cache < /dev/null
echo SURVIVED
""", tmp_path, pip_shim=PIP_19_3_1)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "SURVIVED" in r.stdout, r.stdout + r.stderr
    assert "ERR: Clearing cache canceled!" in r.stdout, r.stdout
    assert "rm -rf" not in r.stdout, r.stdout


def test_an_unterminated_yes_is_treated_as_a_cancel(tmp_path):
    """`read` returns non-zero on EOF even when it already filled yn, so a
    piped 'y' with no newline is overridden to 'n'. A terminal always sends
    the newline, so this only affects piped input; pin it as a decision."""
    r = run_sh("""
printf y | clear_cache
echo SURVIVED
""", tmp_path, pip_shim=PIP_19_3_1)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "SURVIVED" in r.stdout, r.stdout + r.stderr
    assert "ERR: Clearing cache canceled!" in r.stdout, r.stdout
    assert "rm -rf" not in r.stdout, r.stdout


def test_clear_cache_survives_a_missing_helper_folder(tmp_path):
    """The checkout is addressed with `git -C`, not `cd`: a missing or moved
    helper folder is reported by the git gc guard instead of killing the
    helper at an unguarded cd, and the menu shell's working directory is
    left alone for every later action."""
    r = run_sh("""
HELPER_SCRIPT_FOLDER=$PWD/does-not-exist
before=$PWD
# A here-string, not a pipe: a pipeline runs the action in a subshell,
# whose cd could never reach the $PWD checked below. This runs it in the
# test shell, the way helper.sh's menu shell runs it.
clear_cache <<< y
[ "$PWD" = "$before" ] && echo CWD_UNCHANGED
echo SURVIVED
""", tmp_path, pip_shim=PIP_19_3_1, git_shim=GIT_GC_FAILS)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "SURVIVED" in r.stdout, r.stdout + r.stderr
    assert "CWD_UNCHANGED" in r.stdout, r.stdout
    assert "No such file" not in r.stdout + r.stderr, r.stdout + r.stderr
