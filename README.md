rexpectable
===========

About
-----

This software is designed to help you to test your Rest Webservices 
(JSON + XML)

You can write test scenario using the "rexpectable" language.

rexpectable is written in ruby (tested with 1.9.3) and needs special gem to work:
  - gem install bruce-jsonpath --source 'http://gems.github.com'

if you want to use pathpath (test your JSONPath and Xpath expression) tool, you have to install qtbindings gem too.

Thanks
------

 - To my boss (@ Overkiz SAS), he authorized me to publish this code under MIT license
 - To Angelique Chauvel, she has tested "rexpectable" at the beginning of the project
 - To Yoan Roullard, he has developed the Javascript code (for HTML export)
 - To Florent Ivoula, he uses it a lot ;-).

How to use it
--------------

You can find a man in usr/share/man directory and some examples in usr/share/doc/rexpectable/

To use it, simply copy files to your system or build a Linux package (deb, rpm, whatever).

Maybe change the shebang of rexpectable.

It works under windows (tested) and maybe under MacOSX (not tested).

If you want to test a script, you have to install sinatra (gem install sinatra) and run restsrv.rb. All scripts test_*.rpt use restsrv.rb.

example:
/path/to/file/restsrv.rb &
/path/to/rexpectable -p - /path/to/file/test_ref.rpt

