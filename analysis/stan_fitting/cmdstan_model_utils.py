"""Helpers for loading CmdStan models across Mac/Linux sync workflows."""

from __future__ import annotations

import os
import platform
import shutil
import subprocess

from cmdstanpy import CmdStanModel


def _exe_path(stan_file: str) -> str:
    base = stan_file[:-5] if stan_file.endswith(".stan") else stan_file
    name = os.path.basename(base)
    return os.path.join(os.path.dirname(stan_file), name)


def _binary_arch_mismatch(exe: str) -> bool:
    """Return True when an existing executable cannot run on this OS."""
    if not os.path.isfile(exe):
        return False
    if os.environ.get("CMDSTAN_FORCE_RECOMPILE", "").lower() in ("1", "true", "yes"):
        return True
    system = platform.system()
    try:
        desc = subprocess.check_output(["file", "-b", exe], text=True, stderr=subprocess.DEVNULL)
    except (FileNotFoundError, subprocess.CalledProcessError):
        return False
    if system == "Linux":
        return "ELF" not in desc
    if system == "Darwin":
        return "Mach-O" not in desc
    return False


def load_cmdstan_model(stan_file: str) -> CmdStanModel:
    """
    Load a Stan model, recompiling when a stale binary from a different
    operating system or architecture was synced into the repo.
    """
    exe = _exe_path(stan_file)
    if _binary_arch_mismatch(exe):
        print(f"Removing incompatible CmdStan binary: {exe}")
        if os.path.isfile(exe):
            os.remove(exe)
        build_dir = exe
        if os.path.isdir(build_dir):
            shutil.rmtree(build_dir)
        for suffix in (".exe", ".dSYM"):
            path = exe + suffix
            if os.path.exists(path):
                if os.path.isdir(path):
                    shutil.rmtree(path)
                else:
                    os.remove(path)
    model = CmdStanModel(stan_file=stan_file)
    if not os.path.isfile(exe):
        print(f"Compiling Stan model: {stan_file}")
        model.compile(force=True)
    return model
