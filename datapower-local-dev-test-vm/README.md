# Setting up a containerized DataPower local development environment

## Local Deployment

**Instructions**

1. Create a folder for the project and move to that directory.

```
mkdir datapower
cd datapower
```

2. Clone this repo into that parent folder.

```
git clone https://github.com/pbennettibm/datapower-local-dev-test-vm.git
```

3. Create a folder for the virtual DatatPower container volume mounts into your parent folder.

```
mkdir datapower-volume-mounts
```

4. Navigate to the folder you just created and create config, local, and certs subdirectories inside of it.

```
cd datapower-volume-mounts
mkdir config local certs
```

5. Change the permissions on these sub directories to allow the container to write it's volume mounted data to them.

```
chmod 1777 config local certs
```

6. Pull the DataPower Docker image.

- We wil be using an updated version of DataPower for this install as I have been assured that it is stable.

```
podman pull icr.io/integration/datapower/datapower-limited:10.0.4.0
```

7. Create and run the the DataPower container with an interactive shell from the local Docker image with volume mounts.

- Since we are using a shared VM, each user needs to be using different ports.
- Find your name in the [trello board](https://trello.com/b/MZrVMgV9/ce-delta-v-dp) under the "Notes" section for your specific command, and enter it in the VM's terminal.

8. Once you are inside of the DataPower container, enable the UI.

- login: `admin`
- Password: `admin`

```
co
```

```
web-mgmt 0 9090 9090
```

9. Access the DataPower Gateway.

- You can access FireFox in the VM by clicking "Activities" in the upper right corner - Warning: The VM does have a fair amount of lag.
- Check the Trello board for the port number assigned for the UI.
- The address will be https://localhost:(port number)/.
- You should see a screen saying "Warning: Potential Securtity Risk Ahead"
  - If you don't see that screen make sure you are using the correct port assigned to you.
  - Also, make sure you are using "https" and not "http".
  - You can also try clearing FireFox's cache by going into "Settings", selecting "Cookies and Site Data", and then clearing all the data. We have noticed that this method particularily helps inside this VM.
  - Select "Advanced"
  - Scroll down and select "Accept the risk and continue"
  - Username and password both default to "admin".
  - If you still aren't able to access the UI, please send me an email and I can resolve your issue.

10. Import the validation-flow.zip file using the GUI.

- The file is located in the datapower-local-dev-test-vm folder.
- Initially select the "default" domain.
- There are several screens you will need to click through.
- Accept the configuration as is.

11. Now that you have imported your configuration, test that it is working.

- Check the trello board for the port number assigned for the test flow.
- The address will be http://localhost:(port number).
- You should see the [JSON Placeholder](https://jsonplaceholder.typicode.com/) page.
  - If for some reason it isn't working, attempt to re-import the provided zip file again and ensure that you accept all steps appropriately.
  - If that doesn't fix you issue, make sure you are using "http" instead of "https" and clear FireFox's cache.
  - If you still aren't able to see the placeholder, please send me an email and I can resolve your issue.

12. Click on save configuration in the UI's upper right corner.

13. In the terminal, type `write memory` to save the configuration on the volume mounts.

14. Check the config, local, and certs directories to make sure they aren't empty.

- Note that you should now have a key and a certificate in the certs folder.
- This is very important for future deployment steps.

13. Exit the datapower CLI

- Type `exit` twice and then "control+C" to return to the command prompt.

14. Delete the Docker container.

```
podman rm datapower
```

15. (Optional) Try accessing the UI and the flow again.

- You will see that they are no longer accessible
