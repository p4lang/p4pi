# P4Edge Functions
## Login Screen
Login is required to access the P4Edge web services. The default account details are: username:pi password:raspberry
![Login page](./img/Welcome.png "P4Edge Welcome page")

## AP page
P4Edge can be used either on a wired or wireless network, or it can create its own wireless access point. The AP's properties can be changed on the Wireless Access Point page.
![Access point page](./img/AP.png "P4Edge AP page")

## Switch page
The user can choose what compiler to use for the P4 code on this page. Currently, only [T4P4S](http://p4.elte.hu/) is supported. After choosing the compiler, users may select any of the pre-written [examples](./Examples) or upload a custom P4 code by selecting Custom at the P4 program options.
![Switch page](./img/Switch.png "P4Edge Switch page")

## Statistics
This page shows the most important device statistics such as, CPU temeprature, RAM usage, Wifi/ETH bandwidth, CPU and Memory usage. 
![Statistics page](./img/Statistics.png "P4Edge Statistics page")
![Statistics page continued](./img/Statistics2.png "P4Edge Statistics page")

## Table entry editor
The controller can change the behavior of the switch program by inserting entries into the data plane tables. This page shows the current entries for each table in the P4 code. Users may define web read-only and web writeable P4 tables. Web read-only tables are shown on the entry editor page, but cannot be changed, while writeable tables are free to modify from the website. As shown on the image l3tab is read-only while l2tab and l3tabedit are defined to be modifiable.
![Table entry editor page](./img/Entries.png "P4Edge Entries page")

## Web terminal
For users who can't or don't want to use SSH to access the terminal, P4Edge supports a fully functional embedded web terminal.
![Web terminal](./img/Terminal.png "P4Edge Terminal page")

## Password change
The password for every user (such as the default pi user) can be changed on the password change page.
![Password change page](./img/ChangePass.png "P4Edge password change page")

## User creation
P4Edge web service allows multiple users. New user creation is possible on this page.
![Create user page](./img/CreateUser.png "P4Edge new user creation page")
