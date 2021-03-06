## Device Connection

TCP IP:sb.dasudian.net    Port:8008

Devices exchange information with server in full bi-directional way.
Please browse [Dasudian Website](http://docs.dasudian.com/) to lookup the relevant
documents.


## App Connection
Please register at[Dasudian Developer's Portal](https://dev.dasudian.com) and
become a Dasudian partner, create Applicatios, and acquire an AppID and AppKey.

1. App requests to be authenticated via HTTPS：
```
URL: https://sb.dasudian.net:8443/init
Mehod: POST
Header: "content-type": application/json"
Body:
{
 "appid":"Your AppID",
 "appSec":"xxxxxxx",   //   AppSec = SHA1_HMAC(AppKey, AppID + "DSD" + AppKey)  
                      // + means string concatenation
 "imei":"xxxxx"
 }
```

2. Server authenticate the AppSec, AppID, IMEI provided by App
```
{
  "mqtt_host": [MQTT Server Address],
  "mqtt_port":[MQTT Port],
  "mqtt_username":[MQTT Username]
  "mqtt_password": [MQTT Password]
}
```

3. App establish MQTT connection with Servers accroding to the information
gotten at step 2.

4. App subscribe Topic: "dev2app/<imei>/cmd"  
                        "dev2app/<imei>/gps"  
                        ...  

5. App sends commands to devices: 
				 "CMD_WILD"  
			     "CMD_FENCE_ON"  
			     "CMD_FENCE_OFF"  
			     "CMD_FENCE_GET"  
			     "CMD_SEEK_ON"  
			     "CMD_SEEK_OFF"  
			     "CMD_LOCATION"  
				 ...

6. App receives and processes the events generated by devices
