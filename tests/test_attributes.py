import os
import re
import unittest
import xml.etree.ElementTree as ET


class TestCaseSmartAttributes(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        tree = ET.parse('Template_3.4_HDD_SMARTMONTOOLS_2_WITH_LLD.xml')

        # get files from dir
        cls.samples = []
        for (_, _, samples) in os.walk('tests/examples'):
            for sample in samples:
                with open('tests/examples/' + sample, 'r') as fd:
                    cls.samples.append({
                        "text": fd.read(),
                        "name": sample,
                        "disk_type": sample.split('_')[1],
                        "disk_interface": sample.split('_')[0]
                    })
        cls.root = tree.getroot()
        cls.inventory_sata_1 = """
smartctl 6.6 2017-11-05 r4594 [x86_64-w64-mingw32-w10-b17134] (sf-6.6-1)
Copyright (C) 2002-17, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Number:                       THNSN5512GPUK TOSHIBA
Serial Number:                      ZZZZZZZZZZZZ
Firmware Version:                   5KHA4102
PCI Vendor/Subsystem ID:            0x1179
IEEE OUI Identifier:                0x00080d
Controller ID:                      0
Number of Namespaces:               1
Namespace 1 Size/Capacity:          512 110 190 592 [512 GB]
Namespace 1 Formatted LBA Size:     512
Namespace 1 IEEE EUI-64:            00080d 03001d669b
Local Time is:                      Wed Jun 27 05:29:07 2018 RTZST
"""
        cls.inventory_sata_2 = """
$ /cygdrive/c/zabbix/bin/smart/smartctl -a /dev/sda
smartctl 6.5 2016-05-07 r4318 [x86_64-w64-mingw32-win7-sp1] (sf-6.5-1)
Copyright (C) 2002-16, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Device Model:     INTEL SSDSC2KW120H6
Serial Number:    ZZZZZZZZZZZZZZZZZZ
LU WWN Device Id: 5 5cd2e4 14cb9ef43
Firmware Version: LSBG200
User Capacity:    120-034-123-776 bytes [120 GB]
Sector Size:      512 bytes logical/physical
Rotation Rate:    Solid State Device
Form Factor:      2.5 inches
Device is:        Not in smartctl database [for details use: -P showall]
ATA Version is:   ACS-3 (minor revision not indicated)
SATA Version is:  SATA 3.2, 6.0 Gb/s (current: 6.0 Gb/s)
Local Time is:    Thu Apr 13 16:29:53 2017 ope
SMART support is: Available - device has SMART capability.
SMART support is: Enabled
"""

        cls.inventory_sata_3 = """
smartctl -x /dev/sdag
smartctl 6.3 2014-07-26 r3976 [x86_64-linux-3.2.0-4-amd64] (local build)
Copyright (C) 2002-14, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Vendor: SEAGATE
Product: ST4000NM0023
Revision: 0004
Compliance: SPC-4
User Capacity: 4 000 787 030 016 bytes [4,00 TB]
Logical block size: 512 bytes
LB provisioning type: unreported, LBPME=0, LBPRZ=0
Rotation Rate: 7200 rpm
Form Factor: 3.5 inches
Logical Unit id: 0x5000c5005844896b
Serial number: ZZZZZZZZZZZZZZZZZZZZ
Device type: disk
Transport protocol: SAS (SPL-3)
Local Time is: Tue Feb 14 02:28:31 2017 CET
SMART support is: Available - device has SMART capability.
SMART support is: Enabled
Temperature Warning: Enabled
Read Cache is: Enabled
Writeback Cache is: Enabled
"""

    def get_regex_from_template(self, name):

        preprocessing_params = self.root.findall(
            ".//item_prototype[name='" + name + "']/preprocessing/step/params")[0].text
        (regex, group) = preprocessing_params.split("\n")
        group = int(group[1:])
        return (regex, group)

    def test_model(self):
        name = '{#DISKNAME}: Device model'
        preprocessing_params = self.root.findall(
            ".//item_prototype[name='" + name + "']/preprocessing/step/params")[0].text
        regex, _  = preprocessing_params.split("\n")
        m = re.search(regex, self.inventory_sata_1, re.MULTILINE)
        self.assertEqual(m.group(2), "THNSN5512GPUK TOSHIBA")
        m = re.search(regex, self.inventory_sata_2, re.MULTILINE)
        self.assertEqual(m.group(2), "INTEL SSDSC2KW120H6")
        m = re.search(regex, self.inventory_sata_3, re.MULTILINE)
        self.assertEqual(m.group(1) + " " + m.group(2), "SEAGATE ST4000NM0023")

    def test_sata_attributes(self):

        attributes = [
            {'name': '{#DISKNAME}: ID 5 Reallocated sectors count', 'flags': []},
            {'name': '{#DISKNAME}: ID 9 Power on hours', 'flags': []},
            {'name': '{#DISKNAME}: ID 10 Spin retry count', 'flags': ['hdd_only', 'sata_only']},
            {'name': '{#DISKNAME}: ID 177/202/233 SSD wearout', 'flags': ['ssd_only']},
            {'name': '{#DISKNAME}: ID 190/194 Temperature', 'flags': []},
            {'name': '{#DISKNAME}: ID 197 Current pending sector count', 'flags': ['hdd_only', 'sata_only']},
            {'name': '{#DISKNAME}: ID 198 Uncorrectable errors count', 'flags': ['hdd_only', 'sata_only']},
            {'name': '{#DISKNAME}: ID 199 CRC error count', 'flags': []}
        ]
        for a in attributes:
            for s in self.samples:
                # Skip, no ssd life left for this SAS device
                if a['name'] == '{#DISKNAME}: ID 177/202/233 SSD wearout' and s['name'] == 'sas_ssd_hgst.txt':
                    continue
                # Skip, no power on hours for this sample.
                if a['name'] == '{#DISKNAME}: ID 9 Power on hours' and s['name'] == 'sas_hdd_wd.txt':
                    continue
                # Skip no 199 CRC
                if a['name'] == '{#DISKNAME}: ID 199 CRC error count' and s['name'] in ('sata_ssd_direct_kingston.txt', 'sas_hdd_seagate.txt'):
                    continue
                if s['disk_interface'] != 'sata' and 'sata_only' in a['flags']:
                    continue
                if s['disk_interface'] == 'sas' and a['name'] == '{#DISKNAME}: SSD wearout':
                    continue
                if s['disk_interface'] == 'nvme' and a['name'] == '{#DISKNAME}: ID 5 Reallocated sectors count':
                    continue
                if s['disk_type'] != 'ssd' and 'ssd_only' in a['flags']:
                    continue
                if s['disk_type'] != 'hdd' and 'hdd_only' in a['flags']:
                    continue
                with self.subTest(name=s['name'], attrib=a):
                    (regex, group) = self.get_regex_from_template(a['name'])
                    try:
                        m = re.search(regex, s['text'])
                        value = int(m.group(group))
                        self.assertGreaterEqual(value, 0)
                    except AttributeError:
                        self.fail("no attribute '{}' found in '{}' using regex '{}'".format(
                            a['name'], s['name'], regex))
