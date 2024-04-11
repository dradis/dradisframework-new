# Welcome to the Dradis Framework

[ ![CI](https://github.com/dradis/dradis-ce/actions/workflows/ci.yml/badge.svg)](https://github.com/dradis/dradis-ce/actions/workflows/ci.yml)
[ ![Code quality](https://codeclimate.com/github/dradis/dradis-ce/badges/gpa.svg)](https://codeclimate.com/github/dradis/dradis-ce)
[ ![Black Hat Arsenal](https://www.toolswatch.org/badges/arsenal/2016.svg)](https://www.blackhat.com/us-16/arsenal.html#dradis-framework)

Dradis is an open-source collaboration framework, tailored to InfoSec teams.

<a href="https://cloud.digitalocean.com/apps/new?repo=https://github.com/dradis/dradis-ce/tree/develop" target="_blank"><img src="https://www.deploytodo.com/do-btn-blue.svg" height="40"></a>

To try Dradis Community, you can deploy your own instance (you will need accounts in the cloud providers to get started).

## Our goals

* Share the information effectively.
* Easy to use, easy to be adopted. Otherwise it would present little benefit over other systems.
* Flexible: with a powerful and simple extensions interface.
* Small and portable. You should be able to use it while on site (no outside connectivity). It should be OS independent (no two testers use the same OS).


## Some of the features:

* Platform independent
* Markup support for the notes: text styles, code blocks, images, links, etc.
* Integration with existing systems and tools:
  * [Brakeman](https://dradis.com/integrations/brakeman.html)
  * [Burp Suite](https://dradis.com/integrations/burp.html)
  * [MediaWiki](https://dradis.com/integrations/mediawiki.html)
  * [Metasploit](https://dradis.com/integrations/metasploit.html)
  * [Nessus](https://dradis.com/integrations/nessus.html)
  * [NeXpose](https://dradis.com/integrations/nexpose.html)
  * [Nikto](https://dradis.com/integrations/nikto.html)
  * [Nmap](https://dradis.com/integrations/nmap.html)
  * [OpenVAS](https://dradis.com/integrations/openvas.html)
  * [Qualys](https://dradis.com/integrations/qualys.html)
  * [SAINT](https://dradis.com/integrations/saint.html)
  * [Zed Attack Proxy](https://dradis.com/integrations/zap.html)
  * ...
  * [Full list](http://dradis.org/integrations/)


## Editions

There are two editions of Dradis Framework:

* **Dradis Framework Community Edition (CE)**: open-source and available freely under the GPLv2 license.
* **Dradis Framework Professional Edition (Pro)**: includes extra features that are more useful for organizations dealing with bigger teams and multiple projects at a time. To use Pro and get official support please [become a subscriber](https://dradis.com/).


## Getting started: Community Edition

### From Git (recommended)

[Installing Dradis from Git](https://dradis.com/ce/documentation/install_git.html)

### Using Docker

If you'd like to use Dradis in Docker, first get the latest image:

```
docker image pull dradis/dradis-ce:latest
```

And then run the container:

```
docker run -it -p 3000:3000 dradis/dradis-ce
```


## Getting help

* https://dradis.com/support/
* [Community Forums](https://discuss.dradisframework.org/)
* [Slack channel](https://evening-hamlet-4416.herokuapp.com/)
* IRC: **#dradis** `irc.freenode.org`


## Contributing

Please see CONTRIBUTING.md for details.

Many thanks to all Dradis Framework [contributors](https://github.com/dradis/dradis-ce/graphs/contributors). Dradis has been around since 2007, and in 2016 we had to do some nasty Git gymnastics resulting in a lot of the previous SVN + Git history no longer being available in the current repo. We haven't deleted it though, and we're still very much grateful for the work of our former [contributors](https://github.com/dradis/dradis-legacy/graphs/contributors).


### Branching model
We're following Vincent Driessen's [A successful Git branching model](http://nvie.com/posts/a-successful-git-branching-model/) to try to keep things organized.

In this repo we will have: *master*, *develop*, *release-* and *hotfix-* branches.

If you need to work on a feature branch, fork the repo and work on your own copy. We can check it from there. Eventually you'll merge to your *develop* and back to origin's *develop*.


### Community Projects

* [check-user-pwned-dradis by GoVanguard](https://github.com/GoVanguard/check-user-pwned-dradis): Searches for compromised emails across data breaches and creates Dradis Issues
* [csv-data-import-dradis by GoVanguard](https://github.com/GoVanguard/csv-data-import-dradis): Imports Issues, Nodes, Evidence, and Notes from a CSV file into Dradis
* [PyDradis by Novacoast](https://github.com/ncatlabs/pydradis): Python wrapper for the Dradis REST API

Have you built a Dradis connector, add-on, or extension? Contact us so that we can feature it here.


## License

Dradis Framework Community Edition is released under [GNU General Public License version 2.0](http://www.gnu.org/licenses/old-licenses/gpl-2.0.html)

Dradis Framework Professional Edition is released under a commercial license.


## We're hiring

If you love open source, Ruby on Rails and would like to have a lot of freedom and autonomy in your work, maybe you should consider [joining our team](https://dradis.com/careers.html) to make Dradis even better.
