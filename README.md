
[![RootDB](https://www.rootdb.fr/assets/logo_name_blue_500x250.png)]()

# RootDB

* [RootDB](https://www.rootdb.fr) is a self-hosted reporting webapp.
* This repository contains the definition of the official docker images available on [dockerhub](https://hub.docker.com/r/atomicwebsas/rootdb) and an installation script to help you install it without docker.
* Consult the documentation to setup RootDB with :
  * [Docker](https://documentation.rootdb.fr/install/install_with_docker.html) 
  * [Without Docker](https://documentation.rootdb.fr/install/install_without_docker.html) 
* You can use this repository for bug report or features request.

## Support
* Please consult the [roadmap](https://forum.rootdb.fr/d/6-roadmap) to know what is planned for the next releases.
* [Q&A](https://www.rootdb.fr/faqs)
* Community forum: [forum.rootdb.fr](https://forum.rootdb.fr/tags)
* Discord: [join server](https://discord.gg/guKvGJAqZm)

## Features

- Multi-reports - several reports can be opened in the same tab of your web browser.
- Multi-connectors - you can configure and use multiple database connections for your reports. (MySQL, MariaDB, PostgreSQL but more are planned)
- Generation of listings :
    - simple and practical dynamic table configurator.
    - create links to other reports.
- 2 graphics libraries available :
  - full access to the two most popular charting libraries: Chart.js and D3.js, without any limitations.
- View widgets :
  - Add a metric widget in your report to higlight important metrics.
  - Or add a generic info widget to add some context to your report.
- Cache system :
  - A user can put in cache a set of results for a specific period.
  - Or the developer can setup cache jobs, running periodically on a different sets of parameter.
- For developer :
  - javascript code, with sample SQL query, ready to use, for different chart models: the developer is guided.
  - practical keyboard shortcuts are available to limit the use of the mouse
- Report Parameters - use default parameters or easily create your own to filter the data in your reports.
- User management :
  - create user groups if necessary to easily limit access to your reports.
  - it is also possible to limit access to a report to one or more users.
- Integration - integrate your reports into external websites in just a few clicks.
- SQL :
  - access to a real SQL console, to view and list the tables of your databases.
  - create as many drafts as you want to test your SQL queries.
  - enjoy auto-completion wherever you need to type SQL.
- Websocket :
  - Interface heavily use websocket to refresh its interface and get results from data views.  





