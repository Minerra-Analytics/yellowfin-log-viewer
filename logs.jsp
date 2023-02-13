<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="com.hof.util.*, java.util.*, java.text.*, java.nio.file.*" %> 
<%@ page import="com.hof.web.form.*" %>
<%@ page import="com.hof.mi.web.service.*" %>
<%@ page import="org.apache.commons.io.input.ReversedLinesFileReader" %>
<%@ page import="java.io.*" %>
<%@ page import="org.apache.logging.log4j.LogManager" %>
<%@ page import="org.apache.logging.log4j.core.Appender" %>
<%@ page import="org.apache.logging.log4j.core.appender.*" %>
<%@ page import="org.apache.logging.log4j.Logger" %>
<%@ page import="org.apache.logging.log4j.core.LoggerContext" %>
<%@page import="org.apache.logging.log4j.core.config.xml.XmlConfiguration" %>
<%@page import="org.apache.logging.log4j.core.config.Configuration"%>
<%@page import="org.apache.logging.log4j.core.lookup.StrSubstitutor"%>
<%@page import="org.apache.logging.log4j.core.lookup.StrLookup"%>

<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="ISO-8859-1">
<title>Yellowfin Log Viewer by Minerra</title>
<!-- <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous"> -->
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js"></script>
</head>
<style type="text/css">
    html, body {
        height: 100%;
    }
    .container-fluid {
        margin: 0 auto;
        /*height: 100%;*/
    }

</style>
<body>
<%
    ArrayList<String> loggerNamesList = new ArrayList<String>();
    loggerNamesList.add("com.hof.pool.DBConnectionPool.jdbclog");
    //loggerNamesList.add("com.hof.pool.DBConnectionPool.sourcelog");//todo implement this later
    loggerNamesList.add("com.hof.util.Email.emaillog");
    loggerNamesList.add("com.hof.mi.etl");
    loggerNamesList.add("Root Logger");
  
    Logger logger  = null;
    Map<String, Appender>appenderMap = null;
    RollingFileAppender fileAppender = null;
    File logFile = null;
    Map<String, File> logFileDetailsMap = new LinkedHashMap<String, File>();
    
    for (String loggerName: loggerNamesList) {
        logger = LogManager.getLogger(loggerName);
        appenderMap = ((org.apache.logging.log4j.core.Logger) logger).getAppenders();
        for(Map.Entry<String, Appender> entry: appenderMap.entrySet()){
            if(entry.getValue() instanceof RollingFileAppender){
                fileAppender = (RollingFileAppender) entry.getValue();
                logFile = new File(fileAppender.getFileName());
                logFileDetailsMap.put(logFile.getName(), logFile);
            }
        }
    }
    pageContext.setAttribute("logFileDetailsMap", logFileDetailsMap);
    
    Logger rootLogger = LogManager.getRootLogger();
    LoggerContext  loggerContext = ((org.apache.logging.log4j.core.Logger)rootLogger).getContext();
    Configuration configuration = loggerContext.getConfiguration();
    StrSubstitutor strSubstitutor = configuration.getStrSubstitutor();
    StrLookup variableResolver = strSubstitutor.getVariableResolver();
    String propertyValue = variableResolver.lookup("logDir");
    //pageContext.setAttribute("configuration", configuration);
    //pageContext.setAttribute("logDir",  propertyValue);

    List<File> fileList = new ArrayList<File>();
    Map<String, File> allLogFilesDetailsMap = new LinkedHashMap<String, File>();      
    try (DirectoryStream<Path> stream = Files.newDirectoryStream(Paths.get(propertyValue), "*.{log,txt,log.*}")) {
        for (Path path : stream) {
            if (!Files.isDirectory(path)) {
                fileList.add(path.toFile());
            }
        }
    }
    //Collections.sort(fileList, Comparator.comparing(File::getName).reversed());
    //commented out the 1.8 feature as some clients tomcat instance's jsp engine still suports java 1.7 
    Collections.sort(fileList, Collections.reverseOrder());
    for(File file: fileList){
        allLogFilesDetailsMap.put(file.getName(), file);
    }
    pageContext.setAttribute("allLogFilesDetailsMap",  allLogFilesDetailsMap);

    String tabMode = request.getParameter("tabMode");
    if(tabMode == null || tabMode.length() == 0){
        tabMode = "basic"; //default to basic mode always
    }
    pageContext.setAttribute("tabMode",  tabMode);
