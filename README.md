# SentinelStriker
Powershell script to force SentinelOne into a dormant state due to resource consumption by committing all memory available and holding it.

Based on the research done by 0x00Check You can read his original article below: 

https://0x00check.com/Bypassing-SentinelOne-with-resource-consumption/

I took this concept and migrate the code into a powershell script that commits all memory on a system as much as possible. Once this is committed, the scripts hold the memory for 240 seconds. This forces SentinelOne into a dormant state with the GUI showing offline in many instances, and in some instances completely stopping the SentinelAgent service. Once the script is run, the AI/ML detection stops running while the static analysis keeps running. This allows custom or obfuscated injectors to run which can get code execution on the system. 

You may sometimes need to run the script multiple times to trigger the crash/disable in SentinelOne that you want to see. The process will either be stopped or stuck in a starting state without completing. The resource consumption will remain active while the powershell console used to run the script is open. Once you close the window, the resources are released. If you need to run the script again, run it in the same window without closing it. This ensures that resources are constantly spiked, increasing the likelyhood of triggering the behavior. 


![Screenshot 2024-10-01 101927](https://github.com/user-attachments/assets/6e7bc10b-1aaa-42ef-b722-98e49c07110a)
