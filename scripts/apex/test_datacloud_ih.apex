// Ad-hoc test harness for BB_C360_DataCloud_IH_v1 live Data Graph callout
List<String> keys = new List<String>{ 'werrxcbykl145212', 'sdfsdfsdf5545' };

for (String key : keys) {
    System.debug('===== Testing customerKey: ' + key + ' =====');
    try {
        BB_C360_DataCloud_Resp_IB_v1 resp = BB_C360_DataCloud_IH_v1.getDataGraph(key);
        System.debug('RESULT: ' + JSON.serializePretty(resp));
    } catch (Exception e) {
        System.debug('EXCEPTION (' + e.getTypeName() + '): ' + e.getMessage());
    }
}
