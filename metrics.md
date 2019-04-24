# Metrics

|--|Trigger|HDD|SSD|
|--|--|--|--|
|model|| y | y|
|sn|y| y | y|
| test result |y| y | y| 
|5 realloc|| y | y |
|9 poweron || y | y |
|10 spin retry count |y| y | |
|177 wearout ||    | y |
| 194 temp airflow |y| y | y |
| 194 temp |y| y | y |
| 197 current_pending_sector |y| y |  |
| 198 offline uncorrectable |y| y |  |
| 199 crc error |y| y | y |


|Metric name|SATA(HDD)|SATA(SSD)|SAS(HDD)|SAS(SSD)|NVMe|
|--|--|--|--|--|--|
|Model|`[Dd]evice [Mm]odel: +(.+)`|`[Dd]evice [Mm]odel: +(.+)`|`Vendor: +(.+)\nProduct: +(.+)`|`Vendor: +(.+)\nProduct: +(.+)`|`[Mm]odel [Nn]umber: +(.+)`|
|Serial number|`[Ss]erial [Nn]umber: +(.+)`|`[Ss]erial [Nn]umber: +(.+)`|`[Ss]erial [Nn]umber: +(.+)`|`[Ss]erial [Nn]umber: +(.+)`|`[Ss]erial [Nn]umber: +(.+)`|
|Test result|`SMART overall-health self-assessment test result: (.+)`|`SMART overall-health self-assessment test result: (.+)`|`SMART Health Status: +(.+)`|`SMART Health Status: +(.+)`|`SMART overall-health self-assessment test result: (.+)`|
|Reallocated|5 Reallocate.+|5 Reallocate.+|Elements in grown defect list:|Elements in grown defect list:|?|
|Power on hours|`9 Power_On_Hours.+ ([0-9]+)`|`9 Power_On_Hours.+ ([0-9]+)`|`Accumulated power on time, hours:minutes \d+:\d+ [\d+ minutes]`|`Accumulated power on time, hours:minutes \d+:\d+ [\d+ minutes]`|`Power On Hours.+ ([0-9]+)`|
|Spin retry count|`10 Spin_Retry_Count.+ ([0-9]+)`|`10 Spin_Retry_Count.+ ([0-9]+)`|n/a|n/a|n/a|
|SSD wearout|n/a|`(?:177 Wear_Leveling_Count|202 Percent_Lifetime_Used|233 Media_Wearout_Indicator|231 SSD_Life_Left) +0x[0-9a-z]+ +([0-9]+)`|n/a|100-Percentage used endurance indicator(not supported)|Available spare|
|Current pending sector count|y|y|n/a|n/a|n/a|
|Uncorrectable errors count|--|--|JS preprocessing required|JS preprocessing required|--|
|--|--|--|--|--|--|
|--|--|--|--|--|--|
|--|--|--|--|--|--|
