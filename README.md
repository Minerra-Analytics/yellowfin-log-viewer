# Introduction
## What is the Yellowfin Log Viewer?
The Yellowfin Log Viewer by Minerra is a simple utility that is easily added to and removed from a Yellowfin instance.

Installing the Yellowfin Log Viewer only requires two files to be copied to your Yellowfin server and the Yellowfin service restarted. No changes need to be made to Yellowfin configuration files or the Yellowfin configuration database.

## Why Use the Yellowfin Log Viewer?
While Yellowfin provides exentsive, configurable logging of all functions, the log output is only stored in various files on the Yelowfin server's file system that is often only accessible by an organisation's infrastrucutre team. This can make it difficult for a general Yellowfin devloper or conent creator to get easy and timely assess to the contents of a log file when troubleshooting a problem. The Yellowfin Log Viewer allows the content of all Yellowfin log files to be viewed using a web browser.

## Security Considerations
Is it important to note that Yellowfin log files can sometimes contain configuration information about Yellowfin and the environment it is running on. It if the Yellowfin instance is exposed to the public internet, it is recommended that access to the logs.jsp URL only be available to whitelisted IP addresses or IP address ranges. This can be achieved by using the [Remote Access Filter](https://tomcat.apache.org/tomcat-9.0-doc/config/filter.html#Remote_Address_Filter) and/or the [Remote CIDR Filter](https://tomcat.apache.org/tomcat-9.0-doc/config/filter.html#Remote_CIDR_Filter) functionality of the Tomcat appliation server Yellowfin runs on.

Before installing the Yellowfin Log Viewer, consult with your organisation's IT system administrator or security administrator to ensure that all relevant IT system security policies are complied with.

# Installing the Yellowfin Log Viewer
## Preparation
Before adding the Yellowfin log Viewer to a Yellowfin instance obtain the following information:

1. User credentials with administrator permissions for the server Yellowfin is installed on.
2. The directory on the Yellowfin server the Yellowfin application was installed in.

## The Process
Below are the instructions to install the Yellowfin Log Viewer.

  - If you are running Yellowfin in a clustered environment, repeat the following installation instructions for all nodes in the cluster.

Below are the installation instructions for the Yellowfin Log Viewer by Minerra:

1. Log into the Yellowfin server.

2. Download the file logs.jsp to the Yellowfin server using the following link:

    - `https://raw.githubusercontent.com/Minerra-Analytics/yellowfin-log-viewer/main/logs.jsp`

3. Copy `logs.jsp` to the following directory on your Yellowfin server:

    `[yellowfin-install-directory]/appserver/webapps/ROOT`
  
4. Download the file `jstl-1.2.jar` (i.e. JavaServer Pages Standard Tag Library Version 1.2) to the Yellowfin server using the following link:

    - `https://repo1.maven.org/maven2/javax/servlet/jstl/1.2/jstl-1.2.jar`

5. Save the downloaded jstl-1.2.jar file to the following directory on your Yellowfin server:

    `[yellowfin-install-directory]/appserver/webapps/ROOT/WEB-INF/lib`

6. Restart the Yellowfin service. Doing this makes Yellowfin aware of the 'jstl-1.2.jar' library

    - If you are running Yellowfin in a clustered environment, start the Yellowfin service on all nodes in the cluster

# Removing the Yellowfin Log Viewer
## The Process
Below are the instructions to remove for the Yellowfin Log Viewer.

  - If you are running Yellowfin in a clustered environment, repeat the following removal instructions for all nodes in the cluster.

1. Delete the 'logs.jsp' file from the following directory on your Yellowfin server:

    `[yellowfin-install-directory]/appserver/webapps/ROOT`

2. Delete the `jstl-1.2.jar` file from the following directory on your Yellowfin server:

    `[yellowfin-install-directory]/appserver/webapps/ROOT/WEB-INF/lib`

3. Restart the Yellowfin service.

   - If you are running Yellowfin in a clustered environment, repeat the following removal instructions for all nodes in the cluster.
    
# How to Use the Yellowfin Logs Viewer
To use the Yellowfin logs viewer, go to the following URL in a web browser:

  `[address-of-yellowfin-server]/logs.jsp`

for example:

  `http://yellowfin.company.com/logs.jsp`

The Yellowfin Logs Viewer has two modes, Basic and Advanced. Each mode is decribed below.

## Basic
Basic is the default mode for the Yellowfin Log Viewer View. Basic mode displays a user-entered (or a default 100 lines with no value entered) number of log lines from the end of the most recent instance of the four most commonly used Yellowfin log files, namely:

  - yellowfin.log
  - transformation.log
  - jdbc.log
  - email.log

## Advanced
Click the Advanced tab to switch to Advanced mode. Advanced mode allows displays a user-entered (or a default 100 lines with no value entered) number of log lines from the end of all Yellowfin log files on the server, including archived version of a log file (e.g. yellowfin.log.1).

Advanced mode allows log file entries to be filtered to exclude INFO and/or WARN log entries from the output diplayed. Use the toggle the *Exclude INFO* and/or the *Exclude WARN* options to exclude the types of log entries not required.