%>
<div class="container-fluid p-3 bg-light px-0">
    <h4 class="mx-4 mb-2">Yellowfin Log Viewer by <a href="http://www.minerra.net" class="link-primary text-decoration-none" target="_blank" rel="noopener noreferrer">Minerra</a></h4> 
    <div class="m-4">
        <ul class="nav nav-tabs" id="myTab">
            <li class="nav-item">
                <a id="basicTab" href="#basic" class="nav-link <c:if test="${tabMode eq \"basic\"}">active</c:if>" data-bs-toggle="tab">Basic Mode</a>
            </li>
            <li class="nav-item">
                <a id="advTab"  href="#advanced" class="nav-link <c:if test="${tabMode eq \"advanced\"}">active</c:if>" data-bs-toggle="tab">Advanced Mode</a>
            </li>
            <li class="nav-item">
               <a href="#about" class="nav-link" data-bs-toggle="tab">About</a>
           </li>
        </ul>
        <div class="tab-content p-3">
            <div class="tab-pane fade <c:if test="${tabMode eq \"basic\"}">show active</c:if>" id="basic">
                <form method="post">
                    <div class="row mb-3">
                        <div class="col-sm-4">
                            <label for="selLogFile" class="col-form-label">Log File Name (Choose One):</label>
                            <select id="selLogFile" name="selLogFile" class="form-select">
                            <c:forEach items="${logFileDetailsMap}" var="currLogFile">
                                    <option value="${currLogFile.key}" ${currLogFile.key == param.selLogFile ? 'selected' : ''}>${currLogFile.key}</option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="col-sm-4">
                            <label for="numLines" class="col-form-label">Number of Log Lines to View (Default 100):</label>
                            <input type="text" class="form-control" id="numLines" name="numLines"  value="<c:out value="${param.numLines}"/>">
                        </div>
                        <input type="hidden" name="tabMode" id="tabMode" value="basic"/>
                    </div>
                    <div class="row mb-3">
                       <div class="col-sm-2">
                           <button type="submit" class="btn btn-primary">Show Log Entries</button>
                       </div>
                    </div>
                </form>
                <c:if test="${pageContext.request.method=='POST' and tabMode eq \"basic\"}">
                    <%
                        String reqNumLines = request.getParameter("numLines");
                        int requestedNumberOfLines = 100; //by default initialize as 100
                        if(reqNumLines!=null && reqNumLines.trim().length() > 0){
                            requestedNumberOfLines = Integer.valueOf(reqNumLines);
                        }
                        String selLogFile = request.getParameter("selLogFile");
                        File selectedLogFile = null;
                        if(logFileDetailsMap.containsKey(selLogFile)){
                            selectedLogFile = logFileDetailsMap.get(selLogFile);
                        }
                        String logPreview = "";
                        int numberOfLinesRead = 0;
                        if(selectedLogFile != null) {
                            ReversedLinesFileReader reader = null;
                            String line  = null;
                            try {
                                reader = new ReversedLinesFileReader(selectedLogFile);
                                while(numberOfLinesRead < requestedNumberOfLines) {
                                    if (reader==null) {
                                        break;
                                    }
                                    line = reader.readLine();
                                    if(line == null) {
                                       //means no more lines to read
                                       break;
                                    }
                                    logPreview = line + System.lineSeparator() + logPreview;
                                    numberOfLinesRead++;
                                }
                            }catch(Exception ex){
                                //swallow exception?
                                ex.printStackTrace();
                            }finally{
                                if(reader!=null) reader.close();
                            }
                        }
                        pageContext.setAttribute("logPreview", logPreview);
                        pageContext.setAttribute("numberOfLinesRead", numberOfLinesRead);
                    %>      
                    <div class="mt-3 bg-light">
                        <c:if test="${numberOfLinesRead eq 0}">
                            <h4 class="mb-2"><b><c:out value="${param.selLogFile}"/></b> is empty.</h4>
                        </c:if>
                        <c:if test="${numberOfLinesRead gt 0}">
                            <h4 class="mb-2">Displaying <b>last <c:out value="${numberOfLinesRead}" default="100"/> </b>lines of  <b><c:out value="${param.selLogFile}"/></b></h4>
                                <pre><c:out value="${logPreview}" escapeXml="false"/></pre>
                        </c:if>
                    </div>
                </c:if>
            </div>
            <div class="tab-pane fade <c:if test="${tabMode eq \"advanced\"}">show active</c:if>" id="advanced">
                <form method="post">
                    <div class="row mb-3">
                        <div class="col-sm-4">
                            <label for="selLogFile" class="col-form-label">Log File Name (Choose One):</label>
                            <select id="selLogFile" name="selLogFile" class="form-select">
                            <c:forEach items="${allLogFilesDetailsMap}" var="currLogFile">
                                    <option value="${currLogFile.key}" ${currLogFile.key == param.selLogFile ? 'selected' : ''}>${currLogFile.key}</option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="col-sm-4">
                            <label for="numLinesAdv" class="col-form-label">Number of Log Lines to View (Default 100):</label>
                            <input type="text" class="form-control" id="numLinesAdv" name="numLinesAdv" value="<c:out value="${param.numLinesAdv}"/>">
                        </div>
                        <input type="hidden" name="tabMode" id="tabMode" value="advanced"/>
                    </div>
                    <div class="row mb-3 pl-5">
                        <div class="col-sm-6">
                           <div>
                              <label>Filter Log Types: </label>
                           </div>
                           <div class="form-check form-check-inline form-switch">
                              <input class="form-check-input" type="checkbox" id="excludeTypeInfo" name="excludeTypeInfo" value="true" ${param.excludeTypeInfo ? "checked" : ""}>
                              <label class="form-check-label" for="excludeTypeInfo">Exclude INFO</label>
                           </div>
                           <div class="form-check form-check-inline form-switch">
                            <input class="form-check-input" type="checkbox" id="excludeTypeWarn" name="excludeTypeWarn" value="true" ${param.excludeTypeWarn ? "checked" : ""}>
                            <label class="form-check-label" for="excludeTypeWarn">Exclude WARN</label>
                         </div>
                        </div>
                    </div>
                    <div class="row mb-3">
                       <div class="col-sm-2">
                           <button type="submit" class="btn btn-primary">Show Log Entries</button>
                       </div>
                    </div>
                </form>
                <c:if test="${pageContext.request.method=='POST' and tabMode eq \"advanced\"}">
                    <%
                        boolean excludeTypeInfo = Boolean.parseBoolean(request.getParameter("excludeTypeInfo"));
                        boolean excludeTypeWarn = Boolean.parseBoolean(request.getParameter("excludeTypeWarn"));
                       
                        String reqNumLines = request.getParameter("numLinesAdv");
                        int requestedNumberOfLines = 100; //by default initialize as 100
                        if(reqNumLines!=null && reqNumLines.trim().length() > 0){
                            requestedNumberOfLines = Integer.valueOf(reqNumLines);
                        }
                        String selLogFile = request.getParameter("selLogFile");
                        File selectedLogFile = null;
                        if(allLogFilesDetailsMap.containsKey(selLogFile)){
                            selectedLogFile = allLogFilesDetailsMap.get(selLogFile);
                        }
                        String logPreview = "";
                        int numberOfLinesRead = 0;
                        String msg="";
                        if(!excludeTypeInfo && !excludeTypeWarn) {
                            //This is a normal flow.
                            if(selectedLogFile != null) {
                                ReversedLinesFileReader reader = null;
                                String line  = null;
                                try {
                                    reader = new ReversedLinesFileReader(selectedLogFile);
                                    while(numberOfLinesRead < requestedNumberOfLines) {
                                        if (reader==null) {
                                            break;
                                        }
                                        line = reader.readLine();
                                        if(line == null) {
                                            //means no more lines to read
                                            break;
                                        }
                                        if(line.trim().length() == 0) {
                                            //means an empty line
                                            //SKIP the line;
                                            continue;
                                        }
                                        logPreview = line + System.lineSeparator() + logPreview;
                                        numberOfLinesRead++;
                                    }
                                }catch(Exception ex){
                                    //swallow exception?
                                    ex.printStackTrace();
                                }finally{
                                    if(reader!=null) reader.close();
                                }
                            }
                        }else{
                            //msg = "Inside else <br/>";
                            //User has requested to exclude INFO or/and WARN log messages
                            List<String> logLevelStringsToCheck = new ArrayList<String>();
                            logLevelStringsToCheck.add("TRACE ");
                            logLevelStringsToCheck.add("TRACE:");
                            logLevelStringsToCheck.add("DEBUG ");
                            logLevelStringsToCheck.add("DEBUG:");
                            logLevelStringsToCheck.add("INFO ");
                            logLevelStringsToCheck.add("INFO:");
                            logLevelStringsToCheck.add("ERROR ");
                            logLevelStringsToCheck.add("ERROR:");
                            logLevelStringsToCheck.add("FATAL ");
                            logLevelStringsToCheck.add("FATAL:");
                            logLevelStringsToCheck.add("SEVERE ");
                            logLevelStringsToCheck.add("SEVERE:");
                            logLevelStringsToCheck.add("WARN ");
                            logLevelStringsToCheck.add("WARN:");
                            logLevelStringsToCheck.add("NOTICE ");
                            logLevelStringsToCheck.add("NOTICE:");
                            logLevelStringsToCheck.add("[info] ");
                            logLevelStringsToCheck.add("WARNING ");
                            //excluding INFO/WARN msges is an entirely different workflow
                            //reason is that we might need to skip lines which are part of the
                            //warn messages. The difficulty here is that we are reading the file in reverse 
                            //order and hence the lines which are part of the actual INFO/WARN message
                            //might have alredy been read by the program even before reaching the actual INFO/WARN msg line
                            List<String> readLines = new ArrayList<String>();
                            //Since we are reading lines in reverse order, this list will hold the lines which doesnt have
                            //a log level info and will reset when a line with any log level info is read
                            //The idea here is to group those lines to the exact log level info line
                            List<String> linesWithNoLogLevelInfo = new ArrayList<String>();
                            boolean isLogLevelPresentInString = false;
                            if(selectedLogFile != null) {
                                ReversedLinesFileReader reader = null;
                                String line  = null;
                                try {
                                    reader = new ReversedLinesFileReader(selectedLogFile);
                                    while(numberOfLinesRead < requestedNumberOfLines) {
                                        if (reader==null) {
                                            break;
                                        }
                                        line = reader.readLine();
                                        if(line == null) {
                                            //means no more lines to read
                                            if(!linesWithNoLogLevelInfo.isEmpty()){
                                                //means some lines was there wth no info, we havent yet added this
                                                //we have no more lines to read as well. so add these lines to the actual data
                                                readLines.addAll(linesWithNoLogLevelInfo);
                                                numberOfLinesRead = numberOfLinesRead + linesWithNoLogLevelInfo.size();
                                            }
                                            break;
                                        }
                
                                        if(line.trim().length() == 0) {
                                            //means an empty line
                                            //SKIP the line;
                                            continue;
                                        }
                                        isLogLevelPresentInString = false;//reset always first
                                        for(String logLevelStringToCheck: logLevelStringsToCheck){
                                            if(line.contains(logLevelStringToCheck)){
                                                isLogLevelPresentInString = true;
                                                break;
                                            }
                                        }

                                        //if(!logLevelStringsToCheck.stream().anyMatch(line::contains)){
                                        //commented out the 1.8 feature as some clients tomcat instance's jsp engine still suports java 1.7 
                                        if(!isLogLevelPresentInString){
                                            //msg+= "line doesnt have any log level.  LINE:  "+line+ "<br/>";
                                            //means this line doesnt have any log level info.
                                            //will this line be a part of any log level, we are yet to find out
                                            linesWithNoLogLevelInfo.add(line);
                                            //msg+= "!! Skipping line" + "<br/>";
                                            continue;
                                        }else{
                                            //msg+= "line has a log level.  LINE:  "+line+ "<br/>";
                                            //This line has a log level, do we have any read lines with no log levels present in linesWithNoLogLevelInfo?
                                            //if yes then, those lines should not be read if this lines' log level is either 
                                            //INFO or WARN as the user has requested to exclude those lines
                                            if(excludeTypeInfo && 
                                                (line.contains(" INFO") || line.contains("[info]"))){
                                                if(!linesWithNoLogLevelInfo.isEmpty()){
                                                    //lines present in 'linesWithNoLogLevelInfo' also needs to be skipped
                                                    //also we need to reset 'linesWithNoLogLevelInfo' list
                                                    linesWithNoLogLevelInfo.clear();
                                                }
                                                //SKIP the line
                                                //msg+= ">>> Skipping line" + "<br/>";
                                                continue;
                                            }
                
                                            if(excludeTypeWarn && line.contains(" WARN")){
                                                if(!linesWithNoLogLevelInfo.isEmpty()){
                                                    //lines present in 'linesWithNoLogLevelInfo' also needs to be skipped
                                                    //also we need to reset 'linesWithNoLogLevelInfo' list
                                                    linesWithNoLogLevelInfo.clear();
                                                }
                                                //SKIP the line
                                                //msg+= "*** Skipping line" + "<br/>";
                                                continue;
                                            }
                
                                            //we can safely assume that this 'line' has neither INFO nor WARN levels
                                            if(!linesWithNoLogLevelInfo.isEmpty()){
                                                //lines present in 'linesWithNoLogLevelInfo' shoudl not be skipped
                                                //Add these lines lso the the actual readlines
                                                readLines.addAll(linesWithNoLogLevelInfo);
                                                numberOfLinesRead = numberOfLinesRead + linesWithNoLogLevelInfo.size();
                                                //also we need to reset 'linesWithNoLogLevelInfo' list
                                                linesWithNoLogLevelInfo.clear();
                                            }
                                            //msg+= "adding LINE:  "+line+ "<br/>";
                                            readLines.add(line);
                                            numberOfLinesRead++;
                                        }
                                    }
                                }catch(Exception ex){
                                    //swallow exception?
                                    ex.printStackTrace();
                                }finally{
                                    if(reader!=null) reader.close();
                                }
                            }
                            if(!readLines.isEmpty()) {
                                //now the readLines have the content we need
                                Collections.reverse(readLines);
                                for(String data: readLines){
                                    logPreview = logPreview + System.lineSeparator() + data;
                                }
                                //reset the numberOfLinesRead size
                                //todo is this needed?????
                                numberOfLinesRead =  readLines.size();  
                            }                        
                        }
                        pageContext.setAttribute("logPreview", logPreview);
                        pageContext.setAttribute("numberOfLinesRead", numberOfLinesRead);
                        //pageContext.setAttribute("msg", msg);
                    %>
                    <div class="mt-3 bg-light">
                        <c:if test="${numberOfLinesRead eq 0}">
                            <h4 class="mb-2"><b><c:out value="${param.selLogFile}"/></b> is empty.</h4>
                        </c:if>
                        <c:if test="${numberOfLinesRead gt 0}">
                            <h4 class="mb-2">Displaying <b>last <c:out value="${numberOfLinesRead}" default="100"/> </b>lines of  <b><c:out value="${param.selLogFile}"/></b></h4>
                                <pre><c:out value="${logPreview}" escapeXml="false"/></pre>
                        </c:if>
                    </div>
                </c:if>
            </div>
            <div class="tab-pane fade" id="about">
               <div id="LicenseText">
                <p><b>About Minerra</b></p>

                <p>Formed in 2009, with a presence in Melbourne, Sydney, Singapore and the USA, Minerra delivers analytics consulting, system design and development, products and training to leading organisations across multiple sectors in Australia and Asia. Our solutions provide decision-makers and analysts in organisations with the tools, skills and knowledge to use data to monitor performance and make informed decisions.</p>

                <p>Minerra is also a premium Yellowfin implementation partner and the approved global provider of instructor-led Yellowfin training and technical product certification.</p>

                <p><a href="https://www.minerra.net/wp-content/uploads/2022/06/minerra_yellowfin_services_brochure.pdf" target="_blank">This brochure</a> provides more information about the Yellowfin services Minerra provides.</p>
                
                <p><b>License and Copyright</b></p>
                  <p>Copyright &copy; 2022 Minerra Pty Ltd</p>

                  <p>This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.</p>

                  <p>This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.</p>

                  <p>You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.</p>

                  <p>"Yellowfin" is the registered trademark of <a href="https://www.yellowfinbi.com" target="_blank">Yellowfin, Inc</a>.</p>

                  <p><b>Version Details</b></p>

                  <p>Version: 1.3</p>
                  
                  <p>Release Date: 13-02-2023</p>
               </div>
           </div>
        </div>
    </div>
    <footer>
      <div class="row">
          <div class="col-md-6 offset-md-3">
              <hr>
              <p class="text-center">Copyright &copy; 2022 Minerra Pty Ltd</p>
          </div>
      </div>
  </footer>
</div>
<script type="text/javascript">
    //From Steve: Test the size of the number entered and reject an entry great there 32,767
    function setInputFilter(textbox, inputFilter, errMsg) {
        ["input", "keydown", "keyup", "mousedown", "mouseup", "select", "contextmenu", "drop", "focusout"].
            forEach(function(event) {
                textbox.addEventListener(event, function(e) {
                    if (inputFilter(this.value)) {
                        // Accepted value
                        if (["keydown","mousedown","focusout"].indexOf(e.type) >= 0){
                            this.classList.remove("input-error");
                            this.setCustomValidity("");
                        }
                        this.oldValue = this.value;
                        this.oldSelectionStart = this.selectionStart;
                        this.oldSelectionEnd = this.selectionEnd;
                    } else if (this.hasOwnProperty("oldValue")) {
                        // Rejected value - restore the previous one
                        this.classList.add("input-error");
                        this.setCustomValidity(errMsg);
                        this.reportValidity();
                        this.value = this.oldValue;
                        this.setSelectionRange(this.oldSelectionStart, this.oldSelectionEnd);
                    } else {
                        // Rejected value - nothing to restore
                        this.value = "";
                    }
                });
            });
    }

    function setFilter(ele){
        setInputFilter(ele, 
                    function(value) {return /^\d*$/.test(value) && (value === "" || parseInt(value) <= 32767);},
                    "Must be between 0 and 32767");
    }
    
    setInputFilter(document.getElementById("numLines"), 
                    function(value) {return /^\d*$/.test(value) && (value === "" || parseInt(value) <= 32767);},
                    "Must be between 0 and 32767");
    setInputFilter(document.getElementById("numLinesAdv"), 
                    function(value) {return /^\d*$/.test(value) && (value === "" || parseInt(value) <= 32767);},
                    "Must be between 0 and 32767");
    </script>
</body>
</html>
