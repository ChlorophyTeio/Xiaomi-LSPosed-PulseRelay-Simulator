"""Volatile RTL8922AU patch initialization for the 13D3:3617 adapter.

Protocol references: Linux btrtl.c/btrtl.h and Bumble's Realtek driver.
Firmware is downloaded separately from upstream linux-firmware.
"""
import asyncio
import hashlib
import logging
import struct
from pathlib import Path
from bumble import hci
from bumble.drivers import rtk

FIRMWARE_SHA256 = '112290ca9dc3985034f572594812f0deb8530dd031686461b55cac43a1c35a79'


def parse_patch(firmware, rom, key):
    if hashlib.sha256(firmware).hexdigest() != FIRMWARE_SHA256:
        raise ValueError('RTL8922 firmware checksum mismatch')
    if firmware[:8] != b'RTBTCore':
        raise ValueError('Unsupported Realtek firmware format')
    offset = 20
    pieces = []
    for _ in range(struct.unpack_from('<I', firmware, 16)[0]):
        opcode, length = struct.unpack_from('<II', firmware, offset)
        offset += 8
        section = firmware[offset:offset + length]
        offset += length
        if len(section) != length:
            raise ValueError('Truncated Realtek firmware section')
        if opcode not in (1, 2, 3) or (opcode == 3 and key == 0):
            continue
        cursor = 4
        for _ in range(struct.unpack_from('<H', section)[0]):
            eco, priority, section_key, _, size = struct.unpack_from('<BBBBI', section, cursor)
            cursor += 8
            data = section[cursor:cursor + size]
            cursor += size
            if len(data) != size:
                raise ValueError('Truncated Realtek firmware subsection')
            if eco == rom + 1 and (opcode != 3 or section_key == key):
                pieces.append((priority, len(pieces), data))
    payload = b''.join(p[2] for p in sorted(pieces, key=lambda p: (p[0], -p[1])))
    if not payload:
        raise ValueError('No matching RTL8922 firmware patch for this ROM/security key')
    return payload


async def vendor_command(host, opcode, payload):
    command = hci.HCI_Command.from_bytes(b'\x01' + struct.pack('<HB', opcode, len(payload)) + payload)
    response = await host.send_command(command, check_result=True, response_timeout=5)
    parameters = response.return_parameters
    return parameters if isinstance(parameters, bytes) else bytes(parameters)


async def initialize(host):
    await host.reset(driver_factory=None)
    version = await host.send_sync_command(hci.HCI_Read_Local_Version_Information_Command())
    if version.company_identifier != 93:
        raise ValueError('Selected adapter is not a Realtek controller')
    if (version.lmp_subversion, version.hci_subversion) != (0x8922, 10):
        if (version.lmp_subversion, version.hci_subversion) == (0xC905, 0x41C0):
            logging.info('RTL8922 patch firmware is already loaded')
            return
        raise ValueError(f'Unsupported RTL8922 controller version: {version}')
    rom = (await host.send_sync_command(rtk.HCI_RTK_Read_ROM_Version_Command())).version
    key_response = await vendor_command(host, 0xFC61, bytes.fromhex('10a4ad00b0'))
    if len(key_response) != 3:
        raise ValueError('Invalid Realtek security key response')
    key = key_response[1]
    path = Path(__file__).resolve().parent.parent / 'runtime/rtl8922au_fw.bin'
    payload = parse_patch(path.read_bytes(), rom, key)
    logging.info('Loading RTL8922 volatile firmware: ROM=%s key=%s bytes=%s', rom, key, len(payload))
    index = 0
    for offset in range(0, len(payload) + 1, 252):
        fragment = payload[offset:offset + 252]
        last = offset + 252 > len(payload)
        marker = index | (128 if last else 0)
        result = await vendor_command(host, 0xFC20, bytes([marker]) + fragment)
        if len(result) != 2 or result[1] != marker:
            raise ValueError('Unexpected Realtek firmware fragment acknowledgement')
        index += 1
        if index == 127:
            index = 1
    await asyncio.sleep(0.3)
    version = await host.send_sync_command(hci.HCI_Read_Local_Version_Information_Command())
    if (version.lmp_subversion, version.hci_subversion) != (0xC905, 0x41C0):
        raise ValueError(f'RTL8922 firmware version verification failed: {version}')
    logging.info('RTL8922 firmware initialized and verified')
