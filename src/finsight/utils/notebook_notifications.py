import time
import subprocess

cell_start_time = None


def cell_started(info):
    global cell_start_time
    cell_start_time = time.time()


def cell_finished(result):
    global cell_start_time

    if cell_start_time is None:
        return

    duration = time.time() - cell_start_time

    if duration >= 20:
        subprocess.run(
            ["afplay", "/System/Library/Sounds/Hero.aiff"]
        )


def enable_cell_notifications():
    ipython = get_ipython()

    ipython.events.register("pre_run_cell", cell_started)
    ipython.events.register("post_run_cell", cell_finished)