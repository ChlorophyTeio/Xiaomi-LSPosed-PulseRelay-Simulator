"""Exclusive physical USB HCI controller -> Android Emulator netsim bridge."""
import argparse
import asyncio
import logging
import os

from bumble import hci, transport
from bumble.bridge import HCI_Bridge
from bumble.drivers import intel
from bumble.host import Host
from bumble.transport.usb import EventPacketSplitter


async def run(controller: str, port: int) -> None:
    async with await transport.open_transport(controller) as reset_transport:
        reset_host = Host(reset_transport.source, reset_transport.sink)
        reset_driver = await intel.Driver.for_host(reset_host)
        if reset_driver:
            await reset_driver.reboot_bootloader()
    await asyncio.sleep(2)
    async with await transport.open_transport(controller) as usb_transport:
        host = Host(usb_transport.source, usb_transport.sink)
        # AX211 loses its firmware when the Windows driver releases/restarts it.
        # The generic hci-bridge command does not initialize Intel firmware.
        driver = await intel.Driver.for_host(host)
        if driver:
            # Intel bootloader sends command-complete events on the bulk endpoint.
            # Bumble's USB ACL splitter otherwise buffers these as incomplete ACL.
            source = usb_transport.source
            original_splitter = source.splitters[hci.HCI_ACL_DATA_PACKET]
            source.splitters[hci.HCI_ACL_DATA_PACKET] = EventPacketSplitter(
                lambda packet: source.queue_packet(hci.HCI_EVENT_PACKET, packet)
            )
            try:
                await asyncio.wait_for(driver.init_controller(), timeout=45)
            finally:
                source.splitters[hci.HCI_ACL_DATA_PACKET] = original_splitter
        await asyncio.wait_for(host.reset(driver_factory=None), timeout=30)
        address = await host.send_sync_command(hci.HCI_Read_BD_ADDR_Command())
        print(f"PHYSICAL_CONTROLLER {address.bd_addr}", flush=True)
        endpoint = f"android-netsim:127.0.0.1:{port},mode=controller"
        async with await transport.open_transport(endpoint) as android_transport:
            bridge = HCI_Bridge(
                android_transport.source,
                android_transport.sink,
                usb_transport.source,
                usb_transport.sink,
                None,
                None,
            )
            print(f"BRIDGE_READY 127.0.0.1:{port} -> {controller}", flush=True)
            await asyncio.Future()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--controller', required=True)
    parser.add_argument('--port', type=int, default=8877)
    args = parser.parse_args()
    if not 1024 <= args.port <= 65535:
        parser.error('port must be between 1024 and 65535')
    logging.basicConfig(
        level=os.environ.get('BUMBLE_LOGLEVEL', 'INFO'),
        format='%(asctime)s %(levelname)s %(name)s %(message)s',
    )
    # New emulators also offer Wi-Fi frames to this endpoint. Android's mobile
    # network remains validated; this bridge exclusively carries Bluetooth HCI.
    class IgnoreWifiFrames(logging.Filter):
        def filter(self, record):
            return record.getMessage() != 'Unexpected request type: packet'
    logging.getLogger('bumble.transport.android_netsim').addFilter(IgnoreWifiFrames())
    try:
        asyncio.run(run(args.controller, args.port))
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
