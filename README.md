# TelinkBleMesh

## SDK 更新

### 添加设备

需要实现 Mesh 添加和单个设备添加，因为 Mesh 添加无法添加面板，而单个添加无法添加网桥。

目前支持 Mesh 添加的设备：
    
    - 灯
    - 网桥
    
其他设备均需要用单个添加的方式进行添加。

Mesh 添加按现在的流程来，但是，如果在 Mesh 添加时，有不支持 Mesh 添加的设备出类型出现，则中止添加流程。

单个添加，查找到一个就显示出来，然后点添加就进入单个的添加流程，直到添加完成。

