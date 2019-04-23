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
        cls.text = """
smartctl 6.6 2017-11-05 r4594 [x86_64-w64-mingw32-w10-b17134] (sf-6.6-1)
Copyright (C) 2002-17, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Number:                       THNSN5512GPUK TOSHIBA
Serial Number:                      87PB60PKKSPX
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

    def get_regex_from_template(self, name):

        preprocessing_params = self.root.findall(
            ".//item_prototype[name='" + name + "']/preprocessing/step/params")[0].text
        (regex, group) = preprocessing_params.split("\n")
        group = int(group[1:])
        return (regex, group)

    def test_model(self):
        (regex, group) = self.get_regex_from_template(
            '{#DISKNAME}: Device model')
        m = re.search(regex, self.text)
        self.assertEqual(m.group(group), "THNSN5512GPUK TOSHIBA")

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
                # if s['disk_interface'] != 'sata':
                #     continue
                if s['disk_interface'] != 'sata' and 'sata_only' in a['flags']:
                    continue
                if s['disk_interface'] == 'sas' and a['name'] == '{#DISKNAME}: SSD wearout':
                    continue
                if s['disk_interface'] == 'nvme' and a['name'] == '{#DISKNAME}: Reallocated sectors count':
                    continue
                if s['disk_type'] != 'ssd' and 'ssd_only' in a['flags']:
                    continue
                if s['disk_type'] != 'hdd' and 'hdd_only' in a['flags']:
                    continue
                with self.subTest(name=s['name'], attrib=a):
                    (regex, group) = self.get_regex_from_template(a['name'])
                    try:
                        # print(a['name'], s['name'])
                        m = re.search(regex, s['text'])
                        value = int(m.group(group))
                        self.assertGreaterEqual(value, 0)
                        # self.assertLessEqual(value, 100)
                    except AttributeError:
                        print("no attribute {} found on {}".format(
                            a['name'], s['name']))
