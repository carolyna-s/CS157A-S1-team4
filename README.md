# CS157A-S1-team4

1. Use the sql/setup.sql in workbench to create the schema and tables needed if not already done.
    (a) To do this use mysql -u root -p from terminal to get MySQL terminal
    (b) Run SOURCE C:/path-to/setup.sql;
2. in WEB-INF make a copy of the db_config_example.jsp and fill it out with your information
3. mysql connecter should be in tomcat lib folder
4. Tomcat's Root should point to this (so in tomcat/conf/Catalina/localhost create file ROOT.xml and copy paste this <Context docBase="path to folder here" reloadable="true"/>)
5. Start tomcat and go to http://localhost:8080/
6. For flight API, we are using SERPAPI, add your own free api key into the db_config and should work immediatly when searching flights