import QtQuick
import Quickshell.Io

Item {
    id: root
    property bool awake: false

    // Quickshell doesn't expose these two read-only Wayland subscriptions.
    // Keep one blocking listener for the overlay's lifetime. It has no timer
    // and writes only on a change to the combined lock/output state.
    Process {
        id: listener
        running: true
        command: ["python3", "-I", "-c", root.listenerCode]
        stdout: SplitParser { onRead: line => root.awake = line === "awake" }
        onExited: { root.awake = false; retry.restart() }
    }
    Timer { id: retry; interval: 1000; onTriggered: listener.running = true }

    readonly property string listenerCode: `
import itertools
import os
import socket
import struct

sock = socket.socket(socket.AF_UNIX)
sock.connect(os.path.join(os.environ['XDG_RUNTIME_DIR'], os.environ['WAYLAND_DISPLAY']))
stream = sock.makefile('rb')
ids = itertools.count(3)
registry = 2
outputs = {}  # registry global name -> wl_output object
controls = {}  # wl_output object -> output power object
modes = {}  # power object -> powered
power_manager = lock_subscription = ready_callback = None
locked = ready = False
previous = None

def words(*values):
    return struct.pack('=' + 'I' * len(values), *values)

def send(obj, opcode, payload):
    sock.sendall(words(obj, ((8 + len(payload)) << 16) | opcode) + payload)

def bind(name, interface, version):
    ident = next(ids)
    raw = interface.encode() + bytes(1)
    padded = raw + bytes((-len(raw)) % 4)
    send(registry, 0, words(name, len(raw)) + padded + words(version, ident))
    return ident

def watch_outputs():
    for output in outputs.values():
        if power_manager and output not in controls:
            control = next(ids)
            controls[output] = control
            modes[control] = False
            send(power_manager, 0, words(control, output))

def remove_output(name):
    output = outputs.pop(name, None)
    control = controls.pop(output, None)
    if control in modes:
        del modes[control]
        send(control, 1, b'')  # output_power.destroy
    if output:
        send(output, 0, b'')  # wl_output.release (version 3)

send(1, 1, words(registry))  # wl_display.get_registry
while True:
    header = stream.read(8)
    if not header:
        break
    obj, size_opcode = struct.unpack('=II', header)
    size, opcode = size_opcode >> 16, size_opcode & 65535
    data = stream.read(size - 8)
    if obj == registry and opcode == 0:
        name, length = struct.unpack_from('=II', data)
        interface = data[8:8 + length - 1].decode()
        if interface == 'wl_output':
            outputs[name] = bind(name, interface, 3)
            watch_outputs()
        elif interface == 'zwlr_output_power_manager_v1':
            power_manager = bind(name, interface, 1)
            watch_outputs()
        elif interface == 'hyprland_lock_notifier_v1':
            manager = bind(name, interface, 1)
            lock_subscription = next(ids)
            send(manager, 1, words(lock_subscription))
            ready_callback = next(ids)
            send(1, 0, words(ready_callback))  # flush initial lock notification
    elif obj == registry and opcode == 1:
        remove_output(struct.unpack('=I', data)[0])
    elif obj == lock_subscription:
        locked = opcode == 0
    elif obj == ready_callback:
        ready = True
    elif obj in modes:
        if opcode == 0:
            modes[obj] = struct.unpack('=I', data)[0] == 1
        else:
            del modes[obj]
            send(obj, 1, b'')
    elif obj == 1 and opcode == 0:
        raise RuntimeError('Wayland visibility listener lost its protocol connection')

    awake = ready and not locked and any(modes.values())
    if awake != previous:
        print('awake' if awake else 'paused', flush=True)
        previous = awake
`
}
