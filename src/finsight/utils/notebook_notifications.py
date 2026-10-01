import time
import subprocess

cell_start_time = None
caffeinate_process = None
notifications_enabled = False


def cell_started(info):
    global cell_start_time, caffeinate_process

    cell_start_time = time.time()

    caffeinate_process = subprocess.Popen(
        ["caffeinate", "-i"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )


def cell_finished(result):
    global cell_start_time, caffeinate_process

    if caffeinate_process is not None:
        caffeinate_process.terminate()
        caffeinate_process = None

    if cell_start_time is None:
        return

    duration = time.time() - cell_start_time
    cell_start_time = None

    if duration >= 20:
        subprocess.Popen(
            ["afplay", "/System/Library/Sounds/Hero.aiff"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )


def enable_cell_notifications():
    global notifications_enabled

    if notifications_enabled or platform.system() != "Darwin":
        return

    ipython = get_ipython()

    ipython.events.register("pre_run_cell", cell_started)
    ipython.events.register("post_run_cell", cell_finished)

    notifications_enabled = True