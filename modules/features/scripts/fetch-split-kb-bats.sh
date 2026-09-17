import asyncio
from dbus_next.aio import MessageBus
from dbus_next.constants import BusType
from dbus_next.errors import DBusError

BLUEZ = "org.bluez"
BLUEZ_ROOT = "/"
DEVICE_IFACE = "org.bluez.Device1"
GATT_SERVICE = "org.bluez.GattService1"
GATT_CHARACTERISTIC = "org.bluez.GattCharacteristic1"

BATTERY_UUID = "0000180f-0000-1000-8000-00805f9b34fb"
BATTERY_LEVEL_UUID = "00002a19-0000-1000-8000-00805f9b34fb"
APPEARANCE_KEYBOARD = 0x03C1
APPEARANCE_KEYBOARD_MOUSE = 0x03C3
HID_UUID = "00001812-0000-1000-8000-00805f9b34fb"



async def get_connected_keyboard_devices(bus):
    introspection = await bus.introspect(BLUEZ, BLUEZ_ROOT)
    om = bus.get_proxy_object(BLUEZ, BLUEZ_ROOT, introspection)

    mgr = om.get_interface("org.freedesktop.DBus.ObjectManager")
    objects = await mgr.call_get_managed_objects()

    devices = []

    for path, ifaces in objects.items():
        dev = ifaces.get(DEVICE_IFACE)
        if not dev:
            continue

        if not dev.get("Connected", False):
            continue

        # collect service UUIDs if present
        uuids = set(u.lower() for u in dev.get("UUIDs", []).value)

        if HID_UUID not in uuids:
            continue

        devices.append(path)

    return devices


async def device_has_battery_service(bus, device_path):
    introspection = await bus.introspect(BLUEZ, device_path)
    device = bus.get_proxy_object(BLUEZ, device_path, introspection)

    for svc_path in device.child_paths:
        try:
            svc_intp = await bus.introspect(BLUEZ, svc_path)
            svc = bus.get_proxy_object(BLUEZ, svc_path, svc_intp)
            svc_iface = svc.get_interface(GATT_SERVICE)
            if await svc_iface.get_uuid() == BATTERY_UUID:
                return True
        except Exception:
            pass

    return False


async def read_battery_levels(bus, device_path):
    levels = []

    introspection = await bus.introspect(BLUEZ, device_path)
    device = bus.get_proxy_object(BLUEZ, device_path, introspection)

    for svc_path in device.child_paths:
        try:
            svc_intp = await bus.introspect(BLUEZ, svc_path)
            svc = bus.get_proxy_object(BLUEZ, svc_path, svc_intp)
            svc_iface = svc.get_interface(GATT_SERVICE)

            if await svc_iface.get_uuid() != BATTERY_UUID:
                continue
        except Exception:
            continue

        for char_path in svc.child_paths:
            try:
                char_intp = await bus.introspect(BLUEZ, char_path)
                char = bus.get_proxy_object(BLUEZ, char_path, char_intp)
                char_iface = char.get_interface(GATT_CHARACTERISTIC)

                if await char_iface.get_uuid() == BATTERY_LEVEL_UUID:
                    value = await char_iface.call_read_value({})
                    levels.append(int.from_bytes(value, "big"))
            except Exception:
                pass

    return levels


async def main():
    bus = await MessageBus(bus_type=BusType.SYSTEM).connect()

    devices = await get_connected_keyboard_devices(bus)

    if not devices:
        print("  x")
        return

    for dev in devices:
        try:
            levels = await read_battery_levels(bus, dev)
            if not levels:
                continue

            label = dev.split("/")[-1]  # dev_XX_XX_XX_XX_XX_XX
            print(f"  {label}: " + " / ".join(f"{x}%" for x in levels))

        except DBusError:
            continue


asyncio.run(main())

